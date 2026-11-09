extends GdUnitTestSuite
## Sanity suite: proves the gdUnit4 runner finds and runs tests in this project,
## so a CI run that reports "0 tests" can never be mistaken for a pass.
## Remove once real system suites exist under tests/unit/.

const EXPECTED_ENGINE_MAJOR := 4
const EXPECTED_ENGINE_MINOR := 7


func test_runner_executes_assertions_passes() -> void:
	assert_bool(true).is_true()


func test_engine_version_matches_project_pin() -> void:
	# The pin lives in project.yaml (engine.version 4.7.2). A mismatch means the
	# editor or CI runner is not the engine the reference docs describe.
	var info: Dictionary = Engine.get_version_info()
	assert_int(info["major"]).is_equal(EXPECTED_ENGINE_MAJOR)
	assert_int(info["minor"]).is_equal(EXPECTED_ENGINE_MINOR)
