class_name PlayerState
extends RefCounted

var player_id: int = 0
var hand_ids: Array = []
var captured_ids: Array = []

func _init(id: int = 0) -> void:
	player_id = id

func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"hand_ids": hand_ids.duplicate(),
		"captured_ids": captured_ids.duplicate()
	}

static func from_dict(data: Dictionary) -> PlayerState:
	var result := PlayerState.new(int(data.get("player_id", 0)))
	result.hand_ids = Array(data.get("hand_ids", [])).duplicate()
	result.captured_ids = Array(data.get("captured_ids", [])).duplicate()
	return result
