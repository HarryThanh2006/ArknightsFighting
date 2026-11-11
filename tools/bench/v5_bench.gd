class_name V5Bench
extends RefCounted
## V5 FLOOR benchmark (ADR-0001 V5, sim-core AC-V3): per-tick cost of
## snapshot() + step() (which includes the checksum), over N ticks after warm-up.
## Not a pass/fail test. Uses combat inputs and reports how many combat paths ran;
## events, projectiles and SP are not in the pipeline yet, so this is still a floor.
##   Debug:   Godot/godot.exe --headless --path . -s res://tools/bench/run_v5_bench.gd
##   Release: build/windows/ArknightsFighting.console.exe --headless -- --v5-bench
##   (exported builds ignore -s, so the placeholder main scene forwards --v5-bench here)

const WARMUP_TICKS: int = 2_000
const TICKS: int = 100_000
const SEED: int = 20261110
const BUDGET_USEC: float = 250.0
const INPUT_SEED: int = 11
## Attack bits (src/sim/combat.gd).
const LIGHT: int = 4
const HEAVY: int = 8


## Runs the benchmark and returns the report text.
static func run() -> String:
	var words := _combat_inputs(WARMUP_TICKS + TICKS)
	var sim := Sim.new()
	sim.init(SEED)
	var restarts: int = 0
	for t: int in WARMUP_TICKS:
		var s0 := sim.snapshot()
		sim.step(words[2 * t], words[2 * t + 1])
		s0.clear()
	var cost := PackedInt64Array()
	cost.resize(TICKS)
	# Combat-path counters, gathered outside the timed region.
	var hits: int = 0
	var blocks: int = 0
	var hitstop_ticks: int = 0
	var kos: int = 0
	var prev := PackedInt64Array([0, 0, 0, 0])  # hp0, hp1, blockstun0, blockstun1
	for p: int in 2:
		prev[p] = sim.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_HP]
	var mem_before: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var timed_usec: int = 0
	for t: int in TICKS:
		var i: int = WARMUP_TICKS + t
		var t0: int = Time.get_ticks_usec()
		var snap := sim.snapshot()
		sim.step(words[2 * i], words[2 * i + 1])
		cost[t] = Time.get_ticks_usec() - t0
		timed_usec += cost[t]
		snap.clear()
		for p: int in 2:
			var base: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE
			var hp: int = sim.buffer[base + SimLayout.PF_HP]
			var bs: int = sim.buffer[base + SimLayout.PF_BLOCKSTUN]
			if hp < prev[p]:
				hits += 1
				if hp == 0:
					kos += 1
			if bs > 0 and prev[2 + p] == 0:
				blocks += 1
			if sim.buffer[base + SimLayout.PF_HITSTOP] > 0:
				hitstop_ticks += 1
			prev[p] = hp
			prev[2 + p] = bs
		if sim.buffer[SimLayout.R_MATCH_OVER] != 0:
			restarts += 1  # keep combat running: new match, untimed
			sim.init(SEED + restarts)
			for p: int in 2:
				prev[p] = sim.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_HP]
				prev[2 + p] = 0
	var mem_after: int = int(Performance.get_monitor(Performance.MEMORY_STATIC))

	var sorted := cost.duplicate()
	sorted.sort()
	var mean: float = float(timed_usec) / float(TICKS)
	var p99: int = sorted[int(TICKS * 0.99)]
	var p999: int = sorted[int(TICKS * 0.999)]
	var p50: int = sorted[TICKS >> 1]
	var mx: int = sorted[TICKS - 1]
	var lines := PackedStringArray([
		"V5 benchmark with combat pipeline (events / projectiles / SP still missing: partial floor, NOT a V5 pass)",
		"engine: %s | debug_build: %s | os: %s | layout %d" % [Engine.get_version_info()["string"], OS.is_debug_build(), OS.get_name(), SimLayout.LAYOUT_VERSION],
		"cpu: %s (%d logical)" % [OS.get_processor_name(), OS.get_processor_count()],
		"buffer words: %d | ticks: %d after %d warm-up" % [SimLayout.TOTAL, TICKS, WARMUP_TICKS],
		"per tick (snapshot + step incl. checksum), usec: mean %.2f | p50 %d | p99 %d | p99.9 %d | max %d (not gating) | budget %.0f" % [mean, p50, p99, p999, mx, BUDGET_USEC],
		"combat exercised: hits %d | blocks %d | hit-stop ticks %d | KOs %d | matches completed %d" % [hits, blocks, hitstop_ticks, kos, restarts],
		"MEMORY_STATIC delta over run: %d bytes" % (mem_after - mem_before),
	])
	lines.append_array(_slot_breakdown(words))
	return "
".join(lines)


## Scripted aggressive inputs (committed seed): each player holds one of walk toward,
## walk + Light, walk + Heavy, Light, Heavy, Block, walk away or neutral for 3-20 ticks.
## Sides never swap (no cross-ups), so "toward" is RIGHT for P0 and LEFT for P1.
static func _combat_inputs(ticks: int) -> PackedInt64Array:
	var gen := PackedInt64Array([0, 0])
	SimRng.seed(gen, 0, INPUT_SEED)
	var out := PackedInt64Array()
	var held := PackedInt64Array([0, 0])
	var left := PackedInt64Array([0, 0])
	for t: int in ticks:
		for p: int in 2:
			if left[p] <= 0:
				var toward: int = Movement.INPUT_RIGHT if p == 0 else Movement.INPUT_LEFT
				var away: int = Movement.INPUT_LEFT if p == 0 else Movement.INPUT_RIGHT
				var choices := PackedInt64Array([toward, toward | LIGHT, toward | HEAVY, LIGHT, HEAVY,
					Movement.INPUT_BLOCK, away, 0])
				held[p] = choices[SimRng.range_i(gen, 0, 0, choices.size() - 1)]
				left[p] = SimRng.range_i(gen, 0, 3, 20)
			left[p] -= 1
			out.append(held[p])
	return out


## Slot names for the per-slot pass, in pipeline order.
const SLOTS: PackedStringArray = ["snapshot", "block_a", "interval", "ai", "movement", "attack",
	"defense", "resolve", "reactions", "round_check", "checksum"]


## Per-slot pass: the same ticks again, stepping the slots of Sim.step / SimPipeline.block_b
## one by one with a timer around each (tooling copy of the order; keep in sync with
## sim_pipeline.gd). 1 us timer resolution: per-slot means are approximate, sums are not.
static func _slot_breakdown(words: PackedInt64Array) -> PackedStringArray:
	var sim := Sim.new()
	sim.init(SEED)
	var n: int = SLOTS.size()
	var cost: Array[PackedInt64Array] = []
	for k: int in n:
		var c := PackedInt64Array()
		c.resize(TICKS)
		cost.append(c)
	var restarts: int = 0
	for t: int in WARMUP_TICKS + TICKS:
		var row: int = t - WARMUP_TICKS
		var w0: int = words[2 * t]
		var w1: int = words[2 * t + 1]
		var b: PackedInt64Array = sim.buffer
		var kit: SimMoveData = sim.data
		var tk: PackedInt64Array = PackedInt64Array()
		tk.resize(n + 1)
		tk[0] = Time.get_ticks_usec()
		var snap := sim.snapshot()
		tk[1] = Time.get_ticks_usec()
		SimPipeline.block_a(b, w0, w1)
		tk[2] = Time.get_ticks_usec()
		var frozen: bool = b[SimLayout.H_FREEZE_TICKS] > 0
		var interval: bool = b[SimLayout.R_INTERVAL] > 0
		if frozen:
			b[SimLayout.H_FREEZE_TICKS] -= 1
		elif interval:
			SimPipeline.RoundFlow.advance_interval(b, kit)
		tk[3] = Time.get_ticks_usec()
		if not frozen and not interval:
			SimPipeline._placeholder_ai(b)
			tk[4] = Time.get_ticks_usec()
			Movement.step(b)
			tk[5] = Time.get_ticks_usec()
			SimPipeline.Combat.attack(b, kit)
			tk[6] = Time.get_ticks_usec()
			SimPipeline.Combat.defense(b)
			tk[7] = Time.get_ticks_usec()
			var was_stopped: int = 0
			for player: int in SimLayout.P_COUNT:
				if b[SimPipeline.Combat.base(player) + SimLayout.PF_HITSTOP] > 0:
					was_stopped |= 1 << player
			SimPipeline.Combat.resolve(b, kit)
			tk[8] = Time.get_ticks_usec()
			Movement.reactions(b, was_stopped, kit)
			tk[9] = Time.get_ticks_usec()
			SimPipeline.RoundFlow.check(b)
			tk[10] = Time.get_ticks_usec()
		else:
			for k: int in range(4, 11):
				tk[k] = tk[3]
		SimHash.hash_words(b)
		tk[11] = Time.get_ticks_usec()
		snap.clear()
		if row >= 0:
			for k: int in n:
				cost[k][row] = tk[k + 1] - tk[k]
		if b[SimLayout.R_MATCH_OVER] != 0:
			restarts += 1
			sim.init(SEED + restarts)
	var out := PackedStringArray(["per-slot pass (same inputs; us; 1 us timer resolution):",
		"slot          mean     p99  p99.9"])
	for k: int in n:
		var sorted := cost[k].duplicate()
		sorted.sort()
		var total: int = 0
		for v: int in cost[k]:
			total += v
		out.append("%-12s %6.2f  %6d %6d" % [SLOTS[k], float(total) / TICKS, sorted[int(TICKS * 0.99)], sorted[int(TICKS * 0.999)]])
	return out
