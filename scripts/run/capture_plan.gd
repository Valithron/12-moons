class_name CapturePlan
extends RefCounted

var played_card_id: String = ""
var target_card_ids: Array = []
var captured_card_ids: Array = []
var effect_trace: Array = []

func invariant_errors() -> Array:
	var errors: Array = []
	var seen: Dictionary = {}
	for raw_id in captured_card_ids:
		var card_id := String(raw_id)
		if seen.has(card_id):
			errors.append("CapturePlan captures a physical card twice: %s" % card_id)
		seen[card_id] = true
	return errors

func to_dict() -> Dictionary:
	return {
		"played_card_id": played_card_id,
		"target_card_ids": target_card_ids.duplicate(),
		"captured_card_ids": captured_card_ids.duplicate(),
		"effect_trace": effect_trace.duplicate(true)
	}

static func from_dict(data: Dictionary) -> CapturePlan:
	var result := CapturePlan.new()
	result.played_card_id = String(data.get("played_card_id", ""))
	result.target_card_ids = Array(data.get("target_card_ids", [])).duplicate()
	result.captured_card_ids = Array(data.get("captured_card_ids", [])).duplicate()
	result.effect_trace = Array(data.get("effect_trace", [])).duplicate(true)
	return result
