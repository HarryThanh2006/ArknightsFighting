class_name ReplayCheck
extends RefCounted
## Plays a replay file and compares every per-tick checksum (sim-core AC-X5 / AC-V2).
## Runs in the editor (Debug) and in the exported Release build, so the two outputs
## can be compared line for line:
##   Debug:   Godot/godot.exe --headless --path . -s res://tools/replay/run_replay_check.gd
##   Release: build/windows/ArknightsFighting.console.exe --headless -- --replay-check
## The fixture is exported via export_presets.cfg include_filter.

const GOLDEN: String = "res://tests/integration/sim_core/fixtures/golden_replay.txt"


## Plays `path`; returns a report with mismatch count, first mismatch, final checksum
## and a digest (SimHash over all live checksums) that must be equal across builds.
static func run(path: String = GOLDEN) -> String:
	var r := SimReplay.from_text(FileAccess.get_file_as_string(path))
	if r == null:
		return "REPLAY-CHECK ERROR: cannot parse %s" % path
	var kit := SimMoveData.load_default()
	if kit == null or kit.version_hash() != r.move_data_hash or r.layout_version != SimLayout.LAYOUT_VERSION:
		return "REPLAY-CHECK ERROR: incompatible replay (move data or layout)"
	var sim := Sim.new(kit)
	var live := PackedInt64Array()
	live.append(sim.init(r.seed_value))
	for t: int in r.tick_count():
		live.append(sim.step(r.words[2 * t], r.words[2 * t + 1]))
	var mismatches: int = 0
	var first: int = -1
	for t: int in live.size():
		if live[t] != r.checksums[t]:
			mismatches += 1
			if first < 0:
				first = t
	return "\n".join(PackedStringArray([
		"REPLAY-CHECK %s" % path,
		"build: %s | debug_build: %s | layout %d" % [Engine.get_version_info()["string"], OS.is_debug_build(), SimLayout.LAYOUT_VERSION],
		"ticks: %d | mismatching ticks: %d | first mismatch: %d" % [r.tick_count(), mismatches, first],
		"final checksum: %d | digest of all live checksums: %d" % [live[live.size() - 1], SimHash.hash_words(live)],
	]))
