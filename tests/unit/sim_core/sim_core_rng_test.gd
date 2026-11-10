extends GdUnitTestSuite
## SimRng (ADR-0001 rule 7, validation 6; sim-core EC-31, AC-X1 for the SimRng part).
## Golden values come from an independent Python big-int oracle of splitmix64 +
## xorshift128+ 23/18/5 (masked to 64 bits), not from SimRng.

const INT64_MIN: int = -9223372036854775807 - 1
const SLOT: int = 2
const DRAWS: int = 1000

## Seed 12345 -> state after seed() and the first 8 next() values.
const GOLDEN_12345_STATE: Array[int] = [2454886589211414944, 3778200017661327597]
const GOLDEN_12345_SEQ: Array[int] = [
	6233086606872742541, 8068093359486558699, -5167171210566177746, 7067430833834273300,
	5869501872498816438, 8546184145333981366, -7675341174649472037, -5438916696891469318,
]
const GOLDEN_0_STATE: Array[int] = [-2152535657050944081, 7960286522194355700]
const GOLDEN_NEG1_STATE: Array[int] = [-1956407806741107680, -1612297016619662647]
const GOLDEN_MIN_STATE: Array[int] = [5196802822362493915, -4292029157624213486]


func _seeded(seed_value: int) -> PackedInt64Array:
	var b := PackedInt64Array()
	b.resize(8)
	b.fill(0)
	SimRng.seed(b, SLOT, seed_value)
	return b


func test_seed_12345_matches_golden_state_and_sequence() -> void:
	var b := _seeded(12345)
	assert_int(b[SLOT]).is_equal(GOLDEN_12345_STATE[0])
	assert_int(b[SLOT + 1]).is_equal(GOLDEN_12345_STATE[1])
	for expected: int in GOLDEN_12345_SEQ:
		assert_int(SimRng.next(b, SLOT)).is_equal(expected)


func test_edge_seeds_match_golden_states() -> void:
	var seeds: Array[int] = [0, -1, INT64_MIN]
	var goldens: Array[Array] = [GOLDEN_0_STATE, GOLDEN_NEG1_STATE, GOLDEN_MIN_STATE]
	for i: int in seeds.size():
		var b := _seeded(seeds[i])
		var golden: Array[int] = goldens[i]
		assert_int(b[SLOT]).is_equal(golden[0])
		assert_int(b[SLOT + 1]).is_equal(golden[1])


func test_edge_seeds_give_nonzero_state_and_varying_draws() -> void:
	for s: int in [0, -1, INT64_MIN]:
		var b := _seeded(s)
		assert_int(b[SLOT] | b[SLOT + 1]).is_not_equal(0)
		var first: int = SimRng.next(b, SLOT)
		var all_equal: bool = true
		for i: int in DRAWS - 1:
			if SimRng.next(b, SLOT) != first:
				all_equal = false
		assert_bool(all_equal).is_false()


func test_ensure_nonzero_replaces_all_zero_state() -> void:
	var b := PackedInt64Array([0, 0, 0, 0])
	SimRng.ensure_nonzero(b, SLOT)
	assert_int(b[SLOT] | b[SLOT + 1]).is_not_equal(0)
	assert_int(b[SLOT]).is_equal(SimRng.NONZERO_FALLBACK)


func test_ensure_nonzero_keeps_nonzero_state() -> void:
	var b := PackedInt64Array([0, 0, 0, 5])
	SimRng.ensure_nonzero(b, SLOT)
	assert_int(b[SLOT]).is_equal(0)
	assert_int(b[SLOT + 1]).is_equal(5)


func test_next_touches_only_its_two_state_words() -> void:
	var b := _seeded(12345)
	for i: int in b.size():
		if i != SLOT and i != SLOT + 1:
			b[i] = 1000 + i
	var before := b.duplicate()
	SimRng.next(b, SLOT)
	for i: int in b.size():
		if i != SLOT and i != SLOT + 1:
			assert_int(b[i]).is_equal(before[i])


func test_same_seed_gives_identical_streams() -> void:
	var a := _seeded(777)
	var c := _seeded(777)
	for i: int in DRAWS:
		assert_int(SimRng.next(a, SLOT)).is_equal(SimRng.next(c, SLOT))


func test_range_i_stays_inclusive_and_reaches_both_ends() -> void:
	var b := _seeded(42)
	var seen_lo: bool = false
	var seen_hi: bool = false
	for i: int in DRAWS:
		var v: int = SimRng.range_i(b, SLOT, -3, 3)
		assert_bool(v >= -3 and v <= 3).is_true()
		seen_lo = seen_lo or v == -3
		seen_hi = seen_hi or v == 3
	assert_bool(seen_lo and seen_hi).is_true()


func test_range_i_single_value_and_empty_range_return_lo() -> void:
	var b := _seeded(42)
	assert_int(SimRng.range_i(b, SLOT, 9, 9)).is_equal(9)
	assert_int(SimRng.range_i(b, SLOT, 9, 8)).is_equal(9)
