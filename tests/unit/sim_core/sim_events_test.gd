extends GdUnitTestSuite
## SimEvents ring (design/gdd/sim-core.md rules 18-18f, F4-F7, AC-E1..E19) and the
## HIT / BLOCK / KO / ROUND_* / MATCH_END emitters.

const OBS: int = SimEvents.PROJECTILE_HIT  # an observation type
const CRIT: int = SimEvents.HIT            # a critical type
const RING: int = 208
const LIGHT: int = 4
const BLOCK: int = 16

func _sim_at_tick(tick: int) -> Sim:
	var sim := Sim.new()
	sim.init(3)
	sim.buffer[SimLayout.H_TICK] = tick
	return sim

## Starts a new tick by hand (block A's counter reset) for ring-only tests.
func _next_tick(b: PackedInt64Array) -> void:
	b[SimLayout.H_TICK] += 1
	SimEvents.begin_tick(b)

func _seqs(b: PackedInt64Array, cursor: int) -> Array[int]:
	var out := PackedInt64Array()
	SimEvents.read(b, cursor, out)
	var seqs: Array[int] = []
	for k: int in range(0, out.size(), 6):
		seqs.append(out[k + 1])
	return seqs

func _ring_words(b: PackedInt64Array) -> PackedInt64Array:
	return b.slice(SimLayout.EV_BASE, SimLayout.EV_BASE + RING * SimLayout.EVENT_WORDS)

## All records from `cursor` as [tick, seq, type, a0, a1, a2] arrays.
func _records(sim: Sim, cursor: int = 0) -> Array:
	var out := PackedInt64Array()
	SimEvents.read(sim.buffer, cursor, out)
	var rows: Array = []
	for k: int in range(0, out.size(), 6):
		rows.append(Array(out.slice(k, k + 6)))
	return rows

func _payload(rows: Array, i: int) -> Array:
	var r: Array = rows[i]
	return r.slice(3)

func _types(rows: Array) -> Array[int]:
	var t: Array[int] = []
	for r: Array in rows:
		var type: int = r[2]
		t.append(type)
	return t

# --- Ring (unit) ---

## AC-E12, AC-E14: record layout; payload stored as given; no other word changes.
func test_emit_writes_exact_record_and_nothing_else() -> void:
	var sim := _sim_at_tick(5)
	var before := sim.buffer.duplicate()
	var s: int = sim.buffer[SimLayout.EC_EVENT_SEQ]
	SimEvents.emit(sim.buffer, CRIT, 7, -1, 5)
	var at: int = SimLayout.EV_BASE + posmod(s, RING) * 6
	assert_array(Array(sim.buffer.slice(at, at + 6))).is_equal([5, s, CRIT, 7, -1, 5])
	for i: int in sim.buffer.size():
		if i < at or i >= at + 6:
			if i != SimLayout.EC_EVENT_SEQ and i != SimLayout.EC_CRIT_THIS_TICK:
				assert_int(sim.buffer[i]).override_failure_message("word %d" % i).is_equal(before[i])
	assert_int(sim.buffer[SimLayout.EC_EVENT_SEQ]).is_equal(s + 1)

## AC-E1, AC-E13: 13 ticks x 16 = 208 survive with lost 0; one more pushes seq 0 out.
func test_ring_holds_208_then_wraps_with_lost_one() -> void:
	var sim := _sim_at_tick(1)
	var b: PackedInt64Array = sim.buffer
	b[SimLayout.EC_EVENT_SEQ] = 0
	SimEvents.begin_tick(b)
	assert_array(_seqs(b, 0)).is_empty()
	for t: int in 13:
		for k: int in 16:
			SimEvents.emit(b, CRIT, k, t, 0)
		_next_tick(b)
	var out := PackedInt64Array()
	var r := SimEvents.read(b, 0, out)
	assert_array(_seqs(b, 0)).is_equal(range(0, 208))
	assert_int(r[SimEvents.R_LOST]).is_equal(0)
	SimEvents.emit(b, CRIT, 0, 0, 0)
	r = SimEvents.read(b, 0, out)
	assert_array(_seqs(b, 0)).is_equal(range(1, 209))
	assert_int(r[SimEvents.R_LOST]).is_equal(1)

## AC-E2: drain bound — 13 saturated steps lose nothing, 14 lose 16.
func test_drain_bound_13_steps_lossless_14_lose_16() -> void:
	for steps: int in [13, 14]:
		var sim := _sim_at_tick(1)
		var b: PackedInt64Array = sim.buffer
		var e0: int = b[SimLayout.EC_EVENT_SEQ]
		for t: int in steps:
			_next_tick(b)
			for k: int in 16:
				SimEvents.emit(b, CRIT, 0, 0, 0)
		var r := SimEvents.read(b, e0, PackedInt64Array())
		var seqs := _seqs(b, e0)
		assert_int(r[SimEvents.R_LOST]).is_equal(0 if steps == 13 else 16)
		assert_int(seqs[0]).is_equal(e0 if steps == 13 else e0 + 16)

## AC-E3: 10 observation + 2 critical in one tick -> 7 + 2 written, overflow +3, no fault.
func test_observation_cap_drops_and_counts_without_fault() -> void:
	var sim := _sim_at_tick(4)
	var b: PackedInt64Array = sim.buffer
	SimEvents.begin_tick(b)
	var s0: int = b[SimLayout.EC_EVENT_SEQ]
	for k: int in 10:
		SimEvents.emit(b, OBS, k, 0, 0)
	SimEvents.emit(b, CRIT, 0, 0, 0)
	SimEvents.emit(b, CRIT, 1, 0, 0)
	assert_int(b[SimLayout.EC_EVENT_SEQ] - s0).is_equal(9)
	assert_int(b[SimLayout.EC_EVENT_OVERFLOW_COUNT]).is_equal(3)
	assert_int(b[SimLayout.EC_SIM_FAULT]).is_equal(0)
	assert_array(_types(_records(sim, s0))).is_equal([OBS, OBS, OBS, OBS, OBS, OBS, OBS, CRIT, CRIT])

## AC-E4: a 10th critical event on a full tick is dropped, counted, faults; match continues.
func test_critical_overflow_counts_and_faults() -> void:
	var sim := _sim_at_tick(4)
	var b: PackedInt64Array = sim.buffer
	b[SimLayout.EC_OBS_THIS_TICK] = 7
	b[SimLayout.EC_CRIT_THIS_TICK] = 9
	var ring := _ring_words(b)
	var s0: int = b[SimLayout.EC_EVENT_SEQ]
	SimEvents.emit(b, CRIT, 0, 0, 0)
	assert_array(Array(_ring_words(b))).is_equal(Array(ring))
	assert_int(b[SimLayout.EC_EVENT_SEQ]).is_equal(s0)
	assert_int(b[SimLayout.EC_EVENT_OVERFLOW_COUNT]).is_equal(1)
	assert_int(b[SimLayout.EC_CRITICAL_OVERFLOW_COUNT]).is_equal(1)
	assert_int(b[SimLayout.EC_SIM_FAULT]).is_equal(1)
	assert_int(b[SimLayout.R_MATCH_OVER]).is_equal(0)

## AC-E5: accepted set = first 7 observations in emission order + every critical,
## over 200 seeded interleavings plus the two extremes.
func test_interleavings_accept_first_seven_observations_and_all_critical() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261111
	var orders: Array = []
	var extreme_first: Array[int] = []
	var extreme_last: Array[int] = []
	for k: int in 9:
		extreme_first.append(CRIT)
	for k: int in 17:
		extreme_first.append(OBS)
		extreme_last.append(OBS)
	for k: int in 9:
		extreme_last.append(CRIT)
	orders.append(extreme_first)
	orders.append(extreme_last)
	for n: int in 200:
		var seq: Array[int] = []
		for k: int in rng.randi_range(0, 9):
			seq.append(CRIT)
		for k: int in rng.randi_range(0, 17):
			seq.append(OBS)
		for k: int in range(seq.size() - 1, 0, -1):
			var j: int = rng.randi_range(0, k)
			var tmp: int = seq[k]
			seq[k] = seq[j]
			seq[j] = tmp
		orders.append(seq)
	for order: Array in orders:
		var sim := _sim_at_tick(2)
		var b: PackedInt64Array = sim.buffer
		SimEvents.begin_tick(b)
		var s0: int = b[SimLayout.EC_EVENT_SEQ]
		var expected: Array[int] = []
		var obs_seen: int = 0
		for idx: int in order.size():
			var type: int = order[idx]
			SimEvents.emit(b, type, idx, 0, 0)
			if type == CRIT or obs_seen < 7:
				expected.append(idx)
			if type == OBS:
				obs_seen += 1
		var got: Array[int] = []
		for r: Array in _records(sim, s0):
			var a0: int = r[3]
			got.append(a0)
		assert_array(got).is_equal(expected)
		assert_int(b[SimLayout.EC_CRITICAL_OVERFLOW_COUNT]).is_equal(0)

## AC-E6: invalid type or tick 0 -> nothing written, counters unchanged, fault set; repeatable.
func test_invalid_emission_rejected_and_sets_fault() -> void:
	for case: Array in [[0, 5], [-1, 5], [SimEvents.EVENT_TYPE_COUNT, 5], [CRIT, 0]]:
		var type: int = case[0]
		var tick: int = case[1]
		var sim := _sim_at_tick(tick)
		var b: PackedInt64Array = sim.buffer
		var ring := _ring_words(b)
		var s0: int = b[SimLayout.EC_EVENT_SEQ]
		for rep: int in 2:
			SimEvents.emit(b, type, 1, 2, 3)
			assert_array(Array(_ring_words(b))).is_equal(Array(ring))
			assert_int(b[SimLayout.EC_EVENT_SEQ]).is_equal(s0)
			assert_int(b[SimLayout.EC_EVENT_OVERFLOW_COUNT]).is_equal(0)
			assert_int(b[SimLayout.EC_CRITICAL_OVERFLOW_COUNT]).is_equal(0)
			assert_int(b[SimLayout.EC_SIM_FAULT]).is_equal(1)

## AC-E7: drops never create gaps; wrap loss equals the gap.
func test_sequence_semantics_drops_no_gaps_wrap_reports_lost() -> void:
	var sim := _sim_at_tick(1)
	var b: PackedInt64Array = sim.buffer
	b[SimLayout.EC_EVENT_SEQ] = 0
	for t: int in 3:
		_next_tick(b)
		for k: int in 20:
			SimEvents.emit(b, OBS, 0, 0, 0)
		SimEvents.emit(b, CRIT, 0, 0, 0)
		SimEvents.emit(b, CRIT, 0, 0, 0)
	while b[SimLayout.EC_EVENT_SEQ] < 250:
		_next_tick(b)
		for k: int in 16:
			if b[SimLayout.EC_EVENT_SEQ] < 250:
				SimEvents.emit(b, OBS if k < 7 else CRIT, 0, 0, 0)
	var r := SimEvents.read(b, 0, PackedInt64Array())
	assert_array(_seqs(b, 0)).is_equal(range(42, 250))
	assert_int(r[SimEvents.R_LOST]).is_equal(42)
	assert_int(b[SimLayout.EC_EVENT_OVERFLOW_COUNT]).is_equal(39)

## AC-E9: the read copies by value; writing to `out` leaves the ring unchanged.
func test_read_copies_by_value() -> void:
	var sim := _sim_at_tick(3)
	SimEvents.emit(sim.buffer, CRIT, 1, 2, 3)
	var ring := _ring_words(sim.buffer)
	var out := PackedInt64Array()
	SimEvents.read(sim.buffer, 0, out)
	out.fill(99)
	assert_array(Array(_ring_words(sim.buffer))).is_equal(Array(ring))

## AC-E11: seq near INT64_MAX still lands on posmod(seq, 208), never a negative index.
func test_seq_near_int64_max_uses_posmod_slots() -> void:
	var sim := _sim_at_tick(3)
	var b: PackedInt64Array = sim.buffer
	var start: int = 9223372036854775807 - 1000
	b[SimLayout.EC_EVENT_SEQ] = start
	for k: int in 16:
		SimEvents.emit(b, CRIT, k, 0, 0)
		var at: int = SimLayout.EV_BASE + posmod(start + k, RING) * 6
		assert_int(b[at + 1]).is_equal(start + k)
		assert_int(b[at + 3]).is_equal(k)

## AC-E15: counters restore with the snapshot, re-step matches, init clears.
func test_fault_counters_follow_snapshot_restore_and_init() -> void:
	var sim := _sim_at_tick(3)
	var b: PackedInt64Array = sim.buffer
	var snap := sim.snapshot()
	b[SimLayout.EC_OBS_THIS_TICK] = 7
	b[SimLayout.EC_CRIT_THIS_TICK] = 9
	SimEvents.emit(b, CRIT, 0, 0, 0)
	assert_int(b[SimLayout.EC_SIM_FAULT]).is_equal(1)
	sim.restore(snap)
	assert_int(sim.buffer[SimLayout.EC_SIM_FAULT]).is_equal(0)
	assert_int(sim.buffer[SimLayout.EC_CRITICAL_OVERFLOW_COUNT]).is_equal(0)
	var a := sim.step(LIGHT, 0)
	sim.restore(snap)
	assert_int(sim.step(LIGHT, 0)).is_equal(a)
	sim.buffer[SimLayout.EC_SIM_FAULT] = 1
	sim.init(3)
	assert_int(sim.buffer[SimLayout.EC_SIM_FAULT]).is_equal(0)

## AC-E19: 7 observations first, then both characters' HIT -> both accepted, later
## observations dropped, no critical overflow.
func test_saturated_observations_never_block_character_hits() -> void:
	var sim := _sim_at_tick(6)
	var b: PackedInt64Array = sim.buffer
	SimEvents.begin_tick(b)
	var s0: int = b[SimLayout.EC_EVENT_SEQ]
	for k: int in 7:
		SimEvents.emit(b, OBS, k, 0, 0)
	SimEvents.emit(b, SimEvents.HIT, 2, 60, 0)
	SimEvents.emit(b, SimEvents.HIT, 3, 60, 0)
	SimEvents.emit(b, OBS, 9, 0, 0)
	var types := _types(_records(sim, s0))
	assert_int(types.count(SimEvents.HIT)).is_equal(2)
	assert_int(types.count(OBS)).is_equal(7)
	assert_int(b[SimLayout.EC_EVENT_OVERFLOW_COUNT]).is_equal(1)
	assert_int(b[SimLayout.EC_CRITICAL_OVERFLOW_COUNT]).is_equal(0)

# --- Emitters (integration through Sim.step) ---

func _duel(x0: int, x1: int) -> Sim:
	var sim := Sim.new()
	sim.init(17)
	sim.buffer[SimLayout.P_BASE + SimLayout.PF_X] = x0
	sim.buffer[SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_X] = x1
	return sim

## Tick 1 emits ROUND_START (round 1); a point-blank Light trade emits HIT P0 then P1 on
## tick 6 with damage 60 and contact x at the overlap midpoints (+2,500 / −2,500 su).
func test_light_trade_emits_round_start_then_two_hits_with_contact_points() -> void:
	var sim := _duel(-2500, 2500)
	for t: int in 6:
		sim.step(LIGHT if t == 0 else 0, LIGHT if t == 0 else 0)
	var rows := _records(sim)
	assert_array(rows).is_equal([
		[1, 0, SimEvents.ROUND_START, 1, 0, 0],
		[6, 1, SimEvents.HIT, 0 + 2 * 1, 60, 2500],
		[6, 2, SimEvents.HIT, 1 + 2 * 1, 60, -2500]])

## A blocked Light emits BLOCK with zero damage; slots swapped mirror actor and x.
func test_block_event_mirrors_across_player_swap() -> void:
	var got: Array = []
	for attacker: int in [0, 1]:
		var sim := _duel(-2500, 2500)
		for t: int in 6:
			var hit_w: int = LIGHT if t == 0 else 0
			if attacker == 0:
				sim.step(hit_w, BLOCK)
			else:
				sim.step(BLOCK, hit_w)
		var rows := _records(sim)
		got.append(rows[rows.size() - 1])
	assert_array(got[0]).is_equal([6, 1, SimEvents.BLOCK, 0 + 2, 0, 2500])
	assert_array(got[1]).is_equal([6, 1, SimEvents.BLOCK, 1 + 2, 0, -2500])

## EC-9: lethal trade -> HIT P0, HIT P1, KO P0, KO P1, ROUND_END(draw, KO, round 1);
## after the interval, ROUND_START for the replayed round 1.
func test_double_ko_emits_ko_pair_round_end_then_replayed_round_start() -> void:
	var sim := _duel(-2500, 2500)
	for p: int in 2:
		sim.buffer[SimLayout.P_BASE + p * SimLayout.P_STRIDE + SimLayout.PF_HP] = 60
	for t: int in 6:
		sim.step(LIGHT if t == 0 else 0, LIGHT if t == 0 else 0)
	var rows := _records(sim, 1)
	assert_array(_types(rows)).is_equal([SimEvents.HIT, SimEvents.HIT, SimEvents.KO, SimEvents.KO, SimEvents.ROUND_END])
	assert_array(_payload(rows, 2)).is_equal([0, 0, 0])
	assert_array(_payload(rows, 3)).is_equal([1, 0, 0])
	assert_array(_payload(rows, 4)).is_equal([0, SimEvents.REASON_KO, 1])
	for t: int in 91:
		sim.step(0, 0)
	var after := _records(sim, 6)
	assert_array(after).is_equal([[97, 6, SimEvents.ROUND_START, 1, 0, 0]])

## Match point: KO P2 -> KO, ROUND_END(1, KO), MATCH_END(1, 2, 0), and nothing afterwards.
func test_match_point_ko_emits_match_end_with_score() -> void:
	var sim := _duel(-2500, 20_000)
	sim.buffer[SimLayout.R_WINS_0] = 1
	sim.buffer[SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_X] = 2500
	sim.buffer[SimLayout.P_BASE + SimLayout.P_STRIDE + SimLayout.PF_HP] = 50
	for t: int in 10:
		sim.step(LIGHT if t == 0 else 0, 0)
	var rows := _records(sim, 1)
	assert_array(_types(rows)).is_equal([SimEvents.HIT, SimEvents.KO, SimEvents.ROUND_END, SimEvents.MATCH_END])
	assert_array(_payload(rows, 0)).is_equal([2, 50, 2500])
	assert_array(_payload(rows, 3)).is_equal([1, 2, 0])

## Timeout with unequal HP: ROUND_END reason TIMEOUT, no KO event.
func test_timeout_emits_round_end_with_timeout_reason_and_no_ko() -> void:
	var sim := _duel(-20_000, 20_000)
	sim.step(0, 0)
	sim.buffer[SimLayout.P_BASE + SimLayout.PF_HP] = 500
	sim.buffer[SimLayout.R_CLOCK] = 1
	sim.step(0, 0)
	var rows := _records(sim, 1)
	assert_array(rows).is_equal([[2, 1, SimEvents.ROUND_END, 2, SimEvents.REASON_TIMEOUT, 1]])

# --- Consumer (MatchRunner + SimView) ---

## Scripted inputs (seeded): each player holds one of toward, toward + Light, toward +
## Heavy, Light, Heavy, Block, away or neutral for 3-20 ticks (as V5Bench).
func _inputs(ticks: int) -> PackedInt64Array:
	var gen := PackedInt64Array([0, 0])
	SimRng.seed(gen, 0, 5)
	var out := PackedInt64Array()
	var held := PackedInt64Array([0, 0])
	var left := PackedInt64Array([0, 0])
	for t: int in ticks:
		for p: int in 2:
			if left[p] <= 0:
				var toward: int = 2 if p == 0 else 1
				var choices := PackedInt64Array([toward, toward | LIGHT, toward | 8, LIGHT, 8, BLOCK, 3 - toward, 0])
				held[p] = choices[SimRng.range_i(gen, 0, 0, 7)]
				left[p] = SimRng.range_i(gen, 0, 3, 20)
			left[p] -= 1
			out.append(held[p])
	return out

## Reference stream: drain after every single step.
func _per_tick_stream(words: PackedInt64Array, ticks: int) -> Array:
	var sim := _duel(-6000, 6000)
	var cursor: int = 0
	var all: Array = []
	for t: int in ticks:
		sim.step(words[2 * t], words[2 * t + 1])
		var rows := _records(sim, cursor)
		cursor = sim.buffer[SimLayout.EC_EVENT_SEQ]
		all.append_array(rows)
	return all

## 18f: a consumer draining once per frame across 4-tick catch-up gets every event exactly
## once, equal to the per-tick drain; the stream contains HIT, BLOCK, KO and ROUND_END.
func test_frame_drain_across_catch_up_returns_each_event_once() -> void:
	var ticks: int = 12_000
	var words := _inputs(ticks)
	var expected := _per_tick_stream(words, ticks)
	var sim := _duel(-6000, 6000)
	var view := SimView.new(sim)
	var cursor: int = 0
	var got: Array = []
	var out := PackedInt64Array()
	var t: int = 0
	while t < ticks:
		for k: int in mini(4, ticks - t):
			sim.step(words[2 * t], words[2 * t + 1])
			t += 1
		var r := view.events_since(cursor, out)
		assert_int(r[SimEvents.R_LOST]).is_equal(0)
		cursor = r[SimEvents.R_CURSOR]
		for k: int in range(0, out.size(), 6):
			got.append(Array(out.slice(k, k + 6)))
	assert_array(got).is_equal(expected)
	var types := _types(got)
	for want: int in [SimEvents.HIT, SimEvents.BLOCK, SimEvents.KO, SimEvents.ROUND_END]:
		assert_bool(types.has(want)).override_failure_message("stream lacks type %d" % want).is_true()
	for i: int in got.size():
		var row: Array = got[i]
		assert_int(row[1]).is_equal(i)

## Replaying the same inputs reproduces the identical event stream.
func test_replay_reproduces_event_stream() -> void:
	var words := _inputs(2000)
	assert_array(_per_tick_stream(words, 2000)).is_equal(_per_tick_stream(words, 2000))
