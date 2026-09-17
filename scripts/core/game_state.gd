class_name GameState
extends RefCounted

var seed: int = 0
var deck: DeckState = DeckState.new()
var players: Array = []
var field_ids: Array = []
var current_player: int = 0
var turn_index: int = 0
var terminal_result: Dictionary = {}

func _init() -> void:
	players = [PlayerState.new(0), PlayerState.new(1)]

static func fresh(seed_value: int, catalog: CardCatalog) -> GameState:
	var result := GameState.new()
	result.seed = seed_value
	result.deck = DeckState.new(catalog.ids(), seed_value)
	return result

func player(player_id: int) -> PlayerState:
	if player_id < 0 or player_id >= players.size():
		return null
	return players[player_id]

func all_authoritative_ids() -> Array:
	var result: Array = []
	result.append_array(deck.remaining_cards())
	result.append_array(field_ids)
	for player_state in players:
		result.append_array(player_state.hand_ids)
		result.append_array(player_state.captured_ids)
	return result

func invariant_errors(catalog: CardCatalog) -> Array:
	var errors: Array = []
	var seen: Dictionary = {}
	for card_id in all_authoritative_ids():
		var normalized := String(card_id)
		if not catalog.has_card(normalized):
			errors.append("Unknown card ID: %s" % normalized)
		if seen.has(normalized):
			errors.append("Card exists in multiple authoritative zones: %s" % normalized)
		seen[normalized] = true
	return errors

func invariants_ok(catalog: CardCatalog) -> bool:
	return invariant_errors(catalog).is_empty()

func _sorted(values: Array) -> Array:
	var result := values.duplicate()
	result.sort()
	return result

func canonical_dict() -> Dictionary:
	var canonical_players: Array = []
	for player_state in players:
		canonical_players.append({
			"player_id": player_state.player_id,
			"hand_ids": _sorted(player_state.hand_ids),
			"captured_ids": _sorted(player_state.captured_ids)
		})
	canonical_players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["player_id"] < b["player_id"])
	return {
		"seed": seed,
		"deck_cards": deck.cards.duplicate(),
		"deck_draw_index": deck.draw_index,
		"field_ids": _sorted(field_ids),
		"players": canonical_players,
		"current_player": current_player,
		"turn_index": turn_index,
		"terminal_result": terminal_result.duplicate(true)
	}

func canonical_json() -> String:
	return JSON.stringify(canonical_dict())

func state_hash() -> String:
	return canonical_json().sha256_text()

func to_dict() -> Dictionary:
	var serialized_players: Array = []
	for player_state in players:
		serialized_players.append(player_state.to_dict())
	return {
		"seed": seed,
		"deck": deck.to_dict(),
		"players": serialized_players,
		"field_ids": field_ids.duplicate(),
		"current_player": current_player,
		"turn_index": turn_index,
		"terminal_result": terminal_result.duplicate(true)
	}

static func from_dict(data: Dictionary) -> GameState:
	var result := GameState.new()
	result.seed = int(data.get("seed", 0))
	result.deck = DeckState.from_dict(data.get("deck", {}))
	result.players = []
	for player_data in data.get("players", []):
		result.players.append(PlayerState.from_dict(player_data))
	if result.players.is_empty():
		result.players = [PlayerState.new(0), PlayerState.new(1)]
	result.field_ids = Array(data.get("field_ids", [])).duplicate()
	result.current_player = int(data.get("current_player", 0))
	result.turn_index = int(data.get("turn_index", 0))
	result.terminal_result = Dictionary(data.get("terminal_result", {})).duplicate(true)
	return result
