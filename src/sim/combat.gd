## Mirror-kit attack, defense and hit resolution. The pipeline calls each slot
## separately. Gather both contacts before applying damage so trades are symmetric.
const LIGHT: int = 4
const HEAVY: int = 8
const BLOCK: int = Movement.INPUT_BLOCK
## H2 (provisional, tunable): a press stays usable while its age is <= this many live ticks.
## shortcut: const in code like Movement walk speeds; move to Input/Attack data once the Input GDD exists.
const BUFFER_TICKS: int = 6

static func base(p: int) -> int:
	return SimLayout.P_BASE + p * SimLayout.P_STRIDE

static func word(b: PackedInt64Array, p: int, ago: int = 0) -> int:
	var slot: int = posmod(b[SimLayout.H_TICK] - ago, SimLayout.INPUT_RING_TICKS)
	return b[SimLayout.IN_BASE + p * SimLayout.INPUT_RING_TICKS + slot]

static func attack(b: PackedInt64Array, kit: SimMoveData) -> void:
	for p: int in SimLayout.P_COUNT:
		var i: int = base(p)
		_buffer_press(b, p, i)
		if b[i + SimLayout.PF_HITSTOP] > 0:
			continue
		var move: int = b[i + SimLayout.PF_ATK_ACTIVE]
		if move != 0:
			var duration: int = kit.move(move)["frames"]
			if b[i + SimLayout.PF_ATK_FRAME] < duration:
				b[i + SimLayout.PF_ATK_FRAME] += 1
				continue
			cancel(b, i)
		if b[i + SimLayout.PF_HITSTUN] > 0 or b[i + SimLayout.PF_BLOCKSTUN] > 0:
			continue
		# First actionable tick: the buffered press starts, or is dropped if Block is held.
		var buffered: int = b[i + SimLayout.PF_BUF_MOVE]
		b[i + SimLayout.PF_BUF_MOVE] = 0
		b[i + SimLayout.PF_BUF_AGE] = 0
		if buffered != 0 and not (word(b, p) & BLOCK):
			b[i + SimLayout.PF_ATK_ACTIVE] = buffered
			b[i + SimLayout.PF_ATK_FRAME] = 1

## H2: age the buffered press, expire it after BUFFER_TICKS, store a fresh Light/Heavy edge
## (Heavy wins a same-tick press; the newest press replaces an older one).
static func _buffer_press(b: PackedInt64Array, p: int, i: int) -> void:
	if b[i + SimLayout.PF_BUF_MOVE] != 0:
		b[i + SimLayout.PF_BUF_AGE] += 1
		if b[i + SimLayout.PF_BUF_AGE] > BUFFER_TICKS:
			b[i + SimLayout.PF_BUF_MOVE] = 0
			b[i + SimLayout.PF_BUF_AGE] = 0
	var pressed: int = word(b, p) & ~word(b, p, 1)
	if pressed & (LIGHT | HEAVY):
		b[i + SimLayout.PF_BUF_MOVE] = 2 if pressed & HEAVY else 1
		b[i + SimLayout.PF_BUF_AGE] = 0

static func cancel(b: PackedInt64Array, i: int) -> void:
	b[i + SimLayout.PF_ATK_ACTIVE] = 0
	b[i + SimLayout.PF_ATK_FRAME] = 0
	b[i + SimLayout.PF_CONNECTED] = 0

static func defense(b: PackedInt64Array) -> void:
	for p: int in SimLayout.P_COUNT:
		var i: int = base(p)
		if b[i + SimLayout.PF_HITSTOP] == 0:
			var can_guard: bool = b[i + SimLayout.PF_ATK_ACTIVE] == 0 and b[i + SimLayout.PF_HITSTUN] == 0
			# D3: guard holds for the whole blockstun even if Block is released.
			var wants: bool = (word(b, p) & BLOCK) != 0 or b[i + SimLayout.PF_BLOCKSTUN] > 0
			b[i + SimLayout.PF_BLOCKING] = int(can_guard and wants)

## Positive move ID for a hit, negative for a block, zero for no contact.
static func contact(b: PackedInt64Array, p: int, kit: SimMoveData) -> int:
	var i: int = base(p)
	var d: int = base(1 - p)
	var move: int = b[i + SimLayout.PF_ATK_ACTIVE]
	if move == 0 or b[i + SimLayout.PF_CONNECTED] != 0 or b[i + SimLayout.PF_HITSTOP] > 0:
		return 0
	if _first_overlap(b, p, kit).is_empty():
		return 0
	return -move if b[d + SimLayout.PF_BLOCKING] != 0 else move

## First overlapping [strike, hurt] pair for attacker p this tick, or [].
static func _first_overlap(b: PackedInt64Array, p: int, kit: SimMoveData) -> Array:
	var i: int = base(p)
	var d: int = base(1 - p)
	var hurts: Array = kit.boxes(b[d + SimLayout.PF_ATK_ACTIVE], b[d + SimLayout.PF_ATK_FRAME], "hurtboxes")
	for strike: Array in kit.boxes(b[i + SimLayout.PF_ATK_ACTIVE], b[i + SimLayout.PF_ATK_FRAME], "hitboxes"):
		for hurt: Array in hurts:
			if _overlap(b, i, strike, d, hurt):
				return [strike, hurt]
	return []

## Contact x in su: midpoint of the x overlap of the first contacting box pair.
static func contact_x(b: PackedInt64Array, p: int, kit: SimMoveData) -> int:
	var pair: Array = _first_overlap(b, p, kit)
	var strike: Array = pair[0]
	var hurt: Array = pair[1]
	var s_x: int = strike[0]
	var s_hw: int = strike[2]
	var h_x: int = hurt[0]
	var h_hw: int = hurt[2]
	var i: int = base(p)
	var d: int = base(1 - p)
	var sx: int = b[i + SimLayout.PF_X] + b[i + SimLayout.PF_FACING] * s_x
	var hx: int = b[d + SimLayout.PF_X] + b[d + SimLayout.PF_FACING] * h_x
	var lo: int = maxi(sx - s_hw, hx - h_hw)
	var hi: int = mini(sx + s_hw, hx + h_hw)
	return SimMath.div_floor(lo + hi, 2)

static func resolve(b: PackedInt64Array, kit: SimMoveData) -> void:
	var hit0: int = contact(b, 0, kit)
	var hit1: int = contact(b, 1, kit)
	# Contact points are gathered before any write, like the contacts themselves.
	var x0: int = contact_x(b, 0, kit) if hit0 != 0 else 0
	var x1: int = contact_x(b, 1, kit) if hit1 != 0 else 0
	for p: int in SimLayout.P_COUNT:
		var i: int = base(p)
		if b[i + SimLayout.PF_HITSTOP] > 0:
			b[i + SimLayout.PF_HITSTOP] -= 1
		else:
			b[i + SimLayout.PF_BLOCKSTUN] = maxi(0, b[i + SimLayout.PF_BLOCKSTUN] - 1)
		var hit: int = hit0 if p == 0 else hit1
		b[SimLayout.HIT_BASE + p * SimLayout.HIT_STRIDE] = hit
		b[SimLayout.HIT_BASE + p * SimLayout.HIT_STRIDE + SimLayout.HR_CONTACT_X] = x0 if p == 0 else x1
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
	var applied: int = 0
	if hit < 0:
		stop = SimMath.div_floor(stop, 2)
		b[d + SimLayout.PF_BLOCKSTUN] = move["blockstun"]
	else:
		var damage: int = move["damage"]
		var hp_before: int = b[d + SimLayout.PF_HP]
		b[d + SimLayout.PF_HP] = maxi(0, hp_before - damage)
		applied = hp_before - b[d + SimLayout.PF_HP]
		b[d + SimLayout.PF_BLOCKSTUN] = 0
		cancel(b, d)
	b[i + SimLayout.PF_HITSTOP] = maxi(b[i + SimLayout.PF_HITSTOP], stop)
	b[d + SimLayout.PF_HITSTOP] = maxi(b[d + SimLayout.PF_HITSTOP], stop)
	# I5: one character contact event per attacker per tick (one record per attacker).
	SimEvents.emit(b, SimEvents.HIT if hit > 0 else SimEvents.BLOCK, attacker + 2 * absi(hit), applied,
			b[SimLayout.HIT_BASE + attacker * SimLayout.HIT_STRIDE + SimLayout.HR_CONTACT_X])

static func reset_player(b: PackedInt64Array, p: int, kit: SimMoveData) -> void:
	var i: int = base(p)
	cancel(b, i)
	b[i + SimLayout.PF_HP] = kit.max_hp()
	b[i + SimLayout.PF_HITSTOP] = 0
	b[i + SimLayout.PF_BLOCKSTUN] = 0
	b[i + SimLayout.PF_BLOCKING] = 0
	b[i + SimLayout.PF_BUF_MOVE] = 0
	b[i + SimLayout.PF_BUF_AGE] = 0
	b[SimLayout.HIT_BASE + p * SimLayout.HIT_STRIDE] = 0
	b[SimLayout.HIT_BASE + p * SimLayout.HIT_STRIDE + SimLayout.HR_CONTACT_X] = 0

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
