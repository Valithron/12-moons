class_name MultiplierReplacementRequest
extends RefCounted

var multiplier_name: String = ""
var base_value: int = 1
var replacement_candidates: Array = []
var selected_replacement_id: String = ""

func to_dict() -> Dictionary:
	return {"multiplier_name": multiplier_name, "base_value": base_value, "replacement_candidates": replacement_candidates.duplicate(true), "selected_replacement_id": selected_replacement_id}
