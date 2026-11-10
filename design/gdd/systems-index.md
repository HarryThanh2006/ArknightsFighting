# Systems Index: Arknights – Operator Clash: Tactical Deployment

> **Status**: Draft
> **Created**: 2026-11-01
> **Last Updated**: 2026-11-01
> **Source Concept**: design/gdd/game-concept.md
> **Gates**: TD-SYSTEM-BOUNDARY: CONCERNS (applied, notes below) · PR-SCOPE: OPTIMISTIC → adjustments A–E applied (re-reads REALISTIC, low confidence; re-run after Tier −1) · CD-SYSTEMS: CONCERNS (accepted, Creative Director Note under Priority Tiers)

---

## Overview

Operator Clash is a 1v1 2.5D fighter whose whole mechanical scope hangs off one
deterministic 60 Hz simulation. The game needs a small, deep set of systems
rather than a broad one: no economy, no progression, no narrative, no save
data. Everything a player feels — the combo flow, the class-specific SP charge,
the timed skill window, the Ultimate payoff — is produced by sim systems that
must stay bit-exact across machines, and then read (never written) by a
presentation layer. That split is the single most important structural fact in
this index (TD-SYSTEM-BOUNDARY).

**Pillar map.** Pillar 1 (Class Is Identity) lives in **SP, Skills & Ultimate**
and **Operator Definitions** — the SP type is where an Operator's identity is
established. Pillar 2 (Flow Into Burst, with an answer to every burst) lives in
**Attack System**, **Hit Detection & Damage** and **Defense**; the counterplay
floor (Block, movement, hit-interrupt) and the Throw triangle are never cut.
Pillar 3 (Readable Mastery) lives in the **HUD** (UX spec) and **Presentation &
Feel**, governed by the art bible. Pillar 4 (Rhodes Island Faithful) is a
presentation concern for Menus & Select, Arena and the art bible.

**Per-system rationale (thorough).**

- **Sim Core & State** — the fixed tick, the one flat state buffer, snapshot /
  restore, seeded RNG and the numeric model (fixed-point vs controlled float, an
  ADR). Every other sim system registers into its phase pipeline. Bottleneck #1.
- **Input** — device sampling and two-player mapping (shared keyboard +
  gamepad) outside the sim; one raw input word per player per tick inside it.
  Owns ghosting mitigation, not command interpretation.
- **Replay & Checksum** — records input words plus a header (seed, picks, arena,
  move-data hash); per-tick checksum of the state buffer; runs in CI. A Tier −1
  pass condition.
- **Move Data Pipeline** — external per-frame hitbox/hurtbox/throwbox/pushbox
  data, its schema and version hash, hot reload outside matches, debug-draw
  overlay. Bottleneck: Attack, Hit, Defense, Projectiles and Operator data all
  read it.
- **Character Movement & State Machine** *(inferred)* — walk, dash, jump,
  facing, pushbox separation, corner push-out, stage bounds and max player
  distance. Every move sits on top of this state machine.
- **Hit Detection & Damage** — symmetric overlap resolution, damage and scaling
  formula, hitstun / knockback emitted as hit events, hit-stop counter, combo
  counter and total damage. Highest god-object risk (see TD notes).
- **Attack System** — Light / Heavy / Air / Special, direction + button
  commands, input buffer windows, cancel windows, move priority. The "flow" half
  of Pillar 2.
- **Defense** — Block (guard flag), the Throw triangle and throw tech, the
  hit-interrupt rule for skill states; Perfect Guard and Dodge as a separable,
  cut-first section. The "answer" half of Pillar 2.
  **On-block rule (decided 2026-11-09):** every move has a defined on-block
  advantage. Light is ≤ 0 on block; Heavy and Specials are minus; a blocked
  Ultimate or whiffed Throw is punishable by a full combo. After a blocked
  Light the defender's fastest Light can contest, so continuing pressure costs
  the attacker a read (Throw or frame trap), never a free turn.
  **Light-pressure escape (non-guessing):** pushback on block — each blocked hit
  pushes the attacker back, so after at most N blocked Lights the attacker is
  out of Light reach and the defender gets a real turn (N and the corner case
  → Defense GDD, with Movement's corner push-out). Evidence: prototype
  mirror-feel had Light +1 on block and 72 of 90 punish windows ended
  "blocked again" (`prototypes/mirror-feel-concept/REPORT.md`).
- **SP, Skills & Ultimate** *(merged #9 + #10)* — Auto / Offensive / Defensive
  charge, the timed skill state counted in ticks with its interrupt threshold,
  and the Ultimate gauge charged from the same source as the SP type, with its
  startup / block / punish rules and the on-hit freeze. One resource model, so
  one GDD.
- **Projectiles** *(inferred)* — pooled, fixed-size projectile state for
  Amiya's Arts; collides through Hit Detection.
- **Operator Definitions** — the data schema for an Operator plus the Ch'en and
  Amiya sheets. Data plus small hooks, never a class per Operator.
- **Round & Match Flow** — in-sim half: 99 s (5940-tick) round clock, K.O.,
  timeout = higher HP% wins, best-of-3, round reset. Out-of-sim half (rematch,
  return to menu) is handed to Menus & Select. Carries the mandatory
  Amiya-kiting acceptance criterion.
- **Opponent AI** — behaviour states, reaction delay in ticks, seeded RNG in sim
  state; Normal at Tier 0, Easy / Hard at Tier 1. A tuning problem as much as a
  programming one.
- **Arena** — Lungmen Street: bounds, walls / no walls, floor line. Small but
  load-bearing because the wall decision feeds the kiting gate.
- **Presentation & Feel** *(merged #16 + #17 + #18; inferred)* — camera framing
  and push-in, animation seeked to the sim tick, presentation-only slow-mo and
  shake, class-shape VFX and hit sparks. Reads sim events by tick number.
- **Toon & Outline Rendering** *(inferred; no GDD)* — covered by the art bible
  (§5, §6, §8) and a shader ADR.
- **HUD** *(no GDD)* — specified by the UX spec `design/ux/hud.md` against art
  bible §7.
- **Menus & Select** *(merged #21 + #22)* — title, pause, result screens,
  minimal character select, out-of-sim match flow.
- **Audio** — music, SFX, separate music / SFX volume; consumes hit, skill,
  Ultimate and round events. MVP because Pillar 2 says a hit's weight comes from
  hit-stop *and sound*.
- **Settings** — Tier 1, minimal first (rebinding, volume), then the art bible
  §7.7 visual / accessibility options.
- **LAN Netcode** *(merged #26a + #26b)* — input exchange and delay buffer over
  UDP (`PacketPeerUDP`, direct IP), then the session side (handshake, select
  sync, rematch). Tier −1 spike produces a report + ADR, not a GDD; the GDD is
  written for Tier 1.
- **Training Mode** — Tier 1: frame data, input display, dummy settings.
- **Operator Collection** — Tier 2: Operator info and lore.

**Relationship analysis.** The graph is a funnel: Sim Core → Move Data → the
four combat systems (Movement, Hit, Attack, Defense) → the resource layer (SP,
Skills & Ultimate) → content (Operators) and the opponent (AI) → read-only
presentation. Four cycles exist inside the combat cluster; all four are broken
by the same mechanism — a fixed per-tick phase order owned by Sim Core, with
systems communicating through plain fields in the state buffer rather than by
calling each other (see Circular Dependencies). Presentation, HUD and Audio sit
outside the sim entirely and must never write to it.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Sim Core & State | Core | MVP | Designed | design/gdd/sim-core.md | — |
| 2 | Input | Core | MVP | Not Started | — | Sim Core & State |
| 3 | Replay & Checksum | Core | MVP | Not Started | — | Sim Core & State, Input, Move Data Pipeline |
| 4 | Move Data Pipeline | Core | MVP | Not Started | — | Sim Core & State |
| 5 | Character Movement & State Machine (inferred) | Gameplay | MVP | Draft | design/gdd/character-movement.md | Sim Core & State, Input, Move Data Pipeline, Arena |
| 6 | Hit Detection & Damage | Gameplay | MVP | Not Started | — | Sim Core & State, Move Data Pipeline, Character Movement & State Machine |
| 7 | Attack System | Gameplay | MVP | Not Started | — | Sim Core & State, Input, Move Data Pipeline, Character Movement & State Machine, Hit Detection & Damage |
| 8 | Defense | Gameplay | MVP | Not Started | — | Sim Core & State, Character Movement & State Machine, Hit Detection & Damage, Attack System |
| 9 | SP, Skills & Ultimate | Gameplay | MVP | Not Started | — | Sim Core & State, Hit Detection & Damage, Defense |
| 10 | Projectiles (inferred) | Gameplay | MVP | Not Started | — | Sim Core & State, Move Data Pipeline, Hit Detection & Damage |
| 11 | Operator Definitions | Gameplay | MVP | Not Started | — | Move Data Pipeline, Character Movement & State Machine, Attack System, SP, Skills & Ultimate, Projectiles |
| 12 | Round & Match Flow | Gameplay | MVP | Not Started | — | Sim Core & State, Hit Detection & Damage |
| 13 | Opponent AI | Gameplay | MVP | Not Started | — | Sim Core & State, Input, Character Movement & State Machine, Attack System, Defense, SP, Skills & Ultimate, Projectiles |
| 14 | Arena | Gameplay | MVP | Not Started | — | Sim Core & State |
| 15 | Presentation & Feel (inferred) | Core | MVP | Not Started | — | Sim Core & State, Move Data Pipeline, Hit Detection & Damage, SP, Skills & Ultimate |
| 16 | Toon & Outline Rendering (inferred) | Core | MVP | Not Started | design/art/art-bible.md + shader ADR (no GDD) | Presentation & Feel |
| 17 | HUD | UI | MVP | Not Started | design/ux/hud.md (UX spec, no GDD) | Sim Core & State, Hit Detection & Damage, SP, Skills & Ultimate, Round & Match Flow |
| 18 | Menus & Select | UI | MVP | Not Started | — | Sim Core & State, Input, Round & Match Flow, Operator Definitions |
| 19 | Audio | Audio | MVP | Not Started | — | Sim Core & State, Hit Detection & Damage, SP, Skills & Ultimate, Round & Match Flow |
| 20 | Settings | Persistence | Alpha | Not Started | — | Input, HUD, Menus & Select, Audio |
| 21 | LAN Netcode | Core | Alpha | Not Started | — (Tier −1: spike report + ADR) | Sim Core & State, Input, Replay & Checksum, Round & Match Flow, Menus & Select |
| 22 | Training Mode | Gameplay | Alpha | Not Started | — | Sim Core & State, Move Data Pipeline, Defense, Round & Match Flow, HUD, Menus & Select |
| 23 | Operator Collection | Meta | Full Vision | Not Started | — | Operator Definitions, Menus & Select |

**Merges (PR-SCOPE adjustment B, 2026-11-01):** #9 SP & Skill State + #10
Ultimate → *SP, Skills & Ultimate*; #16 Camera + #17 Animation & Presentation
Sync + #18 VFX & Hit Feedback → *Presentation & Feel*; #21 Menus & Screen Flow +
#22 Character Select → *Menus & Select*; #26a LAN Input Exchange + #26b LAN
Session → *LAN Netcode*. Numbering above is post-merge.

**GDD rigor per system (PR-SCOPE adjustment C).** Project default is
`workflow: full`. Lightweight systems get
`workflow_overrides.system_overrides.<system>: standard` in `project.yaml`, added
when each GDD starts (not `minimal` — this project has no `design/game-brief.md`).

| Rigor | Systems |
|---|---|
| **Full (all 8 sections)** | Character Movement & State Machine, Hit Detection & Damage, Attack System, Defense, SP Skills & Ultimate, Round & Match Flow, Opponent AI |
| **Standard (5 sections + Formulas where numeric)** | Sim Core & State, Input, Replay & Checksum, Move Data Pipeline, Projectiles, Operator Definitions, Arena, Presentation & Feel, Menus & Select, Audio |
| **No GDD** | Toon & Outline Rendering (art bible + ADR), HUD (UX spec), LAN at Tier −1 (spike report + ADR) |

---

## Categories

| Category | Description | Typical Systems |
|----------|-------------|-----------------|
| **Core** | Foundation systems everything depends on | Sim core, input, replay, move data, presentation, rendering, netcode |
| **Gameplay** | The systems that make the game fun | Movement, hit detection, attacks, defense, SP/skills, AI, rounds, arena, training |
| **Persistence** | Save state and continuity | Settings |
| **UI** | Player-facing information displays | HUD, menus & select |
| **Audio** | Sound and music systems | Music, SFX |
| **Meta** | Systems outside the core game loop | Operator Collection |

Progression, Economy and Narrative are intentionally absent (anti-pillars: no
grind, no gacha, no story mode).

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | = concept **Tier 0**. Required for the core loop to function. Without these, you can't test "is this fun?" | Tier 0 playable (Ch'en vs Amiya, Lungmen Street) | Design FIRST |
| **Vertical Slice** | Not a separate tier. Concept **Tier −1** is the foundation slice; the **Combat Slice** (Ch'en + Amiya, decided 2026-11-01) is the **first Tier 0 milestone** — all MVP systems except Opponent AI, with Menus & Select minimal. | Combat Slice gate | — |
| **Alpha** | = concept **Tier 1** ("play with friends"). | Tier 1 | Design THIRD |
| **Full Vision** | = concept **Tier 2** (wishlist: up to 10 Operators, 7 arenas). | Tier 2 | Design as needed |

**Tier −1 subset (designed first, from a prototype brief — not GDDs; PR-SCOPE
adjustment A).** Sim Core & State, Input, Replay & Checksum, Move Data Pipeline,
Character Movement & State Machine, Hit Detection & Damage, Attack System
(Light/Heavy only), Defense (Block only), Round & Match Flow (core rules),
Arena (one flat plane), basic Presentation & Feel (box characters, basic
camera), plus the one-week LAN spike. Tier −1 produces: one prototype brief (or
`/quick-design` specs, ~2–3 days), the **numeric-model ADR** (fixed-point vs
controlled float) and the **sim/view-split ADR** before any combat code, and a
LAN spike report + ADR. **Decision 2026-11-01:** GDDs are drafted in parallel
with Tier −1; Formulas and Tuning Knobs stay provisional until Tier −1 data
exists; Sim Core, Movement and Hit Detection GDDs stay drafts until
ADR-0001/0002 are Accepted; the Combat GDD must be written and reviewed before
the Combat Slice.

**Tier 1 (Alpha) order (2026-11-01):** minimal Settings (rebinding, volume) →
LAN Netcode → Training Mode → AI Easy/Hard (extension of Opponent AI) → full
≤ 2.5 s Ultimate cinematic → Mudrock (content). This makes the concept's
fallback ("ship Tier 0 + early Tier 1, including LAN") consistent.

> **Producer Note** (all tiers, PR-SCOPE: OPTIMISTIC → adjusted): assumes ~5
> days/week of real work (confirmed by the user 2026-11-01). Content scope fits;
> documentation at full rigor did not, hence adjustments A–C (~3 weeks of Tier 0
> recovered; GDD effort ~39 → ~22–25 days). **Adjustment D (hard rule):** log time
> spent on docs; if docs exceed 25% of logged time after Tier −1, switch to
> `modes.workflow: standard` and keep full-rigor overrides only on the 7 full
> systems. Re-run PR-SCOPE after Tier −1 with actual velocity, when the Tier 0
> target date (± 4 weeks) is set. Log: `production/time-log.md`.
>
> **Tier −1 schedule rules — decided 2026-11-09 (user, PR-PHASE-GATE):**
> (1) **GDD cap:** during Tier −1, draft only the Foundation GDDs (Sim Core,
> Movement, Hit Detection, Defense), ≤ 5 days total; every other GDD waits for
> Tier −1 PASS, Combat GDD first. (2) **Art spike:** the last week of Tier −1,
> after the LAN spike, timeboxed to 1 week: 1 rigid-part chibi model + 3
> animations; its result sets the per-animation estimate before the Combat Slice
> is committed. Counts inside the 9-week Tier −1 max.
>
> **Adjustment E — decided 2026-11-01 (user, on creative-director advice):** the
> Tier 0 fallback cut order is **Perfect Guard/Dodge → AI Normal → Air attack**.
> Conditions: Tier 0 playtests are tester vs tester (3 pairs, 30 min reserved each, not mandatory — concept 2026-11-09; if a
> tester ever faces the developer, the developer plays a fixed script);
> "Rematch unprompted" counts when either player presses it; Sim Core keeps the
> "AI writes its input word" phase slot in Tier 0 even if AI is cut. Concept MVP
> item 7 and the fallback line were updated to match (2026-11-01).

> **Creative Director Note** (CD-SYSTEMS: CONCERNS, accepted 2026-11-01 — binding
> brief requirements):
> 1. **(MVP) Operator Definitions** — stays Standard rigor, but each Operator
>    sheet must include a **Player Fantasy** section, and the GDD must carry an
>    acceptance criterion applying the Pillar 1 design test: each Operator
>    differs from every other on at least one of **preferred range, when SP comes
>    in, or when the skill wants to be used**. The schema carries those three
>    fields explicitly.
> 2. **(MVP) Defense ↔ SP, Skills & Ultimate** — Defense defines the counterplay
>    floor (Block, movement, hit-interrupt) as the authoritative rule. SP, Skills &
>    Ultimate carries Pillar 2 design test (a) as an acceptance criterion against
>    Defense's definition, for every skill and the Ultimate.
> 3. **(MVP) Presentation & Feel** — stays Standard rigor, but adds a **Player
>    Fantasy** section (the core fantasy's peak: animation, sound and VFX landing
>    at once) and **Tuning Knobs** for shake, slow-mo and camera push-in.
> 4. **(MVP / Alpha) Brief notes** — Attack System states "no motion inputs;
>    direction + button allowed" as a hard constraint. Presentation & Feel states
>    the ≤ 2.5 s Ultimate cinematic cap as a hard limit for its Tier 1 extension.

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Sim Core & State** — owns the fixed 60 Hz tick, the single flat state
   buffer, snapshot / restore, seeded RNG and the numeric model. Every sim
   system stores its state here; nothing else is foundational.

### Core Layer (depends on foundation)

1. **Input** — depends on: Sim Core & State
2. **Move Data Pipeline** — depends on: Sim Core & State
3. **Replay & Checksum** — depends on: Sim Core & State, Input, Move Data
   Pipeline (data-version hash in the header)
4. **LAN Netcode — input exchange half** — depends on: Sim Core & State, Input,
   Replay & Checksum. *(Priority Alpha; spiked in Tier −1.)*

### Feature Layer (depends on core)

1. **Arena** — depends on: Sim Core & State (walls, bounds; feeds Movement)
2. **Character Movement & State Machine** — depends on: Sim Core & State, Input,
   Move Data Pipeline, Arena
3. **Hit Detection & Damage** — depends on: Sim Core & State, Move Data
   Pipeline, Character Movement & State Machine
4. **Attack System** — depends on: Input, Move Data Pipeline, Character Movement
   & State Machine, Hit Detection & Damage *(cycle 1)*
5. **Defense** — depends on: Character Movement & State Machine, Hit Detection &
   Damage, Attack System *(cycles 3, 4)*
6. **SP, Skills & Ultimate** — depends on: Hit Detection & Damage, Defense
   *(cycle 2)*
7. **Projectiles** — depends on: Move Data Pipeline, Hit Detection & Damage
8. **Round & Match Flow (in-sim half)** — depends on: Sim Core & State, Hit
   Detection & Damage
9. **Operator Definitions** — depends on: Move Data Pipeline, Character Movement
   & State Machine, Attack System, SP Skills & Ultimate, Projectiles
10. **Opponent AI** — depends on: Input, Character Movement & State Machine,
    Attack System, Defense, SP Skills & Ultimate, Projectiles

### Presentation Layer (depends on features)

*Read the sim; never write to it (TD-SYSTEM-BOUNDARY). Consume sim events by
tick number so a future rollback cannot fire VFX or SFX twice.*

1. **Presentation & Feel** — depends on: Sim Core & State, Move Data Pipeline,
   Hit Detection & Damage, SP Skills & Ultimate
2. **Toon & Outline Rendering** — depends on: Presentation & Feel
3. **HUD** — depends on: Hit Detection & Damage, SP Skills & Ultimate, Round &
   Match Flow
4. **Menus & Select** — depends on: Input, Round & Match Flow (out-of-sim half),
   Operator Definitions
5. **Audio** — depends on: Hit Detection & Damage, SP Skills & Ultimate, Round &
   Match Flow

### Polish Layer (depends on everything)

1. **Settings** — depends on: Input, HUD, Menus & Select, Audio
2. **LAN Netcode — session half** (handshake, select sync, rematch) — depends
   on: Round & Match Flow, Menus & Select
3. **Training Mode** — depends on: Move Data Pipeline, Defense, Round & Match
   Flow, HUD, Menus & Select
4. **Operator Collection** — depends on: Operator Definitions, Menus & Select

**Bottlenecks** (an error here means rework across every layer above): Sim Core
& State, Move Data Pipeline, Hit Detection & Damage, Input.
**Leaves** (low risk, can be designed late): Operator Collection, Settings,
Training Mode, Audio, Toon & Outline Rendering.

### TD-SYSTEM-BOUNDARY notes (CONCERNS, 2026-11-01) — carry into each GDD

1. **One state buffer, one ordered pipeline (Sim Core GDD).** All sim state
   lives in Sim Core's flat buffer — SP and skill timers, Ultimate meter,
   projectile pools, round clock and wins, AI state and RNG, hit-event buffer,
   input-history ring. Feature systems add fields and keep no gameplay member
   variables. Replay checksums the whole buffer. Snapshot / restore belong to Sim
   Core (Replay and LAN only use them). Sim Core defines fixed phase *slots* that
   systems register into, so it never imports them. Proposed order: input words →
   AI writes its input word → command interpretation → movement & state → attack
   advance → projectiles → hit resolution → reactions applied → SP / skill /
   Ultimate updates → round checks → checksum.
   *Note 2026-11-09 (user decision in `design/gdd/sim-core.md` rule 10a):* a
   **defense slot** is added after attack advance and before projectiles (Defense
   writes the guard flag and throw-tech state there). This changes the order
   above and is **pending technical-director review** (sim-core OQ-7, constraint
   item 8); the text above is left as TD wrote it until that review.
2. **The numeric-model ADR is a hard prerequisite** for the Sim Core, Movement
   and Hit Detection GDDs.
3. **Owners:**
   - *Hit-stop counter* — per character, in the buffer; written by Hit
     Detection; Movement and Attack skip advancing while it is > 0. Never engine
     time scale.
   - *Cinematic freeze count* — one global field; written only by SP, Skills &
     Ultimate on an Ultimate hit; Sim Core's pipeline gates every phase on it;
     Presentation only reads it.
   - *Facing, pushbox, corner push-out, max player distance* — Movement (with
     Arena walls). Pushbox sizes are Move Data. **Camera never owns max
     distance.**
   - *Knockback and hitstun* — emitted in the hit-event record by Hit Detection,
     applied by Movement in the reactions phase.
   - *Input* — Input owns device sampling and 2P mapping (outside the sim) and
     one raw input word per player per tick plus a fixed history ring (inside).
     Only that word is recorded and sent. Attack System owns interpretation:
     direction + button commands, buffer windows, cancel windows, priority.
   - *Replay header* — seed, Operator picks, arena, move-data version hash (hash
     owned by Move Data, match setup by Round & Match Flow); Replay rejects a
     hash mismatch.
   - *AI and replay* — AI runs inside the sim; replays record human inputs and
     recompute AI. Decide explicitly in the AI GDD; recommended: still log the
     AI input word for desync debugging.
4. **Hit Detection is the main god-object risk.** One system through Tier −1,
   with its own Formulas section for damage and scaling; split damage scaling
   out if the rules exceed about one screen.
5. **Operator Definitions stay data** plus small hooks, never a class per
   Operator.
6. **Round & Match Flow and LAN each have an in-sim and an out-of-sim half** —
   draw the line in their GDDs (Menus & Select owns the screen-flow half).

### Project-wide constraint — Evidence-First Deterministic Integrity (user, 2026-11-09) — binding on Sim Core and every dependent gameplay system

Sim Core is the authoritative source of deterministic gameplay state. Every
design decision must preserve deterministic behaviour across machines and
supported execution environments. Every sim GDD states how it complies.

1. **No hidden mutable sim state** outside the one `PackedInt64Array`. Every
   value that can affect a future sim result is covered by snapshot, restore and
   checksum.
2. **No float arithmetic, wall-clock or `delta` access, engine-global random
   functions or engine-dependent hashing** inside sim logic.
3. **Deterministic numeric operations use the project-owned `SimMath`, `SimRng`
   and `SimHash`.** Scope (per ADR-0001 Implementation Guidelines): all
   division, rounding, ratios, box overlap, randomness and hashing go through
   them; plain `int` `+ − ×` and the typed integer built-ins ADR-0001 allows
   (`clampi`, `mini`, `maxi`, `absi`, `signi`) stay allowed. *(Interpretation
   confirmed by the user 2026-11-09 — apply it identically in every sim GDD; do
   not wrap ordinary integer arithmetic in helpers.)*
4. **Engine behaviour that affects sim correctness** (Godot 4.7.2) is a
   guarantee only when verified by the pinned docs (`docs/engine-reference/godot/`)
   or a reproducible headless test. Unverified behaviour is never treated as
   established.
5. **Label every claim** as *Verified*, *Proposed*, *Unverified assumption* or
   *Measured* (with the measurement).
6. **V4 (cross-CPU determinism) and V5 (≤ 0.25 ms tick incl. snapshot +
   checksum) stay explicit validation gates.** Neither is claimed satisfied
   without measurements.
7. **Every system integrating with Sim Core uses its documented phase slots and
   state/event contracts.** No system bypasses the sim pipeline.
8. **Any change that could affect determinism, rollback compatibility or replay
   compatibility** requires an explicit architecture review (`/architecture-review`
   or an ADR) and regression tests (replay checksum + unit) before it merges.

---

## Recommended Design Order

*Tier −1 is built from a prototype brief + ADRs (see Priority Tiers); the GDDs
below are drafted in parallel with it (decision 2026-11-01), with Formulas and
Tuning Knobs provisional until Tier −1 data exists. Independent systems at the
same layer can be designed in parallel.*

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 0 | Tier −1 prototype brief + numeric-model ADR + sim/view-split ADR | MVP | Foundation | technical-director, lead-programmer, game-designer | M |
| 1 | Sim Core & State | MVP | Foundation | lead-programmer, engine-programmer | M |
| 2 | Input | MVP | Core | gameplay-programmer, ux-designer | M |
| 3 | Move Data Pipeline | MVP | Core | tools-programmer, game-designer | M |
| 4 | Replay & Checksum | MVP | Core | lead-programmer | S |
| 5 | Arena | MVP | Feature | level-designer, game-designer | S |
| 6 | Character Movement & State Machine | MVP | Feature | game-designer, gameplay-programmer | M |
| 7 | Hit Detection & Damage | MVP | Feature | systems-designer, game-designer | L |
| 8 | Attack System *(design with 7 — cycle 1)* | MVP | Feature | game-designer, systems-designer | L |
| 9 | Defense | MVP | Feature | game-designer | L |
| 10 | Round & Match Flow | MVP | Feature | game-designer | M |
| 11 | SP, Skills & Ultimate | MVP | Feature | game-designer, systems-designer | L |
| 12 | Projectiles | MVP | Feature | game-designer | S |
| 13 | Operator Definitions | MVP | Feature | game-designer, systems-designer | M |
| 14 | Opponent AI | MVP | Feature | ai-programmer, game-designer | L |
| 15 | Presentation & Feel | MVP | Presentation | technical-artist, art-director | M |
| 16 | HUD (UX spec `design/ux/hud.md`) | MVP | Presentation | ux-designer | M |
| 17 | Menus & Select | MVP | Presentation | ux-designer | S |
| 18 | Audio | MVP | Presentation | audio-director, sound-designer | S |
| 19 | Toon & Outline Rendering (shader ADR) | MVP | Presentation | technical-artist | S |
| 20 | Settings | Alpha | Polish | ux-designer | S |
| 21 | LAN Netcode | Alpha | Core / Polish | network-programmer | M |
| 22 | Training Mode | Alpha | Polish | game-designer, ux-designer | S |
| 23 | Operator Collection | Full Vision | Polish | ux-designer, writer | S |

---

## Circular Dependencies

All four are resolved by Sim Core's fixed per-tick phase order, with systems
communicating through plain fields in the state buffer instead of calls.

- **Attack System ↔ Hit Detection & Damage** — attacks open hitboxes; hits drive
  cancels. Resolution: phase order attack advance → hit resolution → hit events
  consumed by next tick's command phase. Shared contract = the hit-event record
  (preallocated, fixed size, cleared each tick). Hit resolution is
  **symmetric**: gather all overlaps (both players and projectiles) against
  pre-resolution state, then apply — never P1 first. Design the two GDDs
  together.
- **SP, Skills & Ultimate ↔ Hit Detection & Damage** — SP charges from hits;
  skills modify damage and speed. Resolution: SP, Skills & Ultimate publishes
  modifiers as plain buffer fields that Hit Detection reads; Hit Detection only
  emits events. No code dependency from Hit Detection to SP.
- **Defense ↔ Attack System** — Throw is both. Resolution: Throw is a move type
  in Move Data, defined in the Defense GDD and registered with the Attack
  System; its throwbox is checked in Hit Detection, so "a strike beats a throw
  during its startup" falls out of frame data. Defense owns the joint throw-tech
  window state.
- **Defense ↔ Hit Detection & Damage** *(found by TD-SYSTEM-BOUNDARY)* — Hit
  Detection must know whether the defender is guarding. Resolution: Defense
  writes a guard flag in an earlier phase; Hit Detection reads the field.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Sim Core & State | Technical | Determinism silently broken (time scale, physics, global RNG, delta time, float drift between machines; Godot `Vector2/3` is 32-bit `real_t`) | Numeric-model ADR before combat code; per-tick checksum replay in CI from Tier −1; all gameplay counters are integers |
| Hit Detection & Damage | Design / Technical | God-object: overlap, damage, hitstun, knockback, hit-stop, combo, throwbox in one place | Own Formulas section; split damage scaling out if rules exceed ~one screen |
| LAN Netcode | Technical | Hamachi / Radmin latency 20–80 ms; broadcast discovery fails on virtual adapters; Windows Firewall prompt | One-week Tier −1 spike (2 PCs, UDP, Hamachi) → report + ADR; direct IP only; delay-based first, state ready for rollback |
| Round & Match Flow | Design | Amiya (Auto SP) hits once then kites to timeout in Ch'en vs Amiya | **Mandatory acceptance criterion** in the GDD (walls or no walls) **before** Amiya is built; timeout = higher HP% wins |
| SP, Skills & Ultimate | Design | Offensive SP snowballs; Defensive SP turtles; skill window becomes "run until it expires" | Counterplay floor + Throw beats Block; Pillar 2 design test (a); balance check after Tier 0 |
| Opponent AI | Scope / Design | "AI Normal that is fun to fight" is tuning, not just code (L) | Seeded, tick-delayed reactions; possible third fallback cut (open for creative-director) |
| Presentation & Feel | Scope | Animation volume — 1–3 days per animation for a newcomer; ~23 for Tier 0 | Rigid-part shared rig; shared reaction animations allowed (art bible §8); timebox per Operator |
| Input | Technical | Keyboard ghosting with two players on one keyboard | Gamepad support from Tier 0; separated default key clusters; input-test screen |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 23 |
| GDDs required (MVP) | 17 (+ HUD UX spec, + Toon shader ADR) |
| Design docs started | 2 (Sim Core & State, Draft; Character Movement, Draft 2026-11-10, not reviewed) |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 1/19 (+1 Draft) |
| Vertical Slice systems designed | n/a (tier not used; Tier −1 uses a prototype brief) |

---

## Next Steps

- [x] Review and approve this systems enumeration (user, 2026-11-01)
- [x] CD-SYSTEMS review of this index — CONCERNS, accepted 2026-11-01
- [x] Update concept MVP item 7 + fallback line + Next Steps (2026-11-01)
- [x] Finish `/art-bible` — all 9 sections, AD-ART-BIBLE REVISED 2026-11-01
- [ ] Tier −1: prototype brief + numeric-model ADR + sim/view-split ADR (`/architecture-decision`), then `/prototype`
- [ ] Tier 0: design MVP-tier systems in the order above (`/design-system [system-name]`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check technical-setup` when MVP systems are designed
