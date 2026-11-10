extends SceneTree
## Regenerates the golden replay fixture from a committed seed and a deterministic
## scripted input generator. Run only when the sim legitimately changes (bump the
## fixture in the same commit, and say why):
##   Godot/godot.exe --headless --path . -s res://tools/replay/make_golden_replay.gd

const OUT_PATH: String = "res://tests/integration/sim_core/fixtures/golden_replay.txt"
const SIM_SEED: int = 20261110
const INPUT_SEED: int = 7
const TICKS: int = 10_000  # ADR-0001 V4 length
## Held movement, attack and guard inputs after the scripted combat opening.
const CHOICES: Array[int] = [0, 1, 2, 2 | 4, 1 | 8, 4, 8, 16]


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
			# Start at close range with a guarded Light followed by a Heavy trade.
			var input: int = held[p]
			if t < 40:
				input = Movement.INPUT_RIGHT if p == 0 else Movement.INPUT_LEFT
			elif t < 80:
				input = 4 if p == 0 else 16
			elif t == 80:
				input = 8
			words.append(input)
	var replay := SimReplay.record(SIM_SEED, words)
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	f.store_string(replay.to_text())
	f.close()
	print("wrote %s: %d ticks, final checksum %d" % [OUT_PATH, replay.tick_count(), replay.checksums[TICKS]])
	quit()
