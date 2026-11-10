extends GdUnitTestSuite
## SimLayout self-test and snapshot semantics (sim-core AC-L1, AC-L2, AC-L8 layout
## parts; rules 2-4, 15a; F3, F4, F10; ADR-0001 R7). The region list below is the
## test's own oracle, written from the F3 table, not read from SimLayout.

## Golden fingerprint per LAYOUT_VERSION: MD5 of "NAME=value;" over every SimLayout
## constant, sorted by name. Change a constant -> bump LAYOUT_VERSION and add its entry here.
const GOLDEN_FINGERPRINT: Dictionary = {
	2: "e55fe9fca1b5e9c51a86dbceada021e4",  # + PF_X, PF_Y, R_MATCH_OVER placeholders
	3: "bcb202a81387774e91b1936cea55595c",  # + Movement fields, PF_ATK_ACTIVE / PF_HITSTOP placeholders, arena walls
}


## [base, size] in buffer order (F3): header, event control, players, input ring,
## projectiles, hit events, AI, round, arena, event ring.
func _regions() -> Array[PackedInt64Array]:
	return [
		PackedInt64Array([SimLayout.HDR_BASE, SimLayout.HDR_SIZE]),
		PackedInt64Array([SimLayout.EVC_BASE, SimLayout.EVC_SIZE]),
		PackedInt64Array([SimLayout.P_BASE, SimLayout.P_COUNT * SimLayout.P_STRIDE]),
		PackedInt64Array([SimLayout.IN_BASE, SimLayout.P_COUNT * SimLayout.INPUT_RING_TICKS]),
		PackedInt64Array([SimLayout.PROJ_BASE, SimLayout.PROJ_CAP * SimLayout.PROJ_STRIDE]),
		PackedInt64Array([SimLayout.HIT_BASE, SimLayout.HIT_CAP * SimLayout.HIT_STRIDE]),
		PackedInt64Array([SimLayout.AI_BASE, SimLayout.AI_SIZE]),
		PackedInt64Array([SimLayout.ROUND_BASE, SimLayout.ROUND_SIZE]),
		PackedInt64Array([SimLayout.ARENA_BASE, SimLayout.ARENA_SIZE]),
		PackedInt64Array([SimLayout.EV_BASE, SimLayout.EVENT_RING_ENTRIES * SimLayout.EVENT_WORDS]),
	]


static func _fingerprint() -> String:
	var script: Script = load("res://src/sim/sim_layout.gd")
	var consts: Dictionary = script.get_script_constant_map()
	# PackedStringArray: sorting the StringName keys directly is not alphabetical (order varied run to run).
	var names := PackedStringArray(consts.keys())
	names.sort()
	var text: String = ""
	for n: String in names:
		var value: int = consts[n]
		text += "%s=%d;" % [n, value]
	return text.md5_text()


# --- AC-L1 ---

func test_regions_are_contiguous_and_end_at_total_within_budget() -> void:
	var cursor: int = 0
	for r: PackedInt64Array in _regions():
		assert_int(r[0]).override_failure_message("region at %d" % r[0]).is_equal(cursor)
		assert_int(r[1]).override_failure_message("region at %d size" % r[0]).is_greater(0)
		cursor += r[1]
	assert_int(cursor).is_equal(SimLayout.TOTAL)
	assert_int(SimLayout.TOTAL).is_less_equal(SimLayout.SIM_BUFFER_WORD_BUDGET)


func test_f3_estimate_totals_1624_words() -> void:
	assert_int(SimLayout.TOTAL).is_equal(1624)


func test_header_fields_lie_inside_their_regions() -> void:
	for i: int in [SimLayout.H_TICK, SimLayout.H_FREEZE_TICKS, SimLayout.H_RNG_S0,
			SimLayout.H_RNG_S1, SimLayout.H_LAYOUT_VERSION]:
		assert_bool(i >= SimLayout.HDR_BASE and i < SimLayout.HDR_BASE + SimLayout.HDR_SIZE).is_true()
	for i: int in [SimLayout.EC_EVENT_SEQ, SimLayout.EC_OBS_THIS_TICK, SimLayout.EC_CRIT_THIS_TICK,
			SimLayout.EC_EVENT_OVERFLOW_COUNT, SimLayout.EC_CRITICAL_OVERFLOW_COUNT, SimLayout.EC_SIM_FAULT]:
		assert_bool(i >= SimLayout.EVC_BASE and i < SimLayout.EVC_BASE + SimLayout.EVC_SIZE).is_true()
	assert_int(SimLayout.H_RNG_S1).is_equal(SimLayout.H_RNG_S0 + 1)


func test_modulo_divisors_are_positive_and_rings_fit_regions() -> void:
	for d: int in [SimLayout.INPUT_RING_TICKS, SimLayout.EVENT_RING_ENTRIES, SimLayout.PROJ_CAP, SimLayout.HIT_CAP]:
		assert_int(d).is_greater(0)
	assert_int(SimLayout.EV_BASE + SimLayout.EVENT_RING_ENTRIES * SimLayout.EVENT_WORDS).is_less_equal(SimLayout.TOTAL)
	assert_int(SimLayout.HIT_CAP).is_equal(SimLayout.P_COUNT + SimLayout.PROJ_CAP)


func test_movement_reserved_offsets_are_first_three_words() -> void:
	assert_int(SimLayout.PF_PREV_X).is_equal(0)
	assert_int(SimLayout.PF_PREV_Y).is_equal(1)
	assert_int(SimLayout.PF_SNAP).is_equal(2)


# --- AC-L8 (layout parts; the MatchRunner and step() parts wait for those classes) ---

func test_event_ring_entries_follow_f4() -> void:
	var expected: int = SimLayout.MAX_EVENTS_PER_TICK * (SimLayout.CATCHUP_RESERVE + SimLayout.ROLLBACK_WINDOW_TICKS + 1)
	assert_int(SimLayout.EVENT_RING_ENTRIES).is_equal(expected)
	assert_int(expected).is_equal(208)
	assert_int(SimLayout.OBS_CAP).is_less(SimLayout.MAX_EVENTS_PER_TICK)


func test_input_word_for_tick_100_player_1_lands_at_in_base_plus_36() -> void:
	var p: int = 1
	var index: int = SimLayout.IN_BASE + p * SimLayout.INPUT_RING_TICKS + posmod(100, SimLayout.INPUT_RING_TICKS)
	assert_int(index).is_equal(SimLayout.IN_BASE + 36)


# --- AC-L2 ---

func test_layout_fingerprint_matches_golden_for_layout_version() -> void:
	assert_bool(GOLDEN_FINGERPRINT.has(SimLayout.LAYOUT_VERSION)).override_failure_message(
		"no golden fingerprint for LAYOUT_VERSION %d" % SimLayout.LAYOUT_VERSION).is_true()
	var golden: String = GOLDEN_FINGERPRINT.get(SimLayout.LAYOUT_VERSION, "")
	assert_str(_fingerprint()).override_failure_message(
		"SimLayout changed without bumping LAYOUT_VERSION; fingerprint is " + _fingerprint()
	).is_equal(golden)


# --- Snapshot semantics (ADR-0001 R7): assignment aliases, duplicate() copies ---

func test_buffer_assignment_aliases_and_duplicate_is_independent() -> void:
	var b := PackedInt64Array()
	b.resize(SimLayout.TOTAL)
	b.fill(0)
	var alias := b
	var snap := b.duplicate()
	b[SimLayout.H_TICK] = 7
	assert_int(alias[SimLayout.H_TICK]).is_equal(7)
	assert_int(snap[SimLayout.H_TICK]).is_equal(0)
	assert_int(snap.size()).is_equal(SimLayout.TOTAL)
