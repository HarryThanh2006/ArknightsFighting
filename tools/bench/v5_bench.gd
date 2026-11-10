class_name V5Bench
extends RefCounted
## V5 FLOOR benchmark (ADR-0001 V5, sim-core AC-V3): per-tick cost of
## snapshot() + step() (which includes the checksum), over N ticks after warm-up.
## Not a pass/fail test. Most pipeline slots are still no-ops, so this is a lower
## bound for the real game, never a V5 pass.
##   Debug:   Godot/godot.exe --headless --path . -s res://tools/bench/run_v5_bench.gd
##   Release: build/windows/ArknightsFighting.console.exe --headless -- --v5-bench
##   (exported builds ignore -s, so the placeholder main scene forwards --v5-bench here)

const WARMUP_TICKS: int = 2_000
const TICKS: int = 100_000
const SEED: int = 20261110
const BUDGET_USEC: float = 250.0


## Runs the benchmark and returns the report text.
static func run() -> String:
	var sim := Sim.new()
	sim.init(SEED)
	for t: int in WARMUP_TICKS:
		var s0 := sim.snapshot()
		sim.step(_w(t, 0), _w(t, 1))
		s0.clear()
	var cost := PackedInt64Array()
	cost.resize(TICKS)
	var mem_before: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var total_start: int = Time.get_ticks_usec()
	for t: int in TICKS:
		var t0: int = Time.get_ticks_usec()
		var snap := sim.snapshot()
		sim.step(_w(t, 0), _w(t, 1))
		cost[t] = Time.get_ticks_usec() - t0
		snap.clear()
	var total_usec: int = Time.get_ticks_usec() - total_start
	var mem_after: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))

	# Component costs, averaged over many calls (µs timer is too coarse per call).
	var reps: int = 20_000
	var t1: int = Time.get_ticks_usec()
	for i: int in reps:
		SimHash.hash_words(sim.buffer)
	var hash_usec: float = float(Time.get_ticks_usec() - t1) / float(reps)
	var t2: int = Time.get_ticks_usec()
	for i: int in reps:
		var s := sim.snapshot()
		s[0] = i  # force the lazy copy (duplicate() is copy-on-write until first write)
	var snap_usec: float = float(Time.get_ticks_usec() - t2) / float(reps)

	var sorted := cost.duplicate()
	sorted.sort()
	var mean: float = float(total_usec) / float(TICKS)
	var p99: int = sorted[int(TICKS * 0.99)]
	var p999: int = sorted[int(TICKS * 0.999)]
	var p50: int = sorted[TICKS >> 1]
	var mx: int = sorted[TICKS - 1]
	var lines := PackedStringArray([
		"V5 FLOOR benchmark (no-op slots; NOT a V5 pass)",
		"engine: %s | debug_build: %s | os: %s" % [Engine.get_version_info()["string"], OS.is_debug_build(), OS.get_name()],
		"cpu: %s (%d logical)" % [OS.get_processor_name(), OS.get_processor_count()],
		"buffer words: %d | ticks: %d after %d warm-up" % [SimLayout.TOTAL, TICKS, WARMUP_TICKS],
		"per tick (snapshot + step incl. checksum), usec: mean %.2f | p50 %d | p99 %d | p99.9 %d | max %d (not gating) | budget %.0f" % [mean, p50, p99, p999, mx, BUDGET_USEC],
		"components, usec/call: hash_words %.2f | snapshot+first write %.2f" % [hash_usec, snap_usec],
		"MEMORY_STATIC delta over run: %d bytes" % (mem_after - mem_before),
	])
	return "\n".join(lines)


## Scripted input: P0 alternates right / left every 30 ticks, P1 every 45.
static func _w(t: int, p: int) -> int:
	var period: int = 30 if p == 0 else 45
	return SimPipeline.INPUT_RIGHT if posmod(t, 2 * period) < period else SimPipeline.INPUT_LEFT
