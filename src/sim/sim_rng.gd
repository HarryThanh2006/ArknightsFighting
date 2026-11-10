class_name SimRng
## Project-owned PRNG (ADR-0001 rule 7): xorshift128+ (Vigna, shifts 23/18/5) whose two state words live
## in the sim buffer at `slot` and `slot + 1` (Sim Core header: H_RNG_S0, H_RNG_S1).
## Never randi / randf / RandomNumberGenerator in sim code.
## Constants are signed decimal: hex literals above INT64_MAX do not parse (ADR-0001 rule 8).

## splitmix64 increment 0x9E3779B97F4A7C15 as signed int64.
const SPLITMIX_GAMMA: int = -7046029254386353131
## splitmix64 multipliers 0xBF58476D1CE4E5B9 and 0x94D049BB133111EB as signed int64.
const SPLITMIX_MUL1: int = -4658895280553007687
const SPLITMIX_MUL2: int = -7723592293110705685
## PROPOSED (OQ-1, EC-31): state word written by ensure_nonzero when both words are 0.
## Same value as SPLITMIX_GAMMA; fixed here until the ADR-0001 amendment is Accepted.
const NONZERO_FALLBACK: int = -7046029254386353131


## Logical (unsigned) right shift; GDScript `>>` is arithmetic. 0 < n < 64.
static func _lsr(x: int, n: int) -> int:
	return (x >> n) & ((1 << (64 - n)) - 1)


## PROPOSED (OQ-1, EC-31): expands `seed_value` with splitmix64 (two successive outputs)
## into b[slot], b[slot + 1], then ensure_nonzero. Any int seed is valid, including 0, -1, INT64_MIN.
static func seed(b: PackedInt64Array, slot: int, seed_value: int) -> void:
	var x: int = seed_value
	for i: int in 2:
		x += SPLITMIX_GAMMA
		var z: int = x
		z = (z ^ _lsr(z, 30)) * SPLITMIX_MUL1
		z = (z ^ _lsr(z, 27)) * SPLITMIX_MUL2
		b[slot + i] = z ^ _lsr(z, 31)
	ensure_nonzero(b, slot)


## An all-zero xorshift state stays zero forever; replaces (0, 0) with (NONZERO_FALLBACK, 0).
## Runs in every build.
static func ensure_nonzero(b: PackedInt64Array, slot: int) -> void:
	if (b[slot] | b[slot + 1]) == 0:
		b[slot] = NONZERO_FALLBACK


## Advances the state in place and returns the next 64-bit value (any int, may be negative).
static func next(b: PackedInt64Array, slot: int) -> int:
	var s1: int = b[slot]
	var s0: int = b[slot + 1]
	var result: int = s0 + s1
	b[slot] = s0
	s1 ^= s1 << 23
	b[slot + 1] = s1 ^ s0 ^ _lsr(s1, 18) ^ _lsr(s0, 5)
	return result


## Uniform-ish int in [lo, hi_inclusive]; requires lo <= hi_inclusive (returns lo otherwise).
## shortcut: modulo bias up to span / 2^63, negligible for gameplay spans; use rejection sampling if a span nears 2^40.
static func range_i(b: PackedInt64Array, slot: int, lo: int, hi_inclusive: int) -> int:
	var span: int = hi_inclusive - lo + 1
	if span <= 0:
		return lo
	return lo + SimMath.mod_floor(_lsr(next(b, slot), 1), span)
