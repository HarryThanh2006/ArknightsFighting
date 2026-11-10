extends GdUnitTestSuite
## MatchRunner accumulator against a fake clock (ADR-0002 rule 2, W3 / W4, validation 3).
## No real time is read: every frame passes an explicit microsecond value.

const FRAME_USEC: int = 16_667  # ~60 Hz frame
const SEED: int = 1


func _runner() -> MatchRunner:
	var r: MatchRunner = auto_free(MatchRunner.new())
	r.start_match(SEED, 0)
	return r


func test_600_seconds_of_frames_step_exactly_36000_ticks() -> void:
	var r := _runner()
	var now: int = 0
	var max_per_frame: int = 0
	while now < 600_000_000:
		now = mini(now + FRAME_USEC, 600_000_000)
		max_per_frame = maxi(max_per_frame, r.advance(now))
	assert_int(r.ticks_stepped).is_equal(36_000)
	assert_int(r.ticks_dropped).is_equal(0)
	assert_int(max_per_frame).is_less_equal(2)


func test_144hz_frames_never_drift() -> void:
	var r := _runner()
	var now: int = 0
	for f: int in 144 * 60:  # 60 s at 144 Hz
		now += 6_944
		r.advance(now)
	@warning_ignore("integer_division")
	var expected: int = now * 60 / 1_000_000
	assert_int(r.ticks_stepped).is_equal(expected)


func test_hitch_caps_catchup_and_counts_dropped_ticks() -> void:
	var r := _runner()
	r.advance(1_000_000)  # 1 s in one frame: 60 due
	assert_int(r.ticks_stepped).is_equal(MatchRunner.MAX_CATCHUP_TICKS)
	assert_int(r.ticks_dropped).is_equal(60 - MatchRunner.MAX_CATCHUP_TICKS)
	assert_float(r.alpha).is_equal(1.0)
	var stepped: int = r.advance(1_500_000)  # +500 ms hitch: 30 due
	assert_int(stepped).is_equal(MatchRunner.MAX_CATCHUP_TICKS)
	assert_int(r.ticks_stepped + r.ticks_dropped).is_equal(90)


func test_after_hitch_runner_resumes_normal_speed() -> void:
	var r := _runner()
	r.advance(500_000)  # 30 due, 4 stepped, 26 dropped
	var before: int = r.ticks_stepped
	r.advance(500_000 + 1_000_000)  # one second later at normal pace in one frame -> capped again
	r.advance(500_000 + 1_000_000 + FRAME_USEC)
	assert_int(r.ticks_stepped + r.ticks_dropped).is_equal(90 + 1)
	assert_int(r.ticks_stepped).is_greater(before)


func test_pause_of_10_seconds_steps_nothing_and_does_not_count_as_elapsed() -> void:
	var r := _runner()
	r.advance(1_000_000)
	var t0: int = r.ticks_stepped + r.ticks_dropped
	r.pause(1_000_000)
	assert_int(r.advance(11_000_000)).is_equal(0)
	r.resume(11_000_000)
	r.advance(11_000_000)
	assert_int(r.ticks_stepped + r.ticks_dropped).is_equal(t0)
	r.advance(11_000_000 + FRAME_USEC)
	assert_int(r.ticks_stepped + r.ticks_dropped).is_equal(t0 + 1)


func test_alpha_is_fraction_of_tick_when_caught_up() -> void:
	var r := _runner()
	r.advance(25_000)  # 1.5 ticks
	assert_int(r.ticks_stepped).is_equal(1)
	assert_float(r.alpha).is_equal_approx(0.5, 0.0001)


func test_injected_clock_drives_process() -> void:
	var r := _runner()
	var fake := PackedInt64Array([50_000])  # 3 ticks due
	r.clock_usec = func() -> int: return fake[0]
	r._process(0.0)
	assert_int(r.ticks_stepped).is_equal(3)


func test_view_reads_sim_ints_after_stepping() -> void:
	var r := _runner()
	r.input_sampler = func(p: int) -> int: return SimPipeline.INPUT_RIGHT if p == 0 else 0
	r.advance(50_000)
	assert_int(r.view.tick()).is_equal(3)
	assert_int(r.view.pos_x_su(0)).is_equal(-SimPipeline.PLACEHOLDER_START_X_SU + 3 * SimPipeline.PLACEHOLDER_WALK_SU)
	assert_int(r.view.prev_pos_x_su(0)).is_equal(r.view.pos_x_su(0) - SimPipeline.PLACEHOLDER_WALK_SU)
