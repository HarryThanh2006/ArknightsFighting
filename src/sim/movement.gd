class_name Movement
## Character Movement, Tier −1 subset (design/gdd/character-movement.md): walk,
## facing (with the attack / airborne lock), symmetric pushbox separation, stage
## walls and corner push-out. Runs in the "movement & state" slot. Static only.
## Jump and max distance are later steps (GDD § Tier −1 subset).
## shortcut: tuning values are consts here until the Move Data Pipeline / Operator
## Definitions exist; then they come from integer data validated before init.

## Walk speeds, su per tick, facing-local magnitudes (F1).
const WALK_FWD_SU: int = 340
const WALK_BACK_SU: int = 270
## Pushbox half-width, su (M11; Move Data per state later).
const PUSH_HW_SU: int = 2_500
## Start positions (Round & Match setup later).
const START_X_SU: int = 15_000

## Locomotion states (M5).
const MSTATE_GROUND: int = 0
const MSTATE_PREJUMP: int = 1
const MSTATE_AIR: int = 2
const MSTATE_LANDING: int = 3

## Derived states (M10); only the ones whose source fields exist today.
const DERIVED_STUN: int = 6
const DERIVED_IDLE: int = 0
const DERIVED_WALK: int = 1
const DERIVED_ATTACK: int = 2
const DERIVED_PREJUMP: int = 3
const DERIVED_AIR: int = 4
const DERIVED_LANDING: int = 5

## Input bits (PLACEHOLDER until the Input GDD fixes them, M3).
const INPUT_BLOCK: int = 16
const INPUT_LEFT: int = 1
const INPUT_RIGHT: int = 2


## Init hook: start positions and facing (P0 left facing +1, P1 right facing -1).
static func init(b: PackedInt64Array) -> void:
	for p: int in SimLayout.P_COUNT:
		var base: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE
		for offset: int in range(SimLayout.PF_X, SimLayout.PF_KB_DIR + 1):
			b[base + offset] = 0
		b[base + SimLayout.PF_HITSTUN] = 0
		var side: int = -1 if p == 0 else 1
		b[base + SimLayout.PF_X] = side * START_X_SU
		b[base + SimLayout.PF_FACING] = -side


## Movement slot (M17 steps 2-4, Tier −1 subset).
static func step(b: PackedInt64Array) -> void:
	var slot: int = posmod(b[SimLayout.H_TICK], SimLayout.INPUT_RING_TICKS)
	for p: int in SimLayout.P_COUNT:
		var base: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE
		if b[base + SimLayout.PF_HITSTOP] > 0:
			continue  # M4: no own advance during hit-stop
		b[base + SimLayout.PF_MSTATE_TICKS] += 1
		var vx: int = 0
		var d: int = derived(b, p)
		if (d == DERIVED_IDLE or d == DERIVED_WALK) and not (b[SimLayout.IN_BASE + p * SimLayout.INPUT_RING_TICKS + slot] & INPUT_BLOCK):
			var w: int = b[SimLayout.IN_BASE + p * SimLayout.INPUT_RING_TICKS + slot]
			var dir_world: int = (1 if w & INPUT_RIGHT else 0) - (1 if w & INPUT_LEFT else 0)
			var facing: int = b[base + SimLayout.PF_FACING]
			var dir_local: int = dir_world * facing
			if dir_local != 0:
				var speed: int = WALK_FWD_SU if dir_local > 0 else WALK_BACK_SU
				vx = facing * dir_local * speed  # M2: magnitude, sign last
		b[base + SimLayout.PF_VX] = vx
		b[base + SimLayout.PF_X] += vx
	resolve(b)
	update_facing(b)


## M13 bounds, M11 separation (F3), M14 corner push-out (F5). Order-independent in P0 / P1.
static func resolve(b: PackedInt64Array) -> void:
	var i0: int = SimLayout.P_BASE + SimLayout.PF_X
	var i1: int = SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_X
	var lo: int = b[SimLayout.A_WALL_L] + PUSH_HW_SU
	var hi: int = b[SimLayout.A_WALL_R] - PUSH_HW_SU
	b[i0] = clampi(b[i0], lo, hi)
	b[i1] = clampi(b[i1], lo, hi)
	var overlap: int = 2 * PUSH_HW_SU - absi(b[i1] - b[i0])
	if overlap <= 0:
		return
	var s: int = SimMath.div_floor(overlap + 1, 2)  # ceil(overlap / 2)
	var left: int = i0
	var right: int = i1
	if b[i0] > b[i1]:
		left = i1
		right = i0
	elif b[i0] == b[i1]:
		# F3 dx == 0 (setup error): each moves backward (-facing), slot-independent.
		b[i0] -= b[SimLayout.P_BASE + SimLayout.PF_FACING] * s
		b[i1] -= b[SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_FACING] * s
		b[i0] = clampi(b[i0], lo, hi)
		b[i1] = clampi(b[i1], lo, hi)
		return
	b[left] -= s
	b[right] += s
	# F5: the character pushed past its wall stays at the wall; the other takes the rest.
	if b[left] < lo:
		b[right] += lo - b[left]
		b[left] = lo
	if b[right] > hi:
		b[left] -= b[right] - hi
		b[right] = hi
	b[left] = clampi(b[left], lo, hi)


## M8: facing from dx unless locked (attacking or airborne). Reads both before writing either.
static func update_facing(b: PackedInt64Array) -> void:
	var x0: int = b[SimLayout.P_BASE + SimLayout.PF_X]
	var x1: int = b[SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_X]
	var f0: int = _next_facing(b, 0, x1 - x0)
	var f1: int = _next_facing(b, 1, x0 - x1)
	b[SimLayout.P_BASE + SimLayout.PF_FACING] = f0
	b[SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_FACING] = f1


static func _next_facing(b: PackedInt64Array, p: int, dx: int) -> int:
	var base: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE
	var current: int = b[base + SimLayout.PF_FACING]
	if b[base + SimLayout.PF_ATK_ACTIVE] != 0 or b[base + SimLayout.PF_MSTATE] == MSTATE_AIR:
		return current
	return facing_from_dx(dx, current)


## Sim-core EC-33: +1 if dx > 0, -1 if dx < 0, unchanged if dx == 0.
static func facing_from_dx(dx: int, current: int) -> int:
	if dx > 0:
		return 1
	if dx < 0:
		return -1
	return current


## M10 derived state for voluntary locomotion.
static func derived(b: PackedInt64Array, p: int) -> int:
	var base: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE
	if b[base + SimLayout.PF_HITSTUN] > 0 or b[base + SimLayout.PF_BLOCKSTUN] > 0:
		return DERIVED_STUN
	if b[base + SimLayout.PF_ATK_ACTIVE] != 0:
		return DERIVED_ATTACK
	match b[base + SimLayout.PF_MSTATE]:
		MSTATE_PREJUMP:
			return DERIVED_PREJUMP
		MSTATE_AIR:
			return DERIVED_AIR
		MSTATE_LANDING:
			return DERIVED_LANDING
	return DERIVED_WALK if b[base + SimLayout.PF_VX] != 0 else DERIVED_IDLE

## M16/F7: hit knockback moves the defender, block recoil moves the attacker.
static func reactions(b: PackedInt64Array, was_stopped: int, kit: SimMoveData) -> void:
	for p: int in SimLayout.P_COUNT:
		var i: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE
		var incoming: int = b[SimLayout.HIT_BASE + (1 - p) * SimLayout.HIT_STRIDE]
		var outgoing: int = b[SimLayout.HIT_BASE + p * SimLayout.HIT_STRIDE]
		if (was_stopped & (1 << p)) == 0:
			b[i + SimLayout.PF_HITSTUN] = maxi(0, b[i + SimLayout.PF_HITSTUN] - 1)
		if incoming > 0:
			b[i + SimLayout.PF_HITSTUN] = kit.move(incoming)["hitstun"]
			b[i + SimLayout.PF_KB_SPEED] = kit.move(incoming)["kb"]
			var opponent: int = SimLayout.P_BASE + (1 - p) * SimLayout.P_STRIDE
			b[i + SimLayout.PF_KB_DIR] = b[opponent + SimLayout.PF_FACING]
		elif outgoing < 0:
			b[i + SimLayout.PF_KB_SPEED] = kit.move(-outgoing)["recoil"]
			b[i + SimLayout.PF_KB_DIR] = -b[i + SimLayout.PF_FACING]
		if was_stopped & (1 << p) or b[i + SimLayout.PF_HITSTOP] > 0:
			continue
		var speed: int = b[i + SimLayout.PF_KB_SPEED]
		b[i + SimLayout.PF_X] += b[i + SimLayout.PF_KB_DIR] * speed
		b[i + SimLayout.PF_KB_SPEED] = maxi(0, speed - kit.kb_decel())
	resolve(b)
