extends GdUnitTestSuite
## SimHash (ADR-0001 rule 8, validation 6). Golden values from an independent
## Python big-int FNV-1a-64 oracle applied per int64 word.

const INT64_MAX: int = 9223372036854775807
const INT64_MIN: int = -9223372036854775807 - 1


func test_empty_buffer_hashes_to_offset_basis() -> void:
	assert_int(SimHash.hash_words(PackedInt64Array())).is_equal(-3750763034362895579)


func test_small_buffers_match_golden_values() -> void:
	assert_int(SimHash.hash_words(PackedInt64Array([0]))).is_equal(-5808590958014384161)
	assert_int(SimHash.hash_words(PackedInt64Array([1, 2, 3]))).is_equal(-3410805910829992533)
	assert_int(SimHash.hash_words(PackedInt64Array([-1, INT64_MIN, INT64_MAX]))).is_equal(-2164388534302593873)


func test_word_order_changes_hash() -> void:
	assert_int(SimHash.hash_words(PackedInt64Array([3, 2, 1]))).is_equal(-2166299485512046141)


func test_zeroed_total_size_buffer_matches_golden() -> void:
	var b := PackedInt64Array()
	b.resize(SimLayout.TOTAL)
	b.fill(0)
	assert_int(SimHash.hash_words(b)).is_equal(4815617852320866309)


func test_one_word_change_changes_hash_and_restoring_it_restores_hash() -> void:
	var b := PackedInt64Array()
	b.resize(SimLayout.TOTAL)
	b.fill(0)
	var h0: int = SimHash.hash_words(b)
	b[SimLayout.TOTAL - 1] = 1
	assert_int(SimHash.hash_words(b)).is_not_equal(h0)
	b[SimLayout.TOTAL - 1] = 0
	assert_int(SimHash.hash_words(b)).is_equal(h0)
