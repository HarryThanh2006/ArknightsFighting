extends GdUnitTestSuite
## Golden replay: the committed fixture re-simulates to identical per-tick checksums
## (concept: replay + checksum in CI; sim-core AC-T8 / AC-V1 Tier −1 stand-in;
## ADR-0001 validation 3 runs on every CI OS). Reads one committed fixture file.

const FIXTURE: String = "res://tests/integration/sim_core/fixtures/golden_replay.txt"
const FIXTURE_TICKS: int = 10_000


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
	r.words[2 * (t - 1)] ^= Movement.INPUT_RIGHT | Movement.INPUT_LEFT
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

func test_record_writes_move_data_hash_header() -> void:
	var replay := SimReplay.record(7, PackedInt64Array())
	assert_bool(replay.to_text().contains("\nmove_data_hash ")).is_true()

func test_one_hurtbox_frame_changes_contact_and_refuses_old_replay() -> void:
	var config := ConfigFile.new()
	assert_int(config.load(SimMoveData.SOURCE)).is_equal(OK)
	var original := SimMoveData.compile(config)
	# Heavy frame 6 shifts the defender's hurtbox behind its back. Light connects on 6.
	config.set_value("heavy", "hurtboxes", [[1, 5, 0, 6000, 2500, 6000],
			[6, 6, -20000, 6000, 2500, 6000], [7, 29, 0, 6000, 2500, 6000]])
	var modified := SimMoveData.compile(config)
	assert_int(original.version_hash()).is_not_equal(modified.version_hash())
	var header_only := SimReplay.record(5, PackedInt64Array(), original)
	assert_int(header_only.first_mismatch(modified)).is_equal(0)
	var baseline := Sim.new(original)
	var alternate := Sim.new(modified)
	assert_int(baseline.init(5)).is_equal(alternate.init(5))
	for sim: Sim in [baseline, alternate]:
		sim.buffer[SimLayout.P_BASE + SimLayout.PF_X] = -2500
		sim.buffer[SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_X] = 2500
		for t: int in 6:
			sim.step(4, 8)
	var hp: int = SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_HP
	assert_int(baseline.buffer[hp]).is_equal(940)
	assert_int(alternate.buffer[hp]).is_equal(1000)
	alternate.step(0, 0)
	assert_int(alternate.buffer[hp]).is_equal(940)

func test_legacy_replay_parses_but_requires_hash_for_playback() -> void:
	var text: String = "arknights-replay 1\nlayout_version 4\nseed 5\nticks 0\nc0 0\n"
	var legacy := SimReplay.from_text(text)
	assert_object(legacy).is_not_null()
	assert_str(legacy.to_text()).is_equal(text)
	assert_int(legacy.first_mismatch()).is_equal(0)
	var modern: String = text.replace("replay 1", "replay 2")
	assert_object(SimReplay.from_text(modern)).is_null()
	assert_object(SimReplay.from_text(modern.replace("seed", "move_data_hash text\nseed"))).is_null()

func test_kit_validation_rejects_invalid_frames_extents_and_fractions() -> void:
	var config := ConfigFile.new()
	assert_int(config.load(SimMoveData.SOURCE)).is_equal(OK)
	for invalid: Array in [[0, 1, 0, 0, 1, 1], [8, 6, 0, 0, 1, 1], [1, 17, 0, 0, 1, 1],
			[1, 1, 0, 0, 0, 1], [1, 1, 0.5, 0, 1, 1], [1, 1, 0]]:
		config.set_value("light", "hitboxes", [invalid])
		assert_object(SimMoveData.compile(config)).is_null()

func test_compiled_boxes_are_read_only_and_detached_from_source() -> void:
	var config := ConfigFile.new()
	assert_int(config.load(SimMoveData.SOURCE)).is_equal(OK)
	var kit := SimMoveData.compile(config)
	var active: Array = kit.boxes(1, 6, "hitboxes")
	var shape: Array = active[0]
	assert_bool(active.is_read_only()).is_true()
	assert_bool(shape.is_read_only()).is_true()
	config.set_value("light", "hitboxes", [])
	assert_int(kit.boxes(1, 6, "hitboxes").size()).is_equal(1)
	assert_int(kit.boxes(1, 5, "hitboxes").size()).is_equal(0)
	assert_int(kit.boxes(1, 9, "hitboxes").size()).is_equal(0)
