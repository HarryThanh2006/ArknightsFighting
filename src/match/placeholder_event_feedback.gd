class_name PlaceholderEventFeedback
extends Node2D
## PLACEHOLDER hit / block / KO / round feedback driven ONLY by the sim event ring
## (ADR-0002 rule 5, sim-core rule 18f). Presentation & Feel is not designed yet:
## every value here is a stand-in. Never writes to the sim.

const FLASH_SECONDS: float = 0.18
const SHAKE_SECONDS: float = 0.2
const SHAKE_PX: float = 7.0
const BANNER_SECONDS: float = 1.4
## Move id 2 is Heavy in the Tier −1 kit.
const HEAVY_ID: int = 2

## Maps a sim point (x, y in su) to a screen point (set by the owning scene).
var su_to_px: Callable = func(_x_su: int, _y_su: int) -> Vector2: return Vector2.ZERO
## Node shaken on a Heavy hit (presentation offset only).
var shake_target: Node2D

var _cursor: int = 0
var _out := PackedInt64Array()
## Live flashes as parallel arrays: position, colour, seconds left.
var _flash_pos := PackedVector2Array()
var _flash_col := PackedColorArray()
var _flash_left := PackedFloat32Array()
var _shake_left: float = 0.0
var _shake_rng := RandomNumberGenerator.new()
var _banner := Label.new()
var _banner_left: float = 0.0
var _sfx: Dictionary = {}


func _ready() -> void:
	_banner.position = Vector2(440, 200)
	_banner.add_theme_font_size_override("font_size", 64)
	add_child(_banner)
	_sfx["light"] = _player(_make_wav(220.0, 0.55, 0.12, 30.0))
	_sfx["heavy"] = _player(_make_wav(90.0, 0.45, 0.28, 14.0))
	_sfx["block"] = _player(_make_wav(600.0, 0.8, 0.07, 45.0))
	_sfx["ko"] = _player(_make_wav(160.0, 0.3, 0.7, 4.0))
	_sfx["swing_light"] = _player(_make_whoosh(0.12, 0.35, 0.6))
	_sfx["swing_heavy"] = _player(_make_whoosh(0.22, 0.15, 0.8))
	_sfx["whiff"] = _player(_make_whoosh(0.18, 0.08, 0.3))


## New match (fresh init): start reading from seq 0 again.
func reset() -> void:
	_cursor = 0
	_flash_pos.clear()
	_flash_col.clear()
	_flash_left.clear()
	_banner_left = 0.0


## MatchRunner view hook: drain new events, then advance the visuals.
func update_view(view: SimView, _alpha: float) -> void:
	var r := view.events_since(_cursor, _out)
	if r[SimEvents.R_CURSOR] < _cursor:
		_cursor = r[SimEvents.R_CURSOR]  # rewind: resync, no cues for the gap (18f)
		return
	_cursor = r[SimEvents.R_CURSOR]
	for k: int in range(0, _out.size(), SimLayout.EVENT_WORDS):
		_on_event(_out[k + 2], _out[k + 3], _out[k + 4], _out[k + 5])


func _on_event(type: int, a0: int, a1: int, a2: int) -> void:
	@warning_ignore("integer_division")
	var move: int = a0 / 2
	match type:
		SimEvents.ATTACK_START:
			_play("swing_heavy" if move == HEAVY_ID else "swing_light")
		SimEvents.WHIFF:
			_play("whiff")
		SimEvents.HIT:
			_flash(a2, Color(1.0, 0.85, 0.4))
			_play("heavy" if move == HEAVY_ID else "light")
			if move == HEAVY_ID:
				_shake_left = SHAKE_SECONDS
		SimEvents.BLOCK:
			_flash(a2, Color(0.5, 0.8, 1.0))
			_play("block")
		SimEvents.KO:
			_show("K.O.")
			_play("ko")
		SimEvents.ROUND_START:
			_show("ROUND %d" % a0)
		SimEvents.ROUND_END:
			if a0 == 0:
				_show("DRAW - REPLAY")
			elif a1 == SimEvents.REASON_TIMEOUT:
				_show("TIME - P%d" % a0)
		SimEvents.MATCH_END:
			_show("P%d WINS  %d-%d" % [a0, a1, a2])


func _process(delta: float) -> void:
	for i: int in range(_flash_left.size() - 1, -1, -1):
		_flash_left[i] -= delta
		if _flash_left[i] <= 0.0:
			_flash_pos.remove_at(i)
			_flash_col.remove_at(i)
			_flash_left.remove_at(i)
	if shake_target != null:
		_shake_left = maxf(0.0, _shake_left - delta)
		var amp: float = SHAKE_PX * _shake_left / SHAKE_SECONDS
		shake_target.position = Vector2(_shake_rng.randf_range(-amp, amp), _shake_rng.randf_range(-amp, amp))
	_banner_left = maxf(0.0, _banner_left - delta)
	_banner.modulate.a = clampf(_banner_left / 0.4, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	for i: int in _flash_left.size():
		var t: float = _flash_left[i] / FLASH_SECONDS
		var c: Color = _flash_col[i]
		c.a = t
		draw_circle(_flash_pos[i], 10.0 + 26.0 * (1.0 - t), c)


## Flash at a packed HIT/BLOCK contact point (half-su, SimEvents.pack_contact).
func _flash(packed: int, colour: Color) -> void:
	@warning_ignore("integer_division")
	var at: Vector2 = su_to_px.call(SimEvents.contact_x2(packed) / 2, SimEvents.contact_y2(packed) / 2)
	_flash_pos.append(at)
	_flash_col.append(colour)
	_flash_left.append(FLASH_SECONDS)


func _show(text: String) -> void:
	_banner.text = text
	_banner_left = BANNER_SECONDS


func _play(name: String) -> void:
	var p: AudioStreamPlayer = _sfx[name]
	p.play()


func _player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p


## Procedural placeholder SFX (no asset files): a pitched thump mixed with noise.
func _make_wav(thump_hz: float, noise: float, seconds: float, decay: float) -> AudioStreamWAV:
	var rate: int = 22050
	var n: int = int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in n:
		var t: float = float(i) / rate
		var env: float = exp(-t * decay)
		var v: float = (sin(TAU * thump_hz * t * (1.0 - t * 2.0)) * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise) * env
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


## Procedural placeholder swing: low-passed noise under a sine-shaped swell.
## `smooth` is the one-pole filter coefficient (lower = duller, heavier).
func _make_whoosh(seconds: float, smooth: float, gain: float) -> AudioStreamWAV:
	var rate: int = 22050
	var n: int = int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var lp: float = 0.0
	for i: int in n:
		var t: float = float(i) / float(n)
		lp += smooth * (rng.randf_range(-1.0, 1.0) - lp)
		var v: float = lp * sin(PI * t) * gain * 3.0
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
