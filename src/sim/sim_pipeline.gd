class_name SimPipeline
## Composition root of the tick (sim-core rules 8-10, 13): calls every slot in the
## fixed order, with the freeze gate around block B. No Callables, no state.
## Systems that have no GDD yet are no-op slots. The AI slot is a PLACEHOLDER that
## draws once from the shared PRNG so replay checksums exercise PRNG state; the
## Arena init is a PLACEHOLDER until the Arena GDD.
## Adding, removing or reordering a slot changes results: architecture review + tests (rule 13).

const Combat = preload("res://src/sim/combat.gd")
const RoundFlow = preload("res://src/sim/round_flow.gd")
## PLACEHOLDER Arena: half-width of the stage, su (10 m stage).
const PLACEHOLDER_STAGE_HALF_SU: int = 50_000


## Per-system init hooks, same order as step (rule 13). Buffer is already zeroed.
static func init_all(b: PackedInt64Array, kit: SimMoveData) -> void:
	_placeholder_arena_init(b)
	RoundFlow.start(b, kit)


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
static func block_b(b: PackedInt64Array, kit: SimMoveData) -> void:
	if b[SimLayout.R_INTERVAL] > 0:
		RoundFlow.advance_interval(b, kit)
		return
	_placeholder_ai(b)            # AI writes its input word
	pass                          # command interpretation
	Movement.step(b)              # movement & state
	Combat.attack(b, kit)
	Combat.defense(b)
	pass                          # projectiles
	var was_stopped: int = 0
	for player: int in SimLayout.P_COUNT:
		if b[Combat.base(player) + SimLayout.PF_HITSTOP] > 0:
			was_stopped |= 1 << player
	Combat.resolve(b, kit)
	Movement.reactions(b, was_stopped, kit)
	pass                          # SP / skill / Ultimate
	RoundFlow.check(b)


## PLACEHOLDER (Opponent AI slot): draws once from the shared PRNG so its state is exercised.
static func _placeholder_ai(b: PackedInt64Array) -> void:
	SimRng.next(b, SimLayout.H_RNG_S0)


static func _placeholder_arena_init(b: PackedInt64Array) -> void:
	b[SimLayout.A_WALL_L] = -PLACEHOLDER_STAGE_HALF_SU
	b[SimLayout.A_WALL_R] = PLACEHOLDER_STAGE_HALF_SU
