extends GdUnitTestSuite
## Sim object: init, tick, freeze gate, Ended check, snapshot / restore
## (sim-core AC-L3, AC-L6, AC-L7, AC-L8, AC-T2, AC-T3, AC-T8, AC-T10, AC-X2, AC-X3).
## Systems are still no-op / PLACEHOLDER slots, so these test Sim Core's own rules only.

const SEED: int = 12345
const P1_X: int = SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_X
const P0_BASE: int = SimLayout.P_BASE
const RIGHT: int = Movement.INPUT_RIGHT
const LEFT: int = Movement.INPUT_LEFT


func _new_sim() -> Sim:
	var s := Sim.new()
	s.init(SEED)
	return s


## Indices whose value differs between two equal-size buffers.
func _changed(a: PackedInt64Array, b: PackedInt64Array) -> PackedInt64Array:
	var out := PackedInt64Array()
	for i: int in a.size():
		if a[i] != b[i]:
			out.append(i)
	return out


# --- AC-L7 ---

func test_init_zeroes_all_but_version_and_rng_and_returns_checksum() -> void:
	var s := Sim.new()
	s.buffer.resize(SimLayout.TOTAL)
	s.buffer.fill(0x5A)
	var c0: int = s.init(SEED)
	assert_int(s.buffer.size()).is_equal(SimLayout.TOTAL)
	assert_int(s.buffer[SimLayout.H_LAYOUT_VERSION]).is_equal(SimLayout.LAYOUT_VERSION)
	assert_int(s.buffer[SimLayout.H_TICK]).is_equal(0)
	assert_int(c0).is_equal(SimHash.hash_words(s.buffer))
	# Movement init writes start positions and facing; PLACEHOLDER Arena init writes the walls.
	var allowed: Array[int] = [SimLayout.H_LAYOUT_VERSION, SimLayout.H_RNG_S0, SimLayout.H_RNG_S1,
		P0_BASE + SimLayout.PF_X, P1_X, P0_BASE + SimLayout.PF_FACING,
		SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_FACING, SimLayout.A_WALL_L, SimLayout.A_WALL_R,
		P0_BASE + SimLayout.PF_HP, P0_BASE + SimLayout.P_STRIDE + SimLayout.PF_HP, SimLayout.R_ROUND, SimLayout.R_CLOCK]
	for i: int in SimLayout.TOTAL:
		if not allowed.has(i):
			assert_int(s.buffer[i]).override_failure_message("word %d" % i).is_equal(0)


# --- AC-L3, AC-T10 ---

func test_buffer_stays_total_size_and_checksum_is_not_stored() -> void:
	var s := _new_sim()
	for t: int in 1000:
		var c: int = s.step(RIGHT if t % 3 == 0 else 0, LEFT)
		assert_int(s.buffer.size()).is_equal(SimLayout.TOTAL)
		assert_int(c).is_equal(SimHash.hash_words(s.buffer))
		if t % 100 == 0:
			assert_bool(Array(s.buffer).has(c)).is_false()


# --- Block A (rule 8) and AC-L8 input ring ---

func test_block_a_copies_prev_clears_snap_and_writes_input_ring() -> void:
	var s := _new_sim()
	s.step(RIGHT, LEFT)  # tick 1: moves both players
	s.buffer[P0_BASE + SimLayout.PF_SNAP] = 1
	s.step(0, 0)  # tick 2
	assert_int(s.buffer[SimLayout.H_TICK]).is_equal(2)
	assert_int(s.buffer[P0_BASE + SimLayout.PF_PREV_X]).is_equal(-Movement.START_X_SU + Movement.WALK_FWD_SU)
	assert_int(s.buffer[P0_BASE + SimLayout.PF_SNAP]).is_equal(0)
	assert_int(s.buffer[SimLayout.IN_BASE + 1]).is_equal(RIGHT)  # tick 1, p0, slot 1
	assert_int(s.buffer[SimLayout.IN_BASE + 32 + 1]).is_equal(LEFT)  # tick 1, p1


func test_first_step_after_init_writes_ring_slot_1() -> void:
	var s := _new_sim()
	s.step(7, 9)
	assert_int(s.buffer[SimLayout.IN_BASE + 1]).is_equal(7)
	assert_int(s.buffer[SimLayout.IN_BASE + SimLayout.INPUT_RING_TICKS + 1]).is_equal(9)


# --- AC-T3, AC-L6: freeze gate ---

func test_frozen_step_runs_block_a_only_and_decrements_freeze() -> void:
	var s := _new_sim()
	s.step(RIGHT, 0)
	s.buffer[SimLayout.H_FREEZE_TICKS] = 3
	var before := s.snapshot()
	s.step(RIGHT, LEFT)
	assert_int(s.buffer[SimLayout.H_FREEZE_TICKS]).is_equal(2)
	var allowed := PackedInt64Array([SimLayout.H_TICK, SimLayout.H_FREEZE_TICKS,
		P0_BASE + SimLayout.PF_PREV_X, SimLayout.IN_BASE + 2, SimLayout.IN_BASE + 32 + 2])
	for i: int in _changed(before, s.buffer):
		assert_bool(allowed.has(i)).override_failure_message("word %d changed on a frozen tick" % i).is_true()
	assert_int(s.buffer[P0_BASE + SimLayout.PF_X]).is_equal(before[P0_BASE + SimLayout.PF_X])
	assert_int(s.buffer[SimLayout.H_RNG_S0]).is_equal(before[SimLayout.H_RNG_S0])


func test_freeze_of_three_skips_exactly_three_block_b_ticks() -> void:
	var s := _new_sim()
	s.buffer[SimLayout.H_FREEZE_TICKS] = 3
	var x0: int = s.buffer[P0_BASE + SimLayout.PF_X]
	for t: int in 3:
		s.step(RIGHT, 0)
	assert_int(s.buffer[P0_BASE + SimLayout.PF_X]).is_equal(x0)
	s.step(RIGHT, 0)
	assert_int(s.buffer[P0_BASE + SimLayout.PF_X]).is_equal(x0 + Movement.WALK_FWD_SU)


# --- AC-T2: Ended sim changes nothing ---

func test_ended_sim_changes_no_word_and_returns_previous_checksum() -> void:
	for flag: int in [1, 7]:
		var s := _new_sim()
		s.step(RIGHT, LEFT)
		s.buffer[SimLayout.R_MATCH_OVER] = flag
		var before := s.snapshot()
		var c_before: int = SimHash.hash_words(before)
		assert_int(s.step(RIGHT, LEFT)).is_equal(c_before)
		assert_int(_changed(before, s.buffer).size()).is_equal(0)


# --- AC-T8: determinism ---

func test_same_seed_and_inputs_give_identical_checksums_and_one_change_diverges_at_its_tick() -> void:
	var a := _new_sim()
	var b := _new_sim()
	var c := _new_sim()
	for t: int in 1000:
		var w0: int = RIGHT if posmod(t, 14) < 7 else LEFT
		var w1: int = LEFT if posmod(t, 22) < 11 else 0
		var w1_c: int = w1 ^ RIGHT if t == 499 else w1  # tick 500
		var ca: int = a.step(w0, w1)
		assert_int(b.step(w0, w1)).is_equal(ca)
		var cc: int = c.step(w0, w1_c)
		if t < 499:
			assert_int(cc).is_equal(ca)
		elif t == 499:
			assert_int(cc).is_not_equal(ca)


# --- AC-X2: snapshot / restore ---

func test_restore_reproduces_checksum_and_resteps_identically_without_touching_snapshot() -> void:
	var s := _new_sim()
	for t: int in 100:
		s.step(RIGHT if t % 2 == 0 else 0, LEFT)
	var snap := s.snapshot()
	var snap_copy := snap.duplicate()
	var c100: int = SimHash.hash_words(snap)
	var run1 := PackedInt64Array()
	for t: int in 50:
		run1.append(s.step(LEFT, RIGHT))
	assert_int(s.restore(snap)).is_equal(OK)
	assert_int(SimHash.hash_words(s.buffer)).is_equal(c100)
	for t: int in 50:
		assert_int(s.step(LEFT, RIGHT)).is_equal(run1[t])
	assert_bool(snap == snap_copy).is_true()


# --- AC-X3: invalid snapshots rejected, state unchanged ---

func test_restore_rejects_wrong_size_or_version_and_keeps_state() -> void:
	var s := _new_sim()
	s.step(RIGHT, LEFT)
	var before := s.snapshot()
	var bad: Array[PackedInt64Array] = []
	for n: int in [0, 4, SimLayout.TOTAL + 1]:
		var p := PackedInt64Array()
		p.resize(n)
		p.fill(0)
		bad.append(p)
	for delta: int in [-1, 1]:
		var v := s.snapshot()
		v[SimLayout.H_LAYOUT_VERSION] = SimLayout.LAYOUT_VERSION + delta
		bad.append(v)
	for p: PackedInt64Array in bad:
		assert_int(s.restore(p)).is_equal(ERR_INVALID_DATA)
		assert_bool(s.buffer == before).is_true()
