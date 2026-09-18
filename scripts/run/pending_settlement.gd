class_name PendingSettlement
extends RefCounted

var match_id: String = ""
var amount_due: int = 0
var player_score: int = 0
var ai_score: int = 0
var source_result: Dictionary = {}

func is_resolved() -> bool:
	return amount_due <= 0

func to_dict() -> Dictionary:
	return {
		"match_id": match_id,
		"amount_due": amount_due,
		"player_score": player_score,
		"ai_score": ai_score,
		"source_result": source_result.duplicate(true)
	}

static func from_dict(data: Dictionary) -> PendingSettlement:
	var result := PendingSettlement.new()
	result.match_id = String(data.get("match_id", ""))
	result.amount_due = int(data.get("amount_due", 0))
	result.player_score = int(data.get("player_score", 0))
	result.ai_score = int(data.get("ai_score", 0))
	var raw_source = data.get("source_result", {})
	if raw_source is Dictionary:
		result.source_result = raw_source.duplicate(true)
	return result
