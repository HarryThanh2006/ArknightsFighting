extends GdUnitTestSuite
## Rules decided 2026-11-11 (user): D1 corner recoil transfer, D3 guard through
## blockstun, H2 6-tick input buffer, H3 Heavy arm hurtbox. See
## design/gdd/defense.md and design/gdd/hit-detection-damage.md.

const LIGHT: int = 4
const HEAVY: int = 8
const BLOCK: int = 16
## Movement bound = wall (±50,000) − pushbox half-width 2,500.
const BOUND: int = 47_500
## Light reaches a body while centre distance < 6,500 + 4,000 + 2,500.
const LIGHT_REACH: int = 13_000

func _pb(p: int) -> int:
	return SimLayout.P_BASE + p * SimLayout.P_STRIDE

func _sim(x0: int, x1: int) -> Sim:
	var sim := Sim.new()
	sim.init(17)
	sim.buffer[_pb(0) + SimLayout.PF_X] = x0
	sim.buffer[_pb(1) + SimLayout.PF_X] = x1
	return sim

func _step(sim: Sim, p: int, mine: int, theirs: int) -> void:
	if p == 0:
		sim.step(mine, theirs)
	else:
		sim.step(theirs, mine)

func _record(sim: Sim, p: int) -> int:
	return sim.buffer[SimLayout.HIT_BASE + p * SimLayout.HIT_STRIDE]

## D1: attacker's back to the wall, defender holds Block, attacker presses a fresh
## Light every 40 ticks. Blocks 1-3 land, the 4th whiffs (N = 3), for both walls and slots.
func test_corner_block_pushback_escapes_after_three_lights_both_walls_and_slots() -> void:
	for attacker: int in [0, 1]:
		for wall: int in [-1, 1]:
			var ax: int = wall * BOUND
			var dx: int = ax - wall * 5_000
			var sim := _sim(ax if attacker == 0 else dx, dx if attacker == 0 else ax)
			var results: Array[int] = []
			for swing: int in 4:
				var contact: int = 0
				for t: int in 40:
					_step(sim, attacker, LIGHT if t == 0 else 0, BLOCK)
					if _record(sim, attacker) != 0:
						contact = _record(sim, attacker)
				results.append(contact)
			var label: String = "attacker P%d at wall %d" % [attacker, wall]
			assert_array(results).override_failure_message(label + str(results)).is_equal([-1, -1, -1, 0])
			var gap: int = absi(sim.buffer[_pb(0) + SimLayout.PF_X] - sim.buffer[_pb(1) + SimLayout.PF_X])
			assert_int(gap).override_failure_message(label).is_greater_equal(LIGHT_REACH)
			assert_int(sim.buffer[_pb(1 - attacker) + SimLayout.PF_HP]).is_equal(1000)

## D3: after a blocked Light, releasing Block keeps the guard flag for all 8 blockstun ticks.
func test_guard_holds_through_blockstun_after_release() -> void:
	var sim := _sim(-2500, 2500)
	var t: int = 0
	while _record(sim, 0) == 0:
		sim.step(LIGHT if t == 0 else 0, BLOCK)
		t += 1
	var guarded_stun_ticks: int = 0
	for i: int in 30:
		sim.step(0, 0)  # Block released
		var stun: int = sim.buffer[_pb(1) + SimLayout.PF_BLOCKSTUN]
		var guarding: int = sim.buffer[_pb(1) + SimLayout.PF_BLOCKING]
		if stun > 0:
			assert_int(guarding).override_failure_message("guard dropped at stun %d" % stun).is_equal(1)
			guarded_stun_ticks += 1
	assert_int(sim.buffer[_pb(1) + SimLayout.PF_BLOCKING]).is_equal(0)
	assert_int(guarded_stun_ticks).is_greater_equal(7)

## H2 recovery: whiffed Light (16 frames) is actionable again on tick 16. A press at
## tick 10 (age 6) comes out on tick 16; a press at tick 9 (age 7) has expired.
func test_buffered_light_in_recovery_starts_on_first_actionable_tick_and_expires_after_six() -> void:
	for press: int in [10, 9]:
		var sim := _sim(-20_000, 20_000)
		for t: int in 17:
			sim.step(LIGHT if t == 0 or t == press else 0, 0)
			if t == 15:
				assert_int(sim.buffer[_pb(0) + SimLayout.PF_ATK_FRAME]).is_equal(16)
		var started: bool = sim.buffer[_pb(0) + SimLayout.PF_ATK_ACTIVE] == 1
		var frame: int = sim.buffer[_pb(0) + SimLayout.PF_ATK_FRAME]
		if press == 10:
			assert_bool(started and frame == 1).override_failure_message("age-6 press lost").is_true()
		else:
			assert_bool(started).override_failure_message("age-7 press fired").is_false()

## First tick on which the defender of a blocked Heavy may act (oracle: no buffer used).
func _blocked_heavy_actionable_tick() -> int:
	var sim := _sim(-2500, 2500)
	for t: int in 60:
		var b: PackedInt64Array = sim.buffer
		if t > 11 and b[_pb(1) + SimLayout.PF_BLOCKSTUN] == 0 and b[_pb(1) + SimLayout.PF_HITSTOP] == 0:
			return t
		sim.step(HEAVY if t == 0 else 0, BLOCK)
	return -1

## Runs a blocked Heavy where the defender presses Light at `press` (holding Block
## until then, and through `hold_until`). Returns the defender's attack state at `at`.
func _defender_attack_after(press: int, hold_until: int, at: int) -> Array[int]:
	var sim := _sim(-2500, 2500)
	var stopped_at_press: int = 0
	for t: int in at + 1:
		var w: int = BLOCK if t < press or t <= hold_until else 0
		if t == press:
			w |= LIGHT
			stopped_at_press = sim.buffer[_pb(1) + SimLayout.PF_HITSTOP] + sim.buffer[_pb(1) + SimLayout.PF_BLOCKSTUN]
		sim.step(HEAVY if t == 0 else 0, w)
	return [sim.buffer[_pb(1) + SimLayout.PF_ATK_ACTIVE], sim.buffer[_pb(1) + SimLayout.PF_ATK_FRAME], stopped_at_press]

## H2 hit-stop / blockstun: press 6 ticks before the first actionable tick T (while still
## stopped or stunned) starts Light on T; a press 7 ticks before has expired.
func test_buffered_light_during_stop_and_blockstun_comes_out_on_first_actionable_tick() -> void:
	var first: int = _blocked_heavy_actionable_tick()
	assert_int(first).is_greater(0)
	var at_t: Array[int] = _defender_attack_after(first - 6, -1, first)
	assert_int(at_t[2]).override_failure_message("press was not during stop/stun").is_greater(0)
	assert_array(at_t.slice(0, 2)).is_equal([1, 1])
	var before: Array[int] = _defender_attack_after(first - 6, -1, first - 1)
	assert_int(before[0]).is_equal(0)
	var expired: Array[int] = _defender_attack_after(first - 7, -1, first)
	assert_int(expired[0]).is_equal(0)

## H2: a buffered press is dropped when Block is held on the first actionable tick.
func test_buffered_press_dropped_when_block_held_on_actionable_tick() -> void:
	var first: int = _blocked_heavy_actionable_tick()
	assert_int(_defender_attack_after(first - 3, first, first)[0]).is_equal(0)
	assert_int(_defender_attack_after(first - 3, first, first + 2)[0]).is_equal(0)

## H3: Heavy whiffs at 17,000 su; a Light pressed `k` ticks after the Heavy press hits the
## arm hurtbox (Heavy frames 12-29) exactly for k in 4..23. Both slots.
func test_whiffed_heavy_is_punished_by_light_in_frame_window() -> void:
	for heavy_p: int in [0, 1]:
		var hits: Array[int] = []
		for k: int in range(0, 30):
			var sim := _sim(-8_500 if heavy_p == 0 else 8_500, 8_500 if heavy_p == 0 else -8_500)
			var light_hit: bool = false
			for t: int in 45:
				_step(sim, heavy_p, HEAVY if t == 0 else 0, LIGHT if t == k else 0)
				assert_int(_record(sim, heavy_p)).override_failure_message("Heavy connected").is_equal(0)
				if _record(sim, 1 - heavy_p) > 0:
					light_hit = true
			if light_hit:
				hits.append(k)
		assert_array(hits).override_failure_message("P%d Heavy %s" % [heavy_p, hits]).is_equal(range(4, 24))
