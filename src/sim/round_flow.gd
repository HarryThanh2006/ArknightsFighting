## First to two wins. A tied timeout or double KO replays the same round.
const Combat = preload("res://src/sim/combat.gd")
const ROUND_TICKS: int = 5940
const BETWEEN_ROUNDS: int = 90

static func start(b: PackedInt64Array, kit: SimMoveData) -> void:
	b[SimLayout.R_CLOCK] = ROUND_TICKS
	b[SimLayout.R_ROUND] = 1 + b[SimLayout.R_WINS_0] + b[SimLayout.R_WINS_1]
	b[SimLayout.R_RESULT] = 0
	for p: int in SimLayout.P_COUNT:
		Combat.reset_player(b, p, kit)
	Movement.init(b)

static func check(b: PackedInt64Array) -> void:
	b[SimLayout.R_CLOCK] -= 1
	var hp0: int = b[Combat.base(0) + SimLayout.PF_HP]
	var hp1: int = b[Combat.base(1) + SimLayout.PF_HP]
	if mini(hp0, hp1) > 0 and b[SimLayout.R_CLOCK] > 0:
		return
	# Both fighters in the mirror kit have the same maximum HP.
	var result: int = 0
	if hp0 != hp1:
		result = 1 if hp0 > hp1 else 2
		var score: int = SimLayout.R_WINS_0 + result - 1
		b[score] += 1
		if b[score] == 2:
			b[SimLayout.R_MATCH_OVER] = 1
	b[SimLayout.R_RESULT] = result
	if b[SimLayout.R_MATCH_OVER] == 0:
		b[SimLayout.R_INTERVAL] = BETWEEN_ROUNDS

static func advance_interval(b: PackedInt64Array, kit: SimMoveData) -> void:
	b[SimLayout.R_INTERVAL] -= 1
	if b[SimLayout.R_INTERVAL] == 0:
		start(b, kit)
		for p: int in SimLayout.P_COUNT:
			b[Combat.base(p) + SimLayout.PF_SNAP] = 1
