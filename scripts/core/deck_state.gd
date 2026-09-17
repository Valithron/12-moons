class_name DeckState
extends RefCounted

var cards: Array = []
var draw_index: int = 0
var seed: int = 0

func _init(card_ids: Array = [], seed_value: int = 0, should_shuffle: bool = true) -> void:
	seed = seed_value
	cards = card_ids.duplicate()
	draw_index = 0
	if should_shuffle:
		_shuffle_deterministically()

func _shuffle_deterministically() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for index in range(cards.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = temporary

func draw_card() -> String:
	if draw_index >= cards.size():
		return ""
	var card_id := String(cards[draw_index])
	draw_index += 1
	return card_id

func remaining_cards() -> Array:
	return cards.slice(draw_index)

func remaining_count() -> int:
	return cards.size() - draw_index

func to_dict() -> Dictionary:
	return {"cards": cards.duplicate(), "draw_index": draw_index, "seed": seed}

static func from_dict(data: Dictionary) -> DeckState:
	var result := DeckState.new(Array(data.get("cards", [])), int(data.get("seed", 0)), false)
	result.draw_index = int(data.get("draw_index", 0))
	return result
