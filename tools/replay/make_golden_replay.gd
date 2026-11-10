extends SceneTree
## Regenerates the golden replay fixture from a committed seed and a deterministic
## scripted input generator. Run only when the sim legitimately changes (bump the
## fixture in the same commit, and say why):
##   Godot/godot.exe --headless --path . -s res://tools/replay/make_golden_replay.gd

const OUT_PATH: String = "res://tests/integration/sim_core/fixtures/golden_replay.txt"
const SIM_SEED: int = 20261110
const INPUT_SEED: int = 7
const TICKS: int = 5000
## Input generator words: neutral, left, right (SimPipeline PLACEHOLDER bits).
const CHOICES: Array[int] = [0, 1, 2]


func _init() -> void:
	var gen := PackedInt64Array([0, 0])
	SimRng.seed(gen, 0, INPUT_SEED)
	var words := PackedInt64Array()
	var held := PackedInt64Array([0, 0])
	var left := PackedInt64Array([0, 0])
	for t: int in TICKS:
		for p: int in 2:
			if left[p] <= 0:
				held[p] = CHOICES[SimRng.range_i(gen, 0, 0, CHOICES.size() - 1)]
				left[p] = SimRng.range_i(gen, 0, 5, 40)  # hold 5-40 ticks
			left[p] -= 1
			words.append(held[p])
	var replay := SimReplay.record(SIM_SEED, words)
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	f.store_string(replay.to_text())
	f.close()
	print("wrote %s: %d ticks, final checksum %d" % [OUT_PATH, replay.tick_count(), replay.checksums[TICKS]])
	quit()
