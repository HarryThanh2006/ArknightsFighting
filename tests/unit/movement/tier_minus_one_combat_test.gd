extends GdUnitTestSuite

const P0: int = SimLayout.P_BASE
const P1: int = P0 + SimLayout.P_STRIDE

func _duel() -> Sim:
	var sim := Sim.new()
	sim.init(17)
	sim.buffer[P0 + SimLayout.PF_X] = -2500
	sim.buffer[P1 + SimLayout.PF_X] = 2500
	return sim

func test_light_trade_connects_on_sixth_tick_for_both_players() -> void:
	var sim := _duel()
	sim.step(4, 4)
	for tick: int in 4:
		sim.step(0, 0)
	assert_int(sim.buffer[P0 + SimLayout.PF_HITSTOP]).is_equal(0)
	sim.step(0, 0)
	for base: int in [P0, P1]:
		assert_int(sim.buffer[base + SimLayout.PF_HITSTOP]).is_equal(6)

		assert_int(sim.buffer[base + SimLayout.PF_HP]).is_equal(940)
		assert_int(sim.buffer[base + SimLayout.PF_ATK_ACTIVE]).is_equal(0)

func test_block_stops_damage_and_held_light_does_not_retrigger() -> void:
	var sim := _duel()
	for tick: int in 6:
		sim.step(4, 16)
	assert_int(sim.buffer[P1 + SimLayout.PF_HP]).is_equal(1000)
	assert_int(sim.buffer[P1 + SimLayout.PF_BLOCKSTUN]).is_equal(8)
	assert_int(sim.buffer[P0 + SimLayout.PF_HITSTOP]).is_equal(3)
	for tick: int in 3:
		sim.step(4, 16)
	assert_int(sim.buffer[P0 + SimLayout.PF_ATK_FRAME]).is_equal(6)
	assert_int(sim.buffer[P1 + SimLayout.PF_BLOCKSTUN]).is_equal(8)
	sim.step(4, 16)
	assert_int(sim.buffer[P0 + SimLayout.PF_X]).is_equal(-3300)
	for tick: int in 30:
		sim.step(4, 16)
	assert_int(sim.buffer[P0 + SimLayout.PF_ATK_ACTIVE]).is_equal(0)
	assert_int(sim.buffer[P1 + SimLayout.PF_HP]).is_equal(1000)

func test_heavy_mirrors_and_exact_edge_whiffs() -> void:
	for side: int in [-1, 1]:
		for gap: int in [16499, 16500]:
			var sim := _duel()
			sim.buffer[P0 + SimLayout.PF_X] = 0
			sim.buffer[P1 + SimLayout.PF_X] = side * gap
			sim.step(8, 0)
			for tick: int in 11:
				sim.step(0, 0)
			var hp: int = 860 if gap == 16499 else 1000
			assert_int(sim.buffer[P1 + SimLayout.PF_HP]).is_equal(hp)

func test_final_tick_trade_double_ko_replays_same_round() -> void:
	var sim := _duel()
	sim.buffer[P0 + SimLayout.PF_HP] = 60
	sim.buffer[P1 + SimLayout.PF_HP] = 60
	sim.buffer[SimLayout.R_CLOCK] = 6
	for tick: int in 6:
		sim.step(4, 4)
	assert_int(sim.buffer[SimLayout.R_RESULT]).is_equal(0)
	assert_int(sim.buffer[P0 + SimLayout.PF_HP]).is_equal(0)
	assert_int(sim.buffer[P1 + SimLayout.PF_HP]).is_equal(0)
	for tick: int in 90:
		sim.step(0, 0)
	assert_int(sim.buffer[SimLayout.R_ROUND]).is_equal(1)
	assert_int(sim.buffer[SimLayout.R_CLOCK]).is_equal(5940)
	assert_int(sim.buffer[P1 + SimLayout.PF_HP]).is_equal(1000)
	assert_int(sim.buffer[P0 + SimLayout.PF_SNAP]).is_equal(1)

func test_equal_timeout_replays_then_split_rounds_end_two_to_one() -> void:
	var sim := _duel()
	for expected_winner: int in [0, 1, 2, 2]:
		sim.buffer[SimLayout.R_CLOCK] = 1
		if expected_winner == 1:
			sim.buffer[P1 + SimLayout.PF_HP] = 999
		elif expected_winner == 2:
			sim.buffer[P0 + SimLayout.PF_HP] = 999
		sim.step(0, 0)
		assert_int(sim.buffer[SimLayout.R_RESULT]).is_equal(expected_winner)
		for tick: int in 90:
			sim.step(0, 0)
	assert_int(sim.buffer[SimLayout.R_MATCH_OVER]).is_equal(1)
	assert_int(sim.buffer[SimLayout.R_WINS_0]).is_equal(1)
	assert_int(sim.buffer[SimLayout.R_WINS_1]).is_equal(2)
	var ended := sim.snapshot()
	sim.step(4, 8)
	assert_bool(sim.buffer == ended).is_true()

func test_match_from_spawn_to_two_kos_with_only_player_inputs() -> void:
	var sim := Sim.new()
	sim.init(3)
	for tick: int in 4000:
		var input: int = Movement.INPUT_RIGHT
		if posmod(tick, 45) == 0:
			input |= 8
		sim.step(input, 0)
		if sim.buffer[SimLayout.R_MATCH_OVER] != 0:
			break
	assert_int(sim.buffer[SimLayout.R_RESULT]).is_equal(1)
	assert_int(sim.buffer[SimLayout.R_WINS_0]).is_equal(2)
	assert_int(sim.buffer[P1 + SimLayout.PF_HP]).is_equal(0)

func test_swapping_players_mirrors_hit_block_recoil_and_hp() -> void:
	var left := _duel()
	var right := _duel()
	for tick: int in 100:
		var attack: int = 4 if tick == 0 else 0
		if tick == 40:
			attack = 8
		var guard: int = 16 if tick < 30 else 0
		left.step(attack, guard)
		right.step(guard, attack)
		for p: int in 2:
			var a: int = P0 + p * SimLayout.P_STRIDE
			var b: int = P0 + (1 - p) * SimLayout.P_STRIDE
			assert_int(left.buffer[a + SimLayout.PF_X]).is_equal(-right.buffer[b + SimLayout.PF_X])
			for field: int in [SimLayout.PF_HP, SimLayout.PF_HITSTOP, SimLayout.PF_HITSTUN,
					SimLayout.PF_BLOCKSTUN, SimLayout.PF_ATK_FRAME, SimLayout.PF_KB_SPEED]:
				assert_int(left.buffer[a + field]).is_equal(right.buffer[b + field])

func test_snapshot_during_hitstop_resumes_identically() -> void:
	var live := _duel()
	for tick: int in 12:
		live.step(0, 8)
	assert_int(live.buffer[P0 + SimLayout.PF_HP]).is_equal(860)
	var resumed := Sim.new()
	assert_int(resumed.restore(live.snapshot())).is_equal(OK)
	for tick: int in 60:
		var w: int = 4 if tick == 40 else 0
		assert_int(resumed.step(w, 0)).is_equal(live.step(w, 0))
