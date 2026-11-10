extends GdUnitTestSuite
## SimMath + engine integer characterisation (ADR-0001 V1, V2, validation 1-2;
## sim-core AC-P4, AC-P7). Oracles are hand-computed tables, not SimMath itself.

const INT64_MAX: int = 9223372036854775807
const INT64_MIN: int = -9223372036854775807 - 1
## Committed seed for the local test LCG (never the engine's global RNG).
const LCG_SEED: int = 20261110


## Local LCG (Knuth MMIX constants), state passed in a 1-element array.
static func _lcg_small(state: PackedInt64Array) -> int:
	state[0] = state[0] * 6364136223846793005 + 1442695040888963407
	return (state[0] >> 33) & 0xFFFFF  # 20 bits, non-negative


# --- V1: int is 64-bit signed and wraps silently ---

func test_int_add_past_max_wraps_to_min() -> void:
	var m: int = INT64_MAX
	assert_int(m + 1).is_equal(INT64_MIN)


func test_int_mul_overflow_wraps_without_error() -> void:
	var m: int = INT64_MAX
	assert_int(m * 2).is_equal(-2)


# --- V2: raw `/` truncates toward zero, `%` takes the dividend's sign ---

func test_raw_division_truncates_toward_zero() -> void:
	var a: int = -7
	@warning_ignore("integer_division")
	var q: int = a / 2
	assert_int(q).is_equal(-3)
	assert_int(a % 2).is_equal(-1)


# --- div_floor / mod_floor against a signed table ---

func test_div_floor_signed_table_matches_floor() -> void:
	# [a, b, floor(a / b)]
	var cases: Array[PackedInt64Array] = [
		PackedInt64Array([7, 2, 3]), PackedInt64Array([-7, 2, -4]),
		PackedInt64Array([7, -2, -4]), PackedInt64Array([-7, -2, 3]),
		PackedInt64Array([6, 3, 2]), PackedInt64Array([-6, 3, -2]),
		PackedInt64Array([0, 5, 0]), PackedInt64Array([-1, 1000, -1]),
		PackedInt64Array([-5, 2, -3]), PackedInt64Array([5, 2, 2]),
		PackedInt64Array([INT64_MAX, 1, INT64_MAX]),
		PackedInt64Array([INT64_MIN, 2, -4611686018427387904]),
		PackedInt64Array([INT64_MIN, -1, INT64_MIN]),  # wraps, no fault
		PackedInt64Array([5, -1, -5]),
	]
	for c: PackedInt64Array in cases:
		assert_int(SimMath.div_floor(c[0], c[1])).override_failure_message(
			"div_floor(%d, %d)" % [c[0], c[1]]).is_equal(c[2])


func test_mod_floor_signed_table_takes_divisor_sign() -> void:
	# [a, b, a - b * floor(a / b)]
	var cases: Array[PackedInt64Array] = [
		PackedInt64Array([7, 2, 1]), PackedInt64Array([-7, 2, 1]),
		PackedInt64Array([7, -2, -1]), PackedInt64Array([-7, -2, -1]),
		PackedInt64Array([-1, 208, 207]), PackedInt64Array([209, 208, 1]),
		PackedInt64Array([INT64_MIN, 208, 96]), PackedInt64Array([INT64_MAX, 208, 111]),
		PackedInt64Array([INT64_MIN, -1, 0]), PackedInt64Array([7, 1, 0]),
	]
	for c: PackedInt64Array in cases:
		assert_int(SimMath.mod_floor(c[0], c[1])).override_failure_message(
			"mod_floor(%d, %d)" % [c[0], c[1]]).is_equal(c[2])


func test_div_mod_floor_property_reconstructs_dividend() -> void:
	var st := PackedInt64Array([LCG_SEED])
	for i: int in 500:
		var a: int = _lcg_small(st) - 0x80000
		var b: int = _lcg_small(st) % 2001 - 1000
		if b == 0:
			continue
		var q: int = SimMath.div_floor(a, b)
		var r: int = SimMath.mod_floor(a, b)
		assert_int(q * b + r).is_equal(a)
		if b > 0:
			assert_bool(r >= 0 and r < b).is_true()
		else:
			assert_bool(r <= 0 and r > b).is_true()


# --- AC-P7 (PROPOSED value 0) ---

func test_zero_divisor_returns_proposed_value_without_engine_error() -> void:
	assert_int(SimMath.div_floor(5, 0)).is_equal(0)
	assert_int(SimMath.mod_floor(5, 0)).is_equal(0)
	assert_int(SimMath.div_floor(INT64_MIN, 0)).is_equal(0)


# --- AC-P4: posmod characterisation (Debug) ---

func test_posmod_measured_values_hold() -> void:
	assert_int(posmod(-7, 3)).is_equal(2)
	assert_int(posmod(-1, 208)).is_equal(207)
	assert_int(posmod(209, 208)).is_equal(1)
	assert_int(posmod(INT64_MAX, 208)).is_equal(111)
	assert_int(posmod(INT64_MIN, 208)).is_equal(96)


# --- mul_permille ---

func test_mul_permille_floors_toward_negative_infinity() -> void:
	assert_int(SimMath.mul_permille(1000, 500)).is_equal(500)
	assert_int(SimMath.mul_permille(7, 1500)).is_equal(10)      # 10.5 -> 10
	assert_int(SimMath.mul_permille(-1001, 500)).is_equal(-501)  # -500.5 -> -501
	assert_int(SimMath.mul_permille(100_000, 10_000)).is_equal(1_000_000)


# --- boxes_overlap: strict (ADR-0001 rule 6, validation 2) ---

func test_boxes_touching_at_edge_do_not_overlap() -> void:
	# A spans x [-10, 10], B spans x [10, 30]: shared edge only.
	assert_bool(SimMath.boxes_overlap(0, 0, 10, 10, 20, 0, 10, 10)).is_false()
	assert_bool(SimMath.boxes_overlap(0, 0, 10, 10, 0, 20, 10, 10)).is_false()


func test_boxes_overlapping_by_one_su_overlap() -> void:
	assert_bool(SimMath.boxes_overlap(0, 0, 10, 10, 19, 0, 10, 10)).is_true()
	assert_bool(SimMath.boxes_overlap(0, 0, 10, 10, -19, 19, 10, 10)).is_true()


func test_boxes_overlap_needs_both_axes() -> void:
	assert_bool(SimMath.boxes_overlap(0, 0, 10, 10, 5, 25, 10, 10)).is_false()
