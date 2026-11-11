class_name SimView
extends RefCounted
## Read-only accessor for presentation (ADR-0002 rule 4, sim-core rule 22).
## Holds the Sim object, never its buffer, and returns plain ints. Only the
## accessors whose fields exist today are here; the rest arrive with their GDDs.

var _sim: Sim


func _init(sim: Sim) -> void:
	_sim = sim


## Current sim tick.
func tick() -> int:
	return _sim.buffer[SimLayout.H_TICK]


## Position this tick, su (PLACEHOLDER field until the Movement GDD).
func pos_x_su(player: int) -> int:
	return _sim.buffer[SimLayout.P_BASE + player * SimLayout.P_STRIDE + SimLayout.PF_X]


func pos_y_su(player: int) -> int:
	return _sim.buffer[SimLayout.P_BASE + player * SimLayout.P_STRIDE + SimLayout.PF_Y]


## Position at the start of this tick, su (for lerp with alpha, ADR-0002 rule 7).
func prev_pos_x_su(player: int) -> int:
	return _sim.buffer[SimLayout.P_BASE + player * SimLayout.P_STRIDE + SimLayout.PF_PREV_X]


func prev_pos_y_su(player: int) -> int:
	return _sim.buffer[SimLayout.P_BASE + player * SimLayout.P_STRIDE + SimLayout.PF_PREV_Y]


## True when this tick's motion is a discontinuous jump: draw curr without blending.
func snap(player: int) -> bool:
	return _sim.buffer[SimLayout.P_BASE + player * SimLayout.P_STRIDE + SimLayout.PF_SNAP] != 0


func freeze_ticks() -> int:
	return _sim.buffer[SimLayout.H_FREEZE_TICKS]

## Player and round values for the Tier -1 HUD.
func hp(p: int) -> int:
	return _sim.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_HP]

func wins(p: int) -> int:
	return _sim.buffer[SimLayout.R_WINS_0 + p]

func clock_ticks() -> int:
	return _sim.buffer[SimLayout.R_CLOCK]

func round_number() -> int:
	return _sim.buffer[SimLayout.R_ROUND]

func interval() -> bool:
	return _sim.buffer[SimLayout.R_INTERVAL] > 0

func ended() -> bool:
	return _sim.buffer[SimLayout.R_MATCH_OVER] != 0

func result() -> int:
	return _sim.buffer[SimLayout.R_RESULT]

func stance(p: int) -> String:
	var i: int = SimLayout.P_BASE + p * SimLayout.P_STRIDE
	if hp(p) == 0:
		return "KO"
	if _sim.buffer[i + SimLayout.PF_HITSTUN] > 0:
		return "Hit"
	if _sim.buffer[i + SimLayout.PF_BLOCKING] != 0 or _sim.buffer[i + SimLayout.PF_BLOCKSTUN] > 0:
		return "Block"
	match _sim.buffer[i + SimLayout.PF_ATK_ACTIVE]:
		1: return "Light"
		2: return "Heavy"
	return ""

func move_id(p: int) -> int:
	return _sim.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_ATK_ACTIVE]

func move_frame(p: int) -> int:
	return _sim.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_ATK_FRAME]

func facing(p: int) -> int:
	return _sim.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_FACING]

## Immutable facing-local boxes for this exact simulation frame.
func hitboxes(p: int) -> Array:
	return _sim.data.boxes(move_id(p), move_frame(p), "hitboxes")

## Rule 18f: copies by value into `out` the event records (6 ints each, see SimEvents)
## with seq ≥ next_seq still in the ring. Returns [cursor, lost, count,
## event_overflow_count, critical_overflow_count, sim_fault] (SimEvents.R_* indices).
## Read between steps only; the caller keeps the cursor outside the sim.
func events_since(next_seq: int, out: PackedInt64Array) -> PackedInt64Array:
	return SimEvents.read(_sim.buffer, next_seq, out)
