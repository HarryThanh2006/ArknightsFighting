# AGENTS.md — handoff for coding agents (Codex and others)

Written 2026-11-10 at commit `bf025ea` (handoff from Claude Code). `CLAUDE.md` and
`.claude/` hold the full studio process (skills, agents, hooks); you do not need
them to continue the code, but the rules below come from them and still apply.

## Project in one paragraph

**Arknights – Operator Clash** (`project.godot` name "Arknights Operator Clash"):
a solo-developer, private, non-commercial fan 1v1 fighting game in **Godot 4.7.2 +
GDScript**. 2.5D (3D chibi characters on a 2D fight plane). The core is a
**deterministic 60 Hz integer simulation** with per-tick checksums and replays,
so two PCs (LAN, later rollback) and CI always compute bit-identical fights.
Owner: Harry (writes in Vietnamese; reply to him in Vietnamese).
Repo: `https://github.com/HarryThanh2006/ArknightsFighting` (private). Remote
`origin` is that repo; `upstream` is the template
(`Donchitos/Claude-Code-Game-Studios`) — **never push to `upstream`**.

## Where we are

- **Stage:** Tier −1 (foundation vertical slice). Pass condition: two people can
  play a match; the same replay gives the same checksum every run.
- **Done (code, all tested):** `SimMath`, `SimRng`, `SimHash`, `SimLayout`
  (state buffer), `Sim` + `SimPipeline` (tick pipeline), `MatchRunner` +
  `SimView` (scene bridge), `SimReplay` (record / playback), V5 benchmark,
  **Movement Tier −1 subset** (walk, facing with lock, pushbox, walls, corner).
- **Not started:** Input, Move Data Pipeline, Arena, Hit Detection & Damage,
  Attack (Light/Heavy), Defense (Block), Round & Match Flow, events
  (`SimEvents`), real presentation, LAN spike.
- **Tests:** 80/80 pass (gdUnit4, headless). CI (GitHub Actions, Linux, AMD EPYC
  runner) is green and replays a golden fixture recorded on Windows/Intel.

## Commands (godot is NOT on PATH — use the repo-local binary)

| Purpose | Command |
|---|---|
| Tests (all) | `Godot/godot.exe --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode` |
| Re-import after adding a `class_name` script | `Godot/godot.exe --headless --path . --import` (then commit `.godot/global_script_class_cache.cfg` and the new `.uid` files) |
| Smoke | `Godot/godot.exe --path . --headless --quit-after 5` |
| Run game | `Godot/godot.exe --path . --windowed --resolution 1280x720` (P0: A/D, P1: ←/→) |
| Release build | `Godot/godot.exe --headless --path . --export-release "Windows Desktop" build/windows/ArknightsFighting.exe` |
| Regenerate golden replay | `Godot/godot.exe --headless --path . -s res://tools/replay/make_golden_replay.gd` |
| V5 benchmark (Debug) | `Godot/godot.exe --headless --path . -s res://tools/bench/run_v5_bench.gd` |
| V5 benchmark (Release) | `build/windows/ArknightsFighting.console.exe --headless -- --v5-bench` (exported builds ignore `-s`) |

`Godot/` (180 MB editor binary) and `build/` are gitignored. Export templates
4.7.2 are installed in `%APPDATA%\Godot\export_templates\4.7.2.stable`.
Commands also live in `project.yaml` → `commands`.

## Code map

| Path | What |
|---|---|
| `src/sim/sim_math.gd` | `div_floor`, `mod_floor` (zero divisor → 0), `mul_permille`, strict `boxes_overlap` |
| `src/sim/sim_rng.gd` | splitmix64 seed → xorshift128+ (23/18/5); state = 2 buffer words |
| `src/sim/sim_hash.gd` | FNV-1a 64, word-wise, per-tick checksum |
| `src/sim/sim_layout.gd` | All buffer offsets (`const` only), `LAYOUT_VERSION` = 3, `TOTAL` = 1,624 ≤ 2,048 |
| `src/sim/sim.gd` | `Sim`: `init(seed)`, `step(w0, w1) -> checksum`, `snapshot()`, `restore()` |
| `src/sim/sim_pipeline.gd` | Block A, freeze gate, block B slot order (AI placeholder → … → Movement → … ) |
| `src/sim/movement.gd` | Movement Tier −1 subset |
| `src/match/match_runner.gd` | Integer-µs accumulator, injected clock, `MAX_CATCHUP_TICKS` 4, alpha |
| `src/match/sim_view.gd` | Read-only int accessors for presentation |
| `src/match/placeholder_match.gd/.tscn` | Main scene: two boxes; also `--v5-bench` hook |
| `src/replay/sim_replay.gd` | Text replay format, playback, first-mismatch tick |
| `tests/unit/{sim_core,match,movement}/`, `tests/integration/sim_core/` | gdUnit4 suites; golden replay fixture in `tests/integration/sim_core/fixtures/` |
| `tools/replay/`, `tools/bench/` | Fixture generator, V5 benchmark |

## Design documents (source of truth — read by section, they are long)

- `design/gdd/game-concept.md` — vision, pillars, MVP, tiers (mostly Vietnamese).
- `design/gdd/systems-index.md` — 23 systems, design order, ownership notes.
- `design/gdd/sim-core.md` — Sim Core GDD (Draft): buffer, tick, events, ACs.
- `design/gdd/character-movement.md` — Movement GDD (Draft, decisions 2026-11-10).
- `docs/architecture/adr-0001-sim-numeric-model.md` — integers only (Proposed, amendment A1).
- `docs/architecture/adr-0002-sim-view-split.md` — MatchRunner / SimView (Proposed).
- `production/qa/evidence/` — V4 cross-machine replay log, V5 benchmark, screenshots.
- `production/time-log.md` — Harry logs hours himself; do not edit.

## Hard rules for sim code (`src/sim/`) — break one and determinism breaks

1. **Integers only.** No `float`, `Vector2/3`, `sin/cos/sqrt/lerp/round/floor`,
   untyped `abs/min/max/clamp` (use `absi/mini/maxi/clampi`). Units: 1 m = 10,000 su;
   time in ticks; ratios in permille.
2. **No raw `/` or `%`** — use `SimMath.div_floor` / `mod_floor`; `posmod(x, D)` only
   with a positive named constant `D`.
3. **No `randi/randf/RandomNumberGenerator/hash()/Time/OS.get_ticks_*`/`delta`** in sim.
4. **All state in the one `PackedInt64Array` buffer** at offsets from `SimLayout`.
   Sim systems are `static func` + `const` only — no class-scope `var`, no signals,
   no Nodes, no Callables. Packed arrays **alias on assignment**: snapshots are
   `.duplicate()`.
5. **Each buffer region is written only by its owner system** (sim-core rule 5).
6. **Facing-local magnitudes, sign applied last** (`world = facing × magnitude`).
7. **Any `SimLayout` change ⇒ bump `LAYOUT_VERSION`, add the new fingerprint** in
   `tests/unit/sim_core/sim_core_layout_test.gd` (the failing test prints it),
   and **regenerate the golden replay in the same commit**. Any change to sim
   behaviour also changes the fixture — regenerate it and say why in the commit.
8. `project.godot` treats GDScript warnings as errors (integer division,
   narrowing, unsafe casts/calls). Avoid `as` casts from Variant; assign to typed vars.

## Working conventions

- Commits: Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`, `chore:`),
  body references the GDD/ADR section. Work on `main`, push to `origin main`
  after each green commit.
- Tests first; expected values come from an independent oracle (hand-computed or
  a separate implementation), never from the code under test. A new gate must be
  seen failing once.
- Ask Harry before design decisions (GDD content, ADR status, new values that are
  not in a GDD). Mark unconfirmed choices `[Proposed]`. Do not mark V4 / V5 or ADRs
  as passed / Accepted.
- Every value marked `PLACEHOLDER` in code is temporary until its owning GDD exists.

## Open items Harry has not decided / known gaps

- ADR-0001 and ADR-0002 are still **Proposed**; Sim Core and Movement GDDs are
  **Draft, not reviewed**.
- **V4 (cross-CPU replay): PARTIAL** — Intel recording matched on AMD CI once;
  needs repeated runs and real systems. **V5 (≤ 0.25 ms/tick): floor only**
  (Release median mean 19.4 µs, p99 29, p99.9 72) — most slots are empty.
- Layout placeholders to be replaced by their GDDs: `PF_ATK_ACTIVE` (16) and
  `PF_HITSTOP` (17) per player, `R_MATCH_OVER`, arena walls ±50,000 su, input bits
  (`Movement.INPUT_LEFT/RIGHT`), the AI-slot PRNG draw.
- Movement GDD question: should facing also lock in hitstun / blockstun / throw?
- No screenshot yet of the two boxes colliding (headless cannot press keys).
- Release vs Debug checksum parity (sim-core AC-X5) not yet run.

## Suggested next steps (Tier −1 order)

1. Draft the remaining Foundation GDDs (Hit Detection & Damage, Defense) —
   Tier −1 cap is ≤ 5 days total for Foundation GDDs; docs are already ~87 % of
   logged time, so keep them short.
2. Implement Hit Detection + Attack (Light/Heavy) + Defense (Block) Tier −1
   subsets, then Movement step 2 (knockback / pushback, GDD M16).
3. Round & Match Flow core (clock 5,940 ticks, KO, rounds), `SimEvents` ring.
4. LAN spike (1 week, UDP between 2 PCs, Hamachi).
