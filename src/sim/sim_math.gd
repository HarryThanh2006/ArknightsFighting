class_name SimMath
## Fixed-point integer helpers (ADR-0001 rules 1, 2, 5, 6). Pure static
## functions; the only sanctioned place for raw `/` and `%` in sim code.
## Presentation conversion (su -> metres, float) lives in view code, never here.

## Sim units per metre (ADR-0001 rule 1).
const SU_PER_METER: int = 10_000
## 1.0x as a permille ratio (ADR-0001 rule 2).
const PERMILLE: int = 1_000
## Result of div_floor / mod_floor when b == 0, guarded in every build (EC-33, AC-P7).
## Decided 2026-11-10 (ADR-0001 amendment A1).
const ZERO_DIVISOR_RESULT: int = 0
## Debug-only operand bound for mul_permille (ADR-0001 R4): |value|, |ratio| <= 2^31
## keeps value * ratio far below 2^63.
const MUL_OPERAND_LIMIT: int = 2_147_483_648


## Floor division toward negative infinity. Returns ZERO_DIVISOR_RESULT when b == 0.
## div_floor(INT64_MIN, -1) wraps to INT64_MIN (two's complement), like `*`.
static func div_floor(a: int, b: int) -> int:
	if b == 0:
		# Debug report deferred: a failed assert under gdUnit4 headless is unproven (AC-V5a).
		return ZERO_DIVISOR_RESULT
	if b == -1:
		return -a  # INT64_MIN / -1 is a hardware fault in C++; negation wraps instead.
	@warning_ignore("integer_division")
	var q: int = a / b
	if q * b != a and (a < 0) != (b < 0):
		q -= 1
	return q


## Remainder with the sign of b, pairing with div_floor: a == div_floor(a, b) * b + mod_floor(a, b).
## Returns ZERO_DIVISOR_RESULT when b == 0.
static func mod_floor(a: int, b: int) -> int:
	if b == 0:
		return ZERO_DIVISOR_RESULT
	if b == -1 or b == 1:
		return 0  # INT64_MIN % -1 is a hardware fault in C++.
	return posmod(a, b)  # floor-mod for any non-zero b [Measured 4.7.2, sim-core rule 15a].


## value * ratio_permille / 1000, floored. Apply facing signs after, never before (ADR-0001 rule 5a).
static func mul_permille(value: int, ratio_permille: int) -> int:
	var in_range: bool = absi(value) <= MUL_OPERAND_LIMIT and absi(ratio_permille) <= MUL_OPERAND_LIMIT
	assert(in_range, "SimMath.mul_permille operand out of range")
	return div_floor(value * ratio_permille, PERMILLE)


## Strict AABB overlap of two centre + half-extent boxes in su (ADR-0001 rule 6).
## Boxes that only touch at an edge do not overlap.
static func boxes_overlap(a_cx: int, a_cy: int, a_hw: int, a_hh: int,
		b_cx: int, b_cy: int, b_hw: int, b_hh: int) -> bool:
	return absi(a_cx - b_cx) < a_hw + b_hw and absi(a_cy - b_cy) < a_hh + b_hh
