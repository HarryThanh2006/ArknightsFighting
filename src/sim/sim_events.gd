class_name SimEvents
## Presentation event ring (sim-core rules 18-18f, F4-F7). The only writer of the
## ring and of the Event Control region (rule 18a). Records are
## (tick, seq, type, a0, a1, a2) at slot posmod(seq, EVENT_RING_ENTRIES).
## Static only; all state lives in the sim buffer, so it is snapshotted and checksummed.

## Event types. 0 is NONE (the zero-filled ring). Payloads per type are listed in
## design/gdd/sim-core.md rule 18 and the emitting GDDs; only HIT, BLOCK, KO,
## ROUND_START, ROUND_END and MATCH_END are emitted today.
const NONE: int = 0
## a0 = attacker + 2 × move_id, a1 = damage applied, a2 = contact point (pack_contact). Defender = 1 − attacker.
const HIT: int = 1
## As HIT; a1 = 0 (no chip damage).
const BLOCK: int = 2
const THROW_CONNECT: int = 3
const ULTIMATE_ACTIVATE: int = 4
const ULTIMATE_HIT: int = 5
## a0 = player KO'd.
const KO: int = 6
## a0 = result (0 draw → round replays, 1 P1, 2 P2), a1 = reason (REASON_*), a2 = round number.
const ROUND_END: int = 7
## a0 = round number.
const ROUND_START: int = 8
## a0 = winner (1 or 2), a1 = wins P1, a2 = wins P2.
const MATCH_END: int = 9
## Projectile contacts are observation events (rule 18c); not emitted until Projectiles exist.
const PROJECTILE_HIT: int = 10
const PROJECTILE_BLOCK: int = 11
## Observation: a move started (swing cue). a0 = player + 2 × move_id.
const ATTACK_START: int = 12
## Observation: once per attack, the tick after its active window ends with no HIT/BLOCK
## (never when blocked or interrupted). a0 = player + 2 × move_id.
const WHIFF: int = 13
const EVENT_TYPE_COUNT: int = 14

## ROUND_END reasons.
const REASON_KO: int = 0
const REASON_TIMEOUT: int = 1

## Class per type (rule 18a): 1 critical, 0 observation. Indexed only after a range check.
const EVENT_CLASS: Array[int] = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0]

## Contact point packing for one payload word (rule 18 "+ ×" convention), in half-su so
## the overlap centre needs no rounding: a2 = (x2 + CONTACT_X2_BIAS) + CONTACT_STRIDE × y2,
## valid for |x2| < 2^21 (stage ±50,000 su + reach gives |x2| ≤ 140,000).
const CONTACT_X2_BIAS: int = 1 << 21
const CONTACT_STRIDE: int = 1 << 22


## Packs a contact point given in half-su (x2 = 2x, y2 = 2y).
static func pack_contact(x2: int, y2: int) -> int:
	return (x2 + CONTACT_X2_BIAS) + CONTACT_STRIDE * y2


## Contact x in half-su from a packed HIT/BLOCK a2.
static func contact_x2(packed: int) -> int:
	return posmod(packed, CONTACT_STRIDE) - CONTACT_X2_BIAS


## Contact y in half-su from a packed HIT/BLOCK a2.
static func contact_y2(packed: int) -> int:
	return SimMath.div_floor(packed - posmod(packed, CONTACT_STRIDE), CONTACT_STRIDE)

## Index of each field in the array `read` returns.
const R_CURSOR: int = 0
const R_LOST: int = 1
const R_COUNT: int = 2
const R_OVERFLOW: int = 3
const R_CRIT_OVERFLOW: int = 4
const R_FAULT: int = 5


## Block A (rule 7 step 1): reset the per-tick accept counters. Emits nothing.
static func begin_tick(b: PackedInt64Array) -> void:
	b[SimLayout.EC_OBS_THIS_TICK] = 0
	b[SimLayout.EC_CRIT_THIS_TICK] = 0


## Rule 18a-18d: validate, apply the accept rule (F5), then write or count the drop.
## Debug diagnostics come after every state write (AC-P8).
static func emit(b: PackedInt64Array, type: int, a0: int, a1: int, a2: int) -> void:
	var tick: int = b[SimLayout.H_TICK]
	if type <= NONE or type >= EVENT_TYPE_COUNT or tick == 0:
		b[SimLayout.EC_SIM_FAULT] = 1
		_debug_report("invalid event emission: type %d at tick %d" % [type, tick])
		return
	var critical: bool = EVENT_CLASS[type] == 1
	var obs: int = b[SimLayout.EC_OBS_THIS_TICK]
	var crit: int = b[SimLayout.EC_CRIT_THIS_TICK]
	var room: bool = obs + crit < SimLayout.MAX_EVENTS_PER_TICK
	if not critical:
		room = room and obs < SimLayout.OBS_CAP
	if not room:
		b[SimLayout.EC_EVENT_OVERFLOW_COUNT] += 1
		if critical:
			b[SimLayout.EC_CRITICAL_OVERFLOW_COUNT] += 1
			b[SimLayout.EC_SIM_FAULT] = 1
			_debug_report("critical event dropped: type %d at tick %d" % [type, tick])
		return
	var seq: int = b[SimLayout.EC_EVENT_SEQ]
	var at: int = SimLayout.EV_BASE + posmod(seq, SimLayout.EVENT_RING_ENTRIES) * SimLayout.EVENT_WORDS
	b[at] = tick
	b[at + 1] = seq
	b[at + 2] = type
	b[at + 3] = a0
	b[at + 4] = a1
	b[at + 5] = a2
	b[SimLayout.EC_EVENT_SEQ] = seq + 1
	if critical:
		b[SimLayout.EC_CRIT_THIS_TICK] = crit + 1
	else:
		b[SimLayout.EC_OBS_THIS_TICK] = obs + 1


## Rule 18f consumer read: copies by value into `out` (cleared first) the surviving
## records with seq in [max(next_seq, event_seq − 208), event_seq − 1], in seq order,
## skipping any slot whose stored seq is not the expected one. Never writes `b`.
## Returns [cursor, lost, count, event_overflow_count, critical_overflow_count, sim_fault].
static func read(b: PackedInt64Array, next_seq: int, out: PackedInt64Array) -> PackedInt64Array:
	out.clear()
	var event_seq: int = b[SimLayout.EC_EVENT_SEQ]
	var first: int = maxi(next_seq, event_seq - SimLayout.EVENT_RING_ENTRIES)
	var count: int = 0
	for seq: int in range(first, event_seq):
		var at: int = SimLayout.EV_BASE + posmod(seq, SimLayout.EVENT_RING_ENTRIES) * SimLayout.EVENT_WORDS
		if b[at + 1] != seq:
			continue
		for k: int in SimLayout.EVENT_WORDS:
			out.append(b[at + k])
		count += 1
	return PackedInt64Array([event_seq, maxi(0, event_seq - SimLayout.EVENT_RING_ENTRIES - next_seq),
		count, b[SimLayout.EC_EVENT_OVERFLOW_COUNT], b[SimLayout.EC_CRITICAL_OVERFLOW_COUNT],
		b[SimLayout.EC_SIM_FAULT]])


## Debug-build diagnostic for an integrity fault (rule 18d "debug assert"). push_error, not
## assert(): an assert would stop the gdUnit run that must exercise these paths.
static func _debug_report(message: String) -> void:
	if OS.is_debug_build():
		push_error("SimEvents: " + message)
