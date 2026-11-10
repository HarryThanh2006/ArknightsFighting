class_name MatchRunner
extends Node
## The only bridge between the scene tree and the sim (ADR-0002 rules 1-3).
## Steps the sim from an integer-microsecond accumulator read through an injected
## clock; ignores delta; never touches Engine.time_scale. Local / vs-AI stepping only
## (LAN stepping arrives with the LAN ADR).

const TICKS_PER_SECOND: int = 60
const USEC_PER_SECOND: int = 1_000_000
## Most ticks stepped in one frame; excess after a hitch is dropped, not fast-forwarded.
const MAX_CATCHUP_TICKS: int = 4

## Injected clock returning integer microseconds; tests pass a fake one.
var clock_usec: Callable = Time.get_ticks_usec
## Injected input sampler: (player: int) -> int input word. Default: neutral.
var input_sampler: Callable = func(_player: int) -> int: return 0
## Presentation components with update_view(view: SimView, alpha: float), called in this order.
var views: Array[Node] = []

var view: SimView
var ticks_stepped: int = 0
var ticks_dropped: int = 0
## Interpolation fraction for presentation, 0.0-1.0; 1.0 whenever the sim is behind wall time.
var alpha: float = 0.0
var paused: bool = false
## Checksum returned by the last step (debug overlay, replay recording).
var last_checksum: int = 0

var _sim: Sim
var _match_start_usec: int = 0
var _paused_usec: int = 0
var _pause_started_usec: int = 0


## Starts a match with `seed_value`; the clock origin is `now_usec`.
func start_match(seed_value: int, now_usec: int) -> void:
	_sim = Sim.new()
	last_checksum = _sim.init(seed_value)
	view = SimView.new(_sim)
	_match_start_usec = now_usec
	_paused_usec = 0
	ticks_stepped = 0
	ticks_dropped = 0
	alpha = 0.0
	paused = false


func pause(now_usec: int) -> void:
	if not paused:
		paused = true
		_pause_started_usec = now_usec


func resume(now_usec: int) -> void:
	if paused:
		paused = false
		_paused_usec += now_usec - _pause_started_usec


func _process(_delta: float) -> void:
	if _sim != null:
		var now: int = clock_usec.call()
		advance(now)


## One frame (ADR-0002 rule 3): sample input, step due ticks, compute alpha, update views.
## Returns the number of ticks stepped.
func advance(now_usec: int) -> int:
	if paused:
		return 0
	var w0: int = input_sampler.call(0)
	var w1: int = input_sampler.call(1)
	var elapsed_usec: int = now_usec - _match_start_usec - _paused_usec
	@warning_ignore("integer_division")
	var ticks_due_total: int = elapsed_usec * TICKS_PER_SECOND / USEC_PER_SECOND - ticks_dropped
	var behind: int = ticks_due_total - ticks_stepped
	var to_step: int = clampi(behind, 0, MAX_CATCHUP_TICKS)
	ticks_dropped += maxi(behind - MAX_CATCHUP_TICKS, 0)
	for i: int in to_step:
		last_checksum = _sim.step(w0, w1)
	ticks_stepped += to_step
	if ticks_stepped < ticks_due_total:
		alpha = 1.0
	else:
		alpha = clampf(float(posmod(elapsed_usec * TICKS_PER_SECOND, USEC_PER_SECOND)) / float(USEC_PER_SECOND), 0.0, 1.0)
	for v: Node in views:
		v.call("update_view", view, alpha)
	return to_step
