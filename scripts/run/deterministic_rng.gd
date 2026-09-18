class_name DeterministicRng
extends RefCounted

const SCHEMA_VERSION := "rng-scope-v1"

static func scope_seed(root_seed: int, subsystem: String, month: int, sequence: String = "") -> int:
	var scope := "%s|%d|%s|%d|%s" % [SCHEMA_VERSION, root_seed, subsystem, month, sequence]
	var bytes: PackedByteArray = scope.sha256_buffer()
	var value: int = 0
	for index in range(mini(8, bytes.size())):
		value = (value << 8) | int(bytes[index])
	return value

static func for_scope(root_seed: int, subsystem: String, month: int, sequence: String = "") -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = scope_seed(root_seed, subsystem, month, sequence)
	return rng
