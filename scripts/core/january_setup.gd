class_name JanuarySetup
extends RefCounted

static func create_ceremony_state(seed_value: int, catalog: CardCatalog) -> GameState:
	var state := GameState.new()
	state.seed = seed_value
	state.month = 1
	state.moon_id = "wolf_moon"
	state.starter_card_ids = ceremony_cards(seed_value, catalog)
	var deck_ids := catalog.ids()
	for starter_id in state.starter_card_ids:
		deck_ids.erase(starter_id)
	state.deck = DeckState.new(deck_ids, _deal_seed(seed_value, -1), false)
	state.phase = GameState.PHASE_STARTER_PLAYER_SELECT
	state.current_player = 0
	state.first_player = 0
	state.turn_index = 0
	state.last_event = {
		"kind": "starter_ceremony",
		"message": "Choose one face-down card to determine who opens January."
	}
	return state

static func ceremony_cards(seed_value: int, catalog: CardCatalog) -> Array:
	var months: Array = []
	for month in range(1, 13):
		months.append(month)
	var rng := RandomNumberGenerator.new()
	rng.seed = _deal_seed(seed_value, -2)
	for index in range(months.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary = months[index]
		months[index] = months[swap_index]
		months[swap_index] = temporary
	var result: Array = []
	for index in range(3):
		var month := int(months[index])
		var month_cards := catalog.cards_for_month(month)
		if not month_cards.is_empty():
			result.append(month_cards[0])
	return result

static func opening_deal_for_seed(seed_value: int, catalog: CardCatalog) -> Dictionary:
	var attempt := 0
	while attempt < 10000:
		var deck := DeckState.new(catalog.ids(), _deal_seed(seed_value, attempt), true)
		var player_hand: Array = []
		var ai_hand: Array = []
		var field: Array = []
		for _index in range(8):
			player_hand.append(deck.draw_card())
		for _index in range(8):
			ai_hand.append(deck.draw_card())
		for _index in range(8):
			field.append(deck.draw_card())
		if not invalid_initial_field(field, catalog):
			return {
				"deck": deck,
				"player_hand": player_hand,
				"ai_hand": ai_hand,
				"field": field,
				"attempt": attempt
			}
		attempt += 1

	var fallback_deck := DeckState.new(catalog.ids(), _deal_seed(seed_value, attempt), true)
	var fallback_player: Array = []
	var fallback_ai: Array = []
	var fallback_field: Array = []
	for _index in range(8):
		fallback_player.append(fallback_deck.draw_card())
	for _index in range(8):
		fallback_ai.append(fallback_deck.draw_card())
	for _index in range(8):
		fallback_field.append(fallback_deck.draw_card())
	return {
		"deck": fallback_deck,
		"player_hand": fallback_player,
		"ai_hand": fallback_ai,
		"field": fallback_field,
		"attempt": attempt
	}

static func invalid_initial_field(field_ids: Array, catalog: CardCatalog) -> bool:
	var month_counts: Dictionary = {}
	for raw_id in field_ids:
		var definition := catalog.get_card(String(raw_id))
		if definition == null:
			continue
		var month := definition.month
		month_counts[month] = int(month_counts.get(month, 0)) + 1
		if int(month_counts[month]) == 4:
			return true
	return false

static func apply_opening_deal(state: GameState, catalog: CardCatalog) -> void:
	var deal := opening_deal_for_seed(state.seed, catalog)
	state.deck = deal["deck"]
	state.players = [PlayerState.new(0), PlayerState.new(1)]
	state.players[0].hand_ids = Array(deal["player_hand"]).duplicate()
	state.players[1].hand_ids = Array(deal["ai_hand"]).duplicate()
	state.field_ids = Array(deal["field"]).duplicate()
	state.deal_attempt = int(deal["attempt"])
	state.starter_card_ids.clear()
	state.starter_revealed_ids.clear()
	state.starter_player_card_id = ""
	state.starter_ai_card_id = ""
	state.starter_winner_card_id = ""
	state.pending_card_id = ""
	state.pending_card_source = ""
	state.pending_actor_id = -1
	state.pending_match_ids.clear()
	state.turn_index = 0
	state.koi_koi_declared = false
	state.koi_koi_players = [false, false]
	state.terminal_result = {}
	apply_opening_four_of_month_captures(state, catalog)
	state.previous_score_snapshots = [
		YakuEvaluator.evaluate(state.players[0].captured_ids, catalog, state.moon_id),
		YakuEvaluator.evaluate(state.players[1].captured_ids, catalog, state.moon_id)
	]
	state.phase = GameState.PHASE_HAND_PLAY
	state.current_player = state.first_player
	state.last_event = {
		"kind": "deal",
		"message": "January is dealt. Capture matching months and build your yaku."
	}

static func apply_opening_four_of_month_captures(state: GameState, catalog: CardCatalog) -> void:
	for player_state in state.players:
		for month in range(1, 13):
			var month_cards := catalog.cards_for_month(month)
			var has_all := true
			for card_id in month_cards:
				if not player_state.hand_ids.has(card_id):
					has_all = false
					break
			if has_all:
				for card_id in month_cards:
					player_state.hand_ids.erase(card_id)
					player_state.captured_ids.append(card_id)

static func _deal_seed(seed_value: int, attempt: int) -> int:
	return int(seed_value * 1000003 + attempt * 9176 + 7919)
