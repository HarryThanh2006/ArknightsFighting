class_name SimReplay
extends RefCounted
## Tier −1 replay: header + per-tick input words + per-tick checksums; playback
## re-simulates and compares (concept: replay + per-tick checksum in CI).
## Format 2 checks move-data compatibility before creating the playback simulation.
##
## Text format (one record per line, ints in decimal, 64-bit exact):
##   arknights-replay 2
##   layout_version <int>
##   move_data_hash <int>
##   seed <int>
##   ticks <N>
##   c0 <tick-0 checksum>
##   <w0> <w1> <checksum after the tick>     (N lines)

const FORMAT_TAG: String = "arknights-replay"
const FORMAT_VERSION: int = 2

var format_version: int = FORMAT_VERSION
var move_data_hash: int

var seed_value: int = 0
var layout_version: int = SimLayout.LAYOUT_VERSION
## Input words, two per tick: [w0 of tick 1, w1 of tick 1, w0 of tick 2, ...].
var words: PackedInt64Array = PackedInt64Array()
## Checksums for ticks 0..N (index 0 = after init).
var checksums: PackedInt64Array = PackedInt64Array()


## Number of recorded ticks.
func tick_count() -> int:
	return checksums.size() - 1


## Runs a fresh sim over `input_words` (two per tick) and records its checksums.
static func record(seed_in: int, input_words: PackedInt64Array,
		kit: SimMoveData = SimMoveData.load_default()) -> SimReplay:
	if kit == null:
		return null
	var r := SimReplay.new()
	r.move_data_hash = kit.version_hash()
	r.seed_value = seed_in
	r.words = input_words.duplicate()
	r.checksums = _simulate(seed_in, input_words, kit)
	return r


## Re-simulates and returns the first tick whose checksum differs, or -1 if all match.
## Returns 0 when the layout version differs (the replay cannot be played).
func first_mismatch(kit: SimMoveData = SimMoveData.load_default()) -> int:
	if format_version != FORMAT_VERSION or layout_version != SimLayout.LAYOUT_VERSION:
		return 0
	if kit == null or move_data_hash != kit.version_hash():
		return 0
	var live := _simulate(seed_value, words, kit)
	for t: int in checksums.size():
		if live[t] != checksums[t]:
			return t
	return -1


static func _simulate(seed_in: int, input_words: PackedInt64Array, kit: SimMoveData) -> PackedInt64Array:
	var sim := Sim.new(kit)
	var out := PackedInt64Array()
	out.append(sim.init(seed_in))
	for i: int in range(0, input_words.size() - 1, 2):
		out.append(sim.step(input_words[i], input_words[i + 1]))
	return out


func to_text() -> String:
	var lines := PackedStringArray([
		"%s %d" % [FORMAT_TAG, format_version],
		"layout_version %d" % layout_version,
		"seed %d" % seed_value,
		"ticks %d" % tick_count(),
		"c0 %d" % checksums[0],
	])
	if format_version == FORMAT_VERSION:
		lines.insert(2, "move_data_hash %d" % move_data_hash)
	for t: int in tick_count():
		lines.append("%d %d %d" % [words[2 * t], words[2 * t + 1], checksums[t + 1]])
	return "\n".join(lines) + "\n"


## Parses to_text() output. Returns null on any malformed line, count mismatch or bad tag
## (external data is untrusted, sim-core EC-28). A different layout_version parses, but
## first_mismatch() then refuses to play it.
static func from_text(text: String) -> SimReplay:
	var lines := text.strip_edges().split("\n")
	if lines.size() < 5:
		return null
	var version: int = FORMAT_VERSION
	if lines[0].strip_edges() == "%s 1" % FORMAT_TAG:
		version = 1
	elif lines[0].strip_edges() != "%s %d" % [FORMAT_TAG, FORMAT_VERSION]:
		return null
	var head: Dictionary = {}
	var keys := PackedStringArray(["layout_version", "seed", "ticks", "c0"])
	if version == FORMAT_VERSION:
		keys.insert(1, "move_data_hash")
	var header_size: int = keys.size() + 1
	if lines.size() < header_size:
		return null
	for k: int in keys.size():
		var parts := lines[k + 1].strip_edges().split(" ")
		if parts.size() != 2 or parts[0] != keys[k] or not parts[1].is_valid_int():
			return null
		var value: int = parts[1].to_int()
		if str(value) != parts[1]:
			return null
		head[keys[k]] = value
	var n: int = head["ticks"]
	if n < 0 or n != lines.size() - header_size:
		return null
	var r := SimReplay.new()
	r.format_version = version
	r.layout_version = head["layout_version"]
	r.seed_value = head["seed"]
	r.move_data_hash = head.get("move_data_hash", 0)
	var c0: int = head["c0"]
	r.checksums.append(c0)
	for t: int in n:
		var parts := lines[header_size + t].strip_edges().split(" ")
		if parts.size() != 3:
			return null
		for p: String in parts:
			if not p.is_valid_int():
				return null
		r.words.append(parts[0].to_int())
		r.words.append(parts[1].to_int())
		r.checksums.append(parts[2].to_int())
	return r
