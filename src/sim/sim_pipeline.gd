class_name SimPipeline
## Composition root of the tick (sim-core rules 8-10, 13): calls every slot in the
## fixed order, with the freeze gate around block B. No Callables, no state.
## Systems that have no GDD yet are no-op slots; the two PLACEHOLDER slots exist only
## so replay checksums exercise input, the PRNG and position fields. They are not
## gameplay and are replaced when the Movement and Opponent AI GDDs land.
## Adding, removing or reordering a slot changes results: architecture review + tests (rule 13).

## PLACEHOLDER walk speed, su per tick (~3 m/s).
const PLACEHOLDER_WALK_SU: int = 500
## PLACEHOLDER half-width of the stage, su (5 m each side).
const PLACEHOLDER_STAGE_HALF_SU: int = 50_000
## PLACEHOLDER start x for P0 / P1, su.
const PLACEHOLDER_START_X_SU: int = 15_000
## PLACEHOLDER input bits: bit 0 = left, bit 1 = right.
const INPUT_LEFT: int = 1
const INPUT_RIGHT: int = 2


## Per-system init hooks, same order as step (rule 13). Buffer is already zeroed.
static func init_all(b: PackedInt64Array) -> void:
	_placeholder_movement_init(b)


## Block A (rule 8): always runs on a live or frozen tick.
static func block_a(b: PackedInt64Array, w0: int, w1: int) -> void:
	b[SimLayout.H_TICK] += 1
	b[SimLayout.EC_OBS_THIS_TICK] = 0
	b[SimLayout.EC_CRIT_THIS_TICK] = 0
	for p: int in SimLayout.P_COUNT:
		var base: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE
		b[base + SimLayout.PF_PREV_X] = b[base + SimLayout.PF_X]
		b[base + SimLayout.PF_PREV_Y] = b[base + SimLayout.PF_Y]
		b[base + SimLayout.PF_SNAP] = 0
	# Input slot (Input's own step once the Input GDD exists).
	var slot: int = posmod(b[SimLayout.H_TICK], SimLayout.INPUT_RING_TICKS)
	b[SimLayout.IN_BASE + slot] = w0
	b[SimLayout.IN_BASE + SimLayout.INPUT_RING_TICKS + slot] = w1


## Block B (rule 10): gated slots in fixed order, including the defense slot (10a).
static func block_b(b: PackedInt64Array) -> void:
	_placeholder_ai(b)            # AI writes its input word
	pass                          # command interpretation
	_placeholder_movement(b)      # movement & state
	pass                          # attack advance
	pass                          # defense (10a)
	pass                          # projectiles
	pass                          # hit resolution
	pass                          # reactions applied
	pass                          # SP / skill / Ultimate
	pass                          # round checks (clock, KO, timeout, match_over)


## PLACEHOLDER (Opponent AI slot): draws once from the shared PRNG so its state is exercised.
static func _placeholder_ai(b: PackedInt64Array) -> void:
	SimRng.next(b, SimLayout.H_RNG_S0)


static func _placeholder_movement_init(b: PackedInt64Array) -> void:
	b[SimLayout.P_BASE + SimLayout.PF_X] = -PLACEHOLDER_START_X_SU
	b[SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_X] = PLACEHOLDER_START_X_SU


## PLACEHOLDER (movement slot): walks each player left / right from this tick's input word.
static func _placeholder_movement(b: PackedInt64Array) -> void:
	var slot: int = posmod(b[SimLayout.H_TICK], SimLayout.INPUT_RING_TICKS)
	for p: int in SimLayout.P_COUNT:
		var w: int = b[SimLayout.IN_BASE + p * SimLayout.INPUT_RING_TICKS + slot]
		var dir: int = (1 if w & INPUT_RIGHT else 0) - (1 if w & INPUT_LEFT else 0)
		var i: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_X
		b[i] = clampi(b[i] + dir * PLACEHOLDER_WALK_SU, -PLACEHOLDER_STAGE_HALF_SU, PLACEHOLDER_STAGE_HALF_SU)
