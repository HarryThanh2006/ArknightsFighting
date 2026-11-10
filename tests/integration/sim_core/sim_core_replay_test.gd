extends GdUnitTestSuite
## Golden replay: the committed fixture re-simulates to identical per-tick checksums
## (concept: replay + checksum in CI; sim-core AC-T8 / AC-V1 Tier −1 stand-in;
## ADR-0001 validation 3 runs on every CI OS). Reads one committed fixture file.

const FIXTURE: String = "res://tests/integration/sim_core/fixtures/golden_replay.txt"
const FIXTURE_TICKS: int = 5000


func _load() -> SimReplay:
	return SimReplay.from_text(FileAccess.get_file_as_string(FIXTURE))


func test_golden_fixture_parses_with_current_layout() -> void:
	var r := _load()
	assert_object(r).is_not_null()
	assert_int(r.tick_count()).is_equal(FIXTURE_TICKS)
	assert_int(r.layout_version).is_equal(SimLayout.LAYOUT_VERSION)


func test_golden_replay_matches_every_tick_twice_in_one_process() -> void:
	var r := _load()
	assert_int(r.first_mismatch()).is_equal(-1)
	assert_int(r.first_mismatch()).is_equal(-1)


func test_rerecording_the_fixture_inputs_gives_identical_checksums() -> void:
	var r := _load()
	var again := SimReplay.record(r.seed_value, r.words)
	assert_bool(again.checksums == r.checksums).is_true()


func test_one_changed_input_word_is_detected_at_its_tick() -> void:
	var r := _load()
	var t: int = 2500
	r.words[2 * (t - 1)] ^= SimPipeline.INPUT_RIGHT | SimPipeline.INPUT_LEFT
	assert_int(r.first_mismatch()).is_equal(t)


func test_text_round_trip_is_lossless() -> void:
	var text: String = FileAccess.get_file_as_string(FIXTURE)
	assert_str(_load().to_text()).is_equal(text)


func test_layout_version_mismatch_refuses_playback() -> void:
	var r := _load()
	r.layout_version = SimLayout.LAYOUT_VERSION + 1
	assert_int(r.first_mismatch()).is_equal(0)


func test_malformed_text_is_rejected() -> void:
	assert_object(SimReplay.from_text("")).is_null()
	assert_object(SimReplay.from_text("arknights-replay 1\nlayout_version 2\nseed 1\nticks 2\nc0 5\n0 0 1\n")).is_null()
	assert_object(SimReplay.from_text("arknights-replay 1\nlayout_version 2\nseed x\nticks 0\nc0 5\n")).is_null()
