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

## Addendum — combat pipeline, layout 4 (same day, after 23520f0)

Pipeline now runs Movement, Combat (attack, defense, hit resolution), Movement
reactions and RoundFlow (`LAYOUT_VERSION` 4). Events (`SimEvents`), projectiles
and SP / skills / Ultimate are still missing, so this is a **partial floor, not
a V5 pass**. The benchmark now uses scripted aggressive combat inputs (seed 11)
and restarts the match when it ends (restart untimed). Same counts in every run:
**595 hits, 71 blocks, 15,766 hit-stop ticks, 38 KOs, 14 matches completed** —
the combat paths are exercised.

| Build | Run | Mean | p50 | p99 | p99.9 | Max (not gating) | `MEMORY_STATIC` Δ |
|---|---|---|---|---|---|---|---|
| Release | 16 | 23.90 | 23 | 50 | 127 | 753 | 0 |
| Release | 17 | 24.50 | 23 | 62 | 174 | 14,070 | 0 |
| Release | 18 | 24.34 | 23 | 66 | 177 | 737 | 0 |
| Release | 19 | 24.63 | 23 | 67 | 163 | 793 | 0 |
| Release | 20 | 24.82 | 23 | 67 | 165 | 1,782 | 0 |
| **Release median** | | **24.50** | **23** | **66** | **165** | 793 | 0 |
| Debug | 1 | 34.42 | 29 | 93 | 234 | 2,844 | 0 |

**Reading:** all five Release runs meet the AC-V3 gate (mean, p99, p99.9 ≤ 250 µs);
combat added ~5 µs to the mean and roughly doubled p99 / p99.9 versus the
movement-only floor. Debug p99.9 (234 µs) is within 16 µs of the budget, so the
missing systems (events, projectiles, SP) will likely push Debug over; the
Release figure is the one AC-V3 judges.

## Addendum 2026-11-11 — layout 5 (D1, D3, H2, H3)

Code: the `feat:` commit after `1204f38`, `LAYOUT_VERSION` 5. Same scripted
inputs (seed 11); the new rules change the fight, so the counts differ from
layout 4: **425 hits, 27 blocks, 11,314 hit-stop ticks, 29 KOs, 11 matches**
(identical on all five runs). Release export, Intel Core i7-13620H, Windows 11.

| Build | Run | Mean | p50 | p99 | p99.9 | Max (not gating) | `MEMORY_STATIC` Δ |
|---|---|---|---|---|---|---|---|
| Release | 21 | 26.15 | 24 | 79 | 192 | 753 | 0 |
| Release | 22 | 25.95 | 24 | 78 | 211 | 798 | 0 |
| Release | 23 | 26.51 | 24 | 83 | 214 | 5,599 | 0 |
| Release | 24 | 26.30 | 24 | 85 | **263** | 851 | 0 |
| Release | 25 | 27.15 | 24 | 84 | 232 | 8,899 | 0 |
| **Release median** | | **26.30** | **24** | **83** | **214** | 851 | 0 |

**Reading:** the median is inside the AC-V3 gate (≤ 250 µs), but **run 24's
p99.9 (263 µs) exceeds it**: not every run passes, unlike layout 4. Versus
layout 4 (median 24.50 / 66 / 165), mean +1.8 µs, p99 +17, p99.9 +49. The
per-tick work added is small (two buffer words, one clamp), so part of the
tail rise may be machine noise; not investigated. Still a partial floor
(events, projectiles, SP missing), not a V5 pass. No Debug run this time.

## Addendum 2026-11-11 — per-slot breakdown, layout 5 (before SimEvents)

`V5Bench` now adds a second pass over the same inputs that times each pipeline
slot separately (tooling copy of `Sim.step` / `SimPipeline.block_b` order).
The timer has 1 µs resolution and its calls add overhead, so the per-slot
means sum to ~50 µs against a ~26 µs whole-tick mean: read them as
**shares**, not absolute costs. Release export of `acb172c` + this tool
change, Intel Core i7-13620H. Three runs; mean per slot in µs (p99.9 in brackets).

| Slot | Run A | Run B | Run C |
|---|---|---|---|
| snapshot (`duplicate`) | 0.46 [5] | 0.45 [7] | 0.46 [5] |
| block_a | 1.18 [21] | 1.35 [40] | 1.43 [30] |
| interval | 0.18 [1] | 0.21 [2] | 0.22 [2] |
| ai (PRNG) | 1.20 [19] | 1.24 [32] | 1.16 [26] |
| movement | 3.83 [104] | 4.16 [86] | 4.13 [70] |
| attack | 3.47 [103] | 3.70 [80] | 3.72 [67] |
| defense | 1.64 [41] | 1.80 [46] | 1.76 [41] |
| resolve (hit detection) | 4.93 [164] | 5.36 [93] | 5.31 [83] |
| reactions | 2.66 [76] | 2.74 [66] | 2.76 [57] |
| round_check | 0.92 [19] | 1.06 [25] | 1.01 [19] |
| **checksum (whole buffer)** | **28.49 [650]** | **29.85 [293]** | **29.67 [184]** |
| Whole tick (first pass): mean / p99 / p99.9 | 26.01 / 79 / **298** | 25.65 / 73 / 186 | 26.05 / 75 / 166 |

**Reading:** the per-tick checksum over all 1,624 words is ~57–60 % of slot
time and owns the largest tails; the snapshot `duplicate` is negligible.
Gameplay slots together are ~40 %. Whole-tick p99.9 varied 166–298 µs across
three runs of identical code, so yesterday's single 263 µs run is within this
machine's run-to-run tail noise, not a code regression. The cheapest lever, if
the budget gets tight, is the checksum (e.g. a native hash over the packed
bytes instead of a GDScript loop) — a design change that needs the user's OK.

## Addendum 2026-11-11 — layout 6, SimEvents in the pipeline

Code: `de9339f` + `c25a710` (layout 6: HIT/BLOCK/KO/ROUND_*/MATCH_END
emitted into the in-buffer ring). TOTAL still 1,624 words. Same inputs and
counts as layout 5 (425 hits, 27 blocks, 11,314 hit-stop ticks, 29 KOs, 11
matches) on all five runs. Release export, Intel Core i7-13620H.

| Build | Run | Mean | p50 | p99 | p99.9 | Max (not gating) | `MEMORY_STATIC` Δ |
|---|---|---|---|---|---|---|---|
| Release | 26 | 25.32 | 24 | 63 | 165 | 517 | 0 |
| Release | 27 | 26.00 | 24 | 67 | 159 | 2,611 | 0 |
| Release | 28 | 26.49 | 24 | 82 | 244 | 1,790 | 0 |
| Release | 29 | 25.96 | 24 | 72 | 178 | 786 | 0 |
| Release | 30 | 26.12 | 25 | 65 | 152 | 859 | 0 |
| **Release median** | | **26.00** | **24** | **67** | **165** | 859 | 0 |

All five runs are inside the AC-V3 gate (≤ 250 µs); run 28's p99.9 (244 µs)
is the closest. Per-slot means (median of the five runs, µs; before → after
SimEvents, same tool): resolve 5.31 → 6.52 (contact point + HIT/BLOCK
emission; its p99 rose 12 → 22), round_check 1.01 → 1.41 (KO flags +
ROUND_* emission), block_a 1.35 → 1.46, checksum 29.67 → 29.59, every other
slot unchanged within noise. Events cost ≈ 1.7 µs per tick; the checksum is
still ~55 % of slot time. Projectiles and SP are still missing: partial
floor, not a V5 pass.

## Addendum 2026-11-11 — layout 7 (ATTACK_START, WHIFF, packed contact point)

Code: `7a292c3`. Same inputs and combat counts (425 / 27 / 11,314 / 29 / 11).
Release export, Intel Core i7-13620H.

| Build | Run | Mean | p50 | p99 | p99.9 | Max (not gating) | `MEMORY_STATIC` Δ |
|---|---|---|---|---|---|---|---|
| Release | 31 | 26.72 | 25 | 67 | 157 | 1,594 | 0 |
| Release | 32 | 26.58 | 25 | 59 | 164 | 3,780 | 0 |
| Release | 33 | 26.76 | 25 | 63 | 232 | 8,644 | 0 |
| Release | 34 | 26.92 | 25 | 67 | 139 | 4,102 | 0 |
| Release | 35 | 25.82 | 25 | 44 | 110 | 511 | 0 |
| **Release median** | | **26.72** | **25** | **63** | **157** | 3,780 | 0 |

All five runs inside AC-V3 (worst p99.9 232 µs). Per-slot medians vs layout 6:
attack 3.77 → 5.24 µs (WHIFF check reads the hitbox track each advancing
tick, plus ATTACK_START), resolve 6.52 → 6.31, round_check 1.41 → 1.35,
checksum 29.6 → 29.1. Mean per tick +0.7 µs.
