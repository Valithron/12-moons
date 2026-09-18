class_name RunJournal
extends RefCounted

var root_seed: int = 0
var initial_state: Dictionary = {}
var entries: Array = []

func _init(seed_value: int = 0, state_snapshot: Dictionary = {}) -> void:
	root_seed = seed_value
	initial_state = state_snapshot.duplicate(true)

func record(action: RunAction, before_hash: String, after_hash: String) -> void:
	entries.append({
		"index": entries.size(),
		"action": action.to_dict(),
		"before_hash": before_hash,
		"after_hash": after_hash
	})

func to_dict() -> Dictionary:
	return {"root_seed": root_seed, "initial_state": initial_state.duplicate(true), "entries": entries.duplicate(true)}

static func from_dict(data: Dictionary) -> RunJournal:
	var raw_initial = data.get("initial_state", {})
	var initial_state: Dictionary = raw_initial if raw_initial is Dictionary else {}
	var result := RunJournal.new(int(data.get("root_seed", 0)), initial_state)
	result.entries = Array(data.get("entries", [])).duplicate(true)
	return result
