class_name RewardOffer
extends RefCounted

var offer_id: String = ""
var definition_id: String = ""
var slot_index: int = 0
var slot_spec: String = ""
var source: String = ""
var generation_id: int = 0
var consumed: bool = false

func to_dict() -> Dictionary:
	return {
		"offer_id": offer_id,
		"definition_id": definition_id,
		"slot_index": slot_index,
		"slot_spec": slot_spec,
		"source": source,
		"generation_id": generation_id,
		"consumed": consumed
	}

static func from_dict(data: Dictionary) -> RewardOffer:
	var result := RewardOffer.new()
	result.offer_id = String(data.get("offer_id", ""))
	result.definition_id = String(data.get("definition_id", ""))
	result.slot_index = int(data.get("slot_index", 0))
	result.slot_spec = String(data.get("slot_spec", ""))
	result.source = String(data.get("source", ""))
	result.generation_id = int(data.get("generation_id", 0))
	result.consumed = bool(data.get("consumed", false))
	return result
