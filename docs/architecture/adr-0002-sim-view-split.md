# ADR-0002: Sim / View Split — One-Way Presentation of the Deterministic Sim

## Status
Proposed

## Date
2026-11-01

> **Amendment pending — 2D (2026-11-10).** The user decided the game is a 2D sprite fighter. The sim / view split itself (rules 1–5, 8, 9; MatchRunner, SimView, events, presentation clock) is **unchanged**. Clauses that assumed 3D and need a 2D amendment: rule 6 axis table (`Vector3`, fight plane `Z = 0`, camera on `+Z`, 20–30° yaw child) → likely `Node2D`, `X = x_su × px_per_su`, `Y = −y_su × px_per_su`; facing via the 3D root's `scale.x` → `flip_h` / `scale.x` on the sprite root; rule 7 poses via `AnimationMixer` manual processing + `seek(t, true)` on a 3D rig (W1) → frame selection by sim move id + frame (`AnimatedSprite2D.frame` or `AnimationPlayer` on `Sprite2D.frame`), re-verify W1 for that; **W6** mirrored-mesh / inverted-hull capture → a mirrored-sprite check (no winding or culling issue in 2D). Status stays Proposed.

## Last Verified
2026-11-01

## Decision Makers
User (solo developer); drafted via `/architecture-decision`; reviewed by godot-specialist (3 blocking findings revised in; semantics tested headless on 4.7.2) and technical-director (TD-ADR: CONCERNS, 4 required + 4 minor revisions applied, 2026-11-01).

## Summary
The deterministic integer sim (ADR-0001) has to be stepped at exactly 60 Hz and drawn by Godot nodes at any display rate, without anything in presentation ever influencing a sim result. This ADR decides: **a single `MatchRunner` node steps the pure-GDScript sim from its own fixed-timestep accumulator in `_process`; presentation reads the sim only through a read-only `SimView` and tick-stamped events, interpolates positions between the previous and current tick, snaps animation poses to the integer tick, and keeps all presentation time (slow-mo, shake, HUD tweens) on its own clock.**

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (GDScript) |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — 4.7 is post-LLM-cutoff (VERSION.md) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/animation.md`, `modules/rendering.md`, `modules/physics.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md`. Verified there: `AnimationPlayer` / `AnimationTree` extend `AnimationMixer` (4.3); `playback_active` → `AnimationMixer.active`, `method_call_mode` → `callback_mode_method`; 3D physics interpolation moved to SceneTree (4.6). **NOT SOURCEABLE in the reference:** `AnimationMixer` manual-process property / enum names and `seek()` update semantics; `_process` / `_physics_process` timing guarantees; `Time.get_ticks_usec()` monotonicity; Packed-array reference semantics. These were **tested headless on the installed `Godot/godot.exe` 4.7.2.stable.official, 2026-11-01** (godot-specialist) and are marked **[tested-4.7.2]**; `Time.get_ticks_usec()` monotonicity and rendering of mirrored meshes stay **[unverified]**. |
| **Post-Cutoff APIs Used** | `AnimationMixer.callback_mode_process = ANIMATION_CALLBACK_MODE_PROCESS_MANUAL` (base-class property, 4.3+) and `seek(t, true)` [tested-4.7.2]. Nothing else post-cutoff. |
| **Verification Required** | W1 manual processing + `seek(t, true)` shows the exact keyed pose for an integer-tick time with no auto-advance [tested-4.7.2: 121/121 ticks exact with NEAREST keys at `k/60.0`; `seek(t, false)` does **not** apply the pose; `active = false` leaves the pose stale]; re-run as a CI test. W2 `PackedInt64Array` is a **reference type** in GDScript: `var b := a` aliases, writes are visible through every reference and cost no copy; only `.duplicate()` copies [tested-4.7.2] — re-run as an aliasing test (Validation 2). W3 `Time.get_ticks_usec()` is independent of `Engine.time_scale` [tested-4.7.2]; monotonicity **[unverified]** (OS high-resolution clock). W4 the accumulator advances exactly 36,000 ticks in 600 s of wall time (no drift, including after an injected hitch) and never more than the catch-up cap per frame. W5 at 60 Hz and 144 Hz, interpolated motion shows no judder, including during a simulated stall (retained captures in `production/qa/evidence/`). W6 a mirrored box character (`scale.x = -1` on the root) with backface culling and an inverted-hull outline renders correctly under the project renderer (Forward+, D3D12 and Vulkan) [unverified; retained capture; prerequisite for the toon & outline shader ADR]. All run in the Tier −1 spike; W3 / W4 run against an injected fake clock (rule 2). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Sim Numeric Model) — **Proposed, must be Accepted before this ADR can be Accepted**. ADR-0001's R7 assumed copy-on-write snapshots; this ADR's W2 test shows Packed arrays alias instead (correction recorded in rule 9). |
| **Enables** | LAN Netcode / rollback ADR (uses the runner's manual tick control and the event-dedupe rule); toon & outline shader ADR (consumes the axis mapping and facing mirror); Presentation & Feel, Sim Core & State and HUD documents. |
| **Blocks** | Tier −1 vertical slice code that draws the sim (MatchRunner, character views, camera). No stories exist yet. |
| **Ordering Note** | Write and accept after ADR-0001. W1–W5 run in the first Tier −1 spike alongside ADR-0001's V1–V5. |

## Context

### Problem Statement
The sim is pure GDScript over one integer buffer (ADR-0001). Godot, by contrast, renders at the monitor's rate (60, 120, 144 Hz…), plays animation through `AnimationPlayer`, and invites gameplay code into `_process` with float `delta`. Three things must hold at once:

1. The sim advances **exactly** 60 ticks per second of wall time on every machine, and can be stepped several ticks in one frame (LAN input delay, replay fast-forward, rollback later) or held (pause, waiting for a LAN input).
2. Presentation may use floats, easing, slow-mo and shake freely, and **none of it can reach the sim** (registry: `float_in_sim`, `engine_time_in_sim`; `sim_state_buffer` is read-only to presentation).
3. Motion looks smooth on high-refresh monitors, while poses stay frame-exact so a player reads startup and active frames truthfully (art bible §5.4 rule 2, §8.8).

ADR-0001 also handed off three items to this ADR: axis mapping, render interpolation, and the snapshot strategy under copy-on-write arrays.

### Constraints
- **Registry stances (locked):** `sim_state_buffer` — presentation reads only; `float_in_sim`; `engine_time_in_sim`; `sim-core` ≤ 0.25 ms per tick.
- **Concept (mandatory architecture notes):** sim is pure GDScript (no Node, no PhysicsServer), stepped manually several times per frame when needed; hit-stop is a sim counter; slow-mo is presentation only; the Ultimate cinematic freeze is held by the sim and the camera only reads it.
- **Art bible:** Operators face the other way by mirroring the root on world X (§5.5, §8.9); animation keys sit on integer ticks and playback seeks to `tick / 60.0` (§8.8); the HUD runs on unscaled presentation time and is never shaken or slowed (§7.2).
- **Solo developer:** one obvious place where the sim meets the scene tree.

### Requirements
- Exactly 60 sim ticks per wall-clock second, no drift; a bounded catch-up after a hitch.
- Manual control of how many ticks to step per frame, including zero.
- One-way data flow: sim → view; presentation never writes sim state or influences a sim decision.
- Smooth positions above 60 Hz; poses that show the exact keyed frame of the current tick.
- Presentation events (hit sparks, SFX, camera shake) fire once per sim event, even if the sim is stepped several ticks in one frame, or re-simulated later.

## Decision

### 1. The sim is not a Node; one `MatchRunner` node is the bridge
The sim is a plain GDScript object graph (`RefCounted`) owning the ADR-0001 state buffer. Exactly **one** scene node, `MatchRunner`, holds it. `MatchRunner` is the only code that calls `sim.step()`, and the only code that hands sim data to presentation. No other node references the sim object.

### 2. Fixed-timestep accumulator in `_process`, in integer microseconds
`MatchRunner._process` ignores `delta`. It reads the current time in microseconds from an **injected clock** (a `Callable` or small clock object; the default is `Time.get_ticks_usec()`, allowed because this is outside the sim) and computes how many ticks are due **exactly**, with no float accumulator. The injected clock lets the timing tests run against a fake clock instead of real time (project rule: no time-dependent assertions).

```
elapsed_usec    = now_usec - match_start_usec - paused_usec
ticks_due_total = elapsed_usec * 60 / 1_000_000 - ticks_dropped    # integer floor
to_step         = mini(ticks_due_total - ticks_stepped, MAX_CATCHUP_TICKS)
ticks_dropped  += maxi(ticks_due_total - ticks_stepped - MAX_CATCHUP_TICKS, 0)
```

- `MAX_CATCHUP_TICKS = 4` per frame (tunable). If more were due (a long hitch, a debugger break), the excess is **dropped** by adding it to the integer `ticks_dropped` counter, so the match resumes at normal speed rather than fast-forwarding. *Never* shift `match_start_usec` by a tick count in microseconds: one tick is 16,666.67 µs, so that accumulates drift (godot-specialist finding B3). *Local and vs-AI only*; under LAN the stepping rule below applies.
- **Pause** stops stepping and freezes the accumulator: the paused duration is added to `paused_usec` (any microsecond offset is exact here).
- **Window focus loss** does not pause local matches by default (Godot keeps processing); the Menus & Select GDD decides whether focus loss opens the pause menu. `OS.low_processor_usage_mode` **must** stay off during matches, or `_process` stops being called while idle.
- `delta` is ignored **on purpose**: `_process` delta is scaled by `Engine.time_scale`.
- **LAN (delay-based, later):** a tick is stepped only when both players' input words for it are present; the runner stalls otherwise. The accumulator still bounds how far ahead it may run. Details belong to the LAN ADR; this ADR only guarantees the runner owns the step count.
- **Replay playback / CI:** the runner (or a headless test harness) may step as fast as possible with no accumulator at all — the sim does not know wall time exists.
- `Engine.time_scale` is **never changed** during a match (it would scale `delta` for every presentation node and invite drift); slow-mo is rule 7.

### 3. Frame order inside `MatchRunner._process` (fixed, explicit)
1. **Sample input** — the Input system reads devices and produces the current input word per player (outside the sim; analogue values already quantised, ADR-0001).
2. **Step** — the local input word sampled this frame is written for tick `T + D`, where `T` is the next tick to step and `D` is the input delay (`D = 0` locally and vs AI; the LAN ADR sets `D > 0` and supplies the remote word). Then, for each due tick whose inputs are all present, call `sim.step()`. During catch-up, the latest sampled word is used for every stepped tick. Button presses are **latched** between samples by the Input system, so a press and release inside one frame (below 60 fps, or on a frame that steps 0 ticks) is not lost; latching rules are fixed in the Input GDD.
3. **Alpha** — compute the interpolation fraction from the same dropped-tick-adjusted `elapsed_usec`: `alpha = clampf(float((elapsed_usec * 60) % 1_000_000) / 1_000_000.0, 0.0, 1.0)` (presentation float). **Whenever the sim is behind wall time after stepping — for any reason (catch-up cap, LAN stall waiting for inputs, debugger) — `alpha = 1.0`**, i.e. if `ticks_stepped < ticks_due_total` after step 2. Otherwise the fraction would keep cycling while the tick stays put, and characters would visibly jump backward once per tick period. Pause needs no special case: `elapsed_usec` freezes.
4. **View update** — `MatchRunner` calls each presentation component explicitly, in a fixed order: character views → camera → world VFX → HUD. No presentation node runs its own `_process` logic against the sim; order never depends on scene-tree order.
5. **Events** — consume new sim events (rule 5) and dispatch to VFX, SFX and HUD cues.

### 4. Presentation reads through `SimView`, never the raw buffer
`SimView` is a thin read-only accessor that holds a reference to the **sim object**, not to the `PackedInt64Array`, and returns plain `int`s: positions (current and previous tick, rule 6), facing, state and animation IDs, animation tick, hit-stop and freeze counters, HP / SP / Ultimate / skill timer values, round clock, round wins. Presentation **must not** obtain, store or pass on the buffer array (or any `PackedInt64Array` from the sim): `PackedInt64Array` is a **reference type** in GDScript [tested-4.7.2, W2], so any reference presentation holds **is the live sim buffer**, and a single write through it mutates sim state on one machine only — a silent desync and a breach of the one-way rule. There is no copy cost to guard against; the hazard is aliasing. `SimView` never exposes the array, and the CI grep (Validation 6) is the enforcement. Accessor names are fixed in the Sim Core & State GDD.

### 5. Events are tick-stamped and consumed once
The sim writes presentation-relevant events (hit, block, throw, skill start/end, Ultimate hit, KO, round end) into a fixed-size **event ring inside the state buffer**, each with `(tick, seq, type, args…)`. `seq` is a monotonically increasing **counter stored in the buffer** (deterministic, checksummed). **Ring size (binding minimum):** `MAX_EVENTS_PER_TICK × (MAX_CATCHUP_TICKS + ROLLBACK_WINDOW_TICKS + 1)`, with `ROLLBACK_WINDOW_TICKS = 8` reserved now (ADR-0001's ~8-tick rollback budget); the sim asserts in debug builds if a tick emits more than `MAX_EVENTS_PER_TICK`. Values are set in the Sim Core GDD. Presentation keeps `last_presented_tick` / `last_presented_seq` and dispatches only events newer than that, in order. Consequences:
- Stepping several ticks in one frame still fires every event once.
- **This watermark is the delay-based rule.** Under delay-based LAN no tick is ever re-simulated, so it is exact. Under rollback it would suppress re-simulated duplicates but also **silently drop** an event that first appears at an already-presented tick after a misprediction. The rollback ADR **must** replace it with reconciliation (cancel mispredicted cues, late-fire new ones); until then the claim is only "never double-fires and never misses under local, vs-AI and delay-based LAN play".
- Presentation never polls sim state transitions to infer events (no "HP went down, so play a hit") — that would double-fire or miss under catch-up.

### 6. Axis mapping and facing
| Sim | World (Godot, metres) | Note |
|---|---|---|
| `x` (su, + = stage right) | `X = x / 10000.0` | Stage centre is `x = 0`, world origin on the floor line (art bible §8.7) |
| `y` (su, + = up) | `Y = y / 10000.0` | Floor is `y = 0` |
| — (no z in the sim) | `Z = 0` for both Operators | The fight plane. Arena layers sit at `Z < 0` (behind); camera on `+Z` looking `−Z` |
| `facing` (`+1` = facing +x) | Operator root `scale.x = facing` | Mirror on world X only, at the root; the 20–30° yaw toward the camera lives on a child node and is never mirrored (art bible §5.5, §8.9) |

Conversion uses `SimMath.su_to_m` (ADR-0001 rule 10) in presentation code only.

### 7. Interpolation: positions blend, poses snap
- **Positions:** the sim keeps `prev_x`, `prev_y` per character as ordinary int fields in the buffer, copied from `x`, `y` at the start of each tick (a handful of ints, inside the 0.25 ms budget). The view draws `lerp(prev, curr, alpha)` in floats. During hit-stop and freeze `prev == curr`, so motion holds without special cases.
- **Snap flag:** the sim sets a per-character `snap` field on any discontinuous jump (round reset, throw swap, corner push-out over a set distance, teleport). When set, the view draws `curr` without blending for that tick.
- **Facing** changes apply on the tick, never blended.
- **Animation poses snap:** each character's `AnimationPlayer` stays `active = true` with `callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL`; each frame the view sets `assigned_animation` to the sim's current `anim_id` (when it changes) and calls `seek(anim_tick / 60.0, true)` — the `true` is required, `false` does not apply the pose [tested-4.7.2, W1]. Keys **must** sit at exactly `k / 60.0` with NEAREST interpolation (art bible §8.8), which returned the exact keyed pose for every tick tested. Poses are therefore the exact keyed pose of the current tick (held-pose style, truthful active frames).
- **No method or audio tracks** drive gameplay feedback: call-method and audio tracks are untested under manual `seek`, and presentation events come only from the event ring (rule 5).
- **Camera** follows interpolated positions; it reads the sim's freeze counter for the Ultimate push-in but never writes anything.
- **Latency accepted:** interpolation draws up to one tick (~16.7 ms) behind the newest sim state. Extrapolation is not used (it overshoots at hits and corners).

### 8. Presentation time is separate and never reaches the sim
Presentation keeps its own clock from real frame time for: camera shake, presentation slow-mo, VFX lifetimes, HUD tweens, menu animation. **Slow-mo** is a presentation time scale applied only to world-layer effects (VFX playback, camera ease) — never `Engine.time_scale`, never the sim, never the HUD (art bible §7.2). **Hit-stop** is the sim's own counter (ADR-0001 / concept) and is therefore exact and identical on both machines. Nothing in this clock is readable by sim code.

### 9. Snapshot strategy
**Presentation needs no snapshot.** Rule 4 (no retained references) and rule 7 (prev-tick position fields in the buffer) give the view everything it draws from the live buffer.

**Correction to ADR-0001's assumption (R7 there):** Packed arrays are **not** copy-on-write in GDScript 4.7.2 — assignment aliases [tested-4.7.2]. So a snapshot is never taken by assignment; it must be an explicit `buffer.duplicate()` (one native allocation + copy) or a copy into a preallocated ring buffer. Which of the two rollback uses is **deferred to the LAN / rollback ADR**, decided on the cost the Tier −1 spike measures (ADR-0001 V5). Until then nothing takes per-tick snapshots, so ADR-0001's no-allocation-per-tick constraint is met.

### Architecture Diagram

```
                 ┌──────────────────── MatchRunner (Node, _process) ────────────────────┐
 devices ─▶ Input│ 1 sample → input words                                              │
                 │ 2 step ×N (accumulator, ≤ MAX_CATCHUP)  ──▶  Sim (RefCounted)        │
                 │                                             one PackedInt64Array    │
                 │                                             events ring, prev_x/y   │
                 │ 3 alpha (float)                                                      │
                 │ 4 view.update(SimView, alpha) ◀── SimView (read-only ints) ◀────────┤
                 │ 5 events newer than last_presented ──▶ VFX / SFX / HUD cues          │
                 └──────────────────────────────────────────────────────────────────────┘
   Presentation: character roots (scale.x = facing), AnimationPlayer seek(tick/60),
                 camera, VFX, HUD — floats, own clock; nothing flows back up.
```

### Key Interfaces

```gdscript
## The only bridge between the scene tree and the sim.
class_name MatchRunner extends Node
const TICKS_PER_SECOND: int = 60
const MAX_CATCHUP_TICKS: int = 4
var clock_usec: Callable = Time.get_ticks_usec   # injected; tests pass a fake clock
func _process(_delta: float) -> void   # ignores delta; frame order per rule 3
```

```gdscript
## Read-only accessor; returns ints only; holds the sim object, never its buffer.
class_name SimView extends RefCounted
func tick() -> int
func pos_x_su(player: int) -> int
func pos_y_su(player: int) -> int
func prev_pos_x_su(player: int) -> int
func prev_pos_y_su(player: int) -> int
func snap(player: int) -> bool
func facing(player: int) -> int          # +1 / -1
func anim_id(player: int) -> int
func anim_tick(player: int) -> int
func freeze_ticks() -> int
func events_since(tick: int, seq: int, out: PackedInt64Array) -> int   # fills a preallocated array with event records (ints); returns count
```

```gdscript
## Presentation components implement this; MatchRunner calls them in a fixed order.
func update_view(view: SimView, alpha: float) -> void
```

Exact accessor sets are fixed in the Sim Core & State GDD; the rules above are binding.

### Implementation Guidelines
- In the scene tree, only `MatchRunner` **may** call `sim.step()` and hold the sim object. Outside the scene tree, the replay runner and tests under `tests/` may step the sim directly (rule 2).
- `MatchRunner` **must** compute due ticks from integer microseconds read through its injected clock (default `Time.get_ticks_usec()`), never by summing float `delta`.
- `alpha` **must** be 1.0 whenever the sim is behind wall time after stepping (cap, stall, debugger).
- The event ring **must** be at least `MAX_EVENTS_PER_TICK × (MAX_CATCHUP_TICKS + ROLLBACK_WINDOW_TICKS + 1)` entries; `seq` **must** be a buffer counter.
- `Engine.time_scale` **must never** be changed while a match is running.
- Presentation **must** read sim data only through `SimView` and **must never** store a sim `PackedInt64Array` in a member variable or keep it across frames.
- Presentation components **must not** implement `_process` / `_physics_process` logic that reads the sim; `MatchRunner` calls `update_view()` in the fixed order of rule 3.
- Presentation **must** trigger VFX, SFX and HUD cues only from sim events newer than `last_presented_(tick, seq)`, **never** by inferring events from state changes.
- Character views **must** apply `scale.x = facing` on the Operator root and keep camera yaw on a child node.
- Animation **must** be driven by seeking to `anim_tick / 60.0` with manual processing; `AnimationPlayer.play()` auto-advance **must not** be used for in-match character animation.
- Positions **must** be drawn as `lerp(prev, curr, alpha)` except when `snap` is set.
- Slow-mo **must** be a presentation-only time scale on world-layer effects; it **must never** affect the HUD or the sim.
- `MatchRunner` **must** count dropped catch-up ticks in an integer `ticks_dropped`, never by shifting the start time in microseconds.
- `OS.low_processor_usage_mode` **must** be off during matches; `physics/common/physics_interpolation` **must** stay off (nothing is physics-driven).
- `MatchRunner` **should** be processed first in the match scene (lowest `process_priority` value — lower values run first); belt-and-braces, since ordering is already explicit via `update_view()`.
- Character `AnimationPlayer`s **must** use `callback_mode_process = ANIMATION_CALLBACK_MODE_PROCESS_MANUAL`, stay `active = true`, and be posed with `seek(t, true)`.

## Alternatives Considered

### Alternative 1: `_physics_process` at 60 Hz
- **Description**: Set `physics_ticks_per_second = 60` and call `sim.step()` from `_physics_process`.
- **Pros**: Less code; the engine handles catch-up; familiar Godot idiom.
- **Cons**: The engine decides how many steps run per frame and how catch-up behaves (`max_physics_steps_per_frame`, behaviour not covered by the engine reference); LAN stalls, replay fast-forward and rollback re-simulation all need the step count under the game's control and would end up outside it anyway; the physics tick also drives unrelated engine work and a project setting the sim would silently depend on.
- **Rejection Reason**: Manual control of the tick count is a hard requirement (concept: "step thủ công nhiều lần mỗi frame"); splitting stepping between the engine and the runner would make two sources of truth.

### Alternative 2: One sim tick per rendered frame (vsync-locked)
- **Description**: Call `sim.step()` once in every `_process`.
- **Pros**: Simplest possible; no interpolation needed at 60 Hz.
- **Cons**: Game speed tracks the monitor (144 Hz runs 2.4× fast); a dropped frame slows the match; LAN peers with different monitors drift immediately.
- **Rejection Reason**: Breaks the "exactly 60 ticks per second on every machine" requirement.

### Alternative 3: Interpolate animation poses too
- **Description**: Seek animation to `(anim_tick - 1 + alpha) / 60.0`.
- **Pros**: Smoother limb motion on high-refresh monitors.
- **Cons**: Blurs the held-key-pose style (art bible §5.4); active frames no longer appear exactly on their tick, which weakens frame-truthful reading.
- **Rejection Reason**: Readability of startup and active frames outranks smoothness (Pillar 3).

### Alternative 4: Presentation reads a snapshot copy each frame
- **Description**: Copy the buffer (or the fields the view needs) into a presentation-owned array each frame.
- **Pros**: Strong isolation; presentation could even run on another thread later.
- **Cons**: A copy (allocation or GDScript loop) per frame for no current benefit; a stale copy is still a second source of truth.
- **Rejection Reason**: `SimView` accessors give the same isolation at no copy cost; snapshots are a rollback concern (rule 9).

### Alternative 5: Pluggable step source injected into `MatchRunner`
- **Description**: `MatchRunner` delegates "which ticks may be stepped now, and with which inputs" to an injected step source (local, LAN delay-based, LAN rollback, replay).
- **Pros**: The LAN ADR adds stepping policy without editing the runner; replay and local play share one runner.
- **Cons**: An extra abstraction before there is a second policy to justify it.
- **Rejection Reason**: Not rejected — **deferred**. Tier −1 has only local stepping; the injected clock (rule 2) is the first seam, and the LAN ADR is expected to introduce the step source when delay-based stepping arrives.

## Consequences

### Positive
- One seam: every interaction between the scene tree and the sim is in `MatchRunner` and `SimView`, so a determinism review reads two files.
- Exactly 60 ticks/s with no drift, bounded catch-up, and full manual control for LAN, replay and rollback.
- Smooth motion on any monitor; frame-exact poses; hit-stop and freeze need no special-casing in the view.
- Events can never double-fire from catch-up stepping or future re-simulation.
- Headless tests and CI can step the sim with no scene tree at all.

### Negative
- Up to one tick (~16.7 ms) of added visual latency from interpolation.
- Presentation code cannot use the usual "each node updates itself in `_process`" pattern for match visuals; `MatchRunner` must call components explicitly.
- The sim must maintain `prev_x/prev_y`, `snap`, the event ring and `anim_tick` purely for the view (a few int fields).
- Manual animation processing depends on post-cutoff `AnimationMixer` property names (verified on 4.7.2, W1; re-tested in CI so an engine bump cannot break it silently).

## Risks
- **R1 — `AnimationMixer` manual-process / seek behaviour changes in a later engine version** (verified on 4.7.2 only). *Mitigation:* W1 runs as a CI test. Note: `active = false` and `seek()` + `advance(0)` both leave the pose stale [tested-4.7.2] and are **not** fallbacks; the fallback is driving part transforms directly from baked track data.
- **R2 — Aliasing: presentation obtains a reference to the sim buffer and writes through it** (Packed arrays are reference types [tested-4.7.2]) — a one-machine desync with no error. *Mitigation:* rule 4; `SimView` never returns the array; CI grep (Validation 6); the replay checksum in CI catches any write that slips through.
- **R3 — Catch-up cap hides performance problems** (sim silently drops time when it can't keep up). *Mitigation:* the runner counts dropped ticks and shows them on the debug overlay; V5 / W4 measure.
- **R4 — Presentation sneaks state inference back in** ("HP decreased → hit spark"). *Mitigation:* guideline + code review; event-only rule documented in the Presentation & Feel GDD.
- **R5 — Interpolation across discontinuities** (smear on round reset, throw swap). *Mitigation:* the sim's `snap` flag; W5 capture covers a throw and a round reset.
- **R6 — Mirrored meshes render wrongly** (a negative-determinant transform flips winding; the inverted-hull outline relies on front-face culling) [unverified]. *Mitigation:* W6 before any production character art; fallback is the silhouette-only post outline already recorded in art bible §8.9.
- **R7 — Event ring overflow under catch-up** silently loses cues. *Mitigation:* binding minimum ring size (rule 5); debug assert on `MAX_EVENTS_PER_TICK`.

## GDD Requirements Addressed

No system GDDs exist yet (Tier −1 designs from a prototype brief + ADRs). Requirements are taken from the concept, systems index and art bible:

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| game-concept.md (Technical Considerations) | Sim is pure GDScript, stepped manually several times per frame; no engine time scale | Rules 1–2: sim is not a Node; `MatchRunner` steps N ticks from an integer accumulator; `Engine.time_scale` never changed |
| game-concept.md (Technical Considerations) | Hit-stop is a sim counter; slow-mo is presentation only; cinematic freeze held by the sim, camera only reads | Rules 7–8: hit-stop holds via `prev == curr`; slow-mo on a presentation clock; camera reads `freeze_ticks` |
| systems-index.md (TD-SYSTEM-BOUNDARY notes; Presentation layer) | Presentation reads the sim, never writes; consumes sim events by tick number so rollback cannot fire VFX/SFX twice | Rules 4–5: `SimView` read-only ints; tick-stamped event ring with `last_presented` dedupe |
| systems-index.md (TD-SYSTEM-BOUNDARY note 3) | Camera never owns max player distance; cinematic freeze written only by SP, Skills & Ultimate | Camera is a reader in rule 7; no sim state is owned by presentation |
| art-bible.md §5.5, §8.9 | Facing by mirroring the root on world X; yaw on a child node | Rule 6 axis table |
| art-bible.md §8.8 | Animation seeks to `tick / 60.0` with manual processing; keys on integer ticks | Rule 7: poses snap to `anim_tick / 60.0` |
| art-bible.md §7.2 | HUD runs on unscaled presentation time; never shaken or slowed | Rule 8: slow-mo applies to world-layer effects only |
| ADR-0001 (hand-offs) | Settle axis mapping, render interpolation, snapshot strategy | Rules 6, 7, 9 |

## Performance Implications
- **CPU**: Sim side adds a few int copies per tick (`prev_x/y`) and event writes — inside ADR-0001's 0.25 ms. Presentation side: one `lerp` and one `seek` per character per frame, plus event dispatch — negligible against the 5.0 ms render-CPU slice [E] (art bible §8.10).
- **Memory**: Event ring of fixed size inside the state buffer (minimum per rule 5, exact size in the Sim Core GDD); `events_since` fills a preallocated array, so the view allocates nothing per frame.
- **Load Time**: None.
- **Network**: None directly; the runner's stall-until-inputs rule is what the LAN ADR builds on.

## Migration Plan
None — no code exists. The Tier −1 spike builds `MatchRunner`, `SimView` and one box-character view first, then runs W1–W5.

## Validation Criteria
1. **W1 animation**: a test scene seeks an `AnimationPlayer` to each integer tick of a keyed clip with manual processing; captured poses match the keyed values exactly; no advance between frames.
2. **W2 aliasing**: a test obtains a reference to the sim buffer, writes through it, and asserts the sim buffer changed (documents the hazard); a second test asserts the CI grep in criterion 6 flags that code pattern.
3. **W3 / W4 timing** (against an injected fake clock, no real time): over 600 s of fake time the runner steps exactly 36,000 ticks; with an injected 500 ms hitch it steps at most `MAX_CATCHUP_TICKS` per frame, reports the dropped ticks, and `ticks_stepped + ticks_dropped` still equals `floor(elapsed_usec * 60 / 1e6)` exactly; pausing for 10 s does not change the tick count. **Stall case:** with inputs withheld (simulated LAN stall) for 30 ticks, `alpha` stays 1.0 and drawn positions never move backward.
4. **W5 smoothness**: retained 60 Hz and 144 Hz captures (or frame-time plots) of walking, a jump, a throw and a round reset show no judder and no smear across snaps (`production/qa/evidence/`). The 60 Hz run checks frames that step 0 or 2 ticks because of timer jitter.
5. **Event dedupe**: stepping 4 ticks in one frame that contain 2 hit events fires exactly 2 sparks and 2 SFX; re-stepping the same ticks from a restored state (test harness) fires none.
6. **Isolation check**: a CI grep over scene and view code (`src/view/` and any script that extends `Node`; paths per the architecture doc) fails if anything other than `MatchRunner` calls `step(` on the sim, or if view code references a `PackedInt64Array` obtained from the sim. The replay runner and `tests/` are outside the grep's scope by design.
7. **W6 mirrored rendering**: a retained capture of a mirrored box character with backface culling and an inverted-hull outline, on D3D12 and Vulkan, shows correct faces and an intact outline on both facings (`production/qa/evidence/`). Required before the toon & outline shader ADR is Accepted.

## Related
- Depends on: `docs/architecture/adr-0001-sim-numeric-model.md` (Proposed).
- `design/gdd/game-concept.md` — Technical Considerations, mandatory architecture notes.
- `design/gdd/systems-index.md` — TD-SYSTEM-BOUNDARY notes; Presentation layer rule.
- `design/art/art-bible.md` §5.4, §5.5, §7.2, §8.8, §8.9.
- Next: LAN Netcode / rollback ADR (snapshot strategy, LAN stepping); toon & outline shader ADR.
