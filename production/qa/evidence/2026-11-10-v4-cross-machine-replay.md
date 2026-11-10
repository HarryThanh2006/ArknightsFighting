# V4 cross-machine replay — evidence log (started 2026-11-10)

> **Not a V4 pass.** ADR-0001 V4 / sim-core AC-V2 stay **BLOCKED** until the
> user decides the evidence is enough. The sim's block B is still mostly no-op
> slots (two PLACEHOLDER slots), so this proves determinism of what exists today:
> fixed-point math, PRNG, hash, block A / freeze gate and the placeholder walk.

## What each green CI run now demonstrates

The golden replay `tests/integration/sim_core/fixtures/golden_replay.txt`
(10,000 ticks, sim seed 20261110, input-generator seed 7, `LAYOUT_VERSION` 2) was
**recorded on the development PC** and is **replayed on the CI runner** by
`tests/integration/sim_core/sim_core_replay_test.gd`, which asserts every per-tick
checksum (ticks 0–10,000) matches, twice in one process.

| Role | Machine | OS | CPU |
|---|---|---|---|
| Recording | Development laptop | Windows 11 | Intel Core i7-13620H (13th gen) |
| Replay | GitHub Actions `ubuntu-latest` | Linux | printed by the workflow's **Runner CPU** step (read it in each run's log) |

A green run therefore means: same 10,000 checksums on a different OS, a different
Godot build of 4.7.2 (Linux vs Windows), and whatever CPU the runner reports. If
that CPU is AMD, the run is the Intel-vs-AMD case ADR-0001 V4 asks for.

## Log

| Date | CI run | Commit | Runner CPU (from log) | Ticks | Result |
|---|---|---|---|---|---|
| 2026-11-10 | #6 | 24b76b6 | not printed yet | 5,000 | pass (first cross-OS data point) |
| 2026-11-10 | #7 | b5ee953 | not printed yet | 5,000 | pass |

Append a row per run you want to cite, copying the CPU line from the **Runner CPU** step.

## Fixture history

- 2026-11-10: extended from 5,000 to 10,000 ticks (V4 length) with the same seeds
  and generator; the first 5,000 ticks are byte-identical to the previous fixture.
