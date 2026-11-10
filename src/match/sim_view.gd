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
