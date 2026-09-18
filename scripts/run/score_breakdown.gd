class_name ScoreBreakdown
extends RefCounted

var additive_subtotal: int = 0
var multiplier: int = 1
var final_score: int = 0
var card_contributions: Dictionary = {}
var effect_trace: Array = []

func recompute() -> void:
	final_score = additive_subtotal * multiplier

func add_card_bonus(card_id: String, points: int, effect_id: String) -> void:
	additive_subtotal += points
	card_contributions[card_id] = int(card_contributions.get(card_id, 0)) + points
	effect_trace.append({"effect_id": effect_id, "card_id": card_id, "points": points})
	recompute()

func to_dict() -> Dictionary:
	return {
		"additive_subtotal": additive_subtotal,
		"multiplier": multiplier,
		"final_score": final_score,
		"card_contributions": card_contributions.duplicate(true),
		"effect_trace": effect_trace.duplicate(true)
	}
