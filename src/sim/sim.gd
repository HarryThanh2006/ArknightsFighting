class_name Sim
extends RefCounted
## The sim object (sim-core rule 1): exactly two members, the state buffer and
## read-only move data. In the scene tree only MatchRunner holds and steps it;
## outside it, the replay runner and tests may.

## All mutable sim state, laid out by SimLayout. Never alias it outside this object.
var buffer: PackedInt64Array = PackedInt64Array()
## Read-only integer move tables (SimData once the Move Data Pipeline exists).
var _data: SimMoveData
var data: SimMoveData:
	get: return _data

func _init(kit: SimMoveData = SimMoveData.load_default()) -> void:
	_data = kit


## Rule 20: zeroes the buffer, writes layout_version, seeds the PRNG, runs every
## system init. Returns the tick-0 checksum. Round & Match `setup` is added with its GDD.
func init(seed_value: int) -> int:
	if data == null:
		push_error("Invalid move data; match cannot start")
		return 0
	buffer.resize(SimLayout.TOTAL)
	buffer.fill(0)
	buffer[SimLayout.H_LAYOUT_VERSION] = SimLayout.LAYOUT_VERSION
	SimRng.seed(buffer, SimLayout.H_RNG_S0, seed_value)
	SimPipeline.init_all(buffer, data)
	return SimHash.hash_words(buffer)


## Rules 7-11: one tick with this tick's input words; returns the checksum (block C).
## An Ended sim (match_over != 0) changes nothing and returns the unchanged checksum.
func step(w0: int, w1: int) -> int:
	var b: PackedInt64Array = buffer
	if b[SimLayout.R_MATCH_OVER] != 0:
		return SimHash.hash_words(b)
	SimPipeline.block_a(b, w0, w1)
	if b[SimLayout.H_FREEZE_TICKS] > 0:
		b[SimLayout.H_FREEZE_TICKS] -= 1
	else:
		SimPipeline.block_b(b, data)
	return SimHash.hash_words(b)


## Rule 21: an independent copy of the state (never an assignment, which aliases).
## Storage strategy for rollback is deferred to the LAN / rollback ADR.
func snapshot() -> PackedInt64Array:
	return buffer.duplicate()


## Rule 21: installs an independent copy of a trusted in-process snapshot.
## Size is checked before layout_version; on mismatch returns ERR_INVALID_DATA and changes nothing.
func restore(snap: PackedInt64Array) -> Error:
	if snap.size() != SimLayout.TOTAL:
		return ERR_INVALID_DATA
	if snap[SimLayout.H_LAYOUT_VERSION] != SimLayout.LAYOUT_VERSION:
		return ERR_INVALID_DATA
	buffer = snap.duplicate()
	return OK
