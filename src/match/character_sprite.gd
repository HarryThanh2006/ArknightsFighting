class_name CharacterSprite
extends Node2D
## View-side 2D sprite driven only by SimView (design/art/sprite-spec-2d.md §4,
## ADR-0002). Picks an animation and drawing from sim state each frame; never
## writes to the sim. Strips and tick ranges come from the character's frames.cfg.

const ANIMS: PackedStringArray = ["idle", "walk", "light", "heavy", "block", "hit", "ko"]

var player: int = 0
var _sprite := Sprite2D.new()
var _textures: Dictionary = {}
var _ranges: Dictionary = {}
var _drivers: Dictionary = {}
var _loops: Dictionary = {}
var _px_per_m: float = 256.0
var _anim: String = ""
var _enter_state_ticks: int = 0
var _enter_tick: int = 0


## Loads `<dir>/frames.cfg` and, per animation, `<dir>/<name>_<anim>.png`, falling back to
## the strip in `fallback_dir` (blockout) when that animation is not drawn yet.
## Returns false on missing data.
func load_character(dir: String, char_name: String, fallback_dir: String = "", fallback_name: String = "") -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(dir.path_join("frames.cfg")) != OK:
		push_error("CharacterSprite: missing frames.cfg in " + dir)
		return false
	var w: int = cfg.get_value("canvas", "width")
	var h: int = cfg.get_value("canvas", "height")
	var ax: int = cfg.get_value("canvas", "anchor_x")
	var ay: int = cfg.get_value("canvas", "anchor_y")
	_px_per_m = cfg.get_value("canvas", "px_per_m")
	for anim: String in ANIMS:
		_textures[anim] = load(strip_path(dir, char_name, fallback_dir, fallback_name, anim))
		_ranges[anim] = cfg.get_value(anim, "ranges")
		_drivers[anim] = cfg.get_value(anim, "driver")
		_loops[anim] = cfg.get_value(anim, "loop")
	_sprite.centered = false
	_sprite.offset = Vector2(-ax, -ay)  # feet anchor at the node origin
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, w, h)
	add_child(_sprite)
	return true


## The strip to use for `anim`: the character's own if it exists, else the fallback's.
static func strip_path(dir: String, char_name: String, fallback_dir: String, fallback_name: String, anim: String) -> String:
	var own: String = dir.path_join("%s_%s.png" % [char_name, anim])
	if ResourceLoader.exists(own) or fallback_dir.is_empty():
		return own
	return fallback_dir.path_join("%s_%s.png" % [fallback_name, anim])


## Places the sprite at the feet point (screen px) and picks the drawing for this tick.
func update_from(view: SimView, feet_px: Vector2, screen_px_per_m: float) -> void:
	position = feet_px
	var s: float = screen_px_per_m / _px_per_m
	scale = Vector2(s * view.facing(player), s)
	var anim: String = _pick(view)
	if anim != _anim:
		_anim = anim
		_enter_state_ticks = view.state_ticks(player)
		_enter_tick = view.tick()
	var counter: int
	match _drivers[anim]:
		"move_frame":
			counter = view.move_frame(player)
		"tick":
			counter = view.tick() - _enter_tick
		_:
			counter = view.state_ticks(player) - _enter_state_ticks
	var ranges: Array = _ranges[anim]
	var loop: bool = _loops[anim]
	var idx: int = drawing_index(ranges, counter, loop)
	_sprite.texture = _textures[anim]
	var w: float = _sprite.region_rect.size.x
	_sprite.region_rect.position = Vector2(idx * w, 0)


## Animation priority (spec §4): KO → hit → block → attack → walk → idle.
func _pick(view: SimView) -> String:
	if view.hp(player) == 0:
		return "ko"
	if view.hitstun(player) > 0:
		return "hit"
	if view.blockstun(player) > 0 or view.guarding(player):
		return "block"
	match view.move_id(player):
		1: return "light"
		2: return "heavy"
	return "walk" if view.walking(player) else "idle"


## Index of the drawing whose [first, last] range holds `counter`; loops wrap over the
## summed range length; out-of-range counters clamp to the first / last drawing.
static func drawing_index(ranges: Array, counter: int, loop: bool) -> int:
	if loop:
		var last_range: Array = ranges[ranges.size() - 1]
		var first_range: Array = ranges[0]
		var first: int = first_range[0]
		var last: int = last_range[1]
		counter = first + posmod(counter - first, last - first + 1)
	for i: int in ranges.size():
		var r: Array = ranges[i]
		var hi: int = r[1]
		if counter <= hi:
			return i
	return ranges.size() - 1
