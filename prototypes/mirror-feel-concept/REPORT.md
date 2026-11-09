<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# Prototype Report: mirror-feel-concept

**Date:** 2026-11-01 (session) · report written 2026-11-09
**Question:** Does a Light/Heavy/Block mirror match feel fast and weighty when
weight comes from hit-stop + sound, not recovery?

## Verdict

- **Measured: INCONCLUSIVE.** The PASS rule in README.md (≥3 pairs × 10 min,
  ratings ≥4/5, ≥1 block-then-punish per round) was never run: one session, no
  ratings recorded, 0 punishes.
- **User decision: PASS** (declared 2026-11-01, recorded at /gate-check
  2026-11-01). This is a judgment call from playing it, not a measured result.
- Consequence: every number below and in `main.gd` TUNING is **unvalidated**.
  GDD Formulas / Tuning Knobs that borrow them stay *provisional*.

## Evidence on file

Source: `%APPDATA%\Godot\app_userdata\mirror-feel-concept (PROTOTYPE)\logs\godot.log`
(the PLAYTEST.md per-pair logs in `logs/` were never created).

| Measure | Value |
|---|---|
| Sessions / pairs | 1 / unknown |
| Rounds | 13 |
| Play time | ~28,000 ticks ≈ 7.8 min |
| Weight / responsiveness ratings | none recorded |
| Punish windows opened | 90 |
| — HIT (punish landed) | 0 |
| — LOST, blocked again | 72 |
| — LOST, got hit | 8 |
| — MISSED, window expired | 10 |
| Rounds > 5940 ticks (99 s) | 2 (9279, 9875 — prototype had no round clock) |

## Findings

1. **Light is +1 on block** (blockstun 11 vs 2 active + 8 recovery after
   first-frame contact). With 5-frame startup the attacker can repeat Light and
   the defender can only re-block — 72/90 windows. This is why the
   block-then-punish counter never fired, and it became the on-block rule and
   pushback escape in the Defense brief (`design/gdd/systems-index.md`).
2. **Heavy is −11 on block**, so the punish exists on paper; testers did not find it.
3. Weight-from-hit-stop (the riskiest assumption) is **untested**: no A/B ratings
   with F1/F2 were recorded.
4. Long rounds without a clock show stalling is reachable even in a mirror.

## Carry forward

- Re-measure feel and the punish loop at the Combat Slice gate (the hypothesis gate).
- Defense GDD: Light ≤ 0 on block, pushback escape N, corner case.
- Round & Match Flow GDD: the 5940-tick clock is load-bearing (finding 4).
