extends GdUnitTestSuite
## Character Movement, Tier −1 subset (design/gdd/character-movement.md AC-M1-M10, AC-M8b).
## Expected positions are hand-computed in each test (F1, F3, F5); symmetry tests
## compare two independent runs. Walls ±50,000, PUSH_HW 2,500 (bounds ±47,500).

const R: int = Movement.INPUT_RIGHT
const L: int = Movement.INPUT_LEFT
const BASE0: int = SimLayout.P_BASE
const BASE1: int = SimLayout.P_BASE + SimLayout.P_STRIDE
const LCG_SEED: int = 4242


func _sim(x0: int, x1: int) -> Sim:
	var s := Sim.new()
	s.init(1)
	s.buffer[BASE0 + SimLayout.PF_X] = x0
	s.buffer[BASE1 + SimLayout.PF_X] = x1
	s.buffer[BASE0 + SimLayout.PF_FACING] = 1 if x1 >= x0 else -1
	s.buffer[BASE1 + SimLayout.PF_FACING] = -1 if x1 >= x0 else 1
	return s


func _x(s: Sim, p: int) -> int:
	return s.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_X]


func _facing(s: Sim, p: int) -> int:
	return s.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_FACING]


## World-mirrored input word: LEFT <-> RIGHT.
func _mirror(w: int) -> int:
	return ((w & L) * 2) | ((w & R) >> 1)


# --- AC-M1: walk speeds ---

func test_walk_forward_340_and_back_270_per_tick() -> void:
	var a := _sim(0, 40_000)
	for t: int in 10:
		a.step(R, 0)
	assert_int(_x(a, 0)).is_equal(3_400)
	var b := _sim(0, 40_000)
	for t: int in 10:
		b.step(L, 0)
	assert_int(_x(b, 0)).is_equal(-2_700)


func test_p1_facing_left_walks_toward_with_left() -> void:
	var s := _sim(-40_000, 0)
	s.step(0, L)
	assert_int(_x(s, 1)).is_equal(-340)
	s.step(0, R)
	assert_int(_x(s, 1)).is_equal(-340 + 270)


# --- AC-M3 ---

func test_left_and_right_together_is_neutral_and_idle() -> void:
	var s := _sim(0, 40_000)
	for t: int in 5:
		s.step(L | R, 0)
	assert_int(_x(s, 0)).is_equal(0)
	assert_int(Movement.derived(s.buffer, 0)).is_equal(Movement.DERIVED_IDLE)


# --- AC-M2: P0 / P1 swap and mirrored stage give the same per-character result ---

func test_swapping_player_slots_gives_identical_per_character_motion() -> void:
	var a := _sim(-15_000, 15_000)
	var b := _sim(15_000, -15_000)  # same characters, slots swapped
	var st := PackedInt64Array([LCG_SEED])
	for t: int in 300:
		var wl: int = _rand_word(st)
		var wr: int = _rand_word(st)
		a.step(wl, wr)
		b.step(wr, wl)
		assert_int(_x(b, 1)).is_equal(_x(a, 0))
		assert_int(_x(b, 0)).is_equal(_x(a, 1))


func test_mirrored_stage_gives_mirrored_positions_every_tick() -> void:
	var a := _sim(-15_000, 15_000)
	var b := _sim(-15_000, 15_000)
	var st := PackedInt64Array([LCG_SEED + 1])
	for t: int in 300:
		var w0: int = _rand_word(st)
		var w1: int = _rand_word(st)
		a.step(w0, w1)
		b.step(_mirror(w1), _mirror(w0))  # P0 in b plays a's P1 mirrored
		assert_int(_x(b, 0)).is_equal(-_x(a, 1))
		assert_int(_x(b, 1)).is_equal(-_x(a, 0))


## Committed-seed LCG: neutral, left, right or both, held for 1-20 ticks via low bits.
func _rand_word(st: PackedInt64Array) -> int:
	st[0] = st[0] * 6364136223846793005 + 1442695040888963407
	return (st[0] >> 40) & 3


# --- AC-M4: odd overlap, F3 ---

func test_odd_overlap_moves_each_by_ceil_half() -> void:
	var s := _sim(-2_000, 2_999)
	s.step(0, 0)
	assert_int(_x(s, 0)).is_equal(-2_001)
	assert_int(_x(s, 1)).is_equal(3_000)
	var t := _sim(2_999, -2_000)
	t.step(0, 0)
	assert_int(_x(t, 1)).is_equal(-2_001)
	assert_int(_x(t, 0)).is_equal(3_000)


# --- AC-M5: both walk into each other ---

func test_walking_into_each_other_stops_at_contact_symmetrically() -> void:
	var s := _sim(-3_000, 3_000)
	var expected: Array[int] = [2_660, 2_500, 2_500, 2_500, 2_500]
	for t: int in 5:
		s.step(R, L)
		assert_int(_x(s, 0)).is_equal(-expected[t])
		assert_int(_x(s, 1)).is_equal(expected[t])


# --- AC-M6: wall clamp ---

func test_walking_back_into_the_wall_clamps_at_bound() -> void:
	var s := _sim(-47_400, 0)
	s.step(L, 0)
	assert_int(_x(s, 0)).is_equal(-47_500)
	for t: int in 20:
		s.step(L, R)
		assert_bool(_x(s, 0) >= -47_500 and _x(s, 1) <= 47_500).is_true()


# --- AC-M7: corner push-out, F5 (both walls) ---

func test_cornered_character_stays_and_walker_stops_at_contact() -> void:
	var s := _sim(-47_500, -42_300)
	s.step(0, L)
	assert_int(_x(s, 0)).is_equal(-47_500)
	assert_int(_x(s, 1)).is_equal(-42_500)
	var m := _sim(42_300, 47_500)
	m.step(R, 0)
	assert_int(_x(m, 1)).is_equal(47_500)
	assert_int(_x(m, 0)).is_equal(42_500)


func test_pushing_a_cornered_opponent_never_moves_it() -> void:
	var s := _sim(-47_500, -42_500)
	for t: int in 30:
		s.step(0, L)
		assert_int(_x(s, 0)).is_equal(-47_500)
		assert_int(_x(s, 1) - _x(s, 0)).is_greater_equal(5_000)


# --- AC-M8, AC-M8b: facing and its lock ---

func test_facing_from_dx_follows_ec33() -> void:
	assert_int(Movement.facing_from_dx(-1, 1)).is_equal(-1)
	assert_int(Movement.facing_from_dx(0, 1)).is_equal(1)
	assert_int(Movement.facing_from_dx(0, -1)).is_equal(-1)
	assert_int(Movement.facing_from_dx(1, -1)).is_equal(1)


func test_unlocked_wrong_facing_turns_on_next_tick() -> void:
	var s := _sim(-20_000, 20_000)
	s.buffer[BASE0 + SimLayout.PF_FACING] = -1
	s.buffer[BASE1 + SimLayout.PF_FACING] = 1
	s.step(0, 0)
	assert_int(_facing(s, 0)).is_equal(1)
	assert_int(_facing(s, 1)).is_equal(-1)


func test_facing_locked_while_attacking_then_turns_when_lock_clears() -> void:
	var s := _sim(-20_000, 20_000)
	s.buffer[BASE0 + SimLayout.PF_FACING] = -1
	s.buffer[BASE0 + SimLayout.PF_ATK_ACTIVE] = 1
	s.step(0, 0)
	assert_int(_facing(s, 0)).is_equal(-1)
	s.buffer[BASE0 + SimLayout.PF_ATK_ACTIVE] = 0
	s.step(0, 0)
	assert_int(_facing(s, 0)).is_equal(1)


func test_facing_locked_while_airborne_then_turns_when_lock_clears() -> void:
	var s := _sim(-20_000, 20_000)
	s.buffer[BASE1 + SimLayout.PF_FACING] = 1
	s.buffer[BASE1 + SimLayout.PF_MSTATE] = Movement.MSTATE_AIR
	s.step(0, 0)
	assert_int(_facing(s, 1)).is_equal(1)
	s.buffer[BASE1 + SimLayout.PF_MSTATE] = Movement.MSTATE_LANDING
	s.step(0, 0)
	assert_int(_facing(s, 1)).is_equal(-1)


func test_not_actionable_while_attacking_or_airborne() -> void:
	var s := _sim(0, 40_000)
	s.buffer[BASE0 + SimLayout.PF_ATK_ACTIVE] = 1
	s.step(R, 0)
	assert_int(_x(s, 0)).is_equal(0)
	assert_int(Movement.derived(s.buffer, 0)).is_equal(Movement.DERIVED_ATTACK)
	s.buffer[BASE0 + SimLayout.PF_ATK_ACTIVE] = 0
	s.step(R, 0)
	assert_int(_x(s, 0)).is_equal(340)
	assert_int(Movement.derived(s.buffer, 0)).is_equal(Movement.DERIVED_WALK)


# --- AC-M9: hit-stop ---

func test_hitstop_skips_own_advance() -> void:
	var s := _sim(0, 40_000)
	s.buffer[BASE0 + SimLayout.PF_HITSTOP] = 3
	for t: int in 3:
		s.step(R, 0)
	assert_int(_x(s, 0)).is_equal(0)
	assert_int(s.buffer[BASE0 + SimLayout.PF_HITSTOP]).is_equal(0)
	s.step(R, 0)
	assert_int(_x(s, 0)).is_equal(340)


func test_hitstopped_character_is_still_pushed_by_the_walker() -> void:
	var s := _sim(0, 5_000)
	s.buffer[BASE1 + SimLayout.PF_HITSTOP] = 5
	s.step(R, 0)  # P0 walks 340 into the frozen P1: overlap 340, 170 each
	assert_int(_x(s, 0)).is_equal(170)
	assert_int(_x(s, 1)).is_equal(5_170)


# --- AC-M10: ownership ---

func test_movement_slot_writes_only_movement_words() -> void:
	var s := _sim(-3_000, 3_000)
	SimPipeline.block_a(s.buffer, R, L)
	var before := s.buffer.duplicate()
	Movement.step(s.buffer)
	for i: int in s.buffer.size():
		if s.buffer[i] != before[i]:
			var p: int = 0 if i < BASE1 else 1
			var off: int = i - (SimLayout.P_BASE + p * SimLayout.P_STRIDE)
			assert_bool(off >= 3 and off <= 15).override_failure_message("word %d changed" % i).is_true()
