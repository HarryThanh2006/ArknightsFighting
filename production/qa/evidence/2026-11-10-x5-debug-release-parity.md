# AC-X5 Debug vs Release parity — 2026-11-10

**Status: PASS (one machine), after the AC was amended.** The user decided on
2026-11-10 that the golden-replay comparison is sufficient and dropped the
"sim test suite yields identical buffers on both builds" clause (gdUnit4 runs
only in the editor binary). Caveat: the golden fixture has no KO; the KO path's
parity is supported by the V5 combat benchmark counting the same 38 KOs on
both builds, not by per-tick checksums.

## What was run

- Code: `23520f0` + this measurement commit (tools only; `src/sim` unchanged),
  `LAYOUT_VERSION` 4, move data `data/moves/tier_minus_one.cfg`.
- Replay: `tests/integration/sim_core/fixtures/golden_replay.txt` (10,000 ticks,
  sim seed 20261110, recorded with the Debug editor; includes Light / Heavy /
  Block, 27 HP losses, 850 hitstun ticks, 80 blockstun ticks, one round won; no KO).
- Tool: `tools/replay/replay_check.gd` (`ReplayCheck`), compares every live
  per-tick checksum to the file and prints a digest (`SimHash` over all 10,001
  live checksums).
- Debug: `Godot/godot.exe --headless --path . -s res://tools/replay/run_replay_check.gd`
- Release: `build/windows/ArknightsFighting.console.exe --headless -- --replay-check`
  (official 4.7.2 export template; the fixture is exported via `include_filter`).
- Machine: Intel Core i7-13620H, Windows 11.

## Results

| Build | Mismatching ticks | First mismatch | Final checksum | Digest of all checksums |
|---|---|---|---|---|
| Debug (editor 4.7.2) | 0 / 10,000 | — | 3488810694884623485 | 8807891121379209906 |
| Release (export), run 1 | 0 / 10,000 | — | 3488810694884623485 | 8807891121379209906 |
| Release (export), run 2 | 0 / 10,000 | — | 3488810694884623485 | 8807891121379209906 |

Every per-tick checksum is identical on both builds. The V5 combat benchmark
(same day, 100,000 ticks of scripted combat) also counted identical combat
events on Release and Debug (595 hits, 71 blocks, 15,766 hit-stop ticks, 38 KOs,
14 matches) — supporting evidence, not part of the AC.

## Missing for a full pass

- The sim unit / integration suite run against a Release build, comparing
  buffers. Needs a way to run those assertions outside gdUnit4 (e.g. a
  Release-runnable self-test entry point), or the user accepts the replay
  half as sufficient.
- Same machine only; cross-CPU Release parity belongs to AC-V2 / LAN.

## Addendum 2026-11-11 — layout 5 (D1, D3, H2, H3)

Code: the `feat:` commit after `1204f38` (this addendum ships in it),
`LAYOUT_VERSION` 5 (input buffer + block-recoil flag), move data with the Heavy
arm hurtbox. Fixture regenerated with `tools/replay/make_golden_replay.gd`
(same seeds, 10,000 ticks). Same machine (Intel Core i7-13620H, Windows 11),
same commands as above; Release re-exported from this tree.

| Build | Mismatching ticks | First mismatch | Final checksum | Digest of all checksums |
|---|---|---|---|---|
| Debug (editor 4.7.2) | 0 / 10,000 | — | -1249531500449012568 | 1594941114614719159 |
| Release (export), run 1 | 0 / 10,000 | — | -1249531500449012568 | 1594941114614719159 |
| Release (export), run 2 | 0 / 10,000 | — | -1249531500449012568 | 1594941114614719159 |

**AC-X5: PASS on layout 5 (one machine).** Same caveat: the fixture's KO path
parity rests on the V5 benchmark counts (29 KOs on every Release run).

## Addendum 2026-11-11 — layout 6 (SimEvents ring)

Code: `de9339f` (SimEvents + emitters, `LAYOUT_VERSION` 6) and `c25a710`
(presentation only). Fixture regenerated (same seeds). The ring and Event
Control words are inside the buffer, so every per-tick checksum covers the
event stream. Same machine and commands.

| Build | Mismatching ticks | First mismatch | Final checksum | Digest of all checksums |
|---|---|---|---|---|
| Debug (editor 4.7.2) | 0 / 10,000 | — | -8823252577600630705 | 568123663480405302 |
| Release (export), run 1 | 0 / 10,000 | — | -8823252577600630705 | 568123663480405302 |
| Release (export), run 2 | 0 / 10,000 | — | -8823252577600630705 | 568123663480405302 |

**AC-X5: PASS on layout 6 (one machine).**

## Addendum 2026-11-11 — layout 7 (ATTACK_START, WHIFF, packed contact point)

Code: `7a292c3`. Fixture regenerated. Same machine and commands.

| Build | Mismatching ticks | First mismatch | Final checksum | Digest of all checksums |
|---|---|---|---|---|
| Debug (editor 4.7.2) | 0 / 10,000 | — | 1419703315605913082 | -8590935311795763469 |
| Release (export), run 1 | 0 / 10,000 | — | 1419703315605913082 | -8590935311795763469 |
| Release (export), run 2 | 0 / 10,000 | — | 1419703315605913082 | -8590935311795763469 |

**AC-X5: PASS on layout 7 (one machine).**

## Addendum 2026-11-11 — max distance (M15), layout 7

Code: `3090b0c` (sim behaviour change, layout unchanged) + view-only commits.
Fixture regenerated. Same machine and commands.

| Build | Mismatching ticks | Final checksum | Digest of all checksums |
|---|---|---|---|
| Debug (editor 4.7.2) | 0 / 10,000 | -3522965011501976382 | -2405648565753264139 |
| Release (export), run 1 | 0 / 10,000 | -3522965011501976382 | -2405648565753264139 |
| Release (export), run 2 | 0 / 10,000 | -3522965011501976382 | -2405648565753264139 |

**AC-X5: PASS (one machine).**
