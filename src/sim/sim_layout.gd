class_name SimLayout
## Fixed layout of the single sim state buffer (sim-core rules 2-6a, F3, F4, F10).
## `const int`s only. Changing ANY constant requires bumping LAYOUT_VERSION and the
## golden fingerprint in tests/unit/sim_core/sim_core_layout_test.gd (rule 3).
## Sizes other than the two headers and the event ring are F3 estimates until each
## owning GDD fixes its fields. Snapshots are `buffer.duplicate()`: assignment aliases (ADR-0001 R7).

const LAYOUT_VERSION: int = 7
## Hard word limit (user decision 2026-11-09).
const SIM_BUFFER_WORD_BUDGET: int = 2_048

# --- Sim Core header (8 words, rule 6): absolute indices ---
const HDR_BASE: int = 0
const HDR_SIZE: int = 8
const H_TICK: int = 0
const H_FREEZE_TICKS: int = 1
const H_RNG_S0: int = 2
const H_RNG_S1: int = 3
const H_LAYOUT_VERSION: int = 4

# --- Event Control (8 words, rule 6a), written only by SimEvents ---
const EVC_BASE: int = 8
const EVC_SIZE: int = 8
const EC_EVENT_SEQ: int = 8
const EC_OBS_THIS_TICK: int = 9
const EC_CRIT_THIS_TICK: int = 10
const EC_EVENT_OVERFLOW_COUNT: int = 11
const EC_CRITICAL_OVERFLOW_COUNT: int = 12
const EC_SIM_FAULT: int = 13

# --- Per-player blocks (rule 5): b[P_BASE + p * P_STRIDE + PF_*] ---
const P_BASE: int = 16
const P_COUNT: int = 2
const P_STRIDE: int = 64
const PF_PREV_X: int = 0
const PF_PREV_Y: int = 1
const PF_SNAP: int = 2
# Movement fields (character-movement.md M1), offsets 3-15.
const PF_X: int = 3
const PF_Y: int = 4
const PF_VX: int = 5
const PF_VY: int = 6
const PF_FACING: int = 7
const PF_MSTATE: int = 8
const PF_MSTATE_TICKS: int = 9
const PF_KB_SPEED: int = 10
const PF_KB_DIR: int = 11
## 1 while PF_KB_SPEED is block recoil (defense.md D1: wall-clipped recoil transfers to the defender).
const PF_KB_RECOIL: int = 12
## Attack owns move ID, frame and contact latch.
const PF_ATK_ACTIVE: int = 16
## Remaining personal hit-stop, owned by Hit Detection.
const PF_HITSTOP: int = 17
const PF_ATK_FRAME: int = 18
const PF_CONNECTED: int = 19
const PF_HP: int = 20
const PF_HITSTUN: int = 21
const PF_BLOCKSTUN: int = 22
const PF_BLOCKING: int = 23
## Input buffer (hit-detection-damage.md H2): buffered move ID (0 none) and its age in live ticks.
const PF_BUF_MOVE: int = 24
const PF_BUF_AGE: int = 25

# --- Input history ring (F10): b[IN_BASE + p * INPUT_RING_TICKS + posmod(tick, INPUT_RING_TICKS)] ---
const IN_BASE: int = 144
const INPUT_RING_TICKS: int = 32

# --- Projectile pool (F3 estimate) ---
const PROJ_BASE: int = 208
const PROJ_CAP: int = 4
const PROJ_STRIDE: int = 16

# --- Hit-event buffer: (P_COUNT + PROJ_CAP) records ---
const HIT_BASE: int = 272
const HIT_CAP: int = 6
const HIT_STRIDE: int = 8
## Record word 1: contact point (midpoint of the first strike/hurt overlap) packed by SimEvents.pack_contact (half-su).
const HR_CONTACT_POS: int = 1

# --- Opponent AI (includes its own 2 PRNG words) ---
const AI_BASE: int = 320
const AI_SIZE: int = 32

# --- Round & Match ---
const ROUND_BASE: int = 352
const ROUND_SIZE: int = 16
## Round & Match state. Result codes: 0 draw, 1 player one, 2 player two.
const R_MATCH_OVER: int = 352
const R_CLOCK: int = 353
const R_WINS_0: int = 354
const R_WINS_1: int = 355
const R_ROUND: int = 356
const R_INTERVAL: int = 357
const R_RESULT: int = 358
## Per-player KO flags (sim-core I3): 0 -> 1 emits KO; reset at round start.
const R_KO_0: int = 359
const R_KO_1: int = 360

# --- Arena ---
const ARENA_BASE: int = 368
const ARENA_SIZE: int = 8
## Wall positions in su, written at init (Arena; PLACEHOLDER init until the Arena GDD).
const A_WALL_L: int = 368
const A_WALL_R: int = 369

# --- Presentation event ring (rule 18, F4) ---
const EV_BASE: int = 376
const EVENT_WORDS: int = 6
const MAX_EVENTS_PER_TICK: int = 16
const OBS_CAP: int = 7
const CATCHUP_RESERVE: int = 4
const ROLLBACK_WINDOW_TICKS: int = 8
const EVENT_RING_ENTRIES: int = 208

## End of the last region; the buffer is sized to exactly this once, at init.
const TOTAL: int = 1_624
