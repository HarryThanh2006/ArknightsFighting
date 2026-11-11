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

const Combat = preload("res://src/sim/combat.gd")
var _hud := Label.new()
var _runner: MatchRunner
var _boxes: Array[ColorRect] = []
var _feedback := PlaceholderEventFeedback.new()


func _ready() -> void:
	# Tooling hook: the Release V5 floor benchmark (exported builds ignore -s).
	if OS.get_cmdline_user_args().has("--v5-bench"):
		print(V5Bench.run())
		get_tree().quit()
		return
	# Tooling hook: Debug vs Release replay parity (sim-core AC-X5).
	if OS.get_cmdline_user_args().has("--replay-check"):
		print(ReplayCheck.run())
		get_tree().quit()
		return
	add_child(_hud)
	_hud.position = Vector2(24, 24)
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
	# PLACEHOLDER event-driven feedback (flash, shake, SFX, banners).
	_feedback.su_to_px = func(x_su: int, y_su: int) -> Vector2:
		return Vector2(CENTRE_X_PX + float(x_su) / float(SimMath.SU_PER_METER) * PX_PER_M,
			FLOOR_Y_PX - float(y_su) / float(SimMath.SU_PER_METER) * PX_PER_M)
	_feedback.shake_target = self
	add_child(_feedback)
	_runner.views.append(_feedback)
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
	if Input.is_physical_key_pressed(KEY_F if player == 0 else KEY_KP_1) or (player == 1 and Input.is_physical_key_pressed(KEY_COMMA)):
		w |= Combat.LIGHT
	if Input.is_physical_key_pressed(KEY_G if player == 0 else KEY_KP_2) or (player == 1 and Input.is_physical_key_pressed(KEY_PERIOD)):
		w |= Combat.HEAVY
	if Input.is_physical_key_pressed(KEY_H if player == 0 else KEY_KP_3) or (player == 1 and Input.is_physical_key_pressed(KEY_SLASH)):
		w |= Combat.BLOCK
	return w


## Called by MatchRunner each frame (ADR-0002 rule 3.4): lerp prev -> curr unless snapped.
func update_view(view: SimView, alpha: float) -> void:
	var status: String = "Round %d   %ds" % [view.round_number(), ceili(view.clock_ticks() / 60.0)]
	if view.ended():
		status = "P%d wins the match   [R] Rematch" % view.result()
	elif view.interval():
		status = "Draw - replay round" if view.result() == 0 else "P%d wins round" % view.result()
	_hud.text = "%s     P1 %d HP  %s     P2 %d HP  %s     Score %d - %d\nP1  A/D   F Light   G Heavy   H Block       P2  Arrows   , Light   . Heavy   / Block" % [
		status, view.hp(0), view.stance(0), view.hp(1), view.stance(1), view.wins(0), view.wins(1)]
	for p: int in _boxes.size():
		var x_su: float = float(view.pos_x_su(p))
		var y_su: float = float(view.pos_y_su(p))
		if not view.snap(p):
			x_su = lerpf(float(view.prev_pos_x_su(p)), x_su, alpha)
			y_su = lerpf(float(view.prev_pos_y_su(p)), y_su, alpha)
		var m := Vector2(x_su, y_su) / float(SimMath.SU_PER_METER)
		_boxes[p].position = Vector2(CENTRE_X_PX + m.x * PX_PER_M - BOX_SIZE.x * 0.5,
			FLOOR_Y_PX - m.y * PX_PER_M - BOX_SIZE.y)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_R:
		if _runner != null and _runner.view != null and _runner.view.ended():
			_feedback.reset()
			_runner.start_match(MATCH_SEED, Time.get_ticks_usec())

## Draw active strike boxes in the same facing-local coordinates as contact tests.
func _draw() -> void:
	if _runner == null or _runner.view == null:
		return
	var view: SimView = _runner.view
	var scale_su: float = PX_PER_M / float(SimMath.SU_PER_METER)
	for p: int in _boxes.size():
		for box: Array in view.hitboxes(p):
			var x: int = box[0]
			var y: int = box[1]
			var hw: int = box[2]
			var hh: int = box[3]
			var feet := _boxes[p].position + Vector2(BOX_SIZE.x * 0.5, BOX_SIZE.y)
			var centre := feet + Vector2(view.facing(p) * x, -y) * scale_su
			var extent := Vector2(hw, hh) * scale_su
			draw_rect(Rect2(centre - extent, extent * 2.0), Color.GOLD)
