<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Does a Light/Heavy/Block mirror match feel fast and weighty when weight comes from hit-stop + sound, not recovery? -->
<!-- Date: 2026-11-01 -->

# mirror-feel-concept (PROTOTYPE — throwaway)

**Status:** concluded (2026-11-09) — INCONCLUSIVE measured, user PASS; see REPORT.md

## Hypothesis

If two players fight a mirror match with only Light, Heavy and Block, where a
hit's weight comes from hit-stop and sound rather than long recovery, the
exchanges will feel fast and impactful.

**PASS if**, across ≥ 3 pairs × 10 minutes:
- ≥ 2 of 3 testers rate **"hits feel weighty" ≥ 4/5** AND **"controls feel responsive" ≥ 4/5**, and
- pairs average **≥ 1 block-then-punish per round** (on-screen counter + console log).

**Riskiest assumption tested first:** weight without recovery (Pillar 2). The
F1–F3 toggles let testers rate the same fight with and without hit-stop, sound
and shake.

Local, 0 ms only — this says nothing about how it feels over LAN.

## How to run

1. Open Godot 4.7.2 (`Godot/godot.exe` at the repo root).
2. Import / open `prototypes/mirror-feel-concept/project.godot` as its own project.
3. Press F5 (Run Project).

Command line: `Godot/godot.exe --path prototypes/mirror-feel-concept`

## Controls

| | Walk | Light | Heavy | Block (hold) |
|---|---|---|---|---|
| P1 keyboard | A / D | F | G | H |
| P2 keyboard | ← / → | Numpad 1 or `,` | Numpad 2 or `.` | Numpad 3 or `/` |
| Gamepad (pad 0 = P1, pad 1 = P2) | D-pad | X | Y | RB |

F1 hit-stop on/off · F2 SFX on/off · F3 shake on/off · F4 show hitboxes · R restart match.
Light → Heavy cancels once the Light connects (hit or block).

**Playtest sessions:** follow `PLAYTEST.md` (session plan, log capture, score sheet).

## What to try

- Play a round with everything ON, then one with F1 + F2 off. Rate weight and responsiveness 1–5 for each.
- Block a Heavy (it is −11 on block) and punish with your own Heavy.
- Tune: every number is in the `TUNING` block at the top of `main.gd`.

## Findings

See `REPORT.md`. Measured: **INCONCLUSIVE** (1 session, no ratings, 0/90 punishes);
user decision: PASS. Light was +1 on block, so 72/90 punish windows ended "blocked
again" → on-block rule + pushback escape added to the Defense brief. All TUNING values unvalidated.
