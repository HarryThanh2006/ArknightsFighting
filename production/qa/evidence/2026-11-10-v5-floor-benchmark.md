# V5 floor benchmark — 2026-11-10

> **This is a FLOOR measurement, not a V5 pass.** Every block-B slot is a no-op
> except two PLACEHOLDER slots (one PRNG draw, a left/right walk). Movement,
> attack, hit detection, projectiles, events and round logic do not exist yet, so
> the real tick will cost more. ADR-0001 V5 / sim-core AC-V3 stay **BLOCKED**,
> and ADR status is unchanged.

## What was measured

`tools/bench/v5_bench.gd` (`V5Bench.run()`): 100,000 ticks after 2,000 warm-up
ticks. Each timed tick is `sim.snapshot()` (a `duplicate()`) plus `sim.step(w0, w1)`,
which includes block A, the freeze gate, block B and the per-tick `SimHash`
checksum over the whole 1,624-word buffer. The timer is `Time.get_ticks_usec()`
(1 µs resolution). Scripted inputs, fixed seed 20261110.

- Debug: `Godot/godot.exe --headless --path . -s res://tools/bench/run_v5_bench.gd`
- Release: `build/windows/ArknightsFighting.console.exe --headless -- --v5-bench`
  (export via `commands.build`; exported builds ignore `-s`, so the placeholder
  main scene forwards `--v5-bench`)

## Machine

- CPU: 13th Gen Intel Core i7-13620H (10 logical cores, hybrid P/E cores), laptop
- RAM: 16 GB; Windows 11 Home; on AC power (BatteryStatus 2); no core pinning
- Engine: Godot 4.7.2.stable.official (editor binary for Debug; official export template for Release)

## Results (µs per tick; budget 250 µs)

| Build | Run | Mean | p50 | p99 | Max | `MEMORY_STATIC` Δ |
|---|---|---|---|---|---|---|
| Release | 1 | 18.38 | 17 | 39 | 578 | 0 |
| Release | 2 | 18.71 | 18 | 35 | 1,184 | 0 |
| Release | 3 | 19.92 | 19 | 37 | 366 | 0 |
| Debug | 1 | 26.92 | 25 | 64 | 1,967 | 0 |
| Debug | 2 | 24.50 | 24 | 47 | 1,019 | 0 |
| Debug | 3 | 26.53 | 25 | 57 | 2,577 | 0 |
| Debug | 4 | 132.28 | 26 | 102 | 1,870,984 | 0 |
| Debug | 5 | 23.87 | 23 | 48 | 2,569 | 0 |

Debug run 4 contains a single ~1.87 s stall (the whole process was descheduled or
the laptop throttled); its mean is not representative.

## Reading

- **Mean and p99 sit far inside the budget** on Release (~19 µs mean, ≤ 39 µs p99,
  i.e. ≤ 16 % of 250 µs) and on Debug (~25 µs mean, ≤ 64 µs p99), leaving room for
  the real systems, but how much they will cost is unknown.
- **Max fails the budget in every run** (366 µs–2.6 ms, isolated outliers). AC-V3
  requires the maximum ≤ 0.25 ms; on a desktop OS without core pinning a single
  descheduled tick will always exceed it, so either AC-V3's "maximum" needs a
  definition the user decides (e.g. max over ticks excluding OS preemption, or
  a frame-level budget), or the measurement needs pinning / repeated runs.
- **No per-tick memory growth**: `MEMORY_STATIC` is unchanged over 100,000 ticks
  including a `duplicate()` per tick (freed each tick).
- Component timings printed by the tool (`hash_words`, `snapshot+first write`,
  averaged over 20,000 calls) varied 5× between Debug runs (24–221 µs for
  `hash_words`) while the per-tick figure stayed stable, so they are noise-
  dominated on this laptop and not quoted as results. Release `hash_words`
  ≈ 16.5–18.5 µs per 1,624 words, consistent with the F8 model (≈ 18.8 µs).

## Addendum — p99.9 gate (same day)

The user changed the AC-V3 gate on 2026-11-10: **mean, p99 and p99.9 ≤ 250 µs; the
maximum is recorded but does not gate** (`MatchRunner` absorbs isolated late ticks,
`MAX_CATCHUP_TICKS` = 4). The benchmark now reports p99.9. Five more Release runs,
same machine and setup, still a **FLOOR (no-op slots), not a V5 pass**:

| Build | Run | Mean | p50 | p99 | p99.9 | Max (not gating) | `MEMORY_STATIC` Δ |
|---|---|---|---|---|---|---|---|
| Release | 6 | 20.66 | 19 | 41 | 123 | 1,269 | 0 |
| Release | 7 | 20.71 | 19 | 46 | 173 | 2,696 | 0 |
| Release | 8 | 24.83 | 21 | 74 | **426** | 32,979 | 0 |
| Release | 9 | 18.06 | 17 | 35 | 101 | 725 | 0 |
| Release | 10 | 19.10 | 18 | 46 | 148 | 3,388 | 0 |

**Reading:** p99.9 is 101–173 µs in 4 of 5 runs, but **426 µs in run 8**, which
exceeded the budget even with an empty pipeline. Run 8 also has the highest mean and a 33 ms
max, consistent with background load on the laptop during that run. With 100,000
ticks, p99.9 is the 100th-slowest tick, so it is sensitive to OS activity. Before
a real V5 verdict, the measurement procedure should fix the conditions (idle
machine, several runs, report the median run) — or the gate should say how many
runs and which run is judged.

## Addendum — after Tier −1 Movement (same day)

Movement's Tier −1 subset (walk, facing, pushbox separation, walls, corner
push-out) replaced the placeholder movement slot (`LAYOUT_VERSION` 3). Five
Release runs, same machine and procedure; still a **FLOOR** (attack, hit,
defense, events and round slots are empty), not a V5 pass.

| Run | Mean | p50 | p99 | p99.9 | Max (not gating) |
|---|---|---|---|---|---|
| 11 | 19.79 | 19 | 33 | 72 | 776 |
| 12 | 19.21 | 19 | 28 | 59 | 367 |
| 13 | 19.85 | 19 | 33 | 108 | 993 |
| 14 | 19.30 | 19 | 29 | 78 | 3,799 |
| 15 | 19.40 | 19 | 27 | 52 | 821 |
| **Median** | **19.40** | **19** | **29** | **72** | 821 |

All five runs are inside the AC-V3 gate (mean, p99, p99.9 ≤ 250 µs). Movement's
cost is below the run-to-run noise of the earlier floor runs (~18–20 µs mean);
the per-tick checksum over 1,624 words still dominates.
