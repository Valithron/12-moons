class_name MatchingRules
extends RefCounted

static func matching_field_cards(played_card_id: String, field_ids: Array, catalog: CardCatalog) -> Array:
	var played := catalog.get_card(played_card_id)
	if played == null:
		return []
	var matches: Array = []
	for field_id in field_ids:
		var field_card := catalog.get_card(String(field_id))
		if field_card != null and field_card.month == played.month:
			matches.append(String(field_id))
	return matches

static func resolution_for_matches(played_card_id: String, matches: Array) -> Dictionary:
	var choices := matches.duplicate()
	choices.sort()
	match choices.size():
		0:
			return {"kind": "place", "choices": []}
		1:
			return {"kind": "capture_one", "choices": choices}
		2:
			return {"kind": "choose_one", "choices": choices}
		3:
			return {"kind": "capture_all", "choices": choices}
	return {"kind": "invalid", "choices": choices}
