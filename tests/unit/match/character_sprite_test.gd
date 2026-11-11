extends GdUnitTestSuite
## CharacterSprite tick -> drawing mapping and frames.cfg consistency with move data
## (design/art/sprite-spec-2d.md §3-4).

const FRAMES: String = "res://assets/characters/guard_blockout/frames.cfg"
const MOVES: String = "res://data/moves/tier_minus_one.cfg"

func _cfg(path: String) -> ConfigFile:
	var c := ConfigFile.new()
	assert_int(c.load(path)).is_equal(OK)
	return c

func test_drawing_index_maps_ranges_loops_and_clamps() -> void:
	var light: Array = [[1, 2], [3, 5], [6, 8], [9, 11], [12, 14], [15, 16]]
	var got: Array[int] = []
	for counter: int in [1, 2, 3, 6, 8, 9, 16, 40]:
		got.append(CharacterSprite.drawing_index(light, counter, false))
	assert_array(got).is_equal([0, 0, 1, 2, 2, 3, 5, 5])
	var idle: Array = [[0, 7], [8, 15], [16, 23], [24, 31]]
	var looped: Array[int] = []
	for counter: int in [0, 8, 31, 32, 41, -1]:
		looped.append(CharacterSprite.drawing_index(idle, counter, true))
	assert_array(looped).is_equal([0, 1, 3, 0, 1, 3])

## Attack ranges tile 1..frames with no gap, and exactly one drawing equals the active window.
func test_attack_ranges_cover_move_and_isolate_active_frames() -> void:
	var frames := _cfg(FRAMES)
	var moves := _cfg(MOVES)
	for anim: String in ["light", "heavy"]:
		var ranges: Array = frames.get_value(anim, "ranges")
		var total: int = moves.get_value(anim, "frames")
		var hit_rows: Array = moves.get_value(anim, "hitboxes")
		var row: Array = hit_rows[0]
		var expect_next: int = 1
		var active_drawings: int = 0
		for r: Array in ranges:
			var lo: int = r[0]
			var hi: int = r[1]
			assert_int(lo).override_failure_message(anim).is_equal(expect_next)
			expect_next = hi + 1
			if lo == row[0] and hi == row[1]:
				active_drawings += 1
		assert_int(expect_next - 1).override_failure_message(anim).is_equal(total)
		assert_int(active_drawings).override_failure_message(anim).is_equal(1)

## Drop-in override: a character folder without a strip falls back to the blockout's;
## a folder that has the strip uses its own.
func test_strip_path_falls_back_per_animation() -> void:
	var blockout: String = "res://assets/characters/guard_blockout"
	var surtr: String = "res://assets/characters/surtr"
	assert_str(CharacterSprite.strip_path(surtr, "surtr", blockout, "guard_blockout", "light")).is_equal(
		blockout + "/guard_blockout_light.png")
	assert_str(CharacterSprite.strip_path(blockout, "guard_blockout", surtr, "surtr", "light")).is_equal(
		blockout + "/guard_blockout_light.png")
	assert_str(CharacterSprite.strip_path(surtr, "surtr", "", "", "light")).is_equal(surtr + "/surtr_light.png")
