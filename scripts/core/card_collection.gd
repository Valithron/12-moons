class_name CardCollection
extends RefCounted

var card_ids: Array = []

func _init(initial_ids: Array = []) -> void:
	for card_id in initial_ids:
		add_card(String(card_id))

func add_card(card_id: String) -> bool:
	if card_ids.has(card_id):
		return false
	card_ids.append(card_id)
	return true

func remove_card(card_id: String) -> bool:
	var index := card_ids.find(card_id)
	if index < 0:
		return false
	card_ids.remove_at(index)
	return true

func contains(card_id: String) -> bool:
	return card_ids.has(card_id)

func sorted_ids() -> Array:
	var result := card_ids.duplicate()
	result.sort()
	return result

func to_array() -> Array:
	return card_ids.duplicate()
