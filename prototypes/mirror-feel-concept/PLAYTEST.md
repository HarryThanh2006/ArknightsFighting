<!-- PROTOTYPE - NOT FOR PRODUCTION -->
# mirror-feel — Playtest Package

**Status: NOT YET RUN.** Every field below is blank until a real session fills it in.
Never fill in a field from memory or a guess. If something wasn't recorded, write `not recorded`.

Hypothesis and PASS bar: see `README.md`.

> **Decide before testing.** The README's PASS bar says "≥ 2 of 3 testers", but 3 pairs
> means 6 testers. Pick and write the rule here before the first session:
> `PASS rule used: ______________________`

---

## 1. Session plan (per pair, ~10 min of play)

| Block | Config | Keys | Length |
|---|---|---|---|
| A | **ALL ON**: hit-stop + SFX + shake | default at launch | 5 min (play Bo3 matches, press R between matches) |
| B | **F1+F2 OFF**: no hit-stop, no SFX, shake still on | press F1 and F2 once; the bottom bar must read `F1 hitstop off   F2 sfx off   F3 shake ON` | 5 min |

- **Alternate the order** so the result isn't just "the second config felt better": Pair 1 = A then B, Pair 2 = B then A, Pair 3 = A then B.
- Don't tell testers which config is which, only "config 1" and "config 2".
- Rate right after each block, before the next one starts. Testers rate on their own, without talking it over.
- Toggles stay as they are when you press R. Check the bottom bar at the start of each block.

## 2. Running and capturing the log

Run from the repo root in PowerShell. Use the **console** build so you get the printed output:

```powershell
New-Item -ItemType Directory -Force prototypes\mirror-feel-concept\logs | Out-Null
.\Godot\Godot_v4.7.2-stable_win64_console.exe --path prototypes\mirror-feel-concept | Tee-Object -FilePath prototypes\mirror-feel-concept\logs\pair1.txt
```

- Use one log file per pair (`pair1.txt`, `pair2.txt`, …). Start a fresh launch for each pair.
- Close the game window when the pair is done. The log is then complete.
- **Backup log:** Godot also writes its own log to
  `%APPDATA%\Godot\app_userdata\mirror-feel-concept (PROTOTYPE)\logs\godot.log`.
  That file is overwritten on every launch, so copy it right away if you need it.

### What the log contains

One line per round:
```
ROUND 2 | winner P1 | punishes P1 1 P2 0 | ticks 1843 | hitstop true sfx true shake true
```
The `hitstop` / `sfx` values show which config the round was played in. `ticks` is the round length at 60 ticks per second.

One line for every punish chance, from the moment a fighter leaves blockstun:
```
  PUNISH_WINDOW | round 2 | attacker P1 | defender P2 | opened tick 412 | closed after 7 ticks (window 30) | HIT (L, 60 dmg)
```
| Outcome | Meaning |
|---|---|
| `HIT (move, dmg)` | Punish landed within 30 ticks. **Counts toward the PASS bar.** |
| `MISSED (window expired)` | 30 ticks passed with no hit |
| `LOST (got hit)` / `LOST (blocked again)` | The opponent acted first |
| `OPEN AT ROUND END` | The round ended while the window was open |

Limits: rounds cut short by pressing R mid-round have no `ROUND` line. A punish only
counts if it starts after a blocked hit. A hit after a *whiffed* move is not logged.

---

## 3. Score sheet

Fill in one copy per pair. Weight = "hits feel weighty". Responsive = "controls feel responsive". Both are rated 1–5.

### Pair 1 — order: A then B

| Field | Value |
|---|---|
| Date / facilitator | |
| Log file | `logs/pair1.txt` |
| Total play time (min) | |
| Matchup | P1 (cream) ____ vs P2 (orange) ____ (mirror, same moveset) |
| Input devices (P1 / P2) | |

| Tester ID | Side | A: Weight | A: Responsive | B: Weight | B: Responsive |
|---|---|---|---|---|---|
| | P1 | | | | |
| | P2 | | | | |

| From the log | A (all on) | B (F1+F2 off) |
|---|---|---|
| Rounds played | | |
| Punish HITs | | |
| Punishes per round | | |
| MISSED / LOST windows | | |

**Comments (tester's own words):**
-

**Observed issues (bugs, confusion, controls):**
-

### Pair 2 — order: B then A

| Field | Value |
|---|---|
| Date / facilitator | |
| Log file | `logs/pair2.txt` |
| Total play time (min) | |
| Matchup | P1 (cream) ____ vs P2 (orange) ____ (mirror, same moveset) |
| Input devices (P1 / P2) | |

| Tester ID | Side | A: Weight | A: Responsive | B: Weight | B: Responsive |
|---|---|---|---|---|---|
| | P1 | | | | |
| | P2 | | | | |

| From the log | A (all on) | B (F1+F2 off) |
|---|---|---|
| Rounds played | | |
| Punish HITs | | |
| Punishes per round | | |
| MISSED / LOST windows | | |

**Comments (tester's own words):**
-

**Observed issues (bugs, confusion, controls):**
-

### Pair 3 — order: A then B

| Field | Value |
|---|---|
| Date / facilitator | |
| Log file | `logs/pair3.txt` |
| Total play time (min) | |
| Matchup | P1 (cream) ____ vs P2 (orange) ____ (mirror, same moveset) |
| Input devices (P1 / P2) | |

| Tester ID | Side | A: Weight | A: Responsive | B: Weight | B: Responsive |
|---|---|---|---|---|---|
| | P1 | | | | |
| | P2 | | | | |

| From the log | A (all on) | B (F1+F2 off) |
|---|---|---|
| Rounds played | | |
| Punish HITs | | |
| Punishes per round | | |
| MISSED / LOST windows | | |

**Comments (tester's own words):**
-

**Observed issues (bugs, confusion, controls):**
-

_Add more pairs by copying a pair block._

---

## 4. Summary (fill in after all pairs)

| | A (all on) | B (F1+F2 off) |
|---|---|---|
| Testers with Weight ≥ 4 / total | | |
| Testers with Responsive ≥ 4 / total | | |
| Testers with both ≥ 4 / total | | |
| Avg punishes per round (all pairs) | | |

PASS bar met on config A? ☐ yes ☐ no. Is A clearly better than B? ☐ yes ☐ no ☐ unclear
