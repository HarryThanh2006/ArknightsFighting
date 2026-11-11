extends GdUnitTestSuite
## M15 / F6 maximum player distance (design/gdd/character-movement.md), 60,000 su.

const LEFT: int = 1
const RIGHT: int = 2
const P0X: int = SimLayout.P_BASE + SimLayout.PF_X
const P1X: int = SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_X

func _sim(x0: int, x1: int) -> Sim:
	var sim := Sim.new()
	sim.init(9)
	sim.buffer[P0X] = x0
	sim.buffer[P1X] = x1
	return sim

## AC-M13: |dx| 59,800, both walk back 270 -> |dx| 60,000, each moved back exactly 100.
## Same with the players' sides swapped (P0 on the right).
func test_both_walking_back_split_the_excess_both_sides() -> void:
	for p0_right: bool in [false, true]:
		var sim := _sim(29_900 if p0_right else -29_900, -29_900 if p0_right else 29_900)
		sim.step(0, 0)  # settle facing
		var back0: int = RIGHT if p0_right else LEFT
		var back1: int = LEFT if p0_right else RIGHT
		var a: int = sim.buffer[P0X]
		var c: int = sim.buffer[P1X]
		sim.step(back0, back1)
		assert_int(absi(sim.buffer[P1X] - sim.buffer[P0X])).is_equal(60_000)
		assert_int(absi(sim.buffer[P0X] - a)).is_equal(100)
		assert_int(absi(sim.buffer[P1X] - c)).is_equal(100)

## Walking toward is never blocked; one player backing off alone at the limit stays put.
func test_toward_never_blocked_and_lone_retreat_absorbed() -> void:
	var sim := _sim(-30_000, 30_000)
	sim.step(LEFT, LEFT)  # P0 back 270, P1 toward 340
	assert_int(sim.buffer[P1X] - sim.buffer[P0X]).is_equal(60_000 - 340 + 270)
	sim = _sim(-30_000, 30_000)
	sim.step(LEFT, 0)
	assert_array([sim.buffer[P0X], sim.buffer[P1X]]).is_equal([-30_000, 30_000])

## Knockback away from the opponent is limited too: P1 knocked 1,000 away at
## |dx| 59,500 moves only 500 (the other did not move away). Mirrored for P0.
func test_knockback_beyond_limit_is_clipped_both_slots() -> void:
	for victim: int in [0, 1]:
		var sim := _sim(-29_750, 29_750)
		var base: int = SimLayout.P_BASE + victim * SimLayout.P_STRIDE
		sim.buffer[base + SimLayout.PF_KB_SPEED] = 1_000
		sim.buffer[base + SimLayout.PF_KB_DIR] = -1 if victim == 0 else 1
		sim.step(0, 0)
		assert_int(sim.buffer[P1X] - sim.buffer[P0X]).is_equal(60_000)
		assert_int(sim.buffer[P0X]).is_equal(-30_250 if victim == 0 else -29_750)

## Property: over 10,000 ticks of scripted walking, attacks and blocks |dx| never exceeds 60,000.
func test_distance_never_exceeds_limit_in_scripted_play() -> void:
	var sim := _sim(-15_000, 15_000)
	var gen := PackedInt64Array([0, 0])
	SimRng.seed(gen, 0, 23)
	var held := PackedInt64Array([0, 0])
	var left := PackedInt64Array([0, 0])
	var worst: int = 0
	for t: int in 10_000:
		for p: int in 2:
			if left[p] <= 0:
				var away: int = LEFT if p == 0 else RIGHT
				var choices := PackedInt64Array([away, away, 3 - away, 4, 8, 16, 0])
				held[p] = choices[SimRng.range_i(gen, 0, 0, 6)]
				left[p] = SimRng.range_i(gen, 0, 5, 60)
			left[p] -= 1
		sim.step(held[0], held[1])
		worst = maxi(worst, absi(sim.buffer[P1X] - sim.buffer[P0X]))
	assert_int(worst).is_equal(60_000)
