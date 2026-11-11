extends Node2D
## PLACEHOLDER main scene for the Tier −1 spike: two boxes driven by the sim through
## MatchRunner and SimView. P0 walks with A / D, P1 with Left / Right.
## Replaced by the real match scene (Presentation & Feel, Input GDDs).

## PLACEHOLDER camera (user decision 2026-11-11: narrow view, consistent with the 6 m
## max distance). Fixed width, no zoom: 6 m max distance + 2 × 0.25 m half body + 2 × 0.25 m
## margin = 7 m, so both full bodies are always on screen (183 px/m at 1280 wide).
## Follows the players' midpoint, clamped to the walls, snapped to whole pixels.
const VIEW_WIDTH_M: float = 7.0
const STAGE_HALF_M: float = 5.0
const SCREEN_W_PX: float = 1280.0
const FLOOR_Y_PX: float = 620.0
## Placeholder body box in metres (drawn as a ColorRect).
const BOX_M: Vector2 = Vector2(0.4, 1.2)
## Fixed seed for the placeholder match.
const MATCH_SEED: int = 1

const Combat = preload("res://src/sim/combat.gd")
var _hud := Label.new()
var _runner: MatchRunner
var _boxes: Array[ColorRect] = []
var _feedback := PlaceholderEventFeedback.new()
## Art spike (design/art/sprite-spec-2d.md): F2 boxes <-> sprites, F4 hurt/hit box overlay.
## First character (user 2026-11-11); its hand-drawn strips override the blockout per animation.
const SPRITE_DIR: String = "res://assets/characters/surtr"
const SPRITE_CHAR: String = "surtr"
const BLOCKOUT_DIR: String = "res://assets/characters/guard_blockout"
const BLOCKOUT_CHAR: String = "guard_blockout"
var sprite_mode: bool = false
var box_overlay: bool = false
var _sprites: Array[CharacterSprite] = []
var _overlay := Node2D.new()
## Current camera: screen pixels per metre and centre x in metres.
var _px_per_m: float = SCREEN_W_PX / VIEW_WIDTH_M
var _cam_x_m: float = 0.0


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
		box.size = BOX_M * _px_per_m
		add_child(box)
		_boxes.append(box)
	for p: int in 2:
		var spr := CharacterSprite.new()
		spr.player = p
		if not spr.load_character(SPRITE_DIR, SPRITE_CHAR, BLOCKOUT_DIR, BLOCKOUT_CHAR):
			break
		add_child(spr)
		_sprites.append(spr)
	sprite_mode = OS.get_cmdline_user_args().has("--sprites") and _sprites.size() == 2
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_runner.views.append(self)
	# PLACEHOLDER event-driven feedback (flash, shake, SFX, banners).
	_feedback.su_to_px = func(x_su: int, y_su: int) -> Vector2:
		return _to_screen(Vector2(x_su, y_su) / float(SimMath.SU_PER_METER))
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
	_hud.text = "%s     P1 %d HP  %s     P2 %d HP  %s     Score %d - %d\nP1  A/D   F Light   G Heavy   H Block       P2  Arrows   , Light   . Heavy   / Block
F2 boxes / sprites (PLACEHOLDER blockout)   F4 hurt / hit box overlay" % [
		status, view.hp(0), view.stance(0), view.hp(1), view.stance(1), view.wins(0), view.wins(1)]
	var feet_m: Array[Vector2] = []
	for p: int in _boxes.size():
		var x_su: float = float(view.pos_x_su(p))
		var y_su: float = float(view.pos_y_su(p))
		if not view.snap(p):
			x_su = lerpf(float(view.prev_pos_x_su(p)), x_su, alpha)
			y_su = lerpf(float(view.prev_pos_y_su(p)), y_su, alpha)
		feet_m.append(Vector2(x_su, y_su) / float(SimMath.SU_PER_METER))
	_update_camera(feet_m[0].x, feet_m[1].x)
	for p: int in _boxes.size():
		var feet: Vector2 = _to_screen(feet_m[p])
		_boxes[p].size = BOX_M * _px_per_m
		_boxes[p].position = feet - Vector2(_boxes[p].size.x * 0.5, _boxes[p].size.y)
		_boxes[p].visible = not sprite_mode
		if p < _sprites.size():
			_sprites[p].visible = sprite_mode
			_sprites[p].update_from(view, feet, _px_per_m)
	_overlay.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F2 and _sprites.size() == 2:
		sprite_mode = not sprite_mode
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F4:
		box_overlay = not box_overlay
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_R:
		if _runner != null and _runner.view != null and _runner.view.ended():
			_feedback.reset()
			_runner.start_match(MATCH_SEED, Time.get_ticks_usec())

## Camera: centre = midpoint of the feet, clamped so the view never passes a wall,
## snapped to whole screen pixels (no shimmer). Screen shake is applied on top by the
## feedback node as an offset.
func _update_camera(x0_m: float, x1_m: float) -> void:
	var half: float = VIEW_WIDTH_M * 0.5
	var centre: float = clampf((x0_m + x1_m) * 0.5, -STAGE_HALF_M + half, STAGE_HALF_M - half)
	_cam_x_m = roundf(centre * _px_per_m) / _px_per_m


## Sim metres (x right, y up from the floor) to screen pixels under the current camera.
func _to_screen(m: Vector2) -> Vector2:
	return Vector2(SCREEN_W_PX * 0.5 + (m.x - _cam_x_m) * _px_per_m, FLOOR_Y_PX - m.y * _px_per_m).round()


## Box draw on the overlay node (above boxes and sprites), in the same facing-local
## coordinates as contact tests: filled strike boxes in box mode; with F4, hurtbox
## (green) and hitbox (gold) outlines in either mode.
func _draw_overlay() -> void:
	if _runner == null or _runner.view == null:
		return
	var view: SimView = _runner.view
	for p: int in _boxes.size():
		var feet := _boxes[p].position + Vector2(_boxes[p].size.x * 0.5, _boxes[p].size.y)
		if not sprite_mode:
			for box: Array in view.hitboxes(p):
				_overlay.draw_rect(_box_rect(view, p, feet, box), Color.GOLD)
		if box_overlay:
			for box: Array in view.hurtboxes(p):
				_overlay.draw_rect(_box_rect(view, p, feet, box), Color(0.25, 0.85, 0.35), false, 2.0)
			for box: Array in view.hitboxes(p):
				_overlay.draw_rect(_box_rect(view, p, feet, box), Color.GOLD, false, 2.0)


func _box_rect(view: SimView, p: int, feet: Vector2, box: Array) -> Rect2:
	var scale_su: float = _px_per_m / float(SimMath.SU_PER_METER)
	var x: int = box[0]
	var y: int = box[1]
	var hw: int = box[2]
	var hh: int = box[3]
	var centre := feet + Vector2(view.facing(p) * x, -y) * scale_su
	var extent := Vector2(hw, hh) * scale_su
	return Rect2(centre - extent, extent * 2.0)
