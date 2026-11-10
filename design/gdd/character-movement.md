# Character Movement & State Machine

> **Status**: Draft — not yet reviewed (`/design-review` pending). Stays Draft until ADR-0001 and ADR-0002 are Accepted.
> **Author**: user + agents (drafted 2026-11-10 without review rounds, per Tier −1 GDD cap)
> **Last Updated**: 2026-11-10
> **Implements Pillar**: Pillar 3 (Readable Mastery) — movement is the counterplay floor; Pillar 2 (the "answer" half: walking out of range beats Throw)

## Summary

Character Movement owns where each Operator is and what locomotion it is doing:
walking forward and back, jumping, facing, the pushboxes that stop two bodies
overlapping, the stage walls, the corner push-out and the maximum distance
between players. It also owns the **character state view** that every other
combat system reads ("can this character act, and what is it doing?"). All
values are integers in sim units (1 m = 10,000 su) and ticks (ADR-0001). Players
feel it as honest spacing: a step back always moves the same distance, and the
corner is a place you are pushed into, never a place where the rules change.

> **Decisions 2026-11-10 (user):** the nine choices offered with this draft are decided — no cross-ups (M11), no dash in Tier 0 (M12), derived-state composition (M10), walk 340 / 270 (F1), fixed-arc jump (M7, F2), max distance 6 m away-only (M15, F6), knockback decay (M16, F7), round reset by request (M9) as proposed; **facing locks while attacking or airborne** (M8, the alternative). Values remain starting values until Tier −1 data (systems-index decision 2026-11-01).

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Sim Core & State, Input, Move Data Pipeline, Arena`
> **Tier −1 subset**: walk, facing, pushbox separation, stage bounds (§ Tier −1 subset). Jump, max distance and knockback follow.

## Overview

Every move in the game sits on top of this system. It runs in two pipeline
slots of Sim Core (rule 10): **movement & state** (voluntary movement, jump,
facing, separation, bounds) and **reactions applied** (knockback and pushback
from this tick's hit records, then separation and bounds again). It stores its
fields in each player's per-player block, from offset 3 (sim-core rule 5); block
A already copies `prev_x`, `prev_y` and clears `snap` before it runs.

Movement does **not** own attacks, stun, guarding or KO. Those live in the
Attack, Hit Detection, Defense and Round & Match regions. Movement reads them to
decide whether a character may walk or jump, and publishes one pure read
function, `MoveState.derived(b, p)`, that combines all of them into a single
priority-ordered state for the view, AI and other systems (Rule M10).

Claims are labelled **[Verified]**, **[Proposed]**, **[Unverified]** or
**[Measured]** per the Evidence-First Deterministic Integrity constraint
(`systems-index.md`). Every number in this draft is **[Proposed]**; values
borrowed from the mirror-feel prototype are unvalidated (its REPORT.md verdict
is "measured: INCONCLUSIVE").

## Player Fantasy

"I am exactly where I think I am." Footsies — stepping in and out of the
opponent's reach — is the quietest skill in a fighting game and the one that
makes the loud ones (Throw, punish, Ultimate) readable. The player should feel
that walking back is a real answer (it beats Throw, concept counterplay floor),
that the corner is dangerous because space runs out, not because rules change,
and that two characters never slide through each other. Nothing about movement
is random, and nothing depends on which side or which player slot you are.

## Detailed Design

### Core Rules

**M1. Units and fields.** All positions are `su`, velocities `su/tick`, times
ticks (ADR-0001 rules 1, 3). Movement owns these words of each per-player block
(offsets relative to `P_BASE + p × P_STRIDE`; offsets 0–2 belong to block A per
sim-core rule 5):

| Offset | Field | Meaning | Written by |
|---|---|---|---|
| 0–2 | `prev_x`, `prev_y`, `snap` | Sim Core block A (sim-core rule 5) | Block A; Movement **sets** `snap` (M9) |
| 3 | `x` | Centre of the feet, su; 0 = stage centre | Movement |
| 4 | `y` | Height of the feet above the floor, su; ≥ 0 | Movement |
| 5 | `vx` | Voluntary / jump horizontal velocity this tick, su/tick (world sign) | Movement |
| 6 | `vy` | Vertical velocity, su/tick (+ = up) | Movement |
| 7 | `facing` | +1 faces +x, −1 faces −x; never 0 | Movement |
| 8 | `mstate` | Locomotion state (M5) | Movement |
| 9 | `mstate_ticks` | Ticks spent in `mstate` (0 on entry) | Movement |
| 10 | `kb_speed` | Remaining knockback / pushback speed, su/tick, ≥ 0 (facing-local magnitude) | Movement |
| 11 | `kb_dir` | World sign of the knockback (+1 / −1; 0 when none) | Movement |
| 12–15 | spare | Reserved for dash / Dodge (M12) | — |

16 words per player (F8). `P_STRIDE` stays 64 (sim-core F3 estimated Movement at
~16). **[Proposed]**

**M2. Facing-local magnitudes (binding, ADR-0001 rule 5a).** Every speed in
data and in this document is a non-negative magnitude in facing-local space.
The world sign is applied last: `world_dx = facing × dir_local × speed`, where
`dir_local` is +1 toward the opponent, −1 away. No division or ratio is ever
applied to a signed world value.

**M3. Input.** Movement reads the **held direction bits** of this tick's raw
input word from the Input ring (`IN_BASE + p × INPUT_RING_TICKS +
posmod(tick, INPUT_RING_TICKS)`). It converts world LEFT / RIGHT to
`dir_local` with `facing`: RIGHT means toward when `facing = +1`. LEFT + RIGHT
together = neutral. UP requests a jump. The bit positions are the Input GDD's;
Movement never interprets buttons or command sequences (Attack owns those).
**[Proposed — Input GDD fixes the bits]**

**M4. Actionable.** A character may start walking or jumping only if it is
**actionable**: `MoveState.derived` (M10) returns `IDLE` or `WALK`. While it is
not, held directions are ignored and `vx = 0`. Hit-stop: if the character's
hit-stop counter (Hit Detection region) is > 0, Movement skips **all** of its
own advance for that character — no walk, gravity, knockback or `mstate_ticks`
increment — but separation and bounds still run (they move nobody unless the
other character moved). (systems-index TD note 3.)

**M5. Locomotion states (`mstate`).** Owned and written only by Movement.

| `mstate` | Value | Meaning | Entry | Exit |
|---|---|---|---|---|
| `GROUND` | 0 | On the floor, no locomotion commitment | init; `LANDING` ends | `PREJUMP` |
| `PREJUMP` | 1 | Jump startup, still grounded (throwable) | actionable + UP | after `PREJUMP_TICKS` → `AIR` |
| `AIR` | 2 | Airborne, fixed arc | `PREJUMP` ends; knockback that lifts (Hit Detection, later) | `y` reaches 0 → `LANDING` |
| `LANDING` | 3 | Landing recovery, grounded | `AIR` touches down | after `LANDING_TICKS` → `GROUND` |

Walking is not a separate `mstate`: a `GROUND` character with `vx ≠ 0` is
walking (`derived` reports `WALK`). **[Proposed]**

**M6. Walk.** In the movement slot, for an actionable `GROUND` character:
`vx = facing × dir_local × (WALK_FWD_SU if dir_local = +1 else WALK_BACK_SU)`,
or 0 when neutral; then `x += vx`. Walk has no acceleration: full speed on the
first tick, zero on release (readability over momentum). **[Proposed]**

**M7. Jump.** Actionable `GROUND` + UP → `PREJUMP` for `PREJUMP_TICKS` (no
movement; Throw can still catch it — it is grounded). On its last tick the
character takes off: `vy = JUMP_VY0`, `vx = facing × dir_local ×
(JUMP_VX_FWD if dir_local = +1 else JUMP_VX_BACK)` using the direction held on
the **takeoff** tick, then `mstate = AIR`. In `AIR`, each tick: `x += vx`,
`y += vy`, `vy -= GRAVITY` (in that order, F2). No air control, no double jump.
When `y ≤ 0` after the update: `y = 0`, `vx = 0`, `vy = 0`, `mstate = LANDING`.
Jump is **not** in the Tier −1 subset; it is required by Air attacks (Tier 0,
third in the cut order). **[Proposed]**

**M8. Facing.** Sim-core EC-33 plus one amendment (decided 2026-11-10, user;
recorded in sim-core EC-33). With `dx = x_opponent − x_self`, a character whose
facing is **unlocked** takes `facing = +1` if `dx > 0`, `−1` if `dx < 0`, and
keeps it if `dx = 0`. Facing is **locked** (kept from the previous tick) while
the character is **attacking** (`derived = ATTACK`, M10) or **airborne**
(`mstate = AIR`). It is re-evaluated on the first tick the lock is off, so a
character that ends an attack or lands facing the wrong way turns on that
tick. Evaluated once per tick for both players **after** separation and bounds
in the movement slot; both players' `dx` and lock are read before either
facing is written, so P0 and P1 never see each other's new facing first.
Because pushboxes block passing (M11), `dx` cannot change sign in normal play;
the lock matters for setup errors and future side-swap mechanics (e.g. a
throw that swaps sides). **Decided 2026-11-10 (user)**

**M9. Snap.** Movement sets `snap = 1` on any discontinuous position change:
a round reset applied by Movement (Round & Match writes a reset request in its
own region; Movement applies the start positions in its slot) and any
push-out that moves a character more than `SNAP_THRESHOLD_SU` in one tick.
Ordinary walking, jumping, knockback and separation never set it.
**[Proposed]**

**M10. Derived state (read-only, the "state machine" other systems see).**
`MoveState.derived(b, p) -> int` is a pure static function: it reads several
regions and writes nothing. First match wins:

| Priority | Derived state | Condition (owner of the field) |
|---|---|---|
| 1 | `KO` | KO flag set (Round & Match) |
| 2 | `THROW` | Being thrown or throwing (Defense) |
| 3 | `HITSTUN` | Hitstun counter > 0 (Hit Detection) |
| 4 | `BLOCKSTUN` | Blockstun counter > 0 (Defense) |
| 5 | `ATTACK` | An active move (Attack) |
| 6 | `PREJUMP` / `AIR` / `LANDING` | `mstate` (Movement) |
| 7 | `WALK` | `mstate = GROUND` and `vx ≠ 0` |
| 8 | `IDLE` | otherwise |

Only `IDLE` and `WALK` are actionable for movement (M4). Whether an attack may
start from `AIR` or `LANDING`, and whether Block is allowed in `LANDING`, are
the Attack and Defense GDDs' calls; they read `mstate` directly. Until those
regions exist, priorities 1–5 read as false. **Why not one shared state
word:** sim-core rule 5 allows a region to be written only by its owner, with
three exceptions and no others; a single state field written by four systems
would need a fourth exception. **[Proposed]**

**M11. Pushbox separation.** Each character has one pushbox, horizontal only:
half-width `push_hw` from Move Data for its current state / move (Tier −1: the
constant `PUSH_HW_SU`). Pushboxes are **infinite vertical columns**: they
separate regardless of `y`, so nobody can jump over or walk through the other
(no cross-ups in Tier 0). When `|dx| < hw_a + hw_b`, both characters are pushed
apart by the same amount, `ceil(overlap / 2)` each (F3) — no player-index or
side tie-break, so swapping P0 / P1 or mirroring the stage gives mirrored
results. **Decided 2026-11-10 (user)**

**M12. Dash.** Not in this draft's Tier 0 scope: the concept's core mechanics
list walk ("di chuyển"), jump (Air attacks) and Dodge (Defense, cut first), not
dash. Words 12–15 are reserved so a dash or Dodge can be added with a layout
bump. **Decided 2026-11-10 (user)**

**M13. Stage bounds.** The Arena region holds `wall_l` and `wall_r` (su,
written at init). After any position change Movement clamps each centre to
`[wall_l + push_hw, wall_r − push_hw]` (F4). A clamped character's `vx` keeps
its value (the walk animation may keep playing against a wall); its
displacement this tick is what the clamp allows.

**M14. Corner push-out.** If separation would push a character past its wall,
it is clamped there and the **other** character takes the remaining overlap
(F5). The same applies to knockback: a defender pushed into the wall stops, and
the rest of the push moves the attacker back (prototype behaviour, the
pushback-escape rule in the Defense brief). **[Proposed]**

**M15. Maximum player distance.** `|dx| ≤ MAX_DIST_SU` at the end of each
Movement slot. Excess is removed only from movement **away** from the opponent
made this tick (walk back, jump back, knockback), equally from both players
(F6). Walking toward is never blocked by it. The camera reads this limit and
never owns it (systems-index TD note 3). **[Proposed]**

**M16. Knockback and pushback (reactions slot).** For each hit record of this
tick (Hit Detection region) that targets character `p`, Movement sets
`kb_speed = record.kb` (≥ 0) and `kb_dir = attacker.facing`, replacing any
knockback in progress. Pushback on block on the attacker (Defense brief) uses
the same fields with `kb_dir = −attacker.facing`. Each tick while `kb_speed >
0`: `x += kb_dir × kb_speed`, then `kb_speed = max(0, kb_speed −
KB_DECEL_SU)` (F7). Then separation, push-out, bounds and max distance run
again. Knockback is not voluntary movement; it does not change `vx`.
**[Proposed — magnitudes per move are Hit Detection / Defense data]**

**M17. Order inside the movement slot** (both players, P0 then P1 where a
loop is needed; results never depend on that order because each step reads
values from before the step for both players):
1. Advance `mstate` timers (`PREJUMP` → `AIR`, `LANDING` → `GROUND`).
2. Compute and apply walk / jump / airborne motion (M6, M7).
3. Max distance (M15), then separation (M11), corner push-out (M14), bounds (M13).
4. Landing check (M7), facing (M8).

The reactions slot runs: knockback step (M16), then step 3 again.

### Tier −1 subset

Implement first, nothing else: fields `x`, `y` (always 0), `vx`, `facing`,
`mstate` (always `GROUND`), `mstate_ticks`; rules M2–M4 (with M10 priorities 1–5
reading false), M6, M8, M11, M13, M14 for separation, M17 steps 2–4 without
jump. Constants `WALK_FWD_SU`, `WALK_BACK_SU`, `PUSH_HW_SU`, Arena walls ±50,000
su. This replaces the Sim Core PLACEHOLDER movement slot: `PF_X`/`PF_Y` keep
offsets 3 and 4, new fields are added, so `LAYOUT_VERSION` is bumped and the
golden replay fixture regenerated in the same commit (sim-core rule 3).
**Second step (with Hit Detection):** M16 knockback / pushback and M14 for
knockback. **Third step (Tier 0):** jump (M7), landing, max distance (M15).

### States and Transitions

`mstate` transitions are listed in M5. Derived-state priorities are in M10. No
transition is triggered by presentation, by time outside the tick, or by
anything not in the buffer.

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| Sim Core & State | Movement runs in two slots; owns offsets 3–15 of each per-player block | sim-core rules 5, 10, 13; facing rule EC-33; `snap` (rule 5) |
| Input | Movement reads held direction bits from the input ring | Input GDD fixes bit positions (M3) |
| Move Data Pipeline | Supplies `push_hw` per state / move, per-Operator speeds | Integer su, validated before `init` |
| Arena | Writes `wall_l`, `wall_r` at init | su |
| Hit Detection & Damage | Movement reads hit-stop, hitstun, hit records (`kb`, attacker); Hit reads `x`, `y`, `facing`, `mstate` for box placement | M4, M10, M16 |
| Attack System | Attack reads `mstate`, `facing`, `x`; Movement reads "active move" for M10 | M10 |
| Defense | Defense reads `mstate` (airborne not throwable, concept); Movement reads blockstun / throw flags; pushback on block via M16 | M10, M14, M16 |
| Round & Match Flow | Initial positions, facing, round-reset request; KO flag read by M10 | M9 |
| Projectiles | Spawn position from `x`, `y`, `facing` | read-only |
| Opponent AI | Reads `derived`, positions | read-only |
| Presentation & Feel | Reads through `SimView`: `x`, `y`, `prev_*`, `snap`, `facing`, `derived` | ADR-0002 rules 4, 6, 7 |

## Formulas

All integer; `ceil(o / 2)` is written `SimMath.div_floor(o + 1, 2)`; `o ≥ 0`.

### F1. Walk displacement

`dx_world = facing × dir_local × speed`, `speed = WALK_FWD_SU` if `dir_local = +1`, `WALK_BACK_SU` if `−1`, 0 if neutral.

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| facing | int | ±1 | buffer | M8 |
| dir_local | int | −1, 0, +1 | input (M3) | toward / away |
| WALK_FWD_SU | int | 200–500 | data | Proposed 340 |
| WALK_BACK_SU | int | 150–450 | data | Proposed 270 |

**Output range:** −450…+500 su/tick. **Example:** P1 (`facing = −1`) holds
LEFT → toward (`dir_local = +1`) → `dx = −1 × 1 × 340 = −340` su. Mirror: P0
(`facing = +1`) holds RIGHT → `+340`. **Source:** prototype 4.0 / 3.2 px per
tick at ~117 px per metre (140 px body ≈ 1.2 m, art bible §8.7) → 342 / 274
su, rounded. **[Unverified — prototype unvalidated]**

### F2. Jump arc

Takeoff tick `n = 0`: `vy = JUMP_VY0`. Each airborne tick: `y += vy`, then `vy -= GRAVITY`. Height after `n` airborne ticks:

`y(n) = n × JUMP_VY0 − GRAVITY × n × (n − 1) / 2`

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| JUMP_VY0 | int | 600–2,000 | data | Proposed 1,200 su/tick |
| GRAVITY | int | 20–150 | data | Proposed 60 su/tick² |
| n | int | ≥ 1 | tick count | airborne ticks |

**Airtime:** the first `n` with `y(n) ≤ 0`, `n = 2 × JUMP_VY0 / GRAVITY + 1`
when that divides exactly. **Example (proposed values):** `y(41) = 41 × 1,200 −
60 × 41 × 40 / 2 = 49,200 − 49,200 = 0` → lands on airborne tick 41 (0.68 s);
apex `y(20) = y(21) = 24,000 − 11,400 = 12,600` su (1.26 m, about one body
height). Horizontal distance: `41 × JUMP_VX_FWD = 41 × 300 = 12,300` su.
Total jump commitment: `PREJUMP_TICKS + 41 + LANDING_TICKS = 4 + 41 + 3 = 48`
ticks. **[Proposed]**

### F3. Pushbox separation

`overlap = (hw_a + hw_b) − |x_b − x_a|`; if `overlap > 0`: `s = ceil(overlap / 2)`;
the left character moves `−s`, the right `+s`.

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| hw_a, hw_b | int | 1,000–5,000 | Move Data | pushbox half-widths; Proposed 2,500 |
| overlap | int | 1 … hw_a + hw_b | computed | |

**Output:** each moves `ceil(overlap / 2)`; the gap afterwards is 0 or 1 su
(1 su = 0.1 mm, invisible). **Example:** `hw = 2,500` each, `x_a = −2,000`,
`x_b = 2,999` → `|dx| = 4,999`, `overlap = 1`, `s = 1` → `x_a = −2,001`,
`x_b = 3,000`, gap 1. Swapping which player is a/b gives the same per-character
result. **`dx = 0` (setup error only):** each character moves `−facing × s`
(backward), which is also slot-independent. **[Proposed]**

### F4. Bounds

`x = clampi(x, wall_l + push_hw, wall_r − push_hw)`. **Example:** walls
±50,000, `push_hw = 2,500` → `x ∈ [−47,500, 47,500]`.

### F5. Corner push-out

After F3, if a character's new `x` exceeds its bound by `e > 0`, it is clamped
and the other character moves a further `e` away from it (then is clamped
itself). **Example:** `x_a = −47,500` (at the left wall), `x_b = −42,300`
(no overlap: `|dx| = 5,200`) walks to `−42,640`; `overlap = 5,000 − 4,860 =
140`, `s = 70` → `x_a` would be `−47,570`, `e = 70` → `x_a = −47,500`,
`x_b = −42,640 + 70 + 70 = −42,500`. Net: the walker is stopped exactly at
contact distance 5,000 and the cornered character does not move. Both cannot be
at walls on the same side because `wall_r − wall_l > hw_a + hw_b` (Arena
obligation). **[Proposed]**

### F6. Maximum distance

`excess = |dx| − MAX_DIST_SU`; if `excess > 0`: let `away_i ≥ 0` be how far
character `i` moved away from the other this slot. Take back `t_i =
min(away_i, ceil(excess / 2))` from each; if `excess − t_a − t_b > 0`, take
the rest from whichever still has `away_i − t_i > 0` (only one can).

| Variable | Type | Range | Source |
|---|---|---|---|
| MAX_DIST_SU | int | 40,000–90,000 | Proposed 60,000 (6 m on a 10 m stage) |

**Example:** `|dx| = 59,800`, both walk back 270 → `|dx| = 60,340`,
`excess = 340`, `t = 170` each → `|dx| = 60,000`. Symmetric by construction.
**[Proposed — the value is a camera-framing choice]**

### F7. Knockback decay

Displacement on tick `k` (k = 0, 1, …) after the hit: `kb0 − k × KB_DECEL_SU`
while positive. Total distance `D = Σ_{k=0}^{m−1} (kb0 − k × KB_DECEL)` with
`m = ceil(kb0 / KB_DECEL)`.

| Variable | Type | Range | Source |
|---|---|---|---|
| kb0 | int | 0–2,000 su/tick | hit record (Hit Detection / Defense data) |
| KB_DECEL_SU | int | 20–400 | Proposed 100 |

**Example:** `kb0 = 600`, `KB_DECEL = 100` → 600 + 500 + 400 + 300 + 200 + 100
= 2,100 su over 6 ticks. **[Proposed]**

### F8. Buffer words

`Movement words = 16 × P_COUNT = 32` (offsets 0–15 of two 64-word blocks; 3
are block A's). Sim Core F3 total unchanged (1,624 ≤ 2,048) because the
per-player block was already sized 64. **[Verified arithmetic]**

## Edge Cases

- **EC-M1. Both players walk into each other on the same tick.** Both move
  first (M17 step 2), then F3 splits the overlap equally. A mirror test
  (swap P0 / P1, mirror x) must give mirrored positions tick for tick.
- **EC-M2. One player is cornered and the other walks in.** F5: the cornered
  one does not move; the walker stops at contact distance.
- **EC-M3. Overlap at round start** (bad setup data). F3 resolves it on the
  first tick; `dx = 0` uses the facing-based direction (F3) and never divides.
- **EC-M4. Jump onto a cornered opponent.** Pushboxes are columns (M11), so
  the jumper is pushed away from the wall horizontally while airborne; the
  arc's vertical part is unchanged.
- **EC-M5. Jump back while at max distance.** F6 removes the away component;
  the jumper rises and falls in place. Jump forward is never limited.
- **EC-M6. Knockback into the wall.** F5: the defender stops at the wall, the
  attacker is pushed back by the rest (this is the corner pushback rule).
- **EC-M7. Hit-stop on one character only.** That character does not advance
  (M4); the other may walk into it; separation then pushes both (a
  hit-stopped character can be pushed, it does not push itself).
- **EC-M8. Freeze (`freeze_ticks > 0`).** Block B is skipped by Sim Core; no
  Movement code runs; block A copies prev = current, so the view holds still.
- **EC-M9. Ended sim.** Sim Core returns before block A; nothing moves.
- **EC-M10. LEFT + RIGHT held together.** Neutral (M3).
- **EC-M11. UP held through landing.** `LANDING` is not actionable; a new
  jump starts only after `LANDING_TICKS`, and only if UP is still held then
  (no buffering here; buffering is Attack / Input's call).
- **EC-M12. Facing with `dx = 0`.** Unchanged (EC-33).
- **EC-M14. Opponent ends up behind during an attack or a jump.** Cannot
  happen through walking (M11 columns). If it happens anyway (setup error,
  later side-swap), facing stays locked until the attack ends or the
  character lands, then turns on that first unlocked tick (M8). Walk input
  during the lock is irrelevant (not actionable, M4).
- **EC-M13. Integer range.** `|x| ≤ 50,000`, speeds ≤ 2,000, products below
  `10^9`; no overflow path (sim-core F11).

## Dependencies

| System | Hard / soft | What Movement needs | Status |
|---|---|---|---|
| Sim Core & State | Hard | Slots, per-player block, block A prev / snap, facing rule EC-33 | Draft GDD |
| Input | Hard | Direction bit positions in the raw word | Not designed |
| Move Data Pipeline | Hard | `push_hw` per state / move; per-Operator speeds (integer, validated) | Not designed |
| Arena | Hard | `wall_l`, `wall_r` at init; width > sum of pushboxes | Not designed |
| Hit Detection & Damage | Hard (reactions) | Hit-stop and hitstun counters, hit records with `kb` and attacker | Not designed |
| Attack System | Soft (read) | "Active move" flag for M10 | Not designed |
| Defense | Soft (read) | Blockstun, throw flags; pushback magnitude per blocked move | Not designed |
| Round & Match Flow | Hard | Start positions, facing, reset request; KO flag | Not designed |

**Systems that depend on Movement:** Hit Detection, Attack, Defense,
Operator Definitions, Opponent AI, Projectiles, Presentation & Feel (camera
reads max distance). Each must list "Depends on: Character Movement" in its
own GDD (bidirectionality rule).

**Obligations from sim-core (Dependencies table, row 5) — status:** facing
rule adopted (M8); fields from offset 3 (M1); `snap` set on discontinuities
(M9); `P_STRIDE` = 64 confirmed (M1, F8); facing-local magnitudes, sign last
(M2).

## Tuning Knobs

| Knob | Proposed | Safe range | Affects | Source |
|---|---|---|---|---|
| `WALK_FWD_SU` | 340 | 200–500 | Footsies pace, approach | prototype (F1) |
| `WALK_BACK_SU` | 270 | 150–450 | Escape from Throw range, retreat | prototype (F1) |
| `PUSH_HW_SU` | 2,500 | 1,000–5,000 | Closest distance, throw range feel | prototype 30 px |
| `PREJUMP_TICKS` | 4 | 2–6 | Jump reaction window, throwability | genre convention |
| `JUMP_VY0` | 1,200 | 600–2,000 | Jump height and airtime (F2) | F2 |
| `GRAVITY` | 60 | 20–150 | Airtime (F2) | F2 |
| `JUMP_VX_FWD` / `JUMP_VX_BACK` | 300 / 240 | 100–600 | Jump distance | F2 |
| `LANDING_TICKS` | 3 | 0–8 | Punish window after a jump | genre convention |
| `MAX_DIST_SU` | 60,000 | 40,000–90,000 | Camera framing, running away | F6 |
| `KB_DECEL_SU` | 100 | 20–400 | Knockback feel (F7) | F7 |
| `SNAP_THRESHOLD_SU` | 5,000 | 2,000–20,000 | When the view stops interpolating | M9 |

Per-Operator speeds may override the walk and jump knobs through Operator
Definitions (data). All are **[Proposed]**, provisional until Tier −1 data
(systems-index decision 2026-11-01).

## Visual/Audio Requirements

Movement draws nothing (ADR-0002). Presentation maps `derived` and `mstate` to
animations: idle, walk forward, walk back (separate, so retreat reads as
retreat), prejump, airborne (rise / fall by `vy` sign), landing. Footstep SFX
and landing dust, if any, come from events Movement does **not** yet emit —
Movement emits no presentation events in this draft; footsteps can key off
animation in presentation (they never affect the sim).

## Game Feel

- **Input latency:** a direction held on frame F moves the character on the
  next stepped tick (sim-core rule 7); walk has no acceleration (M6).
- **Weight:** comes from fixed, short jump commitment (48 ticks, F2) and no
  air control — a jump is a decision, not a correction.
- **Readability:** walk back is slower than forward (270 vs 340) so retreat is
  visible but still real.

## UI Requirements

N/A — no screen or HUD element. Training Mode may later show positions and
`derived` state through `SimView`.

## Cross-References

| This document references | Target | Element | Nature |
|---|---|---|---|
| M1, M9, M17 | `design/gdd/sim-core.md` | Rules 5, 7a, 8–10, EC-33, F3, F11 | Architecture dependency |
| M2, all formulas | `docs/architecture/adr-0001-sim-numeric-model.md` | Rules 1, 3, 5, 5a, 6 | Numeric model (Proposed) |
| Visual, Interactions | `docs/architecture/adr-0002-sim-view-split.md` | Rules 4, 6, 7 | View contract (Proposed) |
| M7, M12, Pillar | `design/gdd/game-concept.md` | Core Mechanics 1–2; MVP; cut order | Rule source |
| M10, M14, M15 | `design/gdd/systems-index.md` | TD-SYSTEM-BOUNDARY note 3; Defense brief (pushback escape) | Ownership |
| F1, Tuning | `prototypes/mirror-feel-concept/main.gd`, `REPORT.md` | WALK_FWD / WALK_BACK, BODY_HALF_W, corner push | Provisional values |

## Acceptance Criteria

*U = gdUnit4 unit test (`tests/unit/movement/`), oracle computed in the test.
Fixtures set `tick ≥ 1`, Arena walls ±50,000, `PUSH_HW = 2,500` unless stated.
"Mirror" = swap P0 / P1 and negate every x and facing.*

**Tier −1 subset**
- **AC-M1** (U; M6, F1) GIVEN P0 at x = 0, facing +1, actionable, WHEN RIGHT
  is held for 10 ticks, THEN x = 3,400; WHEN LEFT for 10 ticks from 0, THEN
  x = −2,700.
- **AC-M2** (U; M2, F1) GIVEN any input sequence of 300 ticks from a
  committed-seed generator, WHEN run and separately run mirrored, THEN every
  tick's positions are exact negatives with players swapped.
- **AC-M3** (U; M3) GIVEN LEFT + RIGHT held, WHEN 5 ticks run, THEN x is
  unchanged and `derived = IDLE`.
- **AC-M4** (U; M11, F3) GIVEN x_a = −2,000, x_b = 2,999, WHEN separation
  runs, THEN x_a = −2,001, x_b = 3,000; with a/b slots swapped, the same
  per-character result.
- **AC-M5** (U; F3, EC-M1) GIVEN both at ±3,000 walking toward each other,
  WHEN 5 ticks run, THEN `|dx| ≥ 5,000` every tick and positions are
  symmetric about 0 every tick.
- **AC-M6** (U; M13, F4) GIVEN x = 47,400 walking toward +x, WHEN 1 tick runs,
  THEN x = 47,500; no tick ever ends outside `[−47,500, 47,500]`.
- **AC-M7** (U; M14, F5) GIVEN the F5 example, WHEN 1 tick runs, THEN
  x_a = −47,500 and x_b = −42,500.
- **AC-M8** (U; M8, EC-M12) GIVEN dx = −1, 0, +1 and facing unlocked, WHEN
  facing is evaluated, THEN facing = −1, unchanged, +1.
- **AC-M8b** (U; M8, EC-M14) GIVEN P0 with facing +1, the opponent placed at
  dx < 0, and P0 attacking (or `mstate = AIR`), WHEN a tick runs, THEN facing
  stays +1; WHEN the lock clears, THEN facing becomes −1 on that tick. Both
  lock conditions are set directly in the fixture until Attack and jump exist.
- **AC-M9** (U; M4) GIVEN hit-stop 3 on P0 and RIGHT held, WHEN 3 ticks run,
  THEN P0's x is unchanged; on the 4th tick it moves 340.
- **AC-M10** (U; M1, sim-core rule 5) GIVEN a normal tick, WHEN the movement
  slot runs alone, THEN only Movement's offsets 3–15 of both players change
  (block A's offsets 0–2 and every other region unchanged).
- **AC-M11** (U; sim-core rule 3) GIVEN the Tier −1 implementation, WHEN the
  layout fingerprint test runs, THEN it passes only with `LAYOUT_VERSION`
  bumped, and the golden replay fixture was regenerated in the same commit.

**Later steps**
- **AC-M12** (U; M7, F2) GIVEN a jump with the proposed values, WHEN it
  runs, THEN takeoff is on prejump tick 4, `y` peaks at 12,600 on airborne
  ticks 20 and 21, lands on airborne tick 41 with y = 0, and `LANDING` lasts 3.
- **AC-M13** (U; M15, F6) GIVEN |dx| = 59,800 and both walking back, WHEN 1
  tick runs, THEN |dx| = 60,000 and each moved back exactly 100 (270 − 170).
- **AC-M14** (U; M16, F7) GIVEN a hit record with kb = 600 on P1, WHEN 7
  ticks run, THEN P1 moves 2,100 in the attacker's facing direction over 6
  ticks and 0 on the 7th.
- **AC-M15** (U; M14, EC-M6) GIVEN the defender 500 su from the wall and
  kb = 600, WHEN the reactions slot runs, THEN the defender ends at the wall
  and the attacker moves 100 back.
- **AC-M16** (U; M10) GIVEN each combination of KO, throw, hitstun,
  blockstun, active move and `mstate`, WHEN `derived` is called, THEN it
  returns the highest-priority state and writes no buffer word.
- **AC-M17** (U; M9) GIVEN a round-reset request, WHEN the movement slot
  runs, THEN start positions are applied and `snap = 1` for both players;
  WHEN an ordinary walk tick runs, THEN `snap` stays 0.

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| OQ-M1 | ~~No cross-ups — confirm~~ **Decided 2026-11-10 (user):** no cross-ups | — | Done |
| OQ-M2 | ~~Dash excluded from Tier 0 — confirm~~ **Decided 2026-11-10 (user):** no dash | — | Done |
| OQ-M3 | Max distance 6 m decided 2026-11-10 (user); camera framing still to be checked | Presentation | Arena / camera spike |
| OQ-M4 | Derived-state composition instead of one shared state word (M10) — needs Attack, Hit, Defense to expose the flags it reads | Attack / Hit / Defense GDDs | When written |
| OQ-M5 | Input direction bit positions | Input GDD | Before Tier −1 implementation |
| OQ-M6 | Round reset via request in Round's region, applied by Movement (M9) | Round & Match GDD | When written |
| OQ-M7 | Airborne hit reactions (fall, juggle limits) | Hit Detection GDD | Tier 0 |
