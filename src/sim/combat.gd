## Mirror-kit attack, defense and hit resolution. The pipeline calls each slot
## separately. Gather both contacts before applying damage so trades are symmetric.
const LIGHT: int = 4
const HEAVY: int = 8
const BLOCK: int = Movement.INPUT_BLOCK

static func base(p: int) -> int:
	return SimLayout.P_BASE + p * SimLayout.P_STRIDE

static func word(b: PackedInt64Array, p: int, ago: int = 0) -> int:
	var slot: int = posmod(b[SimLayout.H_TICK] - ago, SimLayout.INPUT_RING_TICKS)
	return b[SimLayout.IN_BASE + p * SimLayout.INPUT_RING_TICKS + slot]

static func attack(b: PackedInt64Array, kit: SimMoveData) -> void:
	for p: int in SimLayout.P_COUNT:
		var i: int = base(p)
		if b[i + SimLayout.PF_HITSTOP] > 0:
			continue
		var move: int = b[i + SimLayout.PF_ATK_ACTIVE]
		if move != 0:
			var duration: int = kit.move(move)["frames"]
			if b[i + SimLayout.PF_ATK_FRAME] < duration:
				b[i + SimLayout.PF_ATK_FRAME] += 1
				continue
			cancel(b, i)
		var held: int = word(b, p)
		var pressed: int = held & ~word(b, p, 1)
		if held & BLOCK or b[i + SimLayout.PF_HITSTUN] > 0 or b[i + SimLayout.PF_BLOCKSTUN] > 0:
			continue
		if pressed & (LIGHT | HEAVY):
			b[i + SimLayout.PF_ATK_ACTIVE] = 2 if pressed & HEAVY else 1
			b[i + SimLayout.PF_ATK_FRAME] = 1

static func cancel(b: PackedInt64Array, i: int) -> void:
	b[i + SimLayout.PF_ATK_ACTIVE] = 0
	b[i + SimLayout.PF_ATK_FRAME] = 0
	b[i + SimLayout.PF_CONNECTED] = 0

static func defense(b: PackedInt64Array) -> void:
	for p: int in SimLayout.P_COUNT:
		var i: int = base(p)
		if b[i + SimLayout.PF_HITSTOP] == 0:
			var can_guard: bool = b[i + SimLayout.PF_ATK_ACTIVE] == 0 and b[i + SimLayout.PF_HITSTUN] == 0
			b[i + SimLayout.PF_BLOCKING] = int(can_guard and (word(b, p) & BLOCK) != 0)

## Positive move ID for a hit, negative for a block, zero for no contact.
static func contact(b: PackedInt64Array, p: int, kit: SimMoveData) -> int:
	var i: int = base(p)
	var d: int = base(1 - p)
	var move: int = b[i + SimLayout.PF_ATK_ACTIVE]
	if move == 0 or b[i + SimLayout.PF_CONNECTED] != 0 or b[i + SimLayout.PF_HITSTOP] > 0:
		return 0
	var frame: int = b[i + SimLayout.PF_ATK_FRAME]
	var defender_move: int = b[d + SimLayout.PF_ATK_ACTIVE]
	var hurts: Array = kit.boxes(defender_move, b[d + SimLayout.PF_ATK_FRAME], "hurtboxes")
	for strike: Array in kit.boxes(move, frame, "hitboxes"):
		for hurt: Array in hurts:
			if _overlap(b, i, strike, d, hurt):
				return -move if b[d + SimLayout.PF_BLOCKING] != 0 else move
	return 0

static func resolve(b: PackedInt64Array, kit: SimMoveData) -> void:
	var hit0: int = contact(b, 0, kit)
	var hit1: int = contact(b, 1, kit)
	for p: int in SimLayout.P_COUNT:
		var i: int = base(p)
		if b[i + SimLayout.PF_HITSTOP] > 0:
			b[i + SimLayout.PF_HITSTOP] -= 1
		else:
			b[i + SimLayout.PF_BLOCKSTUN] = maxi(0, b[i + SimLayout.PF_BLOCKSTUN] - 1)
		var hit: int = hit0 if p == 0 else hit1
		b[SimLayout.HIT_BASE + p * SimLayout.HIT_STRIDE] = hit
		if hit != 0:
			b[i + SimLayout.PF_CONNECTED] = 1
	apply_hit(b, 0, hit0, kit)
	apply_hit(b, 1, hit1, kit)

static func apply_hit(b: PackedInt64Array, attacker: int, hit: int, kit: SimMoveData) -> void:
	if hit == 0:
		return
	var i: int = base(attacker)
	var d: int = base(1 - attacker)
	var move: Dictionary = kit.move(absi(hit))
	var stop: int = move["stop"]
	if hit < 0:
		stop = SimMath.div_floor(stop, 2)
		b[d + SimLayout.PF_BLOCKSTUN] = move["blockstun"]
	else:
		var damage: int = move["damage"]
		b[d + SimLayout.PF_HP] = maxi(0, b[d + SimLayout.PF_HP] - damage)
		b[d + SimLayout.PF_BLOCKSTUN] = 0
		cancel(b, d)
	b[i + SimLayout.PF_HITSTOP] = maxi(b[i + SimLayout.PF_HITSTOP], stop)
	b[d + SimLayout.PF_HITSTOP] = maxi(b[d + SimLayout.PF_HITSTOP], stop)

static func reset_player(b: PackedInt64Array, p: int, kit: SimMoveData) -> void:
	var i: int = base(p)
	cancel(b, i)
	b[i + SimLayout.PF_HP] = kit.max_hp()
	b[i + SimLayout.PF_HITSTOP] = 0
	b[i + SimLayout.PF_BLOCKSTUN] = 0
	b[i + SimLayout.PF_BLOCKING] = 0
	b[SimLayout.HIT_BASE + p * SimLayout.HIT_STRIDE] = 0

static func _overlap(b: PackedInt64Array, a: int, strike: Array, d: int, hurt: Array) -> bool:
	var ax: int = strike[0]
	var ay: int = strike[1]
	var dx: int = hurt[0]
	var dy: int = hurt[1]
	var aw: int = strike[2]
	var ah: int = strike[3]
	var dw: int = hurt[2]
	var dh: int = hurt[3]
	return SimMath.boxes_overlap(b[a + SimLayout.PF_X] + b[a + SimLayout.PF_FACING] * ax,
			b[a + SimLayout.PF_Y] + ay, aw, ah, b[d + SimLayout.PF_X] + b[d + SimLayout.PF_FACING] * dx,
			b[d + SimLayout.PF_Y] + dy, dw, dh)
