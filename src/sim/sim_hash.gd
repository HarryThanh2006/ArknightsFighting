class_name SimHash
## Project-owned per-tick checksum (ADR-0001 rule 8): FNV-1a 64 applied word-wise,
## one XOR and one wrapping multiply per int64 element. Never hash() or instance IDs.

## FNV-64 offset basis 0xcbf29ce484222325 as signed int64.
const FNV_OFFSET: int = -3750763034362895579
## FNV-64 prime 0x100000001b3.
const FNV_PRIME: int = 1_099_511_628_211


## Checksum of every word of `buffer`, in index order.
static func hash_words(buffer: PackedInt64Array) -> int:
	var h: int = FNV_OFFSET
	for w: int in buffer:
		h = (h ^ w) * FNV_PRIME
	return h
