# Sim Core & State

> **Status**: Draft (stays Draft until ADR-0001 and ADR-0002 are Accepted)
> **Creative Director Review (CD-GDD-ALIGN)**: REVISED 2026-11-09 — CONCERNS resolved: character contact events made critical (`OBS_CAP` 8 → 7, I5); HUD reads Pillar 3 meters from state; Attack GDD flagged on freeze-input buffering
> **Author**: user + agents
> **Last Updated**: 2026-11-09
> **Last Verified**: 2026-11-09
> **Implements Pillar**: Foundation for all pillars (determinism makes Pillar 3's readable mastery and LAN play trustworthy)

## Summary

Sim Core & State is the fixed 60 Hz simulation at the heart of every fight: it
keeps all gameplay state as integers in one buffer and steps every combat
system in a fixed order, so the same inputs always produce exactly the same
fight. Players never see it; they feel it as fairness — frame data that can be
learned, replays that are exact, and LAN matches where both screens show the
same fight. Every other sim system stores its state here and runs in one of
its phase slots, which is why it is designed first. *(Draft until ADR-0001
and ADR-0002 are Accepted; cross-CPU determinism (V4) and the 0.25 ms tick
budget (V5) are not yet measured.)*

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

> **Binding constraint:** *Evidence-First Deterministic Integrity* (user,
> 2026-11-09), recorded in `design/gdd/systems-index.md` § TD-SYSTEM-BOUNDARY
> notes. Claims in this GDD are labelled **[Verified]**, **[Proposed]**,
> **[Unverified]** or **[Measured]** as that constraint requires.

Sim Core & State is the deterministic heart of the fight: a plain, engine-free
simulation that advances in fixed 60 Hz ticks and keeps **all** gameplay state
(positions, counters, timers, meters, projectile pools, the input-history ring,
the hit-event and presentation-event rings, and the PRNG state) as integers in
one flat `PackedInt64Array`. Each tick it runs a fixed, ordered list of
**phase slots** (input words → AI input word → command interpretation →
movement & state → attack advance → defense → projectiles → hit resolution →
reactions → SP / skill / Ultimate → round checks → checksum) into which every other sim
system registers. Sim Core imports none of them; systems talk only through
plain fields in the buffer. On top of that buffer it owns the operations the
rest of the game relies on: **step**, **snapshot / restore**, the **per-tick
checksum**, the **seeded PRNG** and the shared fixed-point math. **[Proposed]**
— the numeric model and the sim/view boundary come from ADR-0001 and ADR-0002,
both still Proposed.

Players never touch it directly; they feel what it makes possible. Because the
same inputs always produce the same buffer, bit for bit, a replay reproduces a
match exactly, a LAN opponent sees the same fight with only input words on the
wire, a desync is caught by comparing checksums rather than by players
arguing, and frame data is trustworthy enough to learn (Pillar 3, Readable
Mastery). Without it, every later system would carry its own state and timing,
and determinism, replays and LAN play would each have to be fixed system by
system. That is why it is bottleneck #1 in the systems index.

What it does **not** own: device sampling and the 2-player mapping (Input),
command interpretation (Attack System), stepping against wall time (the
`MatchRunner` node, ADR-0002), anything drawn or played (Presentation), and the
choice of snapshot storage for rollback (deferred to the LAN / rollback ADR).
Two promises are explicitly **not yet earned**: identical checksums across
different CPUs (**V4**, untested) and a tick within **≤ 0.25 ms** including
snapshot and checksum (**V5**, unmeasured). Both stay open validation gates
until the Tier −1 spike measures them.

## Player Fantasy

*Indirect — infrastructure.* Players never see Sim Core; they feel it as
**trust**. The same input on the same tick always produces the same outcome —
in training, across LAN and in replay — so a punish that works once works every
time, frame data is learnable, and mastery is real (Pillar 3, Readable Mastery:
depth that is *"học được và nhìn thấy được của cả hai bên"*). Fair LAN fights
and exact replays follow from that one property.

- **The player must never feel:** *"the game cheated me"* — and never *"it
  worked last time, why not now?"*
- Turned into tests in Acceptance Criteria: zero checksum mismatches across a
  LAN soak, and replay checksum equal to the live checksum at every tick.

*(Framing by creative-director, candidate A + B's never-line, 2026-11-09.)*

## Detailed Design

*Specialists consulted 2026-11-09: systems-designer (primary), gameplay-programmer
(feasibility), engine-programmer (engine integration; headless measurements on
4.7.2 **debug** build, 8,000-word test buffer, 2,000-iteration means). User
decisions this session: freeze stops the round clock; fixed const layout;
event overflow = drop + count + debug assert; checksum every tick; one pipeline
file, no Callables; buffer budget ≤ 2,048 words.*

### Core Rules

**Ownership and construction**

1. **The sim object.** The sim is a `RefCounted` (`Sim`) holding exactly two
   things: `buffer: PackedInt64Array` (all mutable state) and `data` (read-only
   integer move tables from the Move Data Pipeline, loaded before the match).
   In the scene tree only `MatchRunner` holds and steps it; outside it, the
   replay runner and tests under `tests/` may. **[Proposed — ADR-0002 rule 1]**
2. **Fixed layout.** `SimLayout` (owned by Sim Core) is a file of `const int`s
   only: one region `(owner, base, size)` per system, a per-player block
   (`P_BASE`, `P_STRIDE`, field offsets `PF_*`), pools (`*_BASE`, `*_CAP`,
   `*_STRIDE`) and rings. `TOTAL` is the end of the last region. Fields are
   read and written with plain integer arithmetic —
   `b[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_X] += vx` — no
   accessor wrappers (constraint item 3). **[Proposed]**
3. **Layout version.** `SimLayout.LAYOUT_VERSION` is bumped on **any** layout
   change (a new field shifts later offsets). It is stored in the buffer header
   and written into the replay header; a replay or snapshot with a different
   version is rejected, never reinterpreted. **A layout change requires a
   version bump**, enforced by a golden **fingerprint test** over every
   `SimLayout` constant (name, offset, size): changing any constant without
   bumping `LAYOUT_VERSION` and the fingerprint together fails the build.
   **[Proposed]**
4. **Budget and fixed size.** `TOTAL ≤ SIM_BUFFER_WORD_BUDGET` (2,048 words).
   The buffer is sized once at init and never resized, appended, inserted into
   or erased during a match. A layout unit test asserts: regions are
   contiguous, never overlap, every pool/ring `CAP × STRIDE` fits its region,
   and the last region ends exactly at `TOTAL ≤ budget`. **[Proposed]**
5. **Write ownership.** Each region is written only by its owner system; any
   system may read any region. Three exceptions, and no others:
   - `freeze_ticks` (Sim Core header) is **set** by SP, Skills & Ultimate and
     **decremented** only by Sim Core (rule 9).
   - The **Event Control region** and the **event ring** are written only by
     `SimEvents` (rule 18a), on behalf of whichever system emits.
   - **Block A's position copy** *(A3, user-approved 2026-11-09)*. Block A
     writes exactly **six words** of Movement's per-player blocks and nothing
     else of Movement's: for `p ∈ {0, 1}`, the indices
     `P_BASE + p × P_STRIDE + PF_PREV_X`, `… + PF_PREV_Y` and `… + PF_SNAP`,
     with `PF_PREV_X = 0`, `PF_PREV_Y = 1`, `PF_SNAP = 2` (the first three
     words of each per-player block, reserved in `SimLayout`; Movement places
     its own fields from offset 3). `prev_x` / `prev_y` are written only by
     block A; `snap` is cleared by block A and set by Movement (or a system the
     Movement GDD names). Block A **reads** Movement's `PF_X` / `PF_Y`, whose
     offsets the Movement GDD decides and `SimLayout` records (rule 2). **[Proposed — relative offsets 0–2 fixed
     here; `P_BASE` and `P_STRIDE` provisional]**

   **Ownership tests (strict).** `before := b.duplicate()`, run, compare.
   - *Per system step:* every index outside that system's own regions, the
     Event Control region and the event ring is unchanged.
   - *Block A* (run in isolation): the only indices that may change are
     `tick`, `obs_this_tick`, `crit_this_tick`, the six words above, and
     Input's history-ring slots for this tick (Input's own region). Every
     other index is unchanged.
   - *Frozen `step()`* (block A + freeze gate, block B skipped): the block-A
     whitelist plus `freeze_ticks` (the rule 9 decrement), and nothing else.
   - *Fixtures:* a normal tick, a frozen tick, an overflow tick, the Ended
     state (no index may change at all, rule 7a), tick 1, and the first tick
     after a `restore`. **[Proposed — event-region whitelist added after the
     systems-designer review 2026-11-09; block-A exception and fixtures added
     by A3]**
6. **Sim Core header region (8 words).** `tick`, `freeze_ticks`, `rng_s0`,
   `rng_s1`, `layout_version` + 3 spare. One shared PRNG stream; consumers draw
   in pipeline order. A system that needs a stream independent of the others
   keeps its own two PRNG words in its own region. `match_over` and the
   per-player KO flags live in the **Round & Match region**, which Round
   writes; Sim Core only reads `match_over` (States and Transitions).
   **[Proposed]**

   **6a. Event Control region (8 words, written only by `SimEvents`).**
   `event_seq`, `obs_this_tick`, `crit_this_tick`, `event_overflow_count`,
   `critical_overflow_count`, `sim_fault` + 2 spare. No stored head index: the
   write position is always `posmod(event_seq, EVENT_RING_ENTRIES)` (F4).
   **[Proposed]**

**The tick**

7. **`step(w0, w1)`** — the two players' input words for this tick are
   arguments. Words for future ticks (`T + D` under delay-based LAN) stay in
   `MatchRunner` / LAN and **never enter the buffer**: otherwise the checksum
   at tick T would include words the two peers receive at different times.
   **[Proposed — fixes an ambiguity in ADR-0002 rule 3.2]**

   **7a. Ended check first** *(A2, user-approved 2026-11-09)*. `step()` begins
   with `if match_over != 0:` (not `== 1`) and returns at once, **in every
   build, before block A**. An Ended sim changes no state: not `tick`, not the
   input ring, not the prev copy, not any event, counter or `event_seq`. It
   returns `SimHash.hash_words(buffer)` of the unchanged buffer, which equals
   the previous tick's checksum. The Debug assert comes after the check
   (EC-0). *Test:* step an Ended sim; buffer, counters, `event_seq` and
   checksum are unchanged (EC-25). **[Proposed]**
8. **Block A — always runs on a live or frozen tick (never when Ended):**
   1. `tick += 1`; `SimEvents` resets `obs_this_tick = 0` and
      `crit_this_tick = 0`. **Block A emits no events** (debug assert), so no
      event, critical or not, can be produced on a frozen tick.
   2. Per character: `prev_x = x`, `prev_y = y`, `snap = 0`. (Skipping this
      during a freeze would leave `prev ≠ curr` and make interpolation jitter.)
   3. **Input slot:** Input's `step` writes `w0`, `w1` into its history ring.
      Whether words received during a freeze count as buffered commands is the
      Attack System's call, not Sim Core's.
9. **Freeze gate.** If `freeze_ticks > 0`: `freeze_ticks -= 1` and skip block B
   entirely. Setting `freeze_ticks = N` on tick T therefore freezes ticks
   T+1 … T+N exactly (see Formulas). **The round clock is in block B, so it
   stops during a freeze** (user decision 2026-11-09). **[Proposed]**
10. **Block B — gated slots, fixed order:** AI writes its input word → command
    interpretation → movement & state → attack advance → **defense** →
    projectiles → hit resolution → reactions applied → SP / skill / Ultimate →
    round checks (clock, KO, timeout, `match_over`). The AI slot exists even if
    Opponent AI is cut (a no-op; systems-index Adjustment E). **[Proposed —
    TD-SYSTEM-BOUNDARY note 1, plus the defense slot]**

    **10a. Defense slot** *(user decision 2026-11-09)*. A dedicated slot owned
    by Defense, where Defense writes the **guard flag** and its **throw-tech
    window state** into its own region, before hit resolution reads them
    (systems-index Circular Dependencies: "Defense writes a guard flag in an
    earlier phase; Hit Detection reads the field").
    - *Position:* after **attack advance**, so Defense sees this tick's
      command, movement state and attack state (whether the character is
      mid-attack, in hitstun or in blockstun) before deciding whether it
      guards; and before **projectiles** and **hit resolution**, so both read
      a guard flag that is current for this tick. **[Proposed — the Defense
      GDD confirms the position or requests another; any change is again a
      pipeline change]**
    - *Pipeline change:* this differs from TD-SYSTEM-BOUNDARY note 1's
      proposed order, so it falls under constraint item 8: it needs the
      technical director's architecture review (the phase list in
      TD-SYSTEM-BOUNDARY note 1 and ADR-0002 must be amended) and a
      regression test. No sim code exists yet, so the regression test is a
      **golden slot-order test** created with the first `SimPipeline`: it
      fails if any slot is added, removed or reordered without updating this
      GDD.
11. **Block C — checksum every tick** (user decision): after block B (or after
    the freeze gate), `SimHash.hash_words(buffer)` over the whole buffer,
    returned to the caller. The checksum is **not stored in the buffer** (it
    would hash itself). Fallback if V5 fails: every N ticks, recorded as an
    Open Question, not adopted. **[Proposed]**
12. **Hit-stop is not a Sim Core gate.** It is a per-character counter in Hit
    Detection's region; Movement and Attack skip their own advance while it is
    > 0. Who decrements it is assigned in the Hit Detection GDD. **[Proposed —
    TD-SYSTEM-BOUNDARY note 3]**

**The pipeline**

13. **One pipeline file, no Callables** (user decision). `sim_pipeline.gd`
    (`SimPipeline`) is the composition root: it calls each system's
    `static func step(b: PackedInt64Array, data: SimData) -> void` directly, in
    the slot order of rules 8–10, with the freeze gate around block B; and each
    system's `static func init(b, data, setup)` in the same order. Sim Core's
    own code (`Sim`, `SimLayout`, `SimMath`, `SimRng`, `SimHash`) imports no
    system. Adding, removing or reordering a slot changes results for the same
    inputs, so it falls under constraint item 8 (architecture review +
    regression tests). **[Proposed]**
14. **Order inside a slot.** Characters P0 then P1; pools and rings by
    ascending index. **Exception:** hit resolution gathers every overlap
    (both players and all projectiles) against pre-resolution state, then
    writes hit records; reactions apply them in the next slot. Gather order
    affects only record order, never the outcome. **[Proposed — systems-index
    Circular Dependencies]**
15. **Sim systems hold no state.** Sim code is static functions and `const`s
    only. CI fails the build on any of these under `src/sim/`: class-scope
    `var` or `static var` (a `static var` lives for the whole process, outside
    snapshot and checksum, and survives between matches **[Verified, 4.x
    language semantics]**), `@onready`, `extends Node`, `Callable`, `signal`,
    `await`, `OS.is_debug_build`, the raw `%` operator **outside `SimMath`**
    (stricter than ADR-0001's "where an operand can be negative"), plus
    ADR-0001's forbidden-token list. **No call or side effect inside
    `assert(…)`**: an assert's argument is a pure comparison of values already
    computed, because a stripped assert must not change state (EC-35). Every
    state-changing check runs before any Debug-only report (EC-0).
    **[Proposed]**

    **15a. Modulo.** Two sanctioned forms, nothing else:
    - **`posmod(x, D)` where `D` is a named positive constant** (a `SimLayout`
      capacity such as `EVENT_RING_ENTRIES` or `INPUT_RING_TICKS`; the layout
      test asserts every such constant is > 0). Used for ring and slot
      indices. Any `int` dividend is allowed, including negative values.
      *Why it is deterministic:* `posmod(int, int)` is an integer-only
      built-in that returns `int`; for `D > 0` it returns the floor-mod
      result in `[0, D − 1]`, a pure function of its inputs with no float
      path. **[Measured 4.7.2 Debug, headless, 2026-11-09:** `posmod(-7, 3) =
      2`, `posmod(-1, 208) = 207`, `posmod(209, 208) = 1`,
      `posmod(INT64_MAX, 208) = 111`, `posmod(INT64_MIN, 208) = 96` (both
      checked by hand), return type `int`; with a negative divisor the result
      takes the divisor's sign (`posmod(7, -3) = -2`); with divisor 0 the
      engine prints an error, returns 0 and the calling function continues.
      Release builds: **[Unverified]**.**]**
    - **`SimMath.mod_floor(a, b)`** for every other case (variable or signed
      divisor). It guards `b == 0` in every build (EC-33), so no zero divisor
      reaches the engine. *(Observation, not a decision: the measured
      `posmod` semantics equal floor-mod for any non-zero divisor, so
      `mod_floor` may be implemented as the zero guard plus `posmod`.)*
    - **No invalid index reaches a buffer access:** a ring or slot index is
      always `BASE + posmod(x, D) × STRIDE + FIELD` with `0 ≤ FIELD < STRIDE`,
      so it lies inside its region; the layout self-test asserts
      `BASE + D × STRIDE ≤` the region's end for every ring and pool. The
      engine's own zero-divisor fallback is never relied on: `D` is a positive
      constant, and `mod_floor` guards 0 itself. **[Proposed]**
16. **Buffer access.** The buffer is reached only through the `b` parameter of
    the current call, never stored in a member or kept across calls, because
    restore may replace the reference with an independent copy (rule 21) and assignment aliases.
    **[Measured 4.7.2 — assignment and parameter passing alias; a restored
    reference makes any cached one stale]**
17. **No negative or out-of-range index.** Every index is `base + offset` with
    a non-negative offset; ring slots use `posmod(i, CAP)` with `CAP > 0`.
    Debug builds assert computed indices. **[Measured 4.7.2 debug: `b[-1]`
    silently writes the last element; an out-of-range write prints an error,
    skips the write and aborts the current function while the caller carries
    on. Release behaviour: Unverified — export templates are not installed]**

**Events**

18. **Presentation event ring** *(event design approved by the user
    2026-11-09 as Option A, provisional until the dependent GDDs confirm their
    payloads and invariants)*. Records of `EVENT_WORDS` = 6 ints
    `(tick, seq, type, a0, a1, a2)`; `EVENT_RING_ENTRIES` = 208 (F4), a Sim
    Core constant that no `MatchRunner` tunable can change. Type `0` is
    reserved as `NONE` (the ring starts zero-filled). Never cleared: each
    accepted record is written at `posmod(seq, 208)`, overwriting the oldest.
    Payload convention: where an event needs "who" plus an ID,
    `a0 = actor + 2 × id` (plain integer `+ ×`, constraint item 3; decoded only
    in presentation); variants (hit / block, final / continuing) are separate
    `type` values. **[Proposed; that 3 arguments suffice is Unverified until
    Hit Detection, Projectiles, SP and Round & Match list their payloads]**

    **18a. One emission path.** Every event goes through
    `SimEvents.emit(b, type, a0, a1, a2)`. Its class comes from the const table
    `EVENT_CLASS[type]` (observation / critical), never from the caller; debug
    builds range-check `type`. Only `SimEvents` writes the ring and the Event
    Control region (ownership test + CI grep). **[Proposed]**

    **18b. Accept rule (dynamic reservation, F5).** An observation event is
    accepted iff `obs_this_tick < OBS_CAP (7)` **and**
    `obs_this_tick + crit_this_tick < MAX_EVENTS_PER_TICK (16)`. A critical
    event is accepted iff `obs_this_tick + crit_this_tick < 16`. Critical
    events therefore always have ≥ 9 slots per tick, plus any slot observations
    leave unused. *(`OBS_CAP` lowered from 8 to 7 by the user on 2026-11-09,
    after CD-GDD-ALIGN, to make room for character contact events; MAX, ring
    and record layout unchanged.)* An accepted event gets the next consecutive `seq`.
    **[Proposed]**

    **18c. Critical classes and the bound of 9 per tick.** Critical:
    `ULTIMATE_ACTIVATE`, `ULTIMATE_HIT`, `KO`, `ROUND_END`, `ROUND_START`,
    `MATCH_END` (user decision 2026-11-09), and the **character contact**
    events `HIT`, `BLOCK`, `THROW_CONNECT` (user decision 2026-11-09, after
    CD-GDD-ALIGN: whether a strike hit or was blocked is the core readable
    signal of Pillar 3, so it must never be dropped). Projectile contact
    events stay observation events. The bound holds **only while these
    dependent-system invariants hold**, each with a debug assert in the owning
    system:
    - **I1:** at most one Ultimate activation is live per player, and Ultimate
      startup is ≥ 1 tick (concept: longer than Heavy), so a player's
      `ULTIMATE_ACTIVATE` and `ULTIMATE_HIT` never share a tick → ≤ 2.
      (SP, Skills & Ultimate)
    - **I2:** `ULTIMATE_HIT` is the **first** connect of one activation against
      a character, once per activation. Later hits of a multi-hit Ultimate, or
      an Ultimate hitting a projectile, are observation events.
      (Hit Detection; SP, Skills & Ultimate)
    - **I3:** `KO` is emitted only when a per-player KO flag (Round & Match
      region) flips 0 → 1; the flags reset on `ROUND_START`; KO detection runs
      once per tick, before any phase transition → ≤ 2. (Round & Match)
    - **I4:** `ROUND_END`, `ROUND_START` and `MATCH_END` are each emitted on
      entering that phase of the single Round & Match state machine → ≤ 1
      each. (Round & Match)
    - **I5:** each attacking character emits at most one character contact
      event (`HIT`, `BLOCK` or `THROW_CONNECT`) per tick: a player has one
      active move, and a move connects with a given defender at most once per
      tick. An Ultimate's first connect emits `ULTIMATE_HIT` **instead of**
      `HIT`, never both → ≤ 2. (Hit Detection; Defense for `THROW_CONNECT`)

    Bound: 2 (I1) + 2 (I5) + 2 (I3) + 1 + 1 + 1 (I4) = **9 ≤ 9** guaranteed
    slots. The true bound is 8, because `MATCH_END` and `ROUND_START` cannot
    share a tick; 9 is the conservative figure. Checked combinations: double
    KO by strike + projectile = 1 `HIT` + 2 `KO` + `ROUND_END` + `MATCH_END`
    = 5; Ultimate trade ending the match = 6 (the Ultimates' connects are
    `ULTIMATE_HIT`, not `HIT`, I5); draws give the same counts.
    **[Proposed — conditional on I1–I5; no dependent GDD exists yet]**

    **18d. Overflow behaviour (deterministic and observable; user decisions
    2026-11-09).**
    - **Observation drop** (anticipated: up to 17 observation events in one
      tick is legal): no `seq`; `event_overflow_count += 1`; **no debug
      assert**. Diagnostic: on each **confirmed** tick whose step raised
      `event_overflow_count`, `MatchRunner` (outside the sim) prints one
      aggregated debug warning, `tick T: n events dropped`. The same inputs
      always give the same warnings, and a re-simulated tick never warns
      twice.
    - **Critical overflow** (reachable only if I1–I5 are broken): the event is
      not written and gets no `seq`; `event_overflow_count += 1`,
      `critical_overflow_count += 1`, `sim_fault = 1`; **debug assert**. The
      match **continues**: Sim Core does not set `match_over` or change any
      gameplay state. Sim state stays correct; only a cue is lost. Affected
      replays are marked with an **event-integrity fault** (18e).
    - **Invalid emission** *(A4, user-approved 2026-11-09)*: `type = 0`
      (`NONE`), `type < 0`, `type ≥ EVENT_TYPE_COUNT`, or any emit while
      `tick == 0` (inside `init`). `SimEvents` validates the type **before**
      indexing `EVENT_CLASS` and checks `tick`, in every build. The event is
      **not written** to the ring and gets no `seq`; `sim_fault = 1`; **neither
      overflow counter changes** (this is not an overflow drop); Debug asserts
      last. The match continues.
      **Deliberate diagnostic limitation** *(user decision 2026-11-09)*: there
      is no invalid-emission counter. Several invalid emissions still leave
      only `sim_fault = 1`; their number is intentionally not observable from
      sim state (the Debug assert at each one is the only per-emission
      signal). The Event Control layout keeps its two spare words unused.
      This is a decision, not an omission.
    - **`sim_fault` means event-integrity fault:** it is set by a critical
      overflow or an invalid emission, and **never** by an ordinary
      observation drop. `event_overflow_count` counts events dropped by the
      accept rule (overflow); `critical_overflow_count` counts the critical
      ones among them. Lifetime, snapshot / restore, rollback and
      confirmed-timeline semantics are unchanged (18e, 18g).
    - Overwriting an already-accepted observation record to make room was
      rejected: it would break the sequence rules (F5). **[Proposed]**

    **18e. Fault and counter lifetime across init, snapshot, restore and
    rollback.**
    - `sim_fault`, `critical_overflow_count` and `event_overflow_count` are
      ordinary buffer words: snapshotted, restored and checksummed like all
      other state.
    - **Sticky until the next `init`:** no sim code ever writes `sim_fault = 0`
      or decreases either counter; only `init`'s zero-fill resets them. Within
      one timeline they never decrease.
    - **`restore`** sets them to the snapshot's values. Restoring to a tick
      before a fault is not a "clear": it returns to a timeline in which that
      fault never happened.
    - **Match-lifetime latch (outside the sim):** `MatchRunner` keeps
      `integrity_fault_confirmed`. It is set the first time a **confirmed**
      tick (18g) shows `sim_fault = 1`, and cleared only by a new match `init`
      (not by training reset, replay seek or rollback). It drives the replay's
      event-integrity flag. A fault seen only on a speculative tick that is
      later rolled back is logged as a speculative diagnostic and does not set
      the latch. Under delay-based play every stepped tick is confirmed.
    - The replay file field that carries the flag is owned by the Replay &
      Checksum GDD. **[Proposed]**

    **18f. Consumer contract (cursor, overwrite detection, rewind).**
    - A consumer's cursor `next_seq` lives **outside** the sim. It is read on
      the same thread as `step()` and only **between** steps.
    - `events_since(next_seq, out)` copies **by value** into a
      presentation-owned `out` (never a slice or reference into the ring,
      ADR-0002 rule 4) the surviving records with seq in
      `[maxi(next_seq, event_seq − 208), event_seq − 1]`, in seq order,
      checking that each slot's stored seq equals the expected seq. It returns
      the new cursor (`event_seq`), `lost` (F6), `event_overflow_count`,
      `critical_overflow_count` and `sim_fault`.
    - **Sufficiency:** at most 13 steps between two reads ⇒ `lost = 0` (F6
      proof). Per mode:
      - local / vs-AI `MatchRunner`: ≤ 4 steps per frame, drains every frame
        it stepped (proven);
      - delay-based LAN: **obligation on the LAN ADR**, ≤ 13 steps between
        drains including post-stall catch-up (the accumulator alone does not
        cap it);
      - viewing a replay: **obligation on Replay & Checksum**, drain every
        ≤ 13 steps;
      - replay verification with no presentation: no consumer;
      - replay **seek** and training reset: explicit **resync** mode;
      - rollback (future): ≤ 8 re-simulated + 4 catch-up + 1 = 13 steps,
        exactly at the bound.
    - **Rewind:** `event_seq < next_seq` after a `restore`. In live
      non-rollback modes → debug assert; in seek / reset → resync.
    - **`lost > 0`:** in live modes a contract breach → debug assert; in seek /
      reset expected.
    - **Resync is state recovery only.** The consumer redraws **current** state
      from `SimView` (round phase, index, wins, HP, freeze, `match_over`, live
      projectile slots), skips cues for the lost span, and processes the
      surviving records in order. **Event history is never reconstructed**:
      lost events are not re-fired, invented, inferred from state differences
      or reordered (user ruling 2026-11-09: no general ADR-0002 exception).
    - Match-flow decisions (leave the match, results screen) check persistent
      state such as `match_over` as a level, never events; events drive cues
      only. *This needs an ADR-0002 rule 5 clarification (Open Questions).*
      **[Proposed]**

    **18g. Speculative-event contract (requirements only; the mechanism
    belongs to the Rollback ADR).**
    - A tick is **confirmed** when every input word for it is authoritative
      (no predicted remote input). `confirmed_tick` is known only outside the
      sim (`MatchRunner` / LAN); the sim never stores or reads it.
    - An event with `tick ≤ confirmed_tick` is **confirmed**: that tick can
      never be rolled back. An event with `tick > confirmed_tick` is
      **speculative**.
    - Consumers must keep the two apart. Match flow, replay flags, statistics
      and anything persistent use confirmed events and confirmed-tick state
      only. Whether speculative events may drive provisional cues, and how
      such cues are cancelled, is the Rollback ADR's decision.
    - An event from a rolled-back timeline must **never** be presented or
      recorded as confirmed.
    - `seq` is timeline-local and **must not** identify equivalent events
      across a rollback. Equivalence is `(tick, type, a0, a1, a2)` plus the
      event's ordinal among identical keys in that tick; the Rollback ADR may
      refine this but must not fall back to `seq`.
    - **Until the Rollback ADR exists:** no `restore` happens in live play
      (delay-based only), so every event is confirmed when read; 18f's rewind
      assert enforces this. This GDD invents no reconciliation mechanism.
      **[Proposed — to be coordinated with the Rollback ADR]**
19. **Hit-event buffer is a different structure.** It lives in Hit Detection's
    region, is cleared at the start of hit resolution, is sized for the worst
    case by construction, and is consumed by reactions and later slots in the
    same tick. Presentation never reads it; it reads the event ring.
    **[Proposed]**

**Lifecycle operations**

20. **`init(seed, setup)`**: `buffer.resize(TOTAL)` then `buffer.fill(0)`
    (explicit — zero-fill on resize is Unverified); write `layout_version`;
    `SimRng.seed(b, RNG_SLOT, seed)` (splitmix64 expansion — **a function
    ADR-0001 does not yet define**); `SimPipeline.init_all(b, data, setup)`;
    `tick = 0`; return the tick-0 checksum. **[Proposed]**
21. **`snapshot()` / `restore(snap)` — contract only.**
    - `snapshot()` returns an independent copy, never an assignment.
    - **Trusted input only.** `restore` accepts snapshots produced by
      `snapshot()` in the current process and held in memory. Sim Core does
      **not** validate field contents. State supplied from outside (a file, the
      network) is untrusted: Replay & Checksum and LAN must validate it
      (size, layout version and per-field ranges) **before** calling `restore`
      (EC-28). **[Proposed]**
    - **Check order:** size `== TOTAL` first, then `layout_version` (reading
      the version word of a short snapshot would be an out-of-range read,
      which aborts the function in 4.7.2 Debug **[Measured]**). Either
      mismatch returns an error and leaves state unchanged. A same-size layout
      change that forgets to bump `LAYOUT_VERSION` is caught by the golden
      layout fingerprint test (rule 3, EC-27).
    - **Isolation** *(A1, user-approved 2026-11-09)*: `restore` installs an
      **independent copy** of the snapshot (`snap.duplicate()` or an element
      copy into the sim's own storage). The sim's buffer never aliases mutable
      snapshot storage, so stepping after a restore never changes the
      snapshot, and the same snapshot can be restored any number of times.
      The buffer reference may be replaced by that copy (rule 16).
      *Test:* restore S, step N ticks, assert S equals a copy taken before the
      restore; restore S again, assert the checksum equals S's original
      checksum and that stepping the same N ticks reproduces the same
      checksum sequence (EC-26).
    - Storage (a ring of
    `duplicate()`s vs element-copy into preallocated arrays) is **deferred to
    the LAN / rollback ADR**. Tier −1 takes no per-tick snapshot.
    **[Measured 4.7.2 debug, 8,000 words: `duplicate()` 0.07 µs, lazily
    copy-on-write — the 64 KB allocation + copy happen at the first write,
    1.25 µs total; element loop into a preallocated array 94.7 µs, no
    allocation; no native bulk copy into an existing `PackedInt64Array`
    exists (doctool method list)]**
22. **`SimView` accessor set (fixed here, per ADR-0002 rule 4).** Ints only;
    holds the `Sim`, never the array: `tick`, `pos_x_su`, `pos_y_su`,
    `prev_pos_x_su`, `prev_pos_y_su`, `snap`, `facing`, `state_id`,
    `anim_id`, `anim_tick`, `hitstop_ticks`, `freeze_ticks`, `hp`, `sp`,
    `ultimate`, `skill_ticks_left`, `round_clock_ticks`, `round_wins`,
    `match_over`, `event_seq`, `event_overflow_count`,
    `critical_overflow_count`, `sim_fault`, `events_since` (rule 18f).
    Dependent GDDs propose additions; each is an amendment to this list.
    **[Proposed]**
23. **Build parity.** Golden checksums must match on debug **and** release
    builds once export templates are installed. Until that test passes, LAN
    peers must run the same build type. **[Proposed; release behaviour
    Unverified]**

### States and Transitions

| From | Trigger | To | Notes |
|---|---|---|---|
| Uninitialised | `init(seed, setup)` | Ready (tick 0) | Tick-0 checksum returned |
| Ready / Running | `step(w0, w1)` | Running | Blocks A → (gate) B → C |
| Running | round-checks slot sets `match_over = 1` | Ended | Checksum still produced that tick |
| Ended | `step()` | Ended | Checked before block A in every build (rule 7a): no state, counter, `event_seq` or checksum change; Debug assert |
| Ready / Running / Ended | `restore(snap)`, valid | state of the snapshot | `match_over` comes from the snapshot |
| Any | `restore(snap)`, size or version mismatch | unchanged | Error returned |

*Frozen* is **data** (`freeze_ticks > 0`), not a lifecycle state: block A and
the checksum run, block B does not.

### Interactions with Other Systems

All provisional — no dependent GDD exists yet. Each dependent GDD must confirm
or amend its row (constraint item 7).

| System | Writes into the buffer | Reads / receives | Interface owner |
|---|---|---|---|
| `MatchRunner` (ADR-0002) | — (calls `init` / `step`, passes `w0, w1`) | checksum, `SimView` | ADR-0002 |
| Input | input-history ring (its region), input slot | `w0, w1` arguments | Input (word format, ring length); Sim Core (slot) |
| Replay & Checksum | — | seed, setup, `LAYOUT_VERSION`, per-tick checksum, snapshot/restore | Sim Core (API); Replay (file) |
| Move Data Pipeline | — (integer tables in `data`, outside the buffer) | — | Move Data |
| Opponent AI | AI input word, AI state / own PRNG words | whole buffer, read-only | AI |
| Attack System | command and move state | input ring, hit records | Attack |
| Character Movement & State Machine | x, y, prev_x/prev_y (block A copy is Sim Core's), facing, `snap`, knockback / hitstun applied in reactions | hit records, Arena bounds | Movement |
| Projectiles | projectile pool region | own region, hit records | Projectiles |
| Hit Detection & Damage | hit-event buffer, hit-stop, damage | boxes, positions, guard flag | Hit Detection |
| Defense | guard flag and throw-tech window state, written in the **defense slot** (rule 10a) | command, movement and attack state of this tick; hit records | Defense (via Hit Detection contract) |
| SP, Skills & Ultimate | meters, skill timers, **sets** `freeze_ticks` | hit records | SP |
| Round & Match Flow (in-sim half) | round clock, wins, phase, `match_over`, per-player KO flags, initial positions / HP via `init`; emits KO / ROUND_* / MATCH_END under I3–I4 | HP | Round & Match |
| Arena | wall bounds written at `init` | — | Arena |
| Presentation & Feel | **nothing** | `SimView` ints, `events_since` | Sim Core (accessor names) |
| LAN Netcode | — (remote words go to `MatchRunner`) | checksums, snapshot/restore | LAN ADR |

**Findings to carry into the ADRs (not changed here):** ADR-0001 needs a
`SimRng.seed()` with a defined expansion; ADR-0001 R7 / ADR-0002 rule 9 should
note that `duplicate()` is lazily copy-on-write (allocation at first write,
measured); ADR-0002 rule 3.2's "written for tick T + D" must mean outside the
buffer (rule 7); the replay header in TD-SYSTEM-BOUNDARY note 3 needs
`LAYOUT_VERSION`; the event-ring capacity is a Sim Core constant, not a
function of `MAX_CATCHUP_TICKS`. From the event design (rules 18–18g):
ADR-0002 rule 5 needs the 6-word record, the `NONE` type, event classes, the
accept rule, the fault latch, the cursor / rewind contract and the new
`events_since` signature, plus a clarification that match flow may check
persistent state as a level; the LAN ADR must cap steps between drains at 13;
the Rollback ADR must adopt rule 18g; the phase list in TD-SYSTEM-BOUNDARY note 1 and ADR-0002 must gain the defense slot (rule 10a, constraint item 8). These go to Open Questions and to
`/propagate-design-change` / `/architecture-decision` — never silently.

## Formulas

*Proposed by systems-designer 2026-11-09; arithmetic re-checked by the main
session; event values revised after the user-approved event audit and an
independent systems-designer review (2026-11-09). Sim formulas are integer-only; the cost models (F8, F9) are
**documentation**, not sim code, and are the only place a non-integer appears.*

### F1. Freeze set

The freeze_set formula is defined as:

`freeze_ticks' = maxi(freeze_ticks, clampi(N, 0, FREEZE_TICKS_MAX))`

applied by SP, Skills & Ultimate (in block B) for each freeze request.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| N | int | 0–150 | data file (Ultimate move data) | Requested freeze length in ticks |
| FREEZE_TICKS_MAX | int | 150 | constant | Cinematic hard cap, 2.5 s (concept / CD note 4) — **provisional, user-decided 2026-11-09** |
| freeze_ticks | int | 0–150 | calculated (header) | Ticks still frozen |

**Output Range:** 0–150. Invalid `N` (`< 0` or `> 150`) is **clamped in Debug
and Release alike**, and Debug additionally asserts whenever a clamp occurs;
the assert never changes state, so identical inputs give identical sim results
on both build types (user decision 2026-11-09). `N = 0` is a no-op.
**Order independence:** `maxi` gives the same result whether P0's or P1's
Ultimate is written first (simultaneous Ultimates on one tick).
**No nested freeze:** when block B runs, `freeze_ticks` is always 0 (the gate
let it through), and SP's slot is in block B, so nothing can raise a freeze
while one is running. The only other writer is `restore`. **[Verified — follows
from Core Rules 9–10]**
**Example:** N = 120 set on tick T = 1,000 → frozen ticks 1,001–1,120; tick
1,121 is live. **[Proposed]**

### F2. Frozen-tick sequence (off-by-one check)

The frozen_ticks formula is defined as:

`frozen(t) = (freeze_ticks at the gate of tick t) > 0`, giving frozen set `{T+1 … T+N}` for a freeze of N set on tick T.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| T | int | ≥ 1 | calculated | Tick whose block B set the freeze |
| N | int | 0–150 | calculated (F1 output) | Freeze length written |
| t | int | ≥ 1 | calculated | Tick being stepped |

| Tick | Gate sees → leaves | Block B | Round clock | Hit-stop |
|---|---|---|---|---|
| T | 0 → 0 | runs; SP sets N; round checks run after SP | −1 | advances |
| T+1 | N → N−1 | skipped | held | held |
| T+k (1 ≤ k ≤ N) | N−k+1 → N−k | skipped | held | held |
| T+N | 1 → 0 | skipped | held | held |
| T+N+1 | 0 → 0 | runs | −1 | advances |

**Output Range:** exactly N frozen ticks; never N−1 or N+1.
**Chained freezes:** the earliest a new freeze can start is the tick after
T+N+1's block B sets it, so two freezes are always separated by at least one
live tick.
**Consequences for dependents:**
- **Hit-stop pauses during a freeze**, because its decrement must sit in a
  block-B slot. Total pause after a hit = N + remaining hit-stop. The Hit
  Detection GDD must not decrement hit-stop in block A.
- **A KO caused by the Ultimate hit is detected on tick T**, before the
  cinematic plays (round checks follow SP on T). The Round & Match Flow GDD
  decides how the KO is presented.

**Example:** N = 3 on T = 10 → ticks 11, 12, 13 frozen (gate 3→2, 2→1, 1→0);
tick 14 live. **[Proposed]**

The round_wall_ticks formula is defined as:

`round_wall_ticks = clock_ticks_used + Σ N_i`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| clock_ticks_used | int | 0–5,940 | calculated | Live ticks the round clock consumed |
| N_i | int | 0–150 | calculated (F1) | Each freeze in the round |

**Output Range:** 0 to 5,940 + 150 × (freezes per round); the freeze count is
bounded by Ultimate gauge gain (SP GDD).
**Example:** timeout round with 3 Ultimates of 120 ticks → 5,940 + 360 = 6,300
ticks (105 s of wall time). **[Proposed]**

### F3. Buffer word budget

The buffer_total formula is defined as:

`TOTAL = Σ region_size ≤ SIM_BUFFER_WORD_BUDGET`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| region_size | int | ≥ 1 | constant (`SimLayout`) | Words in one region |
| SIM_BUFFER_WORD_BUDGET | int | 2,048 | constant | Hard limit (user decision 2026-11-09); layout test fails above it |

Tier 0 estimate (region sizes are **estimates** until each dependent GDD fixes
its fields):

| Region | Words | Basis |
|---|---|---|
| Sim Core header | 8 | 5 named fields (rule 6) + 3 spare (**exact**) |
| Event Control (`SimEvents`) | 8 | 6 named fields (rule 6a) + 2 spare (**exact**) |
| Per-player blocks, `P_STRIDE` 64 × 2 | 128 | Movement ~16, Attack ~12, Hit ~8, Defense ~6, SP ~8 ≈ 50 used + spare |
| Input history ring, 2 × `INPUT_RING_TICKS` 32 | 64 | F10 — **provisional 32, user-decided 2026-11-09; Attack GDD may revise** |
| Projectile pool, `PROJ_CAP` 4 × `PROJ_STRIDE` 16 | 64 | 2 per player at Tier 0 — assumption |
| Hit-event buffer, (2 + `PROJ_CAP`) × 8 | 48 | Every character and projectile hits once |
| Opponent AI | 32 | Includes its own 2 PRNG words |
| Round & Match | 16 | Clock, wins, phase, `match_over`, 2 KO flags (~7 used) |
| Arena | 8 | Wall bounds |
| **Subtotal (non-event)** | **376** | |
| Event ring, `EVENT_RING_ENTRIES` 208 × `EVENT_WORDS` 6 | 1,248 | F4 (**exact**) |
| **TOTAL** | **1,624** | **Margin 424 words (20.7 %)** |

Arithmetic: 8 + 8 + 128 + 64 + 64 + 48 + 32 + 16 + 8 = 376; 376 + 1,248 =
1,624; 2,048 − 1,624 = 424; 424 / 2,048 = 20.7 %. **[Verified arithmetic]**
The two header regions and the ring are exact; every other row is an
**[Unverified] estimate** until its owning GDD fixes its fields.
**Output Range:** 1,624 estimated; 2,048 hard maximum.
**Why the ring is not sized for the full worst case:** the conservative worst
case per tick is 17 observation + 9 critical = 26 events, and
26 × 13 × 6 = 2,028 words for the ring alone (2,404 total, over budget). The
user-approved 16 × 6 design (Option A) instead guarantees critical events by
reservation (F5) and drops only observation events, deterministically and
counted. Changing the budget or the ×13 multiplier requires the user's
approval. **[Proposed]**
**Example:** adding a 2nd projectile per player (`PROJ_CAP` 8) adds 64 + 32 =
96 words → 1,720, margin 328.

### F4. Event ring capacity and slot

The event_ring_capacity formula is defined as:

`EVENT_RING_ENTRIES = MAX_EVENTS_PER_TICK × (CATCHUP_RESERVE + ROLLBACK_WINDOW_TICKS + 1)`, asserted in the layout test.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| MAX_EVENTS_PER_TICK | int | 16 | constant | Accepted events per tick: `OBS_CAP` 7 + 9 guaranteed for critical (user decisions 2026-11-09, provisional) |
| CATCHUP_RESERVE | int | 4 | constant (Sim Core's own copy) | Equals ADR-0002 `MAX_CATCHUP_TICKS` today; a layout test asserts `MatchRunner.MAX_CATCHUP_TICKS ≤ CATCHUP_RESERVE`, so raising the runner's value fails a test instead of resizing the buffer |
| ROLLBACK_WINDOW_TICKS | int | 8 | constant | Reserved by ADR-0002 |
| EVENT_WORDS | int | 6 | constant | `(tick, seq, type, a0, a1, a2)` |

**Output Range:** 16 × (4 + 8 + 1) = **208 entries**; 208 × 6 = **1,248
words**. Independent of every `MatchRunner` tunable. The `+ 1` is the tick
being stepped, 4 is the local catch-up reserve, 8 is the reserved rollback
window. *(An earlier draft said 156 = 12 × 13, from `MAX_EVENTS_PER_TICK` 12;
corrected everywhere 2026-11-09.)* **[Verified arithmetic; values Proposed]**

The event_slot formula is defined as:

`slot = EVT_BASE + posmod(seq, EVENT_RING_ENTRIES) × EVENT_WORDS`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| seq | int | 0 – 2⁶³−1 | calculated | `event_seq` before increment |
| EVT_BASE | int | layout | constant | First word of the ring |

**Output Range:** `EVT_BASE` to `EVT_BASE + 1,242` (207 × 6, the first word of
the last record). There is no stored head index; the write position is always
`posmod(event_seq, 208)`.
**Example:** seq 500 → 500 − 2 × 208 = 84 → `EVT_BASE + 504`. **[Proposed]**

### F5. Emit gate (overflow is deterministic and observable)

The emit_accept formula is defined as:

`accept_obs  = (obs_this_tick < OBS_CAP) and (obs_this_tick + crit_this_tick < MAX_EVENTS_PER_TICK)`

`accept_crit = (obs_this_tick + crit_this_tick < MAX_EVENTS_PER_TICK)`

If accepted: write the record at F4's slot with the current `event_seq`, then
`event_seq += 1` and the class counter `+= 1`. Otherwise **drop**:
`event_overflow_count += 1`; for a critical event also
`critical_overflow_count += 1`, `sim_fault = 1` and a debug assert. An
observation drop does **not** assert (rule 18d).

**Guarantee:** observations never take more than `OBS_CAP` = 7 slots, so a
critical event finds a free slot whenever fewer than 9 critical events were
accepted this tick. With the I1–I5 bound of 9 (rule 18c), a critical event is
never dropped. **[Verified from the formula, given I1–I5; I1–I5 Proposed]**

**Sequence semantics (user decision 2026-11-09):**
- An **accepted** event gets the next consecutive `seq` (no holes are ever
  created at emission).
- A **dropped** event receives **no** `seq`; it is visible only through
  `event_overflow_count`, which increments for every dropped event, is
  checksummed, and is readable through `SimView`.
- An **overwritten** stored event (ring wrap) **keeps its original `seq`**; it
  is simply no longer in the ring.
- Therefore, when a consumer expecting `next_seq` finds that the oldest
  surviving record has `seq > next_seq`, the gap `oldest_seq − next_seq` is
  **exactly the number of records lost to ring wrap** (F6) — never drops.
  Drops never create gaps. After a `restore`, `event_seq` rewinds with the
  snapshot; reconciling a consumer watermark that is ahead of it belongs to
  the rollback ADR.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| obs_this_tick | int | 0–7 | calculated (Event Control; reset in block A) | Observation events accepted this tick |
| crit_this_tick | int | 0–16 | calculated (Event Control; reset in block A) | Critical events accepted this tick |
| OBS_CAP | int | 7 | constant | Observation ceiling per tick (user decision 2026-11-09, was 8) |
| MAX_EVENTS_PER_TICK | int | 16 | constant | Total accepted per tick |
| event_overflow_count | int | ≥ 0 | calculated (Event Control) | Events dropped by the accept rule since `init` (timeline-local, rule 18e); invalid emissions are not counted (18d) |
| critical_overflow_count | int | ≥ 0 | calculated (Event Control) | Critical events dropped by the accept rule since `init`; 0 while I1–I5 hold |
| sim_fault | int | 0–1 | calculated (Event Control) | Event-integrity fault: critical overflow or invalid emission; sticky until `init` (rules 18d, 18e) |

**Output Range:** boolean. Deterministic: the same inputs accept and drop the
same events in the same emission order on every machine; all counters are in
the buffer, checksummed and readable through `SimView`.
**Example:** a tick emits, in pipeline order, 11 observation and 3 critical
events → the first 7 observations are accepted, 4 observations dropped
(`event_overflow_count` +4, one aggregated debug warning), all 3 critical
accepted; 10 records written, `seq` advances by 10. **[Proposed]**

### F6. Lost records (consumer side)

The lost_records formula is defined as:

`lost = maxi(0, event_seq − EVENT_RING_ENTRIES − next_seq)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| event_seq | int | ≥ 0 | calculated (header) | Total accepted events |
| next_seq | int | 0 – event_seq | calculated (consumer watermark) | First seq not yet presented |

**Output Range:** 0 to event_seq. The ring holds exactly the 208 seqs
`[event_seq − 208, event_seq − 1]`; anything older was overwritten.
`events_since` reports `lost` alongside the records.
**Drain bound (proof):** after a read, `next_seq = E0`. Each step accepts at
most 16 events, so after k steps `E1 ≤ E0 + 16k` and
`lost ≤ maxi(0, 16k − 208)`, which is 0 iff `k ≤ 13`. At k = 13 with 16 events
every tick, the last record written is seq E0 + 207, in the slot just before
E0's, so E0 survives; at k = 14 up to 16 records are lost. Under a rollback
the count starts from the restored `event_seq`, so 8 re-simulated + 4
catch-up + 1 = 13 steps also fit, with zero margin. **[Verified arithmetic]**
**Example:** event_seq 500, next_seq 250 → 500 − 208 − 250 = 42 lost. Local
catch-up emits at most 4 × 16 = 64 per frame (< 208) → `lost = 0`.
**[Proposed]**

### F7. Seq overflow horizon

The seq_horizon formula is defined as:

`seq_horizon_s = INT64_MAX / (MAX_EVENTS_PER_TICK × TICKS_PER_SECOND)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| INT64_MAX | int | 9.22 × 10¹⁸ | constant | GDScript `int` maximum |
| TICKS_PER_SECOND | int | 60 | constant | Sim rate |

**Output Range:** 9.22 × 10¹⁸ / (16 × 60 = 960) ≈ 9.6 × 10¹⁵ s ≈ **3.0 × 10⁸
years** of continuous worst-case play. **[Verified arithmetic]**

### F8. Checksum cost model (model ≠ measurement)

The hash_cost formula is defined as:

`cost_hash ≈ k_hash × TOTAL`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| k_hash | float (documentation only) | 11.6 ns/word | **Measured** single point: 92.7 µs / 8,000 words, `for w in buf`, 4.7.2 **debug** build, dev PC, 2,000-iteration mean (engine-programmer, 2026-11-09) | Per-word hash cost |
| TOTAL | int | 1,624–2,048 | calculated (F3) | Buffer words |

**Output Range:** 18.8 µs (1,624 words) – 23.8 µs (2,048 words), i.e. 7.5–9.5 %
of the 0.25 ms tick.
**Label:** the 92.7 µs point is **[Measured]**; every number derived from it
for other sizes is **[Unverified extrapolation]** (linear scaling assumed from
one point; debug build; one machine). Release builds and other CPUs are
unmeasured.
**Example:** 1,624 × 11.6 ns = 18.8 µs.

### F9. Tick cost model (no budget claimed)

The tick_cost formula is defined as:

`cost_tick = cost_pipeline + cost_hash (+ cost_snapshot once rollback exists)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| cost_pipeline | float (doc) | **unknown** | not measured | All block-A/B slot work |
| cost_hash | float (doc) | ~19–24 µs | F8 (Unverified extrapolation) | Checksum |
| cost_snapshot | float (doc) | element copy ≈ 11.8 ns/word × 2,048 ≈ 24.2 µs **[Unverified extrapolation]**; `duplicate()` 1.25 µs at 8,000 words **[Measured]**, other sizes **[Unverified]** | Rollback ADR | Per-tick snapshot, 0 in Tier −1 |

**Output Range:** not computable — `cost_pipeline` is unknown. A rollback of 8
re-simulated ticks costs 8 × `cost_tick`.
**The ≤ 0.25 ms budget is NOT claimed met.** V5 (Tier −1 spike, real sim, with
release build once templates exist) is the gate. **[Unverified]**

### F10. Input history ring slot

The input_slot formula is defined as:

`slot = IN_BASE + p × INPUT_RING_TICKS + posmod(tick, INPUT_RING_TICKS)`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| p | int | 0–1 | calculated | Player index |
| tick | int | ≥ 1 | calculated | Current tick (written in block A) |
| INPUT_RING_TICKS | int | 32 | constant | Ring length — **provisional, user-decided 2026-11-09; the Attack GDD owns the final value and may revise it** |

**Output Range:** `IN_BASE` to `IN_BASE + 63`. Holds the current tick plus 31
ticks of lookback (~0.52 s); a lookback ≥ 32 is a debug assert.
**Example:** tick 100, p = 1 → `IN_BASE + 32 + 4`. **[Proposed]**

### F11. Integer overflow bounds

GDScript `int` is 64-bit and **wraps silently** on overflow [Verified —
ADR-0001, tested 4.7.2].

| Quantity | Worst case | Headroom vs 9.22 × 10¹⁸ |
|---|---|---|
| `tick` | < 10⁵ per match (3 rounds × ~6,300 + transitions; more rounds after draws is Round & Match's call) | ~10¹⁴ × |
| `event_seq` | ≤ 16 × tick ≈ 1.6 × 10⁶ | ~10¹² × |
| `event_overflow_count`, `critical_overflow_count` | ≤ emit calls per tick (conservative 26) × tick ≈ 2.6 × 10⁶ | ~10¹² × |
| `freeze_ticks` | ≤ 150 | trivial |
| su position × permille | 10⁵ × 10⁴ = 10⁹ (ADR-0001 R4) | ~10¹⁰ × |
| PRNG / hash | wrap on multiply **by design** — deterministic, intended | n/a **[Verified — ADR-0001 rule 8]** |

No counter in Sim Core can overflow in any realistic match. **[Verified
arithmetic]**

## Edge Cases

*Drafted 2026-11-09 against the user-approved event design (rules 18–18g, F3–F7);
nothing here changes the layout, accept rule, sequence semantics, ring
multiplier or budget. Missed-case review by systems-designer (cases marked †).*

**Format.** Each case: **If** condition → result, then *Initial* · *Sequence* ·
*Expected* · *Debug* · *Release* · *Invariant / test* · *Status*.

**Status key.**
- **Guaranteed** — follows from this GDD's rules and formulas alone; needs only
  the named test to confirm the implementation.
- **Depends on X** — correct only if a future GDD or ADR (X) upholds the stated
  obligation.

**Cross-build rule used throughout (EC-0).** **Correctness never depends on
whether `assert()` aborts execution.** Every check whose result changes sim
state (range checks, clamps, accept/drop decisions, the Ended check, the
zero-divisor guard) runs in **every** build; only the *report* (assert,
warning) is Debug-only, and it is the **last** statement after all state
writes. Reason: in 4.7.2 Debug an
out-of-range write aborts the current function **[Measured]**; whether a
failed `assert()` does the same is **[Unverified]**. If it does and an assert
precedes a write, Debug and Release diverge. *Test:* headless test of a failed
`assert()` in a Debug build (does the caller continue? is the function
aborted?) before the first sim assert is written; a CI grep for `assert(` not
followed only by `return`/end-of-function in `src/sim/` is the guard.
**Status:** Guaranteed as a rule; the assert behaviour itself is Unverified.

### Event ring and consumers

**EC-1. If exactly 208 events have been accepted since `init`**: every record
is still in the ring; nothing is overwritten.
- *Initial:* after `init`, `event_seq = 0`, ring zero-filled.
- *Sequence:* ≥ 13 ticks (max 16 accepted per tick) bring `event_seq` to 208;
  a consumer with `next_seq = 0` reads.
- *Expected:* `lost = maxi(0, 208 − 208 − 0) = 0`; 208 records, seq 0–207,
  slots 0–207; returned cursor 208.
- *Debug / Release:* no assert; identical (pure integer arithmetic).
- *Test:* unit — emit 208 events through `SimEvents`, read from cursor 0.
- *Status:* **Guaranteed** (F4, F6).

**EC-2. If the 209th event is accepted**: it overwrites seq 0.
- *Initial:* `event_seq = 208`, consumer `next_seq = 0`.
- *Sequence:* one more accepted event (seq 208 → slot `posmod(208, 208) = 0`).
- *Expected:* `lost = 209 − 208 − 0 = 1`; the read returns seq 1–208 (208
  records); seq 0 is gone and is **not** reconstructed. The overwritten record
  kept seq 0 until it was replaced (F5 semantics).
- *Debug:* the sim does not assert (wrap is normal). A **live-mode** consumer
  asserts on `lost > 0` (contract breach, 18f); a seek/reset consumer does not.
- *Release:* identical sim state; the consumer skips cues for seq 0 without
  asserting.
- *Test:* unit — EC-1 + one emit; assert `lost == 1` and first returned seq 1.
- *Status:* **Guaranteed**.

**EC-3. If a consumer reads after exactly 13 steps at full rate**: nothing is lost.
- *Initial:* consumer just read, `next_seq = E0`.
- *Sequence:* 13 steps, each accepting 16 events → `event_seq = E0 + 208`.
- *Expected:* `lost = 0`; 208 records E0 … E0 + 207. E0 sits in the slot after
  the last write (F6 proof).
- *Debug / Release:* no assert; identical.
- *Test:* unit — synthetic 16-per-tick emitter, 13 steps, read.
- *Status:* **Guaranteed** for the arithmetic. **Whether every consumer
  actually reads within 13 steps** depends on the mode — MatchRunner local /
  vs-AI: Guaranteed (≤ 4 per frame, ADR-0002); **delay-based LAN: Depends on
  the LAN ADR** (13-step drain obligation, Unverified); **replay viewing:
  Depends on the Replay & Checksum GDD**; rollback: Depends on the Rollback
  ADR (13 steps exactly, zero margin).

**EC-4. If a consumer reads after 14 steps at full rate**: 16 records are lost.
- *Sequence:* 14 × 16 = 224 accepted since the last read.
- *Expected:* `lost = 224 − 208 = 16`; returned seq E0 + 16 … E0 + 223.
- *Debug:* live-mode consumer asserts (contract breach); seek/reset does not.
- *Release:* identical sim state; consumer resyncs current state from
  `SimView` (18f) and skips the 16 lost cues; nothing is re-fired or inferred.
- *Test:* unit — as EC-3 with 14 steps; integration — MatchRunner with a fake
  clock forcing 14 steps between drains must trip the assert.
- *Status:* **Guaranteed** (detection and resync rule); preventing it in LAN /
  replay viewing **Depends on** those owners.

**EC-5. If a consumer reads before 208 events exist** (early match):
`event_seq − 208` is negative; the read range is `[next_seq, event_seq − 1]`
and `lost = 0` via `maxi`. Unwritten (zero) slots are never read, because only
seq `< event_seq` is returned. *Debug / Release:* no assert; identical.
*Test:* unit with `event_seq` 0, 1 and 207. **Guaranteed**.

### Overflow

**EC-6. If an 8th observation event is emitted in one tick**: it is dropped.
- *Initial:* `obs_this_tick = 7`, any `crit_this_tick ≤ 9`.
- *Expected:* not written, no seq; `event_overflow_count += 1`; later
  critical events in the same tick are still accepted (`obs + crit < 16`).
  One aggregated warning `tick T: n events dropped` is printed by MatchRunner
  for that tick only once it is **confirmed**.
- *Debug:* no assert (anticipated drop; user decision). *Release:* identical
  state; no warning printed (warning is Debug-only output).
- *Test:* unit — 10 observation + 2 critical in one tick: 7 obs + 2 crit
  accepted, `event_overflow_count == 3`.
- *Status:* **Guaranteed**.

**EC-7. If more critical events arrive than the free slots in a tick**
(reachable only if I1–I5 are broken): the excess critical event is dropped,
loudly.
- *Initial:* e.g. `obs_this_tick = 7`, `crit_this_tick = 9`.
- *Sequence:* a 10th critical emit.
- *Expected:* not written, no seq; `event_overflow_count += 1`,
  `critical_overflow_count += 1`, `sim_fault = 1`. The match **continues**;
  Sim Core does not touch `match_over` or any gameplay state (fault policy a).
  Once a confirmed tick shows `sim_fault = 1`, MatchRunner sets
  `integrity_fault_confirmed` and the replay is flagged.
- *Debug:* asserts (after the writes, EC-0). *Release:* identical state, no
  assert.
- *Test:* unit — drive `SimEvents.emit` directly past the bound; integration
  (future) — each owner's I1–I5 assert test.
- *Status:* the overflow **behaviour** is **Guaranteed**; that it is
  **unreachable Depends on I1–I5** (SP, Skills & Ultimate; Hit Detection;
  Round & Match — all **[Proposed]**, no GDD yet).

**EC-8. If critical and observation events interleave in different orders
within a tick**: the accepted set does not depend on the interleaving.
- *Reasoning:* while I1–I5 hold, `crit ≤ 9`. An observation is accepted iff
  `obs < 7` and `obs + crit < 16`; with `obs ≤ 6` and `crit ≤ 9` the second
  test always passes, so exactly **the first 7 observations in emission
  order** are accepted. A critical event is accepted iff `obs + crit < 16`;
  with `obs ≤ 7` and at most 8 critical already accepted, `obs + crit ≤ 15`,
  so **every critical event** is accepted. Record order (and therefore seq order) follows the
  fixed pipeline order (rule 14), which is identical on every machine.
- *Debug / Release:* no assert; identical.
- *Test:* property test — random interleavings of ≤ 9 critical and ≤ 17
  observation emits give the same accepted set.
- *Status:* **Guaranteed given I1–I5** (I1–I5 **[Proposed]**).

### Simultaneous critical events

**EC-9. If both players are KO'd on the same tick** (strike + projectile,
or any pair of hits): Round's checks emit `KO` P0, then `KO` P1 (fixed P0→P1
order, rule 14), then `ROUND_END` (result draw, reason double KO), then
`MATCH_END` if Round & Match's rules decide the match on a double KO.
- *Count:* 1 `HIT` (the strike; the projectile hit is an observation event)
  + 2 `KO` + `ROUND_END` + `MATCH_END` = 5 critical ≤ 9.
- *Debug / Release:* no assert; identical.
- *Test:* integration (Round & Match) — scripted double KO; check record order
  and counts.
- *Status:* event counts **Guaranteed given I3–I4**; who wins a double-KO
  round or match **Depends on the Round & Match GDD**.

**EC-10. If both Ultimates hit each other on the same tick and both KO**
(Ultimate trade, final round): hit resolution emits `ULTIMATE_HIT` P0 then P1
(gather order, rule 14); SP sets `freeze_ticks = maxi(N0, N1)` (F1, order
independent); round checks emit `KO` ×2, `ROUND_END`, `MATCH_END`.
- *Count:* 2 `ULTIMATE_HIT` (no `HIT`, I5) + 2 `KO` + 1 + 1 = 6 ≤ 9.
- *Expected extra:* `match_over = 1` on tick T, so the sim enters **Ended**
  with `freeze_ticks > 0`. Ended `step()` is a no-op, so `freeze_ticks` never
  counts down. Presentation plays the cinematic on its own clock (ADR-0002
  rule 8) and **must not wait for `freeze_ticks` to reach 0 after
  `match_over`**.
- *Debug / Release:* no assert; identical.
- *Test:* integration — scripted trade; Ended-state test that `step()` leaves
  the buffer (and checksum) unchanged.
- *Status:* counts **Guaranteed given I1–I5**; cinematic-after-match-end
  behaviour **Depends on the Presentation & Feel GDD**.

**EC-11. If an Ultimate KOs in a non-final round**: `ROUND_END` is emitted on
tick T (before the freeze, F2); ticks T+1 … T+N are frozen, and Round &
Match's transition timers sit in block B, so the round transition waits for
the cinematic. No critical event can be emitted during the freeze (block A
emits nothing).
- *Status:* **Guaranteed** by rules 8–10; the transition length **Depends on
  the Round & Match GDD**.

**EC-12. If `ROUND_END` and `ROUND_START` fall on the same tick**: allowed by
the conservative bound (counted in the 7). Both records keep pipeline order
(`ROUND_END` first, I4). Whether Round & Match ever chains them is its call.
**Depends on the Round & Match GDD**.

### Freeze

**EC-13. If ticks are frozen**: block A still runs — `tick` advances,
`obs_this_tick` / `crit_this_tick` reset, prev positions copied, input ring
written — and **no event is emitted** (`event_seq` unchanged). The checksum
is still produced.
- *Debug:* asserts if `event_seq` changes in block A. *Release:* identical
  state (no runtime check is needed: block A calls only Sim Core code and
  Input's step, which emits nothing).
- *Test:* unit — set `freeze_ticks = 3`, step 3 times, `event_seq` unchanged,
  `tick` +3, round clock unchanged.
- *Status:* **Guaranteed** for Sim Core; that Input's step emits nothing
  **Depends on the Input GDD** (stated obligation).

**EC-14. If a freeze request has `N = 0`, `N < 0` or `N > 150`**: `N = 0` is a
no-op (no freeze; `ULTIMATE_HIT` still emitted with `a1 = 0`); invalid values
are clamped to 0 … 150 in every build.
- *Debug:* asserts on clamp (after the write, EC-0). *Release:* identical
  state.
- *Test:* unit — N = −5, 0, 150, 151.
- *Status:* **Guaranteed** (F1).

### Snapshot, restore, rollback

**EC-15. If a snapshot is taken before an overflow and restored after it**:
the counters return to the snapshot's values.
- *Initial:* snapshot at tick 100 (`event_overflow_count = c`,
  `critical_overflow_count = k`, `sim_fault = f`).
- *Sequence:* tick 101 drops events (counters rise; `sim_fault = 1` if a
  critical drop); `restore(snapshot@100)`; re-simulate.
- *Expected:* after restore the counters are `c, k, f` — not a "clear", a
  different timeline (18e). Re-simulating the **same** inputs reproduces the
  same drops and the same counter values (determinism); different inputs may
  not overflow at all.
- *Debug:* the overflow asserts follow EC-6/EC-7; restore itself never
  asserts. *Release:* identical state.
- *Test:* unit — snapshot, force overflow, restore, compare buffer to
  snapshot; re-step with same inputs, compare checksum to the first run.
- *Status:* **Guaranteed**.

**EC-16. If a fault (`sim_fault = 1`) occurs on a speculative tick that is
later rolled back**: the confirmed timeline has no fault.
- *Expected:* after rollback the buffer's `sim_fault` is whatever the restored
  snapshot held (0 if it predates the fault). `integrity_fault_confirmed`
  stays unset, because the faulting tick was never confirmed. A speculative
  diagnostic is logged. The replay is not flagged unless the confirmed
  re-simulation faults too.
- *Debug / Release:* identical sim state; the diagnostic log is Debug-only.
- *Status:* **Depends on the Rollback ADR** (it supplies `confirmed_tick`, 18g).
  Cannot occur before rollback exists: live play never restores.

**EC-17. If `restore` makes `event_seq` smaller than a consumer's `next_seq`**
(rewind):
- *Live non-rollback mode:* Debug assert in the consumer (18f). Release: the
  consumer resyncs — redraws current state from `SimView`, sets
  `next_seq = event_seq`, and processes newly emitted events normally.
- *Training reset:* the same resync, no assert.
- Sim state is unaffected either way (the consumer lives outside the sim).
- *Test:* unit — consumer harness with a scripted restore.
- *Status:* **Guaranteed** for non-rollback modes; reconciliation under
  rollback **Depends on the Rollback ADR** (18g; seq must not be used to match
  events across timelines).

**EC-18. If a replay is seeked** (forward by stepping many ticks without
draining, or backward via `init`/`restore` and re-stepping): the consumer is in
**resync** mode. Forward: `lost` may be huge — no assert, redraw current state,
`next_seq = event_seq`. Backward: a rewind (EC-17), resync, no assert. No cue
for the skipped span is ever fired.
- *Status:* **Guaranteed** for the rule; the seek UI and which snapshots exist
  **Depend on the Replay & Checksum GDD**.

### Initialisation, types and payloads

**EC-19. If the ring is read right after `init`** (zero-filled): every slot
holds `(tick 0, seq 0, type 0 = NONE, 0, 0, 0)`. With `event_seq = 0` no slot
is returned (EC-5). Once seq 0 is written, slot 0 holds a real record; every
other unwritten slot fails the stored-seq check (stored 0 ≠ expected), but is
never requested anyway. **Guaranteed**. *Test:* unit.

**EC-20. If an event is emitted with `type = 0` (NONE) or
`type ≥ EVENT_TYPE_COUNT`**: rejected in every build **before** the
`EVENT_CLASS[type]` lookup (an out-of-range table read is exactly the
Debug/Release-divergent case of rule 17).
- *Expected (A4):* not written to the ring, no seq; `sim_fault = 1`;
  `event_overflow_count` and `critical_overflow_count` **unchanged** (not an
  overflow drop). The match continues.
- *Debug:* asserts (after the write of `sim_fault`). *Release:* identical
  state.
- *Test:* unit — emit type 0, −1 and `EVENT_TYPE_COUNT`; assert ring words,
  `event_seq` and both overflow counters unchanged, `sim_fault == 1`; no
  out-of-range read of `EVENT_CLASS` occurs.
- *Diagnostic limitation (deliberate, Decision 1):* a second or tenth
  invalid emission leaves the same state (`sim_fault = 1`); the count is not
  observable from sim state.
- *Status:* **Guaranteed** by rule 18d (A4).

**EC-21. If an event is emitted during `init`** (tick 0): rejected in every
build by rule 18d (`tick == 0` means `init`, since block A raises `tick` to 1
before any slot runs): not written, no seq, `sim_fault = 1`, overflow counters
unchanged, Debug assert. Consequences: **the first `ROUND_START` is emitted
from Round & Match's block-B slot on tick 1 or later, never from its `init`
hook**; unit-test fixtures that call a system's `step` directly must set
`tick ≥ 1`.
- *Test:* unit — emit from an `init` hook; assert nothing written,
  `sim_fault == 1`.
- *Status:* **Guaranteed** for Sim Core (A4); obligation **on the Round &
  Match GDD**.

**EC-22. If an event payload is out of its type's range** (e.g. `a0` actor
not 0/1, a negative id, a position outside the stage): the record is written
**as given** — payloads never change sim state, so no state-affecting check is
needed. Debug asserts per-type ranges (after the write); Release identical
state. Presentation decoders must ignore or clamp unknown values and never
crash. `a0 = actor + 2 × id` cannot overflow for any id below 2⁶² **[Verified
arithmetic]**.
- *Status:* per-type ranges **Depend on** the emitting GDDs (Hit Detection,
  Projectiles, SP, Round & Match); that 3 arguments suffice is
  **[Unverified]**.

### Counters and boundaries

**EC-23. If `event_seq` or `tick` approach `INT64_MAX`**: unreachable — ≈ 3.0 ×
10⁸ years of continuous worst-case play for `event_seq` (F7), and `tick` < 10⁵
per match (F11). No wrap handling exists or is needed; documented, not tested.
**[Verified arithmetic]**

**EC-24. If `tick` is 0 or 1, or a lookback reaches before tick 1** †: `init`
leaves `tick = 0` and returns the tick-0 checksum; the first `step()` raises
it to 1 in block A, so the first input-ring write is slot `posmod(1, 32) = 1`
and the first event (if any) carries tick 1. A lookback of k at tick t ≤ k
reads zero-filled slots (31, 30, …), i.e. "inputs" from ticks ≤ 0.
- *Expected:* those words mean **no input**. *Debug / Release:* no assert;
  identical.
- *Test:* a command detector run at ticks 1–3 finds no command.
- *Status:* **Guaranteed** for Sim Core; **Depends on the Input GDD** defining
  input word `0` as neutral (no direction, no buttons), recorded here as a
  requirement on Input.

**EC-25. If `step()` is called in the Ended state** †: rule 7a — `match_over
!= 0` (not `== 1`) is checked **before block A**, in every build, and `step()`
returns at once: no `tick += 1`, no input-ring write, no prev copy, no events,
no counter or `event_seq` change. The returned checksum is the hash of the
unchanged buffer, equal to the previous tick's.
- *Debug:* asserts after the check. *Release:* identical state.
- *Test:* unit — step an Ended sim (`match_over` = 1 and = 7); buffer,
  `event_seq`, both overflow counters, `sim_fault` and checksum unchanged.
- *Status:* **Guaranteed** by rule 7a (A2).

### Restore, data and determinism (systems-designer review †)

**EC-26. If `restore` assigned the snapshot instead of copying it** †: the next
`step()` would mutate the stored snapshot, so restoring it twice would give
two different states. Assignment aliases **[Measured 4.7.2: a ring slot
restored by assignment was corrupted by the next write]**.
- *Expected:* rule 21 (A1) — `restore` installs an independent copy; the
  snapshot never changes; it can be restored any number of times.
- *Debug / Release:* no assert; identical.
- *Test (A1):* restore S, step N, assert S equals a copy taken before the
  restore; restore S again, assert the checksum equals S's original checksum
  and that stepping the same N ticks reproduces the same checksum sequence.
- *Status:* **Guaranteed** by rule 21 (A1).

**EC-27. If a snapshot is shorter than the header, or a layout change keeps
`TOTAL` but forgets to bump `LAYOUT_VERSION`** †:
- `restore` checks **size first, then version** (rule 21). A short snapshot
  returns an error with state unchanged; the version word is never read out
  of range (that read would abort the function in 4.7.2 Debug
  **[Measured]**).
- **A layout change requires a version bump** (rule 3). A golden fingerprint
  test over every `SimLayout` constant (name, offset, size) fails the build
  when any constant changes without `LAYOUT_VERSION` and the fingerprint
  being updated together.
- *Debug / Release:* returned error, no assert; identical.
- *Test:* a 4-word snapshot; a forged snapshot with version ± 1; editing one
  offset without a version bump fails the fingerprint test.
- *Status:* **Guaranteed** by rules 3 and 21 plus the fingerprint test.

**EC-28. If a snapshot comes from outside the process, or is corrupt** †
(e.g. `freeze_ticks = −5`, which would never decrement; `match_over = 7`):
- **Trusted:** snapshots produced by `snapshot()` in the current process and
  held in memory. `restore` checks only size and version; contents are
  trusted.
- **Untrusted:** anything read from a file or the network. Sim Core defers
  full validation: **Replay & Checksum and LAN must validate externally
  supplied state** (size, layout version, and per-field ranges such as
  `0 ≤ freeze_ticks ≤ FREEZE_TICKS_MAX`, `match_over ∈ {0, 1}`, `sim_fault ∈
  {0, 1}`, counters ≥ 0, `posmod`-reachable indices) **before** calling
  `restore`, in every build.
- `match_over != 0` (rule 7a) and `posmod` indexing (rule 15a) keep a corrupt
  word from producing an out-of-range index in Sim Core itself.
- *Status:* trusted path **Guaranteed** (rule 21); untrusted path **Depends on
  the Replay & Checksum GDD and the LAN ADR**. Tier 0 loads no external
  snapshots.

**EC-29. If a freeze is long relative to the input ring** †: block A writes the
input ring on frozen ticks today (rule 8), so a freeze of ≥ 32 ticks leaves
every lookback slot holding frozen-tick words, and a command started before
the cinematic cannot complete after it.
- *Sim Core statement:* the ring is indexed by **sim tick** (F10); lookback
  counts every tick, frozen ones included. Sim Core does not change this now.
- **Questions the Attack System and Input GDDs must answer** (policy is
  theirs):
  1. Do frozen ticks write input into the history ring, or does Input's slot
     skip them (and if so, what do frozen-tick presses do — latch, discard)?
  2. Does lookback count **simulation ticks** or **active (non-frozen)
     ticks**? If active ticks, how is that indexed without a second ring?
  3. What happens when a freeze is longer than the input-ring capacity
     (`INPUT_RING_TICKS` = 32 provisional; Tier 0 freezes are 60 ticks, up to
     150): is the pre-freeze history deliberately lost, or must the ring
     grow (a layout change needing the user's approval)?
- *Status:* Sim Core consistent; policy **Depends on the Attack System and
  Input GDDs**. No second ring may be added.

**EC-30. If a system reads hit records** †: **hit-record visibility contract**
(the current pipeline; no change now):
- Records written in tick t's hit-resolution slot are visible in tick t to
  **reactions and every later slot** (SP / skill / Ultimate, round checks).
- Slots **before** hit resolution (AI, command interpretation, movement &
  state, attack advance, defense, projectiles) see them only on the **next
  live tick**
  t′, until hit resolution of t′ clears them.
- Across a freeze of N ticks, the records of the last live tick T stay in the
  buffer (checksummed, unread) and are what the pre-resolution slots of tick
  T + N + 1 see.
- Consequence: "hit confirmed" logic in the command or attack slots (e.g. a
  cancel on hit) is one live tick late by design.
- *Test:* hit on tick T; the reactions slot observes it on T; the attack slot
  observes it on T + 1; with a freeze of N set on T, on T + N + 1.
- *Status:* order **Guaranteed** (rules 10, 19). **Explicit dependency for the
  Attack System and Hit Detection GDDs:** each must confirm this contract or
  request a pipeline change, which falls under constraint item 8 (architecture
  review + regression tests).

**EC-31. If `SimRng` is seeded with 0, −1 or `INT64_MIN`** †: a xorshift-family
state of (0, 0) stays zero for ever.
- *Specification:* `SimRng.seed(b, slot, seed)` expands `seed` with splitmix64
  into `rng_s0`, `rng_s1` (two successive outputs), then calls
  `SimRng.ensure_nonzero`: if `(rng_s0 | rng_s1) == 0`, set `rng_s0` to a fixed
  non-zero signed-decimal constant (value fixed in ADR-0001). The guard runs
  in **every** build; a Debug assert follows it. Whether splitmix64 can output
  0 for some seed is not relied on.
- *Test:* `seed(0)`, `seed(−1)`, `seed(INT64_MIN)` each leave
  `rng_s0 | rng_s1 != 0` and produce a sequence that is not constant over 1,000
  draws; `ensure_nonzero(0, 0)` returns a non-zero state; golden values
  (ADR-0001 validation 6).
- *Status:* **[Proposed]**. **Depends on ADR-0001** defining `SimRng.seed()`
  and the constant (amendment listed in Open Questions).

**EC-32. If move data differs between peers, between a recording and its
playback, or changes during a match** †: `data` lives outside the buffer (rule
1), so the tick-0 checksum still matches and the runs diverge only at the
first move that differs, which would look like a sim bug.
- **Two different checks, not one** *(user decision 2026-11-09)*:
  - **Compatibility check (before `init`):** proves both sides *start* from
    the same move data. The replay header stores `move_data_hash` and
    `LAYOUT_VERSION`, and playback refuses to start on a mismatch; the LAN
    handshake exchanges both and refuses the match on a mismatch. **This
    proves compatibility at load time only. It does not prove that move data
    stays unchanged during the match.**
  - **Runtime determinism check (every tick):** the per-tick checksum covers
    the buffer, not `data`. If move data were mutated mid-match, the
    checksum would diverge later, without naming the cause. Runtime
    move-data integrity therefore rests on **immutability** (below), not on
    the header or handshake.
- `move_data_hash` is **not** stored in the Sim Core buffer (user decision
  2026-11-09); the header keeps its three spare words.
- **Move Data Pipeline GDD obligations (explicit dependency):**
  1. **Deterministic hashing:** `move_data_hash` = `SimHash` over the
     converted integer sim fields only, in a defined field order
     (ADR-0001 rule 11), identical on every machine and build.
  2. **Validation before `init`:** data is loaded, integrality- and
     range-checked, hashed and compared (replay header / LAN handshake)
     **before** `Sim.init` is called; a mismatch never reaches the sim.
  3. **Immutable during a match:** `data` is not modified from `init` until
     the match ends (hot reload only outside matches, concept), **or** the
     GDD specifies an invalidation mechanism that rejects or ends the match
     deterministically on both peers. Debug may re-hash `data` at match end
     and assert it equals the pre-`init` hash; this detects mutation after
     the fact and is a diagnostic, not a guarantee.
  4. **Compatibility vs runtime:** the GDD states which of its checks are
     compatibility checks (load time) and which, if any, are runtime
     checks, and never presents the first as the second.
- *Test:* change one frame of one move → tick-0 checksum equal, data hash
  different, replay refused; Debug match-end re-hash equals the pre-`init`
  hash on a normal match.
- *Status:* **Depends on the Move Data Pipeline and Replay & Checksum GDDs
  and the LAN ADR**. **[Proposed]**

**EC-33. If facing is derived when `dx = 0`, or a division could have a zero
divisor** †:
- **Facing rule (binding on the Movement GDD):** with `dx = x_opponent − x_self`,
  `facing = +1` if `dx > 0`, `−1` if `dx < 0`, and **when `dx == 0`, facing
  remains unchanged** (the value from the previous tick). The Movement GDD
  owns facing (Interactions table) and must adopt this rule as written; any
  other `dx == 0` behaviour, or extra conditions (e.g. no turning while
  airborne or during an attack), is an amendment to this rule, not a
  replacement. No Movement GDD exists yet, so there is nothing to conflict
  with today.
  Facing is always ±1, never 0; `init` sets both values (P0 `+1`, P1 `−1`,
  through the setup owned by Round & Match). Facing-dependent math divides the
  non-negative facing-local magnitude and applies the sign last (ADR-0001 rule
  5a), so `div_floor(−7, 2) = −4` vs `div_floor(7, 2) = 3` never arises.
- **No division-by-zero path:** (1) raw `/` and `%` are forbidden in sim code
  except inside `SimMath` (ADR-0001; rule 15); (2) every divisor in sim code is
  either a positive constant or a data value the Move Data loader rejects
  unless it is > 0; (3) `SimMath.div_floor` and `mod_floor` guard `b == 0` in
  **every** build and return a defined result (proposed: 0), Debug asserts
  after. So the GDScript division operator never receives 0. GDScript's own
  behaviour on integer division by zero in Release is **[Unverified]** and is
  never exercised.
- *Test:* facing unit test at `dx` = −1, 0, +1 (0 keeps the previous value);
  mirror-symmetry golden test (swap sides, compare mirrored positions);
  `div_floor(5, 0)` and `mod_floor(5, 0)` return the defined value; loader
  rejects a zero divisor field.
- *Status:* **[Proposed]**. **Depends on the Movement GDD** (facing),
  **the Move Data Pipeline GDD** (divisor validation) and **an ADR-0001
  amendment** (defined zero-divisor result; it currently says "b must be
  non-zero").

**EC-34. If block A writes into Movement's per-player block** †: rule 5 (A3)
grants exactly six words — for `p ∈ {0, 1}`: `P_BASE + p × P_STRIDE + 0`
(`PF_PREV_X`), `+ 1` (`PF_PREV_Y`), `+ 2` (`PF_SNAP`) — and no other write
access.
- *Expected:* the strict block-A ownership test (rule 5) allows changes only
  to `tick`, `obs_this_tick`, `crit_this_tick`, those six words and Input's
  ring slots for the tick; a full frozen `step()` may additionally change only
  `freeze_ticks` (the rule 9 decrement).
- *Fixtures:* normal tick, frozen tick, overflow tick (overflow happens in
  block B; block A must still touch nothing else), Ended state (nothing may
  change), tick 1, first tick after `restore`.
- *Debug / Release:* test-time check; no runtime cost.
- *Status:* **Guaranteed** by rule 5 (A3) plus the test; absolute `P_BASE` /
  `P_STRIDE` provisional until the Movement GDD fixes its fields.

**EC-35. If code behaves differently in Debug and Release** †:
- (a) **Side effects inside `assert()` are prohibited** (rule 15). `assert` is
  stripped in Release builds **[Unverified for 4.7.2; not covered by the
  pinned engine reference]**, so any call or write inside its argument would
  change state between builds. An assert's argument is a pure comparison of
  values already computed.
- (b) **The `%` restriction:** the raw `%` operator is banned in `src/sim/`
  outside `SimMath`; all modulo goes through `posmod(x, positive named
  constant)` (ring and slot indices) or `SimMath.mod_floor` (everything else)
  — rule 15a, with `posmod`'s semantics measured on 4.7.2 Debug. Reason: `%`
  keeps the dividend's sign **[Verified: ADR-0001, tested 4.7.2]**, and a
  negative index silently writes from the end (`b[−1]` → last element
  **[Measured 4.7.2 Debug]**). `OS.is_debug_build` is also banned in sim code.
- (c) **Correctness must never depend on whether `assert()` aborts
  execution.** All validation and state-changing safeguards (range check,
  clamp, accept / drop, Ended check, invalid-emission rejection, zero-divisor
  guard) run in **every** build; Debug-only asserts and diagnostics occur
  **after** those safeguards; assert expressions have **no side effects**.
  So whether a failed assert aborts the function, pauses the debugger or is
  stripped, the sim state reached is the same (EC-0).
- *Test:* CI grep over `src/sim/` (excluding `SimMath`) for `%`, `OS.is_debug_build` and calls
  inside `assert(`; rule 23's golden checksums on Debug **and** Release
  builds.
- *Status:* the lint is **Guaranteed** once written; Debug/Release equality is
  **[Unverified]** until export templates are installed and rule 23's test
  passes.

## Dependencies

*Drafted 2026-11-09 from the systems index "Depends On" column and the
contracts fixed in Detailed Design and Edge Cases. No dependent GDD exists
yet, so every downstream row is a **requirement this GDD places on that
system**, to be confirmed or amended there (constraint item 7).*

**Hard vs soft.** **Hard**: the system cannot function without Sim Core — it
stores state in the buffer, runs in a phase slot, or calls the sim API.
**Soft / indirect**: it touches Sim Core only through another system.

### Upstream — what Sim Core depends on

Sim Core depends on **no gameplay system** (Foundation layer). Its own code
(`Sim`, `SimLayout`, `SimMath`, `SimRng`, `SimHash`, `SimEvents`) imports none;
only the composition root `SimPipeline` names the systems (rule 13).

| Prerequisite | Kind | What Sim Core needs from it | Status |
|---|---|---|---|
| ADR-0001 Sim Numeric Model | Hard (architecture) | Integer-only model, su / permille / ticks, `SimMath`, `SimRng`, `SimHash`, forbidden tokens | **Proposed** — GDD stays Draft until Accepted; amendments pending (`SimRng.seed` + `ensure_nonzero`, zero-divisor result, `%` ban, lazy-COW note) |
| ADR-0002 Sim / View Split | Hard (architecture) | `MatchRunner` stepping, `SimView`, event ring, prev/snap interpolation | **Proposed** — amendments pending (rule 5 event contract and level-check clarification, rule 3.2 T + D outside the buffer, rule 9 note) |
| Evidence-First Deterministic Integrity constraint | Hard (project rule) | Labelled claims, V4 / V5 gates, no bypass of the pipeline, review + regression tests for determinism changes | Binding (systems index, user 2026-11-09) |
| Godot 4.7.2 engine behaviour | Hard (platform) | Measured on Debug: `int` wrap, `PackedInt64Array` aliasing, `duplicate()` lazy copy, out-of-range write aborts the function, negative index wraps, `posmod` floor-mod. **Unverified:** Release builds (asserts, out-of-range writes, `posmod`, division), cross-CPU equality (V4), tick cost (V5) | Partly Measured; Release blocked on export templates |

**Runtime inputs (interfaces, not design dependencies).** At run time Sim Core
receives `data` (integer move tables; Move Data Pipeline), the input words
`w0`, `w1` (Input via `MatchRunner`) and the match `setup` and `seed` (Round
& Match / Menus & Select via `MatchRunner`). It never interprets `data`; it
holds it read-only for the systems that do.

### Downstream — systems that depend on Sim Core

| # | System | Hard / soft | Interface with Sim Core | Obligations this GDD places on it | Index lists Sim Core? |
|---|---|---|---|---|---|
| 2 | Input | **Hard** | Input slot in block A; owns the input-history ring region | Word `0` = neutral (EC-24); its step emits no events (EC-13); with Attack, answer the three EC-29 questions; word format and final ring length | Yes |
| 3 | Replay & Checksum | **Hard** | `init`, `step`, per-tick checksum, `snapshot` / `restore`, `LAYOUT_VERSION` | Header carries seed, setup, `LAYOUT_VERSION`, `move_data_hash` (EC-32); drain events within 13 steps while viewing (18f); seek = resync mode (EC-18); validate external snapshots before `restore` (EC-28); store the event-integrity flag (18e) | Yes |
| 4 | Move Data Pipeline | **Hard** | Supplies `data` (integers only, outside the buffer) | The four EC-32 obligations: deterministic hash; validation before `init`; immutable during a match or a defined rejection; compatibility vs runtime checks kept distinct. Loader rejects zero divisors (EC-33) | Yes |
| 5 | Character Movement & State Machine | **Hard** | Owns the per-player block; block A writes `PF_PREV_X/Y`, `PF_SNAP` at offsets 0–2 (rule 5) | Adopt the facing rule (EC-33); place fields from offset 3; set `snap` on discontinuities; fix `P_STRIDE`; facing-local magnitudes, sign last | Yes |
| 6 | Hit Detection & Damage | **Hard** | Hit-resolution slot; owns the hit-event buffer and hit-stop | I2 and I5 (18c); confirm the hit-record visibility contract (EC-30); hit-stop decrements in block B (F2); event payloads within 3 arguments (18); size the hit-event buffer | Yes |
| 7 | Attack System | **Hard** | Command-interpretation and attack-advance slots | Three EC-29 questions (with Input); confirm EC-30; final `INPUT_RING_TICKS` (F10). **Creative-direction flag (CD-GDD-ALIGN 2026-11-09):** whatever rule decides whether inputs pressed during a freeze are buffered, it must be identical for both players and visible in Training Mode, because it decides whether the victim can act on the first tick after a cinematic (Pillars 2 and 3) | **No — gap** |
| 8 | Defense | **Hard** | Owns the **defense slot** (rule 10a): writes the guard flag and throw-tech window state into its region | Confirm the slot position (after attack advance, before projectiles and hit resolution) or request another; I5 for `THROW_CONNECT` (18c); confirm the EC-30 visibility contract (its slot sees the previous live tick's hit records) | **No — gap** |
| 9 | SP, Skills & Ultimate | **Hard** | SP slot; the only writer that **sets** `freeze_ticks` (F1) | I1, I2 (18c); freeze set through F1 only | **No — gap** |
| 10 | Projectiles | **Hard** | Projectiles slot; owns the projectile pool region | ≤ 1 event per projectile per tick (18); confirm or change `PROJ_CAP` = 4 (F3) | **No — gap** |
| 11 | Operator Definitions | Soft / indirect | Through Move Data and its hooks inside other systems | Stay data + small hooks (TD note 5); no buffer fields of its own | No — correct |
| 12 | Round & Match Flow (in-sim half) | **Hard** | Round-checks slot; owns the Round & Match region (`match_over`, KO flags, clock, wins, phase) | I3, I4 (18c); first `ROUND_START` from block B (EC-21); double-KO / draw outcomes (EC-9); initial positions and HP via `init` | Yes |
| 13 | Opponent AI | **Hard** | AI slot (exists even if AI is cut, Adjustment E); its own region and PRNG words | Writes only its input word and its region; reads the buffer read-only | **No — gap** |
| 14 | Arena | **Hard** | Writes wall bounds at `init` (its region) | Bounds in su | Yes |
| 15 | Presentation & Feel | **Hard** | Reads only `SimView` and `events_since` | Never waits for `freeze_ticks` to reach 0 after `match_over` (EC-10); decoders never crash on bad payloads (EC-22); cues only from events, state only for drawing (18f) | Yes |
| 16 | Toon & Outline Rendering | Soft / indirect | Through Presentation & Feel | — | No — correct |
| 17 | HUD | **Hard** (read-only) | `SimView` meters, clock, wins; events for cues | Read-only; resync from `SimView` on `lost > 0` (18f). **Pillar 3 information comes from state, never from events (CD-GDD-ALIGN 2026-11-09):** SP, SP type, Ultimate meter and remaining skill time are read from `SimView` every frame; observation events may be dropped and may only drive cues | **No — gap** |
| 18 | Menus & Select (screen-flow half) | **Hard** (read-only) *(user decision 2026-11-09)* | Reads `match_over` through `SimView` as a level check (18f), via `MatchRunner`, to leave the match / show results | Never uses events for match flow; never writes the sim; reads confirmed-tick state only (18g) | **No — gap** |
| 19 | Audio | **Hard** (read-only) | Event cues via `events_since` | Cues only from events; never infer from state | **No — gap** |
| 20 | Settings | Soft / indirect | None in the sim | — | No — correct |
| 21 | LAN Netcode | **Hard** | Checksums, `snapshot` / `restore`, words to `MatchRunner` | ≤ 13 steps between drains (18f); handshake on `move_data_hash` + `LAYOUT_VERSION` (EC-32); validate external snapshots (EC-28); same build type for both peers until Release is verified (rule 23) | Yes |
| 22 | Training Mode | **Hard** | Reset via `restore` / `init` | Reset = resync mode, no assert (EC-17); does not clear `integrity_fault_confirmed` (18e) | **No — gap** |
| 23 | Operator Collection | Soft / indirect | None in the sim | — | No — correct |
| — | `MatchRunner` (ADR-0002, not a system) | **Hard** | The only scene-tree caller of `step()` | Ended / confirmed-tick handling, aggregated drop warning, `integrity_fault_confirmed` latch (18d, 18e) | n/a |
| — | Rollback ADR (future) | **Hard** | `snapshot` / `restore`, events | Adopt rule 18g; choose snapshot storage (rule 21) | n/a |

**Bidirectionality.** Every **Hard** row must list "Depends on: Sim Core &
State" in its own GDD, with the obligations above, when that GDD is written.

**Systems-index gaps (one-directional dependencies found).** Nine systems
store state in the buffer, run in a phase slot or read the sim directly, but
the index's "Depends On" column does not list Sim Core: **Attack System (7),
Defense (8), SP, Skills & Ultimate (9), Projectiles (10), Opponent AI (13),
HUD (17), Menus & Select (18), Audio (19), Training Mode (22).** The index is owned by
`/map-systems`; the correction is proposed in Phase 5 and needs the user's
approval. Design order is unaffected, because each of these already depends
on a system that depends on Sim Core.

## Tuning Knobs

*Derived 2026-11-09 by the main session from the F1–F11 variable tables,
which were already reviewed twice by systems-designer; systems-designer was
not consulted again for this section. Word costs use the F3 / F4 arithmetic
**[Verified arithmetic]**; every time cost is the F8 model **[Unverified
extrapolation from one Debug measurement]**.*

**Sim Core has almost no designer knobs.** Nearly every value here is a
**structural constant**: changing it changes the buffer layout, so it changes
results and checksums for the same inputs. That makes it a determinism
change under constraint item 8, not a tuning pass.

**Change process for every structural knob (S):**
1. Ask the user first wherever the user reserved the decision (buffer budget,
   ring multiplier, event layout and accept rule; user rulings 2026-11-09).
2. Update `SimLayout`, bump `LAYOUT_VERSION` and the golden layout
   fingerprint (rule 3). Old replays and snapshots become incompatible and are
   rejected, never reinterpreted.
3. Re-run the layout self-test (budget, overlaps, every `D > 0`), the F5
   critical-guarantee check and the replay checksum regression.

`SimLayout` constants are a deliberate exception to the coding standard
"gameplay values are data-driven": they must be compile-time constants so
that the fingerprint, the layout test and every peer agree. The one
gameplay-facing value, the freeze length `N`, is data (Ultimate move data).

### Knob table

| Knob | Value | Kind | Safe range | Too high | Too low | Interacts with | Owner |
|---|---|---|---|---|---|---|---|
| `SIM_BUFFER_WORD_BUDGET` | 2,048 words | S (user-reserved) | ≥ `TOTAL` (1,624 est.) | Checksum and snapshot grow (+11.6 ns per word per hash, model) | Below `TOTAL` the layout test fails | Every region size; F8 / F9 | Sim Core, user decision |
| `MAX_EVENTS_PER_TICK` | 16 | S (user-reserved) | `OBS_CAP + 9` (=16) … 21 at today's sizes | Each +1 costs 78 words (13 entries × 6); 22+ exceeds the budget | Below `OBS_CAP + 9` the critical guarantee (F5) breaks | `OBS_CAP`, `EVENT_WORDS`, the ×13 multiplier | Sim Core, user decision |
| `OBS_CAP` | 7 (was 8) | S (user-reserved) | 0 … `MAX − 9` (= 7) | Above `MAX − 9` a legal tick could drop a critical event | More observation events dropped (worst case 17 legal) | `MAX_EVENTS_PER_TICK`, critical bound 9 (I1–I5) | Sim Core, user decision |
| `EVENT_WORDS` | 6 (3 args) | S (user-reserved) | 6 … 8 | Each +1 costs 208 words: 7 → TOTAL 1,832; 8 → 2,040 (margin 8) | Below 6 the payload table no longer fits | Payload convention (rule 18); budget | Sim Core, user decision |
| `CATCHUP_RESERVE` | 4 | S | ≥ `MatchRunner.MAX_CATCHUP_TICKS` | Each +1 costs 96 words (16 × 6) and raises the drain bound by 1 | Below the runner's value the layout test fails | `MAX_CATCHUP_TICKS`, drain bound (F6) | Sim Core |
| `ROLLBACK_WINDOW_TICKS` | 8 | S (reserved) | Set by the Rollback ADR | Each +1 costs 96 words | Below the rollback depth, re-simulated events overwrite unread ones | Drain bound; Rollback ADR | ADR-0002 / Rollback ADR |
| `EVENT_RING_ENTRIES` | 208 | **Derived, not a knob** | = `MAX × (CATCHUP + ROLLBACK + 1)` | — | — | Drain bound = `CATCHUP + ROLLBACK + 1` = 13 steps, independent of `MAX` | Sim Core |
| `INPUT_RING_TICKS` | 32 (provisional) | S | ≥ longest command lookback + 1 | Each +1 costs 2 words | Commands longer than the ring cannot be read; a freeze ≥ ring length erases pre-freeze history (EC-29) | `FREEZE_TICKS_MAX`, Attack buffer windows | **Attack System GDD** (final value) |
| `PROJ_CAP` | 4 (assumption) | S | ≥ the most projectiles alive at once in Tier 0 | Each +1 costs 24 words (16 pool + 8 hit-event) and adds 1 legal observation event per tick | Spawns beyond the cap are dropped (Projectiles GDD) | Observation worst case; F3 | **Projectiles GDD** |
| `P_STRIDE` | 64 (estimate) | S | ≥ 3 reserved + Movement, Attack, Hit, Defense, SP fields | Each +1 costs 2 words | Fields do not fit | Rule 5 offsets 0–2 | **Movement GDD** (with the systems sharing the block) |
| `FREEZE_TICKS_MAX` | 150 ticks (provisional) | Safety cap | 60 … 150 | Above 150 breaks the creative-director hard limit (≤ 2.5 s cinematic) | Below 60 clamps Tier 0's 60-tick Ultimate freeze | Ultimate `N` (data); input ring (EC-29); round wall time (F2) | Sim Core (cap); SP GDD owns `N` |
| Freeze length `N` | Tier 0: 60; Tier 1: ≤ 150 | **Designer knob (data)** | 0 … `FREEZE_TICKS_MAX` | Longer cinematic, longer wall-clock round, more frozen input words | 0 = no cinematic | F1, F2, EC-29 | **SP, Skills & Ultimate GDD** (Ultimate move data) |
| Checksum interval | every tick | Policy (user decision) | 1 | — | Every N ticks: cheaper, but a desync is located only to an N-tick window | V5 | Sim Core; changing it needs the user and a failed V5 |
| `MatchRunner.MAX_CATCHUP_TICKS` | 4 | Runtime (ADR-0002) | 1 … `CATCHUP_RESERVE` | Fast-forward after a hitch; above the reserve the layout test fails | The sim falls behind on slow frames (more dropped ticks) | `CATCHUP_RESERVE` | ADR-0002 |

**Locked, not knobs:** `TICKS_PER_SECOND` = 60, `SU_PER_METER` = 10,000 and
`PERMILLE` = 1,000 (ADR-0001); `LAYOUT_VERSION` (bumped, never tuned); the slot
order (rules 10 and 10a; a pipeline change).

### Knob interactions

- **Ring size:** `ring_words = MAX_EVENTS_PER_TICK × (CATCHUP_RESERVE +
  ROLLBACK_WINDOW_TICKS + 1) × EVENT_WORDS`, and `TOTAL ≤ budget`. With the
  other regions at 376 words, `MAX × 13 × EVENT_WORDS ≤ 1,672`.
- **Critical guarantee:** `MAX_EVENTS_PER_TICK − OBS_CAP ≥ 9` (the I1–I5
  bound). Raising `OBS_CAP` without raising `MAX` breaks it.
- **Drain bound:** the steps allowed between consumer reads are
  `CATCHUP_RESERVE + ROLLBACK_WINDOW_TICKS + 1` (13). Changing `MAX` does not
  change it; changing either reserve does.
- **Freeze vs input ring:** `FREEZE_TICKS_MAX ≥ INPUT_RING_TICKS` (150 ≥ 32
  today) means a maximal freeze erases all pre-freeze input history. That is
  the open EC-29 policy question, not a tuning error.
- **Ownership:** where a dependency GDD owns a value (`INPUT_RING_TICKS`,
  `PROJ_CAP`, `P_STRIDE`, `N`), that GDD is the source of truth and this table
  only records Sim Core's constraint on it. No duplicate knob is created.

## Visual/Audio Requirements

**None directly; Sim Core draws and plays nothing** (category Core; this
section is optional for it). Everything visible or audible comes from
Presentation & Feel, HUD and Audio reading `SimView` and the event ring
(ADR-0002). What Sim Core guarantees those systems:
- Every presentation event fires from a tick-stamped record, at most once,
  and never from inferred state (rules 18–18f).
- Positions can be interpolated (`prev_x`, `prev_y`, `snap`, rule 8); poses
  snap to the integer tick (ADR-0002 rule 7).
- Hit-stop and the Ultimate freeze are exact sim counters, identical on both
  machines; slow-mo and shake live on the presentation clock (ADR-0002 rule
  8).

No asset spec is needed for this system.

## Game Feel

**Not owned here** (optional for Core). Sim Core's contribution to feel is
**fixed latency and exact timing**, not tunable feel:
- **Input-to-sim latency:** an input sampled in a frame enters the sim on the
  next stepped tick (rule 7; D = 0 locally). Interpolation draws up to one
  tick (~16.7 ms) behind the newest state (ADR-0002 rule 7). Both are
  architectural, not knobs.
- **Hit-stop and freeze** are counted in ticks and are frame-exact (F1, F2).
- Feel targets (hit-stop lengths, shake, slow-mo, camera push-in) belong to
  Presentation & Feel and to the moves' data.

## UI Requirements

**None.** Sim Core has no screen and no HUD element. HUD and Menus & Select
read it through `SimView` (rule 22); debug overlays (hitbox draw, checksum
readout) are presentation tools and are specified by the systems that own
them.

## Cross-References

| This document references | Target | Specific element | Nature |
|---|---|---|---|
| Overview, Player Fantasy | `design/gdd/game-concept.md` | Pillar 3 (Readable Mastery); Technical Considerations (60 Hz fixed sim, input-only sync, integer counters, replay + checksum in CI) | Rule source |
| Overview, Dependencies | `design/gdd/systems-index.md` | Evidence-First Deterministic Integrity constraint; TD-SYSTEM-BOUNDARY notes 1 and 3; Circular Dependencies; Adjustment E (AI slot kept) | Binding rule source |
| Detailed Design, Formulas | `docs/architecture/adr-0001-sim-numeric-model.md` | Rules 1–11 (su, permille, ticks, `div_floor` / `mod_floor`, facing-local magnitudes, boxes, PRNG, word-wise hash, one `PackedInt64Array`, one-way conversion, loader); R4, R5, R7 | Architecture dependency (Proposed) |
| Detailed Design, Events | `docs/architecture/adr-0002-sim-view-split.md` | Rules 1–5, 7–9 (`MatchRunner`, accumulator, `MAX_CATCHUP_TICKS`, frame order, `SimView`, event ring and `ROLLBACK_WINDOW_TICKS`, interpolation, presentation clock, snapshot deferral) | Architecture dependency (Proposed) |
| Dependencies, Interactions | `docs/registry/architecture.yaml` | Stances `sim_state_buffer`, `sim_presentation_events`, `sim-core` budget 0.25 ms | Consistency check (no conflict found) |
| Rule 5, EC-33, EC-34 | Character Movement & State Machine GDD *(not yet written)* | Owns the per-player block (offsets from 3), facing rule, `snap` setting, `P_STRIDE` | Ownership handoff |
| Rules 8, 10, EC-24, EC-29, F10 | Input GDD *(not yet written)* | Input word format, word 0 = neutral, ring region, frozen-tick input policy | Ownership handoff |
| Rule 10, EC-29, EC-30, F10 | Attack System GDD *(not yet written)* | Command interpretation, lookback policy, final `INPUT_RING_TICKS`, hit-record visibility | Ownership handoff |
| Rule 10a, EC-30 | Defense GDD *(not yet written)* | Defense slot position, guard flag, throw-tech state | Ownership handoff |
| Rules 12, 18c, 19, EC-30, F2 | Hit Detection & Damage GDD *(not yet written)* | Hit-event buffer, hit-stop decrement in block B, I2, payloads | Ownership handoff |
| F1, 18c | SP, Skills & Ultimate GDD *(not yet written)* | Sole setter of `freeze_ticks`, freeze length `N`, I1, I2 | Ownership handoff |
| Rule 6, 18c, EC-9, EC-21 | Round & Match Flow GDD *(not yet written)* | `match_over`, KO flags, I3, I4, first `ROUND_START` from block B, double-KO outcome | Ownership handoff |
| 18, F3 | Projectiles GDD *(not yet written)* | Pool region, `PROJ_CAP`, ≤ 1 event per projectile per tick | Ownership handoff |
| Rule 1, EC-32, EC-33 | Move Data Pipeline GDD *(not yet written)* | Integer `data`, `move_data_hash`, validation before `init`, immutability, zero-divisor rejection | Data dependency |
| Rule 21, 18e, 18f, EC-18, EC-28, EC-32 | Replay & Checksum GDD *(not yet written)* | Header fields, drain rule while viewing, seek resync, external snapshot validation, event-integrity flag | Data dependency |
| 18f, 18g, EC-28, EC-32, rule 23 | LAN Netcode ADR *(not yet written)* | ≤ 13 steps between drains, handshake, external snapshot validation, same build type | Architecture dependency |
| 18g, rule 21 | Rollback ADR *(not yet written)* | Speculative-event reconciliation, snapshot storage | Architecture dependency |
| EC-10, EC-22, 18f | Presentation & Feel GDD *(not yet written)* | Cinematic after `match_over`, payload decoders, cues from events only | Ownership handoff |

## Acceptance Criteria

*Given-When-Then; drafted by the main session, validated by qa-lead
2026-11-09 (revised for its testability, coverage and "passes while false"
findings). Every criterion names its fixture, action and expected value.*

**Type:** U = unit (`tests/unit/sim_core/`, no file I/O), I = integration
(`tests/integration/sim_core/`; file I/O allowed, fixtures created and
cleaned up by the test), P = performance measurement, C = CI static check
(may read source files), M = manual / multi-PC run. **Gate:** BLOCKING
unless marked. **BLOCKED (reason)** = cannot pass yet and is never reported
as passed. **PARTIAL** = ran, but not under the full stated condition; not a
pass.

**Test rules for this section.**
- *Fixtures:* any fixture that emits events or calls a system `step`
  directly sets `tick ≥ 1` (emission at `tick == 0` is rejected, rule 18d)
  and respects ≤ 16 accepted events per tick; bursts larger than 16 are
  produced by stepping, or by resetting the per-tick counters between
  bursts.
- *Randomness:* property tests draw from a local deterministic generator
  (`SimRng` or a test LCG) with committed seeds, never the engine's global
  RNG.
- *Oracles:* expected values come from an independent oracle in the test,
  never from the code under test.
- *Assert prerequisite:* criteria that deliberately trigger a Debug assert
  (AC-T5, AC-E4, AC-E6, AC-E8, AC-I3) depend on **AC-V5a** — whether gdUnit4
  survives a failed `assert()` headless is not yet known.
- *Evidence:* CI "has been seen to fail" evidence (planted-violation
  fixtures and the retained failing log) lives in `production/qa/evidence/`.

### Layout, ownership and the sim object (rules 1–6a, F3, F4, F10)

- **AC-L0** (C; rule 1) GIVEN `Sim`, WHEN CI inspects it, THEN it declares
  exactly two member variables, `buffer: PackedInt64Array` and `data`.
- **AC-L1** (U; rules 2, 4, 15a, F3) GIVEN `SimLayout`, WHEN the layout
  self-test runs, THEN regions are contiguous and non-overlapping, every pool
  and ring fits its region, every modulo divisor `D` > 0, every
  `BASE + D × STRIDE` ≤ its region end, and `TOTAL` ≤ 2,048.
- **AC-L2** (U; rule 3) GIVEN the committed layout fingerprint, WHEN any
  `SimLayout` constant changes without `LAYOUT_VERSION` and the fingerprint
  changing together, THEN the fingerprint test fails.
- **AC-L3** (U; rule 4) GIVEN a sim after `init`, WHEN 1,000 ticks are
  stepped, THEN `buffer.size() == TOTAL` at every tick.
- **AC-L4** (U; rule 5) GIVEN each system's step and each of the six fixtures
  (normal, frozen, overflow, Ended, tick 1, first tick after `restore`),
  WHEN the step runs, THEN no index outside that system's own regions, the
  Event Control region and the event ring changes, **and** at least one
  index inside its own region changes on the normal fixture (it did work).
- **AC-L5** (U; rule 5, A3) GIVEN a normal-tick fixture with `x ≠ prev_x`,
  `snap = 1`, at tick T, WHEN block A runs alone with words (w0, w1), THEN
  `tick == T + 1`, `prev_x == x`, `prev_y == y`, `snap == 0` for both
  players, the input ring at `IN_BASE + p × 32 + posmod(T + 1, 32)` holds
  w0 / w1, **and** the changed indices are only, and include, `tick`,
  `obs_this_tick`, `crit_this_tick`, the six words
  `P_BASE + p × P_STRIDE + {0, 1, 2}` and those two ring words. Repeated on
  the tick-1 and post-restore fixtures.
- **AC-L6** (U; rule 5) GIVEN `freeze_ticks = 3`, WHEN one full `step()`
  runs, THEN the changed indices are only, and include, the AC-L5 set plus
  `freeze_ticks` (3 → 2).
- **AC-L7** (U; rules 6, 20) GIVEN a `Sim` whose buffer is pre-filled with
  `0x5A` and every system `init` hook a no-op, WHEN `init(12345, setup)` runs,
  THEN every word except `layout_version`, `rng_s0` and `rng_s1` is 0,
  `layout_version == LAYOUT_VERSION`, `tick == 0`, and the returned value
  equals `SimHash.hash_words(buffer)`.
- **AC-L8** (U; F4, F10, EC-24) GIVEN the layout, THEN
  `EVENT_RING_ENTRIES == 16 × (4 + 8 + 1) == 208` and
  `MatchRunner.MAX_CATCHUP_TICKS ≤ CATCHUP_RESERVE`; GIVEN tick 100 and
  p = 1, the input word lands at `IN_BASE + 36`; GIVEN a fresh `init`, the
  first `step()` writes ring slot 1, and a lookback of 3 at tick 1 reads 0.

### The tick (rules 7–12, F1, F2)

- **AC-T1** (I; rule 7) GIVEN a fake `MatchRunner` with input delay D = 2
  holding a unique sentinel word queued for tick T + 2, WHEN it steps tick
  T + 1, THEN no buffer word equals the sentinel.
- **AC-T2** (U; rule 7a, EC-25) GIVEN `match_over = 1`, and separately
  `match_over = 7`, WHEN `step()` runs, THEN the buffer is word-for-word
  identical to before and the returned checksum equals the previous tick's.
- **AC-T3** (U; rule 8, EC-13) GIVEN `freeze_ticks = 3`, `x ≠ prev_x`,
  `snap = 1`, WHEN one `step()` runs, THEN `prev_x == x`, `snap == 0`,
  `tick` +1 and `event_seq` unchanged.
- **AC-T4** (U; rule 9, F2) GIVEN a sim whose `freeze_ticks` is set to 3
  directly after tick 10, WHEN ticks 11–14 are stepped, THEN the round-clock
  word is unchanged across 11, 12 and 13 and decrements on 14.
- **AC-T5** (U; F1, EC-14) GIVEN freeze requests of N = −5, 0, 150 and 151,
  WHEN applied through the F1 set rule, THEN `freeze_ticks` becomes 0, 0, 150
  and 150 on Debug. *The "identical in Release" clause:* **BLOCKED (export
  templates)**.
- **AC-T6** (U; F1) GIVEN freeze requests of 60 and 90 on the same tick,
  WHEN applied in order (60, 90) and then (90, 60), THEN
  `freeze_ticks == 90` both times.
- **AC-T7** (C; rules 10, 10a, 13) GIVEN `sim_pipeline.gd`, WHEN CI parses
  the order of its static `step` calls and of its `init_all` calls, THEN
  both equal the golden list: input (block A); AI → command interpretation →
  movement & state → attack advance → defense → projectiles → hit
  resolution → reactions → SP / skill / Ultimate → round checks (block B);
  and the check fails on a planted reorder.
- **AC-T8** (U; rule 11) GIVEN two sims with the same seed and setup, WHEN
  both step the same 1,000 input pairs, THEN the 1,000 returned checksums are
  identical; changing one input word at tick 500 changes the checksum at
  tick 500 and leaves ticks 1–499 identical.
- **AC-T9** (I; rule 12, F2) GIVEN a character with hit-stop 5 and a freeze of
  N = 10 starting next tick, WHEN 15 ticks are stepped, THEN hit-stop reaches
  0 on the 15th tick, not earlier. *(Depends on the Hit Detection GDD placing
  the decrement in block B.)*
- **AC-T10** (U; rule 11) GIVEN a live, a frozen and an Ended tick, WHEN
  `step()` returns, THEN the returned value equals `SimHash.hash_words(buffer)`
  computed by the test right after, and no buffer word equals it (the
  checksum is not stored in the buffer).

### Pipeline and code rules (rules 13–17, EC-0)

- **AC-P1** (C; rule 13) GIVEN the source tree, WHEN CI runs, THEN none of
  `Sim`, `SimLayout`, `SimMath`, `SimRng`, `SimHash`, `SimEvents` references a
  system class; only `SimPipeline` does.
- **AC-P2** (I; rule 14) GIVEN a scripted tick in which both players hit each
  other, WHEN hit resolution runs, THEN both hits apply (a trade), and
  swapping which player is P0 gives mirrored results. *(Depends on the Hit
  Detection GDD.)*
- **AC-P3** (C; rules 15, 15a, 16, EC-35) GIVEN `src/sim/`, WHEN the CI
  forbidden-token check runs, THEN it fails on each planted violation:
  class-scope `var` (including one holding a `PackedInt64Array`), `static
  var`, `@onready`, `extends Node`, `Callable`, `signal`, `await`,
  `OS.is_debug_build`, `%` outside `SimMath`, a call inside `assert(`, and
  each ADR-0001 forbidden token; each plant has been seen to fail once
  (evidence retained).
- **AC-P4** (U; rule 15a) GIVEN `posmod`, WHEN called with (−7, 3), (−1, 208),
  (209, 208), (INT64_MAX, 208) and (INT64_MIN, 208), THEN it returns 2, 207,
  1, 111 and 96, typed `int`. *Release run:* **BLOCKED (export templates)**.
- **AC-P5** (U; rule 16) *Engine characterisation, conditional:* GIVEN an
  implementation whose `restore` replaces the buffer reference, WHEN a test
  writes through a reference taken before the restore, THEN the live buffer is
  unchanged. (If `restore` element-copies into existing storage, this
  criterion is marked not applicable; rule 16 is then enforced by AC-P3's
  class-scope-var plant.)
- **AC-P6** (U; rule 17, 15a) GIVEN fixtures with `event_seq` set directly to
  0, 1, 207, 208 and `INT64_MAX − 16`, and `tick` set directly to 31, 32 and
  `INT64_MAX − 1`, WHEN one event is emitted and one tick is stepped, THEN
  the record and the input word land at the F4 / F10 positions, inside their
  regions, and no other word changes.
- **AC-P7** (U; EC-33) GIVEN `SimMath`, WHEN `div_floor(5, 0)` and
  `mod_floor(5, 0)` are called, THEN each returns the defined value with no
  engine error. *(Unblocked 2026-11-10: value 0, ADR-0001 A1.)*
- **AC-P8** (C; EC-0) GIVEN `src/sim/`, WHEN CI runs, THEN it fails on a
  planted `assert(` placed before a state write in the same function.

### Events (rules 18–19, F4–F7, EC-5, EC-15, EC-18, EC-19, EC-22)

- **AC-E1** (U; F4, EC-1, EC-2) GIVEN a sim at tick ≥ 1, WHEN 13 ticks each
  accept 16 events (208 total), THEN a read from cursor 0 returns seq 0–207
  with `lost = 0`; WHEN one more event is accepted on the next tick, THEN the
  read returns seq 1–208 with `lost = 1`.
- **AC-E2** (U; F6, EC-3, EC-4) GIVEN a consumer that has just read and an
  emitter accepting 16 events per tick, WHEN it reads after 13 steps, THEN
  `lost = 0`; WHEN after 14 steps, THEN `lost = 16` and the first returned
  seq is E0 + 16.
- **AC-E3** (U; F5, EC-6) GIVEN one tick emitting 10 observation and 2
  critical events, WHEN accepted, THEN 7 observation and 2 critical records
  are written, `event_overflow_count += 3`, `sim_fault` unchanged, and no
  assert fires.
- **AC-E4** (U; F5, EC-7) GIVEN `obs_this_tick = 7`, `crit_this_tick = 9`,
  WHEN a 10th critical event is emitted, THEN nothing is written,
  `event_overflow_count` and `critical_overflow_count` each +1,
  `sim_fault = 1`, and `match_over` unchanged.
- **AC-E5** (U; F5, EC-8) GIVEN interleavings of ≤ 9 critical and ≤ 17
  observation emits in one tick — 200 drawn from a committed-seed local
  generator plus the extremes "all critical first" and "all critical last" —
  WHEN accepted, THEN the accepted set equals the test oracle's "first 7
  observations in emission order plus every critical event".
- **AC-E6** (U; rules 18a, 18d, EC-20, EC-21) GIVEN emits of type 0, −1 and
  `EVENT_TYPE_COUNT`, and an emit while `tick == 0`, WHEN each runs, THEN no
  ring word and no `event_seq` changes, both overflow counters are
  unchanged, `sim_fault == 1`, and `EVENT_CLASS` is never indexed out of
  range; repeating the invalid emit leaves the same state.
- **AC-E7** (U; F5 sequence semantics) GIVEN 3 ticks each emitting 20
  observation + 2 critical events (9 accepted, 13 dropped per tick), then
  further ticks of at most 7 observation and 9 critical events until
  `event_seq == 250`, WHEN read from cursor 0, THEN the returned seqs are
  42 … 249 with no gaps, `lost == 42` and `event_overflow_count == 39`.
- **AC-E19** (U; 18c, CD-GDD-ALIGN concern 1) GIVEN a saturated tick in which
  7 observation events are emitted before hit resolution (1 throw tech, 2
  projectile spawns, 4 projectile expiries) and then both players' strikes
  connect, WHEN the tick resolves, THEN both character `HIT` records are
  accepted, every later observation event that tick is dropped and counted,
  and `critical_overflow_count == 0`.
- **AC-E8** (U; rule 18f, EC-17) GIVEN a consumer with `next_seq = 500` and a
  restore that sets `event_seq = 300`, WHEN the consumer reads in a live mode,
  THEN the rewind is detected (Debug assert) and the consumer resyncs with
  `next_seq = 300`.
- **AC-E9** (U; rule 18f) GIVEN a read, WHEN `events_since` returns, THEN
  writing to `out` leaves every ring word unchanged.
- **AC-E10** (I; rule 19) GIVEN hit records from tick T, WHEN tick T + 1's
  hit resolution starts, THEN the hit-event buffer is cleared before new
  records are written, and no presentation-ring word changes in the clear.
  *(Depends on the Hit Detection GDD.)*
- **AC-E11** (U; F7, F11) GIVEN `event_seq = INT64_MAX − 1000` set directly,
  WHEN 16 events are accepted, THEN each slot follows `posmod(seq, 208)` with
  no negative index. *(Boundary only; unreachable in play, F7.)*
- **AC-E12** (U; rule 18) GIVEN tick 5, WHEN `emit(b, T, 3, 4, 5)` is accepted
  with seq s, THEN its slot holds exactly `(5, s, T, 3, 4, 5)`.
- **AC-E13** (U; EC-5, EC-19, F6) GIVEN `event_seq` of 0, 1 and 207 after a
  fresh `init`, WHEN read from cursor 0, THEN `lost == 0` and exactly
  `event_seq` records are returned (none for 0).
- **AC-E14** (U; EC-22) GIVEN an event with `a0 = 7`, `a1 = −1`, WHEN emitted,
  THEN the record stores the values as given and no other word changes.
- **AC-E15** (U; 18e, EC-15) GIVEN snapshot S with counters
  (`event_overflow_count`, `critical_overflow_count`, `sim_fault`) = (c, k, 0),
  WHEN a critical overflow is forced, THEN they rise; WHEN S is restored,
  THEN they equal (c, k, 0); WHEN re-stepped with the same inputs, THEN the
  counters and checksums match the first run; WHEN `init` runs, THEN all
  three are 0.
- **AC-E16** (C; 18e) GIVEN `src/sim/`, WHEN CI runs, THEN no code writes
  `sim_fault = 0` or decrements either overflow counter outside `init`.
- **AC-E17** (U; EC-18) GIVEN a consumer in seek mode with `lost = 500`, and
  separately after a rewind, WHEN it reads, THEN no assert fires and
  `next_seq == event_seq`.
- **AC-E18** (C; 18a) GIVEN `src/sim/`, WHEN CI runs, THEN the event-ring and
  Event Control layout constants are referenced only by `SimEvents` and
  `SimView`.

### Lifecycle (rules 20–23, 18e, 18g)

- **AC-X1** (U; rule 20, EC-31) GIVEN seeds 0, −1 and INT64_MIN, WHEN `init`
  runs, THEN `rng_s0 | rng_s1 ≠ 0` and 1,000 draws are not all equal;
  `ensure_nonzero(0, 0)` returns a non-zero state; the golden sequence for
  seed 12345 matches the committed values. *(SimRng part unblocked 2026-11-10,
  ADR-0001 A1; the `init` part waits for `Sim`.)*
- **AC-X2** (U; rule 21, A1, EC-26) GIVEN snapshot S taken at tick 100 with
  checksum C₁₀₀, WHEN the sim restores S, THEN `SimHash.hash_words(buffer)`
  equals C₁₀₀ before any step; WHEN it steps 50 ticks, restores S again and steps the same 50
  ticks, THEN S is unchanged and both 50-checksum sequences are identical.
- **AC-X3** (U; rule 21, EC-27) GIVEN snapshots of size 0, 4 and `TOTAL + 1`,
  and a `TOTAL`-size snapshot with `layout_version` ± 1, WHEN restored, THEN
  each returns `ERR_INVALID_DATA` (proposed error value) and the buffer is
  unchanged.
- **AC-X4** (U; rule 22) GIVEN a `SimView`, WHEN every accessor is called,
  THEN each returns an `int` (or fills a caller-owned `int` array), and none
  returns an array that aliases the buffer.
- **AC-X5** (I; rule 23, EC-0) GIVEN the golden replay of AC-V2, WHEN run on a
  Debug build and a Release export, THEN all per-tick checksums match, and
  the sim test suite yields identical buffers on both builds. **BLOCKED
  (export templates not installed)**.
- **AC-X6** (I; 18e, 18g, EC-16) GIVEN a speculative tick that sets
  `sim_fault = 1` and is later rolled back, WHEN the confirmed timeline is
  stepped, THEN `integrity_fault_confirmed` stays unset and no speculative
  event is presented as confirmed. **BLOCKED (Rollback ADR)** — kept so the
  latch and speculative-event rules cannot be forgotten.

### Validation gates (Player Fantasy, V4, V5, EC-0)

- **AC-V1** (I; Player Fantasy) GIVEN a match recorded through the Replay &
  Checksum GDD's real serialisation (written and read back by the test),
  WHEN replayed headless, THEN the replay checksum equals the live checksum
  at every tick. *(Depends on the Replay & Checksum GDD; until then AC-T8 is
  the in-memory equivalent.)*
- **AC-V2** (M; V4, ADR-0001 validation 3) GIVEN a 10,000-tick replay file,
  WHEN replayed on an Intel PC and an AMD PC and repeatedly in CI, THEN every
  per-tick checksum matches. Fewer than two vendors = **PARTIAL**, never a
  pass. **BLOCKED (V4 not yet run)**.
- **AC-V3** (P; V5, F9) GIVEN the Tier −1 sim on the development PC (hardware
  recorded), WHEN 10,000 ticks are stepped after warm-up, THEN the mean,
  p99 and maximum tick cost including checksum (and snapshot, once rollback
  exists) are each ≤ 0.25 ms, and `Performance.MEMORY_STATIC` changes by 0
  over the run. A Debug-only figure is provisional; the pass requires a
  Release measurement. **BLOCKED (V5 not yet measured; F8 / F9 are a model,
  not a pass)**.
- **AC-V4** (M; Player Fantasy) GIVEN two PCs on LAN, WHEN a planted input
  divergence on one peer is detected at the correct tick, and then a
  10-minute unplanted match is played, THEN zero checksum mismatches are
  reported. **BLOCKED (LAN ADR and spike)**.
- **AC-V5a** (U; EC-0) GIVEN a headless gdUnit4 run on 4.7.2 Debug, WHEN a
  test function's `assert()` fails mid-function, THEN the observed behaviour
  (function aborted or continued, caller continued, test runner survived) is
  recorded as **[Measured]**. Must run before the first sim assert is
  written; prerequisite for AC-T5, AC-E4, AC-E6, AC-E8, AC-I3.
- **AC-V5b** (I; EC-0, EC-35) the Release half of the same question is part
  of AC-X5. **BLOCKED (export templates)**.

### Cross-system integration

- **AC-I1** (I; 18c, EC-9, EC-10) GIVEN a scripted Ultimate trade that KOs
  both players in the final round, WHEN the tick resolves, THEN exactly 6
  critical events are emitted in the order `ULTIMATE_HIT` P0,
  `ULTIMATE_HIT` P1, `KO` P0, `KO` P1, `ROUND_END`, `MATCH_END`, and
  `critical_overflow_count == 0`. *(Depends on the Hit Detection, SP and Round
  & Match GDDs.)*
- **AC-I2** (I; EC-30) GIVEN a hit on tick T, WHEN ticks T and T + 1 run, THEN
  the reactions slot observes it on T and the attack and defense slots on
  T + 1. *(Depends on the Attack, Defense and Hit Detection GDDs.)*
- **AC-I3** (I; rule 18f, EC-4) GIVEN `MatchRunner` with a fake clock forcing
  14 steps between drains in a live mode, WHEN the consumer reads, THEN the
  contract-breach assert fires; with 4 steps per frame, it never fires over
  10,000 ticks.
- **AC-I4** (I; EC-32) GIVEN a replay fixture file recorded with move data A
  (created and deleted by the test), WHEN played with move data A′ (one frame
  changed), THEN playback refuses to start before `init`. *(Depends on the
  Move Data and Replay GDDs.)*
- **AC-I5** (I; 18d) GIVEN `MatchRunner` stepping a confirmed tick that drops 3
  observation events, WHEN the frame completes, THEN exactly one aggregated
  warning `tick T: 3 events dropped` is emitted for that tick. *The "never
  twice for a re-simulated tick" half:* **BLOCKED (Rollback ADR)**.

**Not Sim Core criteria (owned elsewhere):** the facing rule (EC-33 a) —
Movement GDD; external snapshot validation (EC-28) — Replay & Checksum / LAN;
frozen-tick lookback policy (EC-29) — Attack / Input. Each is listed as an
obligation under Dependencies.

**Coverage:** every core rule 1–23 and sub-rules 6a, 7a, 10a, 15a, 18–18g has
at least one criterion; every formula with a runtime effect (F1, F2, F3, F4,
F5, F6, F10, F11) has one; F2's `round_wall_ticks` and F7 are documentation
only, and F8 / F9 are covered by AC-V3 as a gate, not as a pass.

## Open Questions

*Owner = who resolves it. Target = the milestone it must be resolved by
(no calendar dates have been set for Tier −1). None of these is resolved by
this GDD; ADR changes go through `/architecture-decision` or
`/propagate-design-change`, never silently.*

### ADR amendments (owner: technical-director)

| # | Question | Target |
|---|---|---|
| OQ-1 | ~~ADR-0001: define `SimRng.seed()` (splitmix64 expansion) and `ensure_nonzero` with its fixed constant (EC-31; unblocks AC-X1)~~ **Resolved 2026-11-10** by ADR-0001 amendment A1 (user-approved): splitmix64 → xorshift128+ 23/18/5, `NONZERO_FALLBACK = -7046029254386353131` | — |
| OQ-2 | ~~ADR-0001: define the zero-divisor result of `div_floor` / `mod_floor` (proposed 0; EC-33; unblocks AC-P7)~~ **Resolved 2026-11-10** by ADR-0001 amendment A1 (user-approved): result 0, every build | — |
| OQ-3 | ADR-0001: record the `%` ban outside `SimMath` and `posmod`'s measured semantics (rule 15a) | Before ADR-0001 is Accepted |
| OQ-4 | ADR-0001 R7 / ADR-0002 rule 9: `duplicate()` is lazily copy-on-write (measured) | Before either ADR is Accepted |
| OQ-5 | ADR-0002 rule 3.2: input words for tick T + D stay outside the buffer (rule 7) | Before ADR-0002 is Accepted |
| OQ-6 | ADR-0002 rule 5: 6-word records, `NONE` type, event classes, accept rule, `sim_fault` meaning, cursor / rewind contract, new `events_since` signature; plus the clarification that match flow may check persistent state as a level | Before ADR-0002 is Accepted |
| OQ-7 | ADR-0002 + TD-SYSTEM-BOUNDARY note 1: add the defense slot to the phase list (rule 10a; constraint item 8) | Before ADR-0002 is Accepted |
| OQ-8 | ADR-0002: the event-ring capacity is the Sim Core constant `CATCHUP_RESERVE`, not a function of `MAX_CATCHUP_TICKS` (F4) | Before ADR-0002 is Accepted |
| OQ-9 | TD-SYSTEM-BOUNDARY note 3: replay header gains `LAYOUT_VERSION` and `move_data_hash` (EC-32) | Before the Replay & Checksum GDD |

### Engine and validation (owner: engine-programmer, Tier −1 spike)

| # | Question | Target |
|---|---|---|
| OQ-10 | What a failed `assert()` does in 4.7.2 Debug under gdUnit4 headless (AC-V5a) | Before the first sim assert is written |
| OQ-11 | Install export templates; measure Release behaviour: assert stripping, out-of-range writes, `posmod`, integer `/` by zero, golden checksum parity (rule 23, AC-X5) | Tier −1 spike |
| OQ-12 | V4: identical per-tick checksums on Intel and AMD (AC-V2) | Tier −1 spike (PASS condition) |
| OQ-13 | V5: tick ≤ 0.25 ms mean, p99 and max, zero per-tick allocation (AC-V3); if it fails, the user decides on the every-N-ticks checksum fallback | Tier −1 spike (PASS condition) |
| OQ-14 | Does a `const` defined from other `const`s parse in 4.7.2 (needed by `SimLayout`)? | First `SimLayout` commit |

### Dependent GDDs (owner: that GDD's author)

| # | Question | Target |
|---|---|---|
| OQ-15 | Attack + Input: the three EC-29 questions (frozen-tick input; sim vs active ticks; freeze longer than the ring); per CD-GDD-ALIGN the answer must be identical for both players and visible in Training Mode | When those GDDs are written |
| OQ-16 | Attack, Defense, Hit Detection: confirm the EC-30 hit-record visibility contract or request a pipeline change | When those GDDs are written |
| OQ-17 | SP, Hit Detection, Defense, Round & Match: confirm invariants I1–I5 (rule 18c) | When those GDDs are written |
| OQ-18 | Hit Detection, Projectiles, SP, Round & Match: confirm every event payload fits 3 arguments (rule 18) | When those GDDs are written |
| OQ-19 | Projectiles: `PROJ_CAP` (assumed 4); Movement: `P_STRIDE`; all owners: region sizes (F3 estimate) | When those GDDs are written |
| OQ-20 | Defense: confirm the defense slot position (rule 10a) | Defense GDD |
| OQ-21 | Replay & Checksum, LAN: validate externally supplied snapshots before `restore` (EC-28) | Replay GDD / LAN ADR |
| OQ-22 | LAN ADR: ≤ 13 steps between drains including post-stall catch-up; same build type for both peers until OQ-11 passes | LAN ADR |
| OQ-23 | Rollback ADR: adopt rule 18g; choose snapshot storage (`duplicate()` ring vs element copy) against the measured costs | Rollback ADR |

### Index and process

| # | Question | Owner | Target |
|---|---|---|---|
| OQ-24 | ~~Systems index: add Sim Core to "Depends On" for Attack, Defense, SP, Projectiles, Opponent AI, HUD, Menus & Select, Audio, Training Mode~~ **Resolved 2026-11-09:** index updated with user approval | `/map-systems` (user approval) | Done |
