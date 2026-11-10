extends Node2D
## PLACEHOLDER main scene for the Tier −1 spike: two boxes driven by the sim through
## MatchRunner and SimView. P0 walks with A / D, P1 with Left / Right.
## Replaced by the real match scene (Presentation & Feel, Input GDDs).

## Pixels per metre for the placeholder 2D draw (presentation-only float).
const PX_PER_M: float = 100.0
const BOX_SIZE: Vector2 = Vector2(40.0, 120.0)
const FLOOR_Y_PX: float = 500.0
const CENTRE_X_PX: float = 640.0
## Fixed seed for the placeholder match.
const MATCH_SEED: int = 1

var _runner: MatchRunner
var _boxes: Array[ColorRect] = []


func _ready() -> void:
	# Tooling hook: the Release V5 floor benchmark (exported builds ignore -s).
	if OS.get_cmdline_user_args().has("--v5-bench"):
		print(V5Bench.run())
		get_tree().quit()
		return
	_runner = MatchRunner.new()
	_runner.process_priority = -100  # ADR-0002: runner processes first
	_runner.input_sampler = _sample_input
	add_child(_runner)
	for c: Color in [Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9)]:
		var box := ColorRect.new()
		box.color = c
		box.size = BOX_SIZE
		add_child(box)
		_boxes.append(box)
	_runner.views.append(self)
	_runner.start_match(MATCH_SEED, Time.get_ticks_usec())


## Input sampling stand-in until the Input GDD: bit 0 = left, bit 1 = right.
func _sample_input(player: int) -> int:
	var left: Key = KEY_A if player == 0 else KEY_LEFT
	var right: Key = KEY_D if player == 0 else KEY_RIGHT
	var w: int = 0
	if Input.is_physical_key_pressed(left):
		w |= Movement.INPUT_LEFT
	if Input.is_physical_key_pressed(right):
		w |= Movement.INPUT_RIGHT
	return w


## Called by MatchRunner each frame (ADR-0002 rule 3.4): lerp prev -> curr unless snapped.
func update_view(view: SimView, alpha: float) -> void:
	for p: int in _boxes.size():
		var x_su: float = float(view.pos_x_su(p))
		var y_su: float = float(view.pos_y_su(p))
		if not view.snap(p):
			x_su = lerpf(float(view.prev_pos_x_su(p)), x_su, alpha)
			y_su = lerpf(float(view.prev_pos_y_su(p)), y_su, alpha)
		var m := Vector2(x_su, y_su) / float(SimMath.SU_PER_METER)
		_boxes[p].position = Vector2(CENTRE_X_PX + m.x * PX_PER_M - BOX_SIZE.x * 0.5,
			FLOOR_Y_PX - m.y * PX_PER_M - BOX_SIZE.y)
