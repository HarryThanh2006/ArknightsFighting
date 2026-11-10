class_name SimMoveData
extends RefCounted
## Validated, read-only mirror kit. The source config is discarded after compilation.
const SOURCE: String = "res://data/moves/tier_minus_one.cfg"
const POSES: Array[String] = ["neutral", "light", "heavy"]
const TUNING: Array[String] = ["damage", "stop", "hitstun", "blockstun", "kb", "recoil"]
const MAX_FRAMES: int = 600
const MAX_VALUE: int = 1_000_000

var _kit: Dictionary = {}
var _moves: Array[Dictionary] = []
var _hash: int

## Load before constructing a match or comparing a replay header.
static func load_default() -> SimMoveData:
	var config := ConfigFile.new()
	if config.load(SOURCE) != OK:
		push_error("Cannot load move data: " + SOURCE)
		return null
	return compile(config)

## Field order for SimHash: kit values, then neutral/light/heavy in ID order.
## Each pose contributes duration, attack tuning (attacks only), then hit/hurt
## tracks in file order. Each track starts with its row count, then six ints per row.
static func compile(config: ConfigFile) -> SimMoveData:
	var data := SimMoveData.new()
	var words := PackedInt64Array()
	for key: String in ["max_hp", "kb_decel"]:
		var v: Variant = config.get_value("kit", key, -1)
		if not _integer_in(v, 1, MAX_VALUE):
			return null
		data._kit[key] = v
		var integer: int = v
		words.append(integer)
	data._kit.make_read_only()
	for pose: String in POSES:
		var duration: Variant = config.get_value(pose, "frames", -1)
		if not _integer_in(duration, 1, MAX_FRAMES) or (pose == "neutral" and duration != 1):
			return null
		var frames: int = duration
		words.append(frames)
		var move: Dictionary = {"frames": frames}
		if pose != "neutral":
			for key: String in TUNING:
				var v: Variant = config.get_value(pose, key, -1)
				if not _integer_in(v, 0, MAX_VALUE):
					return null
				move[key] = v
				var integer: int = v
				words.append(integer)
		for key: String in ["hitboxes", "hurtboxes"]:
			var rows: Variant = config.get_value(pose, key, false)
			if typeof(rows) != TYPE_ARRAY:
				return null
			var source: Array = rows
			var track: Array = _compile_track(source, frames, words)
			if track.is_empty():
				return null
			move[key] = track
		move.make_read_only()
		data._moves.append(move)
	data._moves.make_read_only()
	data._hash = SimHash.hash_words(words)
	return data

static func _integer_in(value: Variant, low: int, high: int) -> bool:
	return typeof(value) == TYPE_INT and value >= low and value <= high

## Pre-index active boxes by one-based frame; index 0 is unused.
static func _compile_track(rows: Array, frames: int, words: PackedInt64Array) -> Array:
	if rows.size() > 128:
		return []
	var track: Array[Array] = []
	for i: int in frames + 1:
		track.append([])
	words.append(rows.size())
	for entry: Variant in rows:
		if typeof(entry) != TYPE_ARRAY:
			return []
		var row: Array = entry
		if row.size() != 6:
			return []
		for v: Variant in row:
			if not _integer_in(v, -MAX_VALUE, MAX_VALUE):
				return []
			var integer: int = v
			words.append(integer)
		var start: int = row[0]
		var end: int = row[1]
		if start < 1 or end < start or end > frames or row[4] <= 0 or row[5] <= 0:
			return []
		var box: Array = row.slice(2)
		box.make_read_only()
		for frame: int in range(start, end + 1):
			track[frame].append(box)
	for active: Array in track:
		active.make_read_only()
	track.make_read_only()
	return track

func version_hash() -> int:
	return _hash

func max_hp() -> int:
	return _kit["max_hp"]

func kb_decel() -> int:
	return _kit["kb_decel"]

func move(id: int) -> Dictionary:
	return _moves[id]

func boxes(id: int, frame: int, track: String) -> Array:
	var frames: Array = _moves[id][track]
	return frames[1 if id == 0 else frame]
