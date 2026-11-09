# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does a Light/Heavy/Block mirror match feel fast and weighty when weight comes from hit-stop + sound, not recovery?
# Date: 2026-11-01
#
# Controls
#   P1: A / D walk, F Light, G Heavy, H Block (hold)        | pad 0: d-pad, X Light, Y Heavy, RB Block
#   P2: Left / Right walk, Numpad 1 / 2 / 3  (or , . /)      | pad 1: same as pad 0
#   F1 hit-stop on/off   F2 SFX on/off   F3 shake on/off   F4 hitboxes   R restart match
extends Node2D

# ---------------- TUNING (frames at 60 Hz, pixels) ----------------
const LIGHT := {
	"name": "L", "startup": 5, "active": 3, "recovery": 8,
	"dmg": 60, "hitstop": 6, "hitstun": 15, "blockstun": 11,
	"push_hit": 6.0, "push_block": 8.0,
	"reach": 80.0, "y0": -110.0, "y1": -80.0, "sfx": 0, "shake": 3.0,
}
const HEAVY := {
	"name": "H", "startup": 11, "active": 4, "recovery": 14,
	"dmg": 140, "hitstop": 12, "hitstun": 22, "blockstun": 6,
	"push_hit": 14.0, "push_block": 4.0,
	"reach": 115.0, "y0": -125.0, "y1": -70.0, "sfx": 1, "shake": 7.0,
}
const WALK_FWD := 4.0
const WALK_BACK := 3.2
const MAX_HP := 1000
const BUFFER_FRAMES := 6
const PUNISH_WINDOW := 30          # a hit within this many ticks after leaving blockstun = block-then-punish
const ROUNDS_TO_WIN := 2
const ROUND_END_FREEZE := 90
const BODY_HALF_W := 30.0
const BODY_H := 140.0
const FLOOR_Y := 560.0
const WALL_L := 60.0
const WALL_R := 1220.0
# -------------------------------------------------------------------

class Fighter:
	var id: int
	var x: float
	var facing: int = 1
	var hp: int = 1000
	var state: String = "idle"     # idle walk block attack blockstun hitstun ko
	var move: Dictionary = {}
	var move_frame: int = 0
	var stun: int = 0
	var hit_connected: bool = false
	var blockstun_end_frame: int = -1
	var wins: int = 0
	var punishes: int = 0
	var press := {"light": -999, "heavy": -999}

var p: Array = []
var frame: int = 0
var freeze: int = 0
var round_no: int = 1
var round_start_frame: int = 0
var round_over: int = 0
var match_over: bool = false
var hitstop_on := true
var sfx_on := true
var shake_on := true
var show_boxes := false
var shake_timer: int = 0
var shake_amp: float = 0.0
var flashes: Array = []          # [x, y, timer, size]
var sfx_players: Array = []
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	_setup_input()
	_setup_sfx()
	p = [Fighter.new(), Fighter.new()]
	p[0].id = 0
	p[1].id = 1
	_reset_round()

# ---------------- input ----------------
func _add_key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _add_pad(action: String, device: int, button: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.device = device
	ev.button_index = button
	InputMap.action_add_event(action, ev)

func _setup_input() -> void:
	_add_key("p0_left", [KEY_A]); _add_key("p0_right", [KEY_D])
	_add_key("p0_light", [KEY_F]); _add_key("p0_heavy", [KEY_G]); _add_key("p0_block", [KEY_H])
	_add_key("p1_left", [KEY_LEFT]); _add_key("p1_right", [KEY_RIGHT])
	_add_key("p1_light", [KEY_KP_1, KEY_COMMA]); _add_key("p1_heavy", [KEY_KP_2, KEY_PERIOD])
	_add_key("p1_block", [KEY_KP_3, KEY_SLASH])
	for d in 2:
		var pre := "p%d_" % d
		_add_pad(pre + "left", d, JOY_BUTTON_DPAD_LEFT)
		_add_pad(pre + "right", d, JOY_BUTTON_DPAD_RIGHT)
		_add_pad(pre + "light", d, JOY_BUTTON_X)
		_add_pad(pre + "heavy", d, JOY_BUTTON_Y)
		_add_pad(pre + "block", d, JOY_BUTTON_RIGHT_SHOULDER)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1: hitstop_on = not hitstop_on
			KEY_F2: sfx_on = not sfx_on
			KEY_F3: shake_on = not shake_on
			KEY_F4: show_boxes = not show_boxes
			KEY_R: _reset_match()
	# latch presses so a tap inside a frozen or short frame is not lost
	for f in p:
		for b in ["light", "heavy"]:
			if event.is_action_pressed("p%d_%s" % [f.id, b], false):
				f.press[b] = frame

func _buffered(f: Fighter, b: String) -> bool:
	return frame - f.press[b] <= BUFFER_FRAMES

func _consume(f: Fighter, b: String) -> void:
	f.press[b] = -999

func _held(f: Fighter, a: String) -> bool:
	return Input.is_action_pressed("p%d_%s" % [f.id, a])

# ---------------- sfx (procedural, no asset files) ----------------
func _make_wav(thump_hz: float, noise: float, dur: float, decay: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * decay)
		var v := (sin(TAU * thump_hz * t * (1.0 - t * 2.0)) * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise) * env
		var s := int(clampf(v, -1.0, 1.0) * 30000.0)
		data.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w

func _setup_sfx() -> void:
	var streams := [
		_make_wav(220.0, 0.55, 0.12, 30.0),   # 0 light hit
		_make_wav(90.0, 0.45, 0.28, 14.0),    # 1 heavy hit
		_make_wav(600.0, 0.8, 0.07, 45.0),    # 2 block
	]
	for s in streams:
		var pl := AudioStreamPlayer.new()
		pl.stream = s
		add_child(pl)
		sfx_players.append(pl)

func _play(i: int) -> void:
	if sfx_on:
		sfx_players[i].play()

# ---------------- round flow ----------------
func _reset_round() -> void:
	p[0].x = 480.0; p[1].x = 800.0
	p[0].facing = 1; p[1].facing = -1
	for f in p:
		f.hp = MAX_HP
		f.state = "idle"
		f.stun = 0
		f.move = {}
		f.blockstun_end_frame = -1
		f.punishes = 0
		f.press = {"light": -999, "heavy": -999}
	freeze = 0
	round_over = 0
	round_start_frame = frame

func _reset_match() -> void:
	for f in p:
		f.wins = 0
	round_no = 1
	match_over = false
	_reset_round()

# One log line per punish window (opened when f leaves blockstun), whatever its outcome.
func _close_window(f: Fighter, outcome: String) -> void:
	if f.blockstun_end_frame < 0:
		return
	print("  PUNISH_WINDOW | round %d | attacker P%d | defender P%d | opened tick %d | closed after %d ticks (window %d) | %s" % [
		round_no, f.id + 1, 2 - f.id, f.blockstun_end_frame - round_start_frame,
		frame - f.blockstun_end_frame, PUNISH_WINDOW, outcome])
	f.blockstun_end_frame = -1

func _end_round() -> void:
	for f in p:
		_close_window(f, "OPEN AT ROUND END")
	var winner := -1
	if p[0].hp > p[1].hp: winner = 0
	elif p[1].hp > p[0].hp: winner = 1
	if winner >= 0:
		p[winner].wins += 1
	print("ROUND %d | winner %s | punishes P1 %d P2 %d | ticks %d | hitstop %s sfx %s shake %s" % [
		round_no, ("P%d" % (winner + 1)) if winner >= 0 else "draw",
		p[0].punishes, p[1].punishes, frame - round_start_frame,
		hitstop_on, sfx_on, shake_on])
	round_over = ROUND_END_FREEZE
	if p[0].wins >= ROUNDS_TO_WIN or p[1].wins >= ROUNDS_TO_WIN:
		match_over = true

# ---------------- sim ----------------
func _physics_process(_delta: float) -> void:
	frame += 1
	if match_over:
		return
	if round_over > 0:
		round_over -= 1
		if round_over == 0:
			round_no += 1
			_reset_round()
		return
	if shake_timer > 0:
		shake_timer -= 1
	if freeze > 0:
		freeze -= 1
		return
	for f in p:
		if f.blockstun_end_frame >= 0 and frame - f.blockstun_end_frame > PUNISH_WINDOW:
			_close_window(f, "MISSED (window expired)")
	for f in p:
		_update_fighter(f)
	_resolve_hits()
	_separate()
	for f in p:
		if f.state in ["idle", "walk", "block"]:
			var o: Fighter = p[1 - f.id]
			f.facing = 1 if o.x >= f.x else -1
	if p[0].hp <= 0 or p[1].hp <= 0:
		for f in p:
			if f.hp <= 0:
				f.state = "ko"
		_end_round()

func _start_attack(f: Fighter, m: Dictionary) -> void:
	f.state = "attack"
	f.move = m
	f.move_frame = 0
	f.hit_connected = false

func _update_fighter(f: Fighter) -> void:
	match f.state:
		"hitstun", "blockstun":
			f.stun -= 1
			if f.stun <= 0:
				if f.state == "blockstun":
					f.blockstun_end_frame = frame
				f.state = "idle"
			return
		"attack":
			f.move_frame += 1
			var m: Dictionary = f.move
			var total: int = m.startup + m.active + m.recovery
			# Light -> Heavy cancel once Light has connected (hit or block)
			if m.name == "L" and f.hit_connected and f.move_frame > m.startup and _buffered(f, "heavy"):
				_consume(f, "heavy")
				_start_attack(f, HEAVY)
				return
			if f.move_frame >= total:
				f.state = "idle"
			return
	# idle / walk / block
	if _buffered(f, "heavy"):
		_consume(f, "heavy"); _start_attack(f, HEAVY); return
	if _buffered(f, "light"):
		_consume(f, "light"); _start_attack(f, LIGHT); return
	if _held(f, "block"):
		f.state = "block"
		return
	var dir := 0
	if _held(f, "left"): dir -= 1
	if _held(f, "right"): dir += 1
	if dir == 0:
		f.state = "idle"
	else:
		f.state = "walk"
		f.x += dir * (WALK_FWD if dir == f.facing else WALK_BACK)
		f.x = clampf(f.x, WALL_L, WALL_R)

func _active(f: Fighter) -> bool:
	if f.state != "attack":
		return false
	var m: Dictionary = f.move
	return f.move_frame > m.startup and f.move_frame <= m.startup + m.active

func _hitbox(f: Fighter) -> Rect2:
	var m: Dictionary = f.move
	var front := f.x + f.facing * BODY_HALF_W
	var reach: float = m.reach
	var x0: float = front if f.facing > 0 else front - reach
	return Rect2(x0, FLOOR_Y + m.y0, m.reach, m.y1 - m.y0)

func _hurtbox(f: Fighter) -> Rect2:
	return Rect2(f.x - BODY_HALF_W, FLOOR_Y - BODY_H, BODY_HALF_W * 2.0, BODY_H)

func _resolve_hits() -> void:
	# gather first, then apply, so trades are symmetric
	var hits: Array = []
	for a in p:
		if _active(a) and not a.hit_connected:
			var d: Fighter = p[1 - a.id]
			if _hitbox(a).intersects(_hurtbox(d)):
				hits.append([a, d, a.move])
	var max_stop := 0
	for h in hits:
		var a: Fighter = h[0]
		var d: Fighter = h[1]
		var m: Dictionary = h[2]
		a.hit_connected = true
		var blocked: bool = d.state == "block"
		var push: float
		if blocked:
			d.state = "blockstun"
			d.stun = m.blockstun
			push = m.push_block
			_play(2)
		else:
			d.state = "hitstun"
			d.stun = m.hitstun
			d.hp -= m.dmg
			push = m.push_hit
			_play(m.sfx)
			if a.blockstun_end_frame >= 0 and frame - a.blockstun_end_frame <= PUNISH_WINDOW:
				a.punishes += 1
				_close_window(a, "HIT (%s, %d dmg)" % [m.name, m.dmg])
			a.blockstun_end_frame = -1
		_close_window(d, "LOST (blocked again)" if blocked else "LOST (got hit)")
		# push the defender away; if they are cornered, push the attacker instead
		var nx := d.x + a.facing * push
		if nx < WALL_L or nx > WALL_R:
			a.x -= a.facing * push
		d.x = clampf(nx, WALL_L, WALL_R)
		flashes.append([d.x - a.facing * BODY_HALF_W, FLOOR_Y + (m.y0 + m.y1) * 0.5, 6, 18.0 if m.name == "L" else 32.0])
		max_stop = maxi(max_stop, m.hitstop if not blocked else m.hitstop / 2)
		if shake_on and not blocked:
			shake_timer = m.hitstop
			shake_amp = m.shake
	if hitstop_on and max_stop > 0:
		freeze = max_stop

func _separate() -> void:
	var a: Fighter = p[0]
	var b: Fighter = p[1]
	var overlap := BODY_HALF_W * 2.0 - absf(a.x - b.x)
	if overlap > 0.0:
		var s := 1.0 if a.x <= b.x else -1.0
		a.x -= s * overlap * 0.5
		b.x += s * overlap * 0.5
		a.x = clampf(a.x, WALL_L, WALL_R)
		b.x = clampf(b.x, WALL_L, WALL_R)

# ---------------- draw ----------------
func _process(_delta: float) -> void:
	for fl in flashes:
		fl[2] -= 1
	flashes = flashes.filter(func(fl): return fl[2] > 0)
	queue_redraw()

func _draw() -> void:
	var off := Vector2.ZERO
	if shake_timer > 0:
		off = Vector2(randf_range(-shake_amp, shake_amp), randf_range(-shake_amp, shake_amp))
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.07, 0.07, 0.08))
	draw_set_transform(off)
	draw_line(Vector2(0, FLOOR_Y), Vector2(1280, FLOOR_Y), Color(0.5, 0.5, 0.55), 3.0)
	draw_line(Vector2(WALL_L - BODY_HALF_W, FLOOR_Y - 300), Vector2(WALL_L - BODY_HALF_W, FLOOR_Y), Color(0.3, 0.3, 0.33), 2.0)
	draw_line(Vector2(WALL_R + BODY_HALF_W, FLOOR_Y - 300), Vector2(WALL_R + BODY_HALF_W, FLOOR_Y), Color(0.3, 0.3, 0.33), 2.0)
	for f in p:
		_draw_fighter(f)
	for fl in flashes:
		draw_circle(Vector2(fl[0], fl[1]), fl[3] * (fl[2] / 6.0), Color(1, 1, 0.95))
	draw_set_transform(Vector2.ZERO)
	_draw_hud()

func _draw_fighter(f: Fighter) -> void:
	var base := Color(0.93, 0.9, 0.84) if f.id == 0 else Color(0.66, 0.4, 0.25)
	var body := _hurtbox(f)
	var c := base
	if f.state == "hitstun": c = base.lerp(Color(1, 0.3, 0.3), 0.5)
	if f.state == "ko": c = base.darkened(0.6)
	var lean := 0.0
	if f.state == "hitstun": lean = -f.facing * 10.0
	draw_rect(Rect2(body.position + Vector2(lean, 0), body.size), c)
	# head marker shows facing
	draw_rect(Rect2(f.x + f.facing * 8.0 - 10.0 + lean, FLOOR_Y - BODY_H - 26.0, 20, 20), c)
	if f.state == "block" or f.state == "blockstun":
		var sx := f.x + f.facing * (BODY_HALF_W + 4.0) - (0.0 if f.facing > 0 else 14.0)
		draw_rect(Rect2(sx, FLOOR_Y - BODY_H + 10, 14, BODY_H - 30), Color(0.35, 0.51, 0.72))
	if f.state == "attack":
		var m: Dictionary = f.move
		var hb := _hitbox(f)
		var ext := 0.3
		if f.move_frame <= m.startup:
			ext = 0.25 + 0.15 * float(f.move_frame) / m.startup   # wind-up: arm pulled short
		elif _active(f):
			ext = 1.0
		else:
			ext = lerpf(1.0, 0.3, float(f.move_frame - m.startup - m.active) / m.recovery)
		var w := hb.size.x * ext
		var ax := hb.position.x if f.facing > 0 else hb.end.x - w
		draw_rect(Rect2(ax, hb.position.y, w, hb.size.y), c if not _active(f) else Color(1, 0.95, 0.6))
	if show_boxes:
		draw_rect(body, Color(0.4, 0.8, 1.0), false, 1.0)
		if _active(f):
			draw_rect(_hitbox(f), Color(1, 0.2, 0.2), false, 2.0)

func _draw_hud() -> void:
	for f in p:
		var w := 500.0
		var x0 := 40.0 if f.id == 0 else 1240.0 - w
		var frac := clampf(float(f.hp) / MAX_HP, 0.0, 1.0)
		draw_rect(Rect2(x0, 30, w, 24), Color(0.15, 0.15, 0.17))
		var fw := w * frac
		draw_rect(Rect2(x0 if f.id == 0 else x0 + w - fw, 30, fw, 24), Color(0.93, 0.9, 0.84))
		var label := "P%d  wins %d  punishes %d  [%s]" % [f.id + 1, f.wins, f.punishes, f.state]
		draw_string(font, Vector2(x0, 80), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.8, 0.8))
	draw_string(font, Vector2(560, 46), "ROUND %d" % round_no, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.85, 0.6))
	var t := "F1 hitstop %s   F2 sfx %s   F3 shake %s   F4 boxes   R restart" % [
		"ON" if hitstop_on else "off", "ON" if sfx_on else "off", "ON" if shake_on else "off"]
	draw_string(font, Vector2(40, 700), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.6, 0.65))
	if match_over:
		var w := 0 if p[0].wins > p[1].wins else 1
		draw_string(font, Vector2(470, 300), "P%d WINS — press R" % (w + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(1, 1, 1))
	elif round_over > 0:
		draw_string(font, Vector2(590, 300), "K.O.", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1, 1, 1))
