# ADR-0001: Sim Numeric Model — Fixed-Point Integers

## Status
Proposed

## Date
2026-11-01

## Last Verified
2026-11-10 (amendment A1: SimRng seed/algorithm, zero-divisor result; user-approved)

## Decision Makers
User (solo developer); drafted via `/architecture-decision`; reviewed by godot-specialist (no blocking issues; semantics tested headless) and technical-director (TD-ADR: CONCERNS, C1-C5 and A1-A4 revised in, 2026-11-01).

## Summary
The deterministic 60 Hz combat simulation must produce bit-identical state on different PCs (LAN lockstep, replay checksums in CI), and the concept left open whether its spatial math uses controlled floats or fixed-point integers. This ADR decides: **every value in sim state and every sim computation is a GDScript `int` in fixed-point sim units; floats and `Vector2/3` are allowed only in presentation, converted one-way from sim state.**

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript) |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — 4.7 is post-LLM-cutoff (VERSION.md) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`, `modules/physics.md`, `modules/networking.md`. **NOT SOURCEABLE in the reference:** no Core / math module exists. Numeric semantics were instead **tested headless on the installed `Godot/godot.exe` 4.7.2.stable.official, 2026-11-01, one machine** (godot-specialist): marked **[tested-4.7.2]** below. Still **[unverified]**: `RandomNumberGenerator` / `hash()` cross-version stability, per-directory GDScript warning severity, cross-CPU identity (V4), sim performance (V5). |
| **Post-Cutoff APIs Used** | None. The decision deliberately depends only on `int`, `PackedInt64Array` and plain arithmetic. |
| **Verification Required** | V1 `int` is 64-bit signed and **wraps silently** on overflow [tested-4.7.2]. V2 `/` on `int` truncates toward zero and `%` takes the dividend's sign [tested-4.7.2]. V3 `JSON.parse_string` returns every number as `float`; integers ≤ 2^53 survive, larger ones lose precision, and out-of-range `int()` saturates silently to INT64_MIN [tested-4.7.2]. V1–V3 are re-run as unit tests in CI so a future engine bump cannot change them unnoticed. V4 two different x86-64 CPUs (one Intel, one AMD if available) produce identical per-tick checksums over a 10,000-tick replay. V5 one sim tick **including snapshot and checksum** takes **≤ 0.25 ms** on the development PC, so an ~8-tick rollback window (≈ 133 ms, covering Hamachi round trips) fits the 2.0 ms sim slice (art bible §8.10 [E]). All five run in the Tier −1 spike. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — first ADR; no other ADR exists (checked `docs/architecture/` and `docs/registry/architecture.yaml`, 2026-11-01). |
| **Enables** | Sim/view-split ADR (next Tier −1 ADR); LAN spike ADR; Sim Core & State, Character Movement & State Machine, Hit Detection & Damage GDDs (systems index: "numeric-model ADR is a hard prerequisite"). |
| **Blocks** | Any combat sim code (Tier −1 vertical slice) and the three GDDs above. No stories exist yet. |
| **Ordering Note** | Must be Accepted before the first line of combat code. Its Validation Criteria run as the first Tier −1 spike task; if V1–V4 fail, this ADR is revisited before any other sim work. |

## Context

### Problem Statement
The concept requires a deterministic, input-only-synchronised simulation: fixed 60 Hz, replay with per-tick checksum from Tier −1 (run in CI), delay-based LAN between two different PCs, and state designed for rollback later. Any value that can differ by one bit between machines makes the checksums diverge and the LAN match desync with no visible cause.

Two reviews disagreed. TD-FEASIBILITY recommended controlled float. The concept's `/design-review` (network-programmer, godot-specialist, systems-designer) recommended fixed-point integers, because Godot's `Vector2/3` use `real_t` (32-bit in the installed official build; `OS.has_feature("double")` is false [tested-4.7.2]) and cross-machine float determinism is fragile. The concept already fixes all resources and counters (HP, SP, Ultimate gauge, time) as integers; what is open is spatial math (position, velocity, gravity, pushbox and hitbox geometry) and formula arithmetic (damage scaling, knockback).

It must be decided now: it is the type of every field in the sim state buffer (TD-SYSTEM-BOUNDARY note 1) and of every value in move data, so changing it later rewrites the sim and every data file.

### Constraints
- **Engine:** Godot 4.7.2, pure GDScript sim; no Node, no PhysicsServer, no engine time scale in the sim (concept, mandatory architecture notes).
- **No allocation per tick** — the state is flat Packed arrays; snapshot < 1 ms.
- **Solo developer, new to Godot;** the rule set must be small enough to follow without tooling.
- **Data-driven:** frame data lives in external files authored by hand (Move Data Pipeline).
- **Knowledge gap:** the engine reference does not cover GDScript numeric semantics; behaviour must be proven by test, not assumed.

### Requirements
- Bit-identical sim state on two different PCs for the same inputs (LAN).
- The same replay file yields the same checksum every run, every machine (Tier −1 pass condition, CI).
- Sub-pixel smooth motion at 60 Hz (walk, dash, jump arcs, knockback).
- Arithmetic simple enough for hand-authored frame data and formulas.
- Sim tick ≤ 0.25 ms including snapshot and checksum (ruling 2026-11-01), so ~8 re-simulated ticks fit the ≤ 2.0 ms sim slice [E] (art bible §8.10) when rollback arrives.

## Decision

**Fixed-point integers everywhere in the sim; float only in presentation.**

1. **Sim units.** Lengths are integers in **sim units, 1 m = 10,000 su** (0.1 mm). Positions are `su`; velocities are `su/tick`; accelerations (gravity) are `su/tick²`. A standing Operator (~1.2 m, art bible §8.7) is ~12,000 su; a 10 m stage is 100,000 su. *Why decimal and not a power of two:* frame data is typed by hand; `5000` is half a metre at a glance, and nothing in the sim needs bit-shift speed.
2. **Ratios** (damage scaling, knockback multipliers, proration) are integers in **permille (‰, 1000 = 1.0×)**. Multiply-then-divide: `value * ratio_permille / 1000` through the shared rounding helper (rule 5).
3. **Time** is integer ticks (already in the concept: 99 s = 5940 ticks).
4. **Resources and counters** (HP, SP, Ultimate gauge, hit-stop, freeze counters, combo count) stay integers in their own units, as the concept already requires.
5. **One rounding rule.** All sim division goes through `SimMath.div_floor(a, b)` (floor toward −∞) and `SimMath.mod_floor(a, b)`. **Amendment A1 (user-approved 2026-11-10):** both guard `b == 0` in **every** build and return `ZERO_DIVISOR_RESULT = 0`; the engine's division operator never receives 0. Raw `/` and `%` on possibly-negative operands are forbidden in sim code: `/` truncates toward zero and `%` takes the dividend's sign [tested-4.7.2]. Floor is chosen because it has no bias or discontinuity at 0, which suits positions. **It is not mirror-symmetric** (`div_floor(-5, 2) = -3` but `-div_floor(5, 2) = -2`), hence rule 5a.
   **5a. Facing-local magnitudes (binding).** Every facing-dependent quantity (knockback, move displacement, velocity scaling, box offsets) is computed as a **non-negative magnitude in facing-local space**, and the facing sign (`+1` / `-1`) is applied **last**: `world_dx = facing * magnitude`. No division or ratio is ever applied to a signed world-space value. Otherwise a left-facing character would get ±1 su different results from a right-facing one: a fairness bug, not a desync.
6. **Geometry is axis-aligned integer boxes, centre plus half-extents.** Hitbox / hurtbox / pushbox / throwbox are `(cx, cy, hw, hh)` in su, relative to the character origin, with `hw, hh > 0`. Mirroring for facing is `cx' = -cx` (per rule 5a: authored facing right, sign applied last). **Overlap is strict** (ruling 2026-11-01): A and B overlap iff `absi(A.cx - B.cx) < A.hw + B.hw` **and** `absi(A.cy - B.cy) < A.hh + B.hh`; boxes that only touch at an edge do not hit. Overlap tests are integer comparisons only. No rotation, no circles, no square roots. If an angle is ever needed, it uses a precomputed integer lookup table shipped as data, never `sin`/`cos`.
7. **Randomness** uses a project-owned integer PRNG whose state is a field in the sim buffer. **Amendment A1 (user-approved 2026-11-10):** the algorithm is **xorshift128+ (Vigna, shifts 23/18/5)**, result `s0 + s1` taken before the state update, with two state words `rng_s0`, `rng_s1`. `SimRng.seed(b, slot, seed)` expands any `int` seed with **splitmix64** (two consecutive outputs → `rng_s0`, `rng_s1`), then `ensure_nonzero`: if both words are 0, `rng_s0 = NONZERO_FALLBACK = -7046029254386353131` (`0x9E3779B97F4A7C15`), in every build. Golden sequences: `tests/unit/sim_core/sim_core_rng_test.gd`. `randi()`, `randf()`, `RandomNumberGenerator` and global RNG are forbidden in sim code (their cross-version stability is **[unverified]**).
8. **Checksum** is a project-owned integer hash computed **word-wise**: FNV-1a-style, one XOR and one wrapping multiply **per int64 element** of the state buffer (not per byte), so its cost is one loop iteration per field and its golden values are well defined. Fallback if the GDScript loop misses V5: `HashingContext` (native MD5 / SHA-1) over `buffer.to_byte_array()`, stable by algorithm definition, at the cost of one allocation per tick (all targets are x86-64, so byte order is fixed). Never `hash()` (32-bit here, stability across versions **[unverified]**) or `Object.get_instance_id()`. The checksum iterates **arrays only**, never Dictionaries or instance IDs.
   **Bit-twiddling traps [tested-4.7.2]** for the PRNG and hash: `>>` is **arithmetic** (`-8 >> 1 == -4`), so a logical shift needs a mask `(x >> n) & ((1 << (64 - n)) - 1)`; `>>` on a negative *constant literal* is a parse error (variables are fine); shift counts wrap (`1 << 64 == 1`); hex literals above INT64_MAX fail to parse (`0xFFFFFFFFFFFFFFFF`, and the FNV-64 offset basis `0xcbf29ce484222325`) — write such constants as **signed decimal**. Wrapping 64-bit multiply works without error, so PCG / xorshift64* are viable.
9. **Storage: one buffer means one buffer.** The sim state buffer holds `int` fields only, in **one `PackedInt64Array`**, and it holds *all* sim state: positions, counters, the input-history ring, the hit-event buffer, projectile pools and PRNG state (TD-SYSTEM-BOUNDARY note 1). Snapshot, restore and checksum are operations on that single array. `PackedInt32Array` is **forbidden** for sim state: it truncates silently on assignment (`5000000000 → 705032704`) [tested-4.7.2]. No `float`, `Vector2`, `Vector3`, `Transform*`, `Basis`, `Color` or `Variant`-of-unknown-type in sim state.
10. **Presentation conversion is one-way.** The view reads sim ints and converts once: `float(x_su) / 10000.0` metres → `Vector3` for the node transform. Nothing computed in presentation is ever written back into sim state or used in a sim decision.
11. **Data loading.** **Every field the sim consumes is an integer** (su, ticks, permille, counts). Strings (move IDs, animation and VFX names) are mapped to integer IDs at load; presentation-only fields (shake strength, blend times, VFX names) live in a separate presentation table and never enter the sim. The file format is the Move Data Pipeline's choice; **if it is JSON**, numbers parse as `float` [tested-4.7.2], so the loader **range-checks the float first** (`absf(f) <= 2^53`), then asserts `f == floorf(f)`, then converts with `int()`, and rejects the file otherwise — out-of-range `int()` saturates silently, so the order matters. The **move-data version hash** (Replay header) is `SimHash` over the **converted sim fields only**, so a presentation tweak does not invalidate replays.

### Architecture Diagram

```
 move data files ──(loader: int(), assert integral, range)──▶ PackedInt arrays
                                                                    │
 input words (int) ──▶ ┌──────────── SIM (60 Hz, ints only) ────────────┐
                       │ state buffer: PackedInt64Array                  │
                       │ SimMath.div_floor / mod_floor / mul_permille    │
                       │ integer AABB overlap, integer PRNG, int hash    │
                       └───────────────┬─────────────────────────────────┘
                                       │ read-only, one-way
                                       ▼
                       ┌──────── PRESENTATION (floats OK) ───────────────┐
                       │ float(su) / 10000.0 → Vector3 node transforms   │
                       │ camera, animation seek, VFX, HUD                │
                       └─────────────────────────────────────────────────┘
```

### Key Interfaces

```gdscript
## Fixed-point helpers. Pure static functions; the only sanctioned way to divide in the sim.
class_name SimMath

const SU_PER_METER: int = 10_000
const PERMILLE: int = 1_000

## Floor division toward negative infinity. b == 0 returns ZERO_DIVISOR_RESULT (0), every build (A1).
static func div_floor(a: int, b: int) -> int

## Remainder with the sign of b (pairs with div_floor).
static func mod_floor(a: int, b: int) -> int

## value * ratio_permille / 1000, floored.
static func mul_permille(value: int, ratio_permille: int) -> int

## Presentation-only conversion (lives in view code, never called by the sim).
static func su_to_m(su: int) -> float
```

```gdscript
## Project-owned PRNG; state is two ints stored in the sim buffer.
class_name SimRng
static func next(state: PackedInt64Array, slot: int) -> int   # advances state in place
static func range_i(state: PackedInt64Array, slot: int, lo: int, hi_inclusive: int) -> int
```

```gdscript
## Project-owned checksum over the state buffer: one XOR + wrapping multiply per int64 word.
class_name SimHash
static func hash_words(buffer: PackedInt64Array) -> int
```

```gdscript
## Box overlap (rule 6): centre + half-extents in su, strict inequality. Lives in SimMath.
static func boxes_overlap(a_cx: int, a_cy: int, a_hw: int, a_hh: int,
		b_cx: int, b_cy: int, b_hw: int, b_hh: int) -> bool
```

Exact signatures are refined in the Sim Core & State GDD; the rules below are binding regardless.

### Implementation Guidelines
- Sim code **must** use only `int` for state and intermediate values.
- Sim code **must never** declare or compute `float`, `Vector2`, `Vector3`, `Transform2D/3D`, `Basis`, `Quaternion` or `Color`.
- Sim code **must never** call `sin`, `cos`, `sqrt`, `pow`, `exp`, `lerp`, `snapped`, `round`, `floor`, `ceil`, the **untyped** `abs`, `clamp`, `min`, `max` (they return Variant and can be float), or any float-returning built-in. The **typed** integer built-ins `clampi`, `mini`, `maxi`, `absi`, `signi` are allowed; `posmod` is allowed only with a positive divisor (otherwise `SimMath.mod_floor`).
- Sim code **must never** use raw `/` or `%` where either operand can be negative; use `SimMath.div_floor` / `mod_floor`. (Constant positive literals divided by positive literals are allowed only in `const` definitions.)
- Sim code **must never** call `randi`, `randf`, `randomize`, `RandomNumberGenerator`, `hash()`, `Time.*`, `OS.get_ticks_*` or read `delta`.
- Every move-data field the sim consumes **must** be an integer in su, ticks or permille; the loader **must** reject non-integral or out-of-range numbers, map strings to integer IDs, and keep presentation-only fields out of sim data.
- Facing-dependent math **must** use non-negative facing-local magnitudes with the facing sign applied last (rule 5a).
- Boxes **must** be `(cx, cy, hw, hh)` and overlap **must** use strict `<` (rule 6).
- Presentation **must** convert sim ints with `SimMath.su_to_m` (or equivalent) and **must never** write a converted or derived value back into sim state.
- Every new sim field **must** be an `int` slot in the state buffer (TD-SYSTEM-BOUNDARY note 1).
- GDScript warnings **INTEGER_DIVISION**, **NARROWING_CONVERSION** and the **UNSAFE_*** family **must** be set to Error for sim code (backs the grep; a grep for `/` alone is unreliable). Per-directory severity is **[unverified]** in 4.7; if it is not available, set them to Error **project-wide**. `project.godot` (checked 2026-11-10) sets them to Error **project-wide** with `treat_warnings_as_errors=true`; per-directory severity remains unverified and is not relied on.
- `SimMath.div_floor`, `mod_floor`, `mul_permille` and any allowed `const` literal division **must** carry `@warning_ignore("integer_division")` on the exact line; they are the only sanctioned `/` in sim code.
- A static check (grep in CI over `src/sim/`) **must** fail the build on the forbidden tokens above.
- Analogue input (sticks) **must** be quantised to ints at the input boundary (Input system), before it enters the sim.
- The sim **must** advance by its own tick counter, never by `delta`.

## Alternatives Considered

### Alternative 1: Controlled float (TD-FEASIBILITY recommendation)
- **Description**: Sim uses GDScript `float` (64-bit IEEE double: `0.1 + 0.2 == 0.30000000000000004` and `2^52 + 1` are exact [tested-4.7.2]) with a fixed operation order, no transcendental functions, and rounding/quantising positions at the end of each tick; `Vector2/3` avoided because of 32-bit `real_t`.
- **Pros**: Natural to write; formulas read like the design docs; no unit conversion for presentation; IEEE-754 basic ops are deterministic on one machine.
- **Cons**: Cross-machine bit-identity depends on things this project cannot see or test cheaply: compiler flags of the official export templates, x87 vs SSE paths, fused multiply-add contraction, operation reordering inside the engine's VM, and any built-in that is not correctly rounded. A single divergent bit is undetectable until a LAN desync. Quantising every tick still requires a rounding convention, so most of fixed-point's discipline is paid anyway. The engine reference cannot confirm any of it (NOT SOURCEABLE).
- **Rejection Reason**: Determinism across two different PCs is the core requirement and the hardest to debug; float makes it a property of the toolchain instead of the code. Fixed-point makes it a property of the code, which a solo developer can test and grep.

### Alternative 2: Hybrid — integer positions, float formulas
- **Description**: Positions and boxes are integers, but intermediate formula math (damage scaling, knockback curves) uses float and is rounded back to int.
- **Pros**: Positions are safe; formulas stay "natural".
- **Cons**: Every float→int rounding point is a place where two machines can disagree by one unit, and then positions diverge anyway. Two numeric regimes in one tick double the rules a programmer must remember.
- **Rejection Reason**: It keeps float's cross-machine risk at the exact points (damage, knockback) that decide matches, while adding a second set of rules. The permille convention covers every ratio the concept needs.

### Alternative 3: Power-of-two fixed-point (e.g. Q16.16)
- **Description**: Values stored with 16 fractional bits; multiply with shift.
- **Pros**: Classic, fast in native code; well-known.
- **Cons**: Hand-authored frame data becomes unreadable (`32768` = 0.5); GDScript gains nothing from shifts over integer division; the 64-bit `int` already gives ample range for a decimal scale.
- **Rejection Reason**: Readability of hand-typed data matters more than shift speed in an interpreted VM.

## Consequences

### Positive
- Determinism becomes a property of the code: greppable, unit-testable, independent of CPU, compiler flags and engine internals.
- Rollback-ready: snapshot is a copy of one `PackedInt64Array` (rule 9); checksum is a pure function of it.
- Frame data is exact and readable (su, ticks, permille); design docs can state formulas with integer variables and worked examples.
- A single conversion seam (sim → view) makes the sim/view-split ADR simpler.

### Negative
- Every formula needs explicit units and a rounding rule; designers must think in permille and su.
- Engine helpers (`Vector2.move_toward`, `lerp`, `clamp` on floats, physics queries) are unavailable in sim code; small integer helpers must be written and tested.
- Slight presentation cost: one int→float conversion per rendered transform per frame (negligible at two characters).
- Any future need for rotation or curved hitboxes requires integer lookup tables.

## Risks
- **R1 — GDScript `int` semantics change in a future engine version.** V1–V3 were tested on 4.7.2 only. *Mitigation:* V1–V3 run as CI unit tests; `SimMath` hides division semantics behind one tested function, so a surprise changes one file.
- **R2 — Accidental float in sim code** (a `0.5` literal, a `Vector2` local). *Mitigation:* CI grep for forbidden tokens over `src/sim/`; static typing on every sim variable; replay checksum in CI catches what grep misses.
- **R3 — JSON number parsing loses precision above 2^53 and `int()` saturates silently** [tested-4.7.2]. *Mitigation:* loader range-checks before converting (rule 11); all realistic values are < 2^31.
- **R4 — Overflow** in `value * ratio` chains. Overflow **wraps silently, with no runtime error** [tested-4.7.2], so debug asserts are the only guard. *Mitigation:* 64-bit range is ~9.2e18; worst realistic product (100,000 su × 10,000‰) is 1e9. `SimMath.mul_permille` and the hash/PRNG helpers assert operand ranges in debug builds.
- **R5 — Performance:** one tick including snapshot and checksum within ≤ 0.25 ms. The checksum loop is the largest GDScript cost and grows with buffer size. *Mitigation:* V5 measures it; word-wise hashing; `HashingContext` fallback (rule 8); keep the buffer small (expected well under 8,000 words).
- **R6 — Hand-written hash/PRNG constants** hit the shift and hex-literal traps (rule 8). *Mitigation:* golden-value tests (Validation 6).
- **R7 — Snapshots by assignment alias the live buffer.** *(Corrected 2026-11-01 from ADR-0002 testing; the earlier text assumed copy-on-write.)* `PackedInt64Array` is a reference type in GDScript: `var snap := buffer` shares the same data, so later writes change the "snapshot" too, and nothing is copied [tested-4.7.2]. *Mitigation:* a snapshot must be an explicit `buffer.duplicate()` (one native allocation + copy) or a copy into a preallocated ring buffer; the LAN / rollback ADR chooses between them on the cost measured in V5. No per-tick snapshot is taken until then.

## GDD Requirements Addressed

No system GDDs exist yet (Tier −1 designs from a prototype brief + ADRs; systems index, PR-SCOPE adjustment A). Requirements are taken from the concept and the systems index:

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| game-concept.md (Technical Considerations) | Sim 60 Hz fixed, input-only sync; all time in ticks | Integer ticks; integer state makes input-only sync sufficient |
| game-concept.md (Technical Considerations) | All resources and gameplay counters (HP, SP, Ultimate, time) are integers | Kept, and extended to all spatial math |
| game-concept.md (Technical Considerations) | Replay + per-tick checksum from Tier −1, in CI | Project-owned int hash over an int-only buffer |
| game-concept.md (Technical Considerations) | AI RNG seeded in state | Project-owned integer PRNG stored in the buffer |
| game-concept.md (Technical Considerations) | Hitboxes are per-frame data in external files; overlap in sim code; no engine physics | Integer AABBs in su, integer overlap tests, integral-only loader |
| systems-index.md (TD-SYSTEM-BOUNDARY note 2) | Numeric-model ADR is a hard prerequisite for Sim Core, Movement and Hit Detection GDDs | This ADR |

## Performance Implications
- **CPU**: Neutral vs float in GDScript (both are VM ops). Budget **≤ 0.25 ms per tick including snapshot and checksum** (ruling 2026-11-01), leaving room for ~8 re-simulated ticks in the ≤ 2.0 ms sim slice [E]; verified by V5.
- **Memory**: State buffer of 8-byte ints; well under 64 KB for two characters, projectiles and round state.
- **Load Time**: Negligible; one integrality pass over move data on load.
- **Network**: None directly (only input words are sent); makes desync detection by checksum exchange cheap.

## Migration Plan
None — no sim code exists. The Tier −1 spike starts with `SimMath`, `SimRng`, `SimHash` and the V1–V5 tests.

## Validation Criteria
1. **V1–V3 unit tests** (gdUnit4, `tests/unit/sim_core/`): 64-bit range and overflow behaviour; `div_floor` / `mod_floor` against a table of signed cases; JSON integer round-trip up to 2^53 (if JSON is the move-data format).
2. **Mirror test**: the same move performed by P1 facing right and P2 facing left yields exactly opposite world displacement, knockback and box positions, tick by tick. **Box test**: edge-touching boxes do not overlap; 1 su of overlap does.
3. **V4 cross-machine replay**: the same 10,000-tick replay file produces identical per-tick checksums on two different PCs (different CPU vendors if available), and on repeated runs in CI.
4. **V5 performance**: Tier −1 sim tick **≤ 0.25 ms including snapshot and checksum** on the development PC (Performance monitor), with no per-tick allocation. *Gate statistic (user decision 2026-11-10, sim-core AC-V3):* mean, p99 and p99.9 must each be ≤ 0.25 ms; the maximum is recorded but does not gate, since `MatchRunner` absorbs isolated OS-preempted ticks (ADR-0002 `MAX_CATCHUP_TICKS`).
5. **Static check**: the CI forbidden-token grep over `src/sim/` exists and has been seen to fail once on a planted `float`; a check that has never failed may not be checking anything.
6. **Golden values**: `SimRng` and `SimHash` produce committed golden sequences; a change fails the test.

## Related
- `design/gdd/game-concept.md` — Technical Considerations, mandatory architecture notes (TD-FEASIBILITY; `/design-review` 2026-10-31 fixed-point recommendation).
- `design/gdd/systems-index.md` — TD-SYSTEM-BOUNDARY notes 1–2; Tier −1 subset.
- `design/art/art-bible.md` §8.7 (Operator height ↔ sim units), §8.10 (sim ≤ 2.0 ms [E]).
- Next: sim/view-split ADR (depends on this one). **Hand-offs it must settle:** axis mapping (sim x to world X, sim y to world Y up, and the Z / lane value for the 2.5D plane); render interpolation between the previous and current tick for displays above 60 Hz (floats allowed there); and the snapshot strategy given that Packed arrays alias on assignment (R7). Settled in ADR-0002 (`docs/architecture/adr-0002-sim-view-split.md`).
