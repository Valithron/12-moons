class_name GameState
extends RefCounted

const PHASE_STARTER_PLAYER_SELECT := "starter_player_select"
const PHASE_STARTER_AI_REVEAL := "starter_ai_reveal"
const PHASE_STARTER_RESULT := "starter_result"
const PHASE_HAND_PLAY := "hand_play"
const PHASE_HAND_MATCH_CHOICE := "hand_match_choice"
const PHASE_DRAW_REVEAL := "draw_reveal"
const PHASE_DRAW_MATCH_CHOICE := "draw_match_choice"
const PHASE_SCORE_DECISION := "score_decision"
const PHASE_MONTH_COMPLETE := "month_complete"

var seed: int = 0
var deck: DeckState = DeckState.new()
var players: Array = []
var field_ids: Array = []
var current_player: int = 0
var first_player: int = 0
var turn_index: int = 0
var month: int = 1
var moon_id: String = "wolf_moon"
var phase: String = PHASE_HAND_PLAY

var starter_card_ids: Array = []
var starter_revealed_ids: Array = []
var starter_player_card_id: String = ""
var starter_ai_card_id: String = ""
var starter_winner_card_id: String = ""
var deal_attempt: int = 0

var pending_card_id: String = ""
var pending_card_source: String = ""
var pending_actor_id: int = -1
var pending_match_ids: Array = []

var previous_score_snapshots: Array = []
var koi_koi_declared: bool = false
var koi_koi_players: Array = []
var last_event: Dictionary = {}
var terminal_result: Dictionary = {}

func _init() -> void:
	players = [PlayerState.new(0), PlayerState.new(1)]
	previous_score_snapshots = [{}, {}]
	koi_koi_players = [false, false]

static func fresh(seed_value: int, catalog: CardCatalog) -> GameState:
	var result := GameState.new()
	result.seed = seed_value
	result.deck = DeckState.new(catalog.ids(), seed_value)
	result.phase = PHASE_HAND_PLAY
	return result

func player(player_id: int) -> PlayerState:
	if player_id < 0 or player_id >= players.size():
		return null
	return players[player_id]

func all_authoritative_ids() -> Array:
	var result: Array = []
	if deck.draw_index >= 0 and deck.draw_index <= deck.cards.size():
		result.append_array(deck.remaining_cards())
	else:
		result.append_array(deck.cards)
	result.append_array(starter_card_ids)
	result.append_array(field_ids)
	for player_state in players:
		result.append_array(player_state.hand_ids)
		result.append_array(player_state.captured_ids)
	if not pending_card_id.is_empty():
		result.append(pending_card_id)
	return result

func invariant_errors(catalog: CardCatalog) -> Array:
	var errors: Array = []
	var known_ids := catalog.ids()
	var known_lookup: Dictionary = {}
	for card_id in known_ids:
		known_lookup[String(card_id)] = true

	if players.size() != 2:
		errors.append("Expected exactly two players, got %d" % players.size())
	var player_ids: Dictionary = {}
	for player_state in players:
		if player_state == null:
			errors.append("Null player state")
			continue
		if player_ids.has(player_state.player_id):
			errors.append("Duplicate player ID: %d" % player_state.player_id)
		player_ids[player_state.player_id] = true
		if player_state.player_id < 0 or player_state.player_id > 1:
			errors.append("Invalid player ID: %d" % player_state.player_id)

	if deck.draw_index < 0 or deck.draw_index > deck.cards.size():
		errors.append("Invalid deck draw index: %d" % deck.draw_index)

	var deck_seen: Dictionary = {}
	for raw_id in deck.cards:
		var deck_id := String(raw_id)
		if not known_lookup.has(deck_id):
			errors.append("Unknown card ID in deck: %s" % deck_id)
		if deck_seen.has(deck_id):
			errors.append("Card appears twice in deck order: %s" % deck_id)
		deck_seen[deck_id] = true

	var starter_seen: Dictionary = {}
	var starter_months: Dictionary = {}
	for raw_id in starter_card_ids:
		var starter_id := String(raw_id)
		if not known_lookup.has(starter_id):
			errors.append("Unknown starter card ID: %s" % starter_id)
		if starter_seen.has(starter_id):
			errors.append("Starter card appears twice: %s" % starter_id)
		starter_seen[starter_id] = true
		var starter_definition := catalog.get_card(starter_id)
		if starter_definition != null:
			if starter_months.has(starter_definition.month):
				errors.append("Starter cards contain a repeated month: %d" % starter_definition.month)
			starter_months[starter_definition.month] = true

	var revealed_starter_seen: Dictionary = {}
	for raw_id in starter_revealed_ids:
		var revealed_id := String(raw_id)
		if not starter_seen.has(revealed_id):
			errors.append("Revealed starter is not in the ceremony: %s" % revealed_id)
		if revealed_starter_seen.has(revealed_id):
			errors.append("Starter card was revealed twice: %s" % revealed_id)
		revealed_starter_seen[revealed_id] = true
	for selected_id in [starter_player_card_id, starter_ai_card_id, starter_winner_card_id]:
		if not String(selected_id).is_empty() and not starter_seen.has(String(selected_id)):
			errors.append("Selected starter is not in the ceremony: %s" % selected_id)

	var expected_deck_ids: Dictionary = {}
	for card_id in known_ids:
		expected_deck_ids[String(card_id)] = true
	for starter_id in starter_seen.keys():
		expected_deck_ids.erase(String(starter_id))
	if deck_seen.size() != expected_deck_ids.size():
		errors.append("Deck order contains %d cards; expected %d" % [deck_seen.size(), expected_deck_ids.size()])
	for deck_id in expected_deck_ids.keys():
		if not deck_seen.has(deck_id):
			errors.append("Card missing from deck order: %s" % deck_id)

	var zone_seen: Dictionary = {}
	for raw_id in all_authoritative_ids():
		var normalized := String(raw_id)
		if not known_lookup.has(normalized):
			errors.append("Unknown card ID: %s" % normalized)
		if zone_seen.has(normalized):
			errors.append("Card exists in multiple authoritative zones: %s" % normalized)
		zone_seen[normalized] = true
	if zone_seen.size() != known_ids.size():
		errors.append("Expected all %d physical cards in authoritative zones, got %d" % [known_ids.size(), zone_seen.size()])
	for card_id in known_ids:
		if not zone_seen.has(String(card_id)):
			errors.append("Physical card is missing from authoritative zones: %s" % card_id)

	if current_player < 0 or current_player > 1:
		errors.append("Invalid current player: %d" % current_player)
	if first_player < 0 or first_player > 1:
		errors.append("Invalid first player: %d" % first_player)
	if previous_score_snapshots.size() != 2:
		errors.append("Expected two score snapshots")
	if koi_koi_players.size() != 2:
		errors.append("Expected two Koi-Koi player flags")

	var choice_phase := phase == PHASE_HAND_MATCH_CHOICE or phase == PHASE_DRAW_MATCH_CHOICE
	if choice_phase:
		if pending_card_id.is_empty():
			errors.append("Match-choice phase has no pending card")
		if pending_actor_id != current_player:
			errors.append("Pending actor does not own the turn")
		var expected_source := "hand" if phase == PHASE_HAND_MATCH_CHOICE else "draw"
		if pending_card_source != expected_source:
			errors.append("Pending source does not match phase: %s" % pending_card_source)
		if pending_match_ids.size() != 2:
			errors.append("Match-choice phase must expose exactly two targets")
		for match_id in pending_match_ids:
			if not field_ids.has(match_id):
				errors.append("Pending match is not on the field: %s" % match_id)
			elif pending_card_id != "":
				var pending_definition := catalog.get_card(pending_card_id)
				var match_definition := catalog.get_card(String(match_id))
				if pending_definition == null or match_definition == null or pending_definition.month != match_definition.month:
					errors.append("Pending match has the wrong month: %s" % match_id)
	elif phase == PHASE_DRAW_REVEAL:
		if pending_card_id.is_empty():
			errors.append("Draw-reveal phase has no pending card")
		if pending_card_source != "draw":
			errors.append("Draw-reveal phase has a non-draw pending source")
		if pending_actor_id != current_player:
			errors.append("Draw-reveal pending actor does not own the turn")
		if pending_match_ids.size() > 3:
			errors.append("Draw-reveal phase has too many matches")
	else:
		if not pending_card_id.is_empty():
			errors.append("Unexpected pending card outside a resolution phase: %s" % pending_card_id)
		if not pending_card_source.is_empty():
			errors.append("Unexpected pending source outside a resolution phase: %s" % pending_card_source)
		if pending_actor_id != -1:
			errors.append("Unexpected pending actor outside a resolution phase")
		if not pending_match_ids.is_empty():
			errors.append("Unexpected pending matches outside a resolution phase")

	var valid_phases := [
		PHASE_STARTER_PLAYER_SELECT,
		PHASE_STARTER_AI_REVEAL,
		PHASE_STARTER_RESULT,
		PHASE_HAND_PLAY,
		PHASE_HAND_MATCH_CHOICE,
		PHASE_DRAW_REVEAL,
		PHASE_DRAW_MATCH_CHOICE,
		PHASE_SCORE_DECISION,
		PHASE_MONTH_COMPLETE
	]
	if not valid_phases.has(phase):
		errors.append("Unknown gameplay phase: %s" % phase)
	if phase == PHASE_STARTER_PLAYER_SELECT or phase == PHASE_STARTER_AI_REVEAL or phase == PHASE_STARTER_RESULT:
		if starter_card_ids.size() != 3:
			errors.append("Starter ceremony must contain three cards")
		if starter_revealed_ids.size() > 3:
			errors.append("Too many revealed starter cards")
		if phase == PHASE_STARTER_PLAYER_SELECT and (current_player != 0 or starter_revealed_ids.size() != 0):
			errors.append("Player starter-selection phase is internally inconsistent")
		if phase == PHASE_STARTER_AI_REVEAL and (current_player != 1 or starter_player_card_id.is_empty() or starter_revealed_ids.size() != 1):
			errors.append("AI starter-reveal phase is internally inconsistent")
		if phase == PHASE_STARTER_RESULT and (starter_player_card_id.is_empty() or starter_ai_card_id.is_empty() or starter_revealed_ids.size() != 2):
			errors.append("Starter-result phase is internally inconsistent")
	if phase == PHASE_MONTH_COMPLETE and terminal_result.is_empty():
		errors.append("Month-complete state has no terminal result")

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
		"deck_seed": deck.seed,
		"starter_card_ids": starter_card_ids.duplicate(),
		"starter_revealed_ids": starter_revealed_ids.duplicate(),
		"starter_player_card_id": starter_player_card_id,
		"starter_ai_card_id": starter_ai_card_id,
		"starter_winner_card_id": starter_winner_card_id,
		"deal_attempt": deal_attempt,
		"field_ids": _sorted(field_ids),
		"players": canonical_players,
		"current_player": current_player,
		"first_player": first_player,
		"turn_index": turn_index,
		"month": month,
		"moon_id": moon_id,
		"phase": phase,
		"pending_card_id": pending_card_id,
		"pending_card_source": pending_card_source,
		"pending_actor_id": pending_actor_id,
		"pending_match_ids": _sorted(pending_match_ids),
		"previous_score_snapshots": previous_score_snapshots.duplicate(true),
		"koi_koi_declared": koi_koi_declared,
		"koi_koi_players": koi_koi_players.duplicate(),
		"last_event": last_event.duplicate(true),
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
		"first_player": first_player,
		"turn_index": turn_index,
		"month": month,
		"moon_id": moon_id,
		"phase": phase,
		"starter_card_ids": starter_card_ids.duplicate(),
		"starter_revealed_ids": starter_revealed_ids.duplicate(),
		"starter_player_card_id": starter_player_card_id,
		"starter_ai_card_id": starter_ai_card_id,
		"starter_winner_card_id": starter_winner_card_id,
		"deal_attempt": deal_attempt,
		"pending_card_id": pending_card_id,
		"pending_card_source": pending_card_source,
		"pending_actor_id": pending_actor_id,
		"pending_match_ids": pending_match_ids.duplicate(),
		"previous_score_snapshots": previous_score_snapshots.duplicate(true),
		"koi_koi_declared": koi_koi_declared,
		"koi_koi_players": koi_koi_players.duplicate(),
		"last_event": last_event.duplicate(true),
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
	result.first_player = int(data.get("first_player", 0))
	result.turn_index = int(data.get("turn_index", 0))
	result.month = int(data.get("month", 1))
	result.moon_id = String(data.get("moon_id", "wolf_moon"))
	result.phase = String(data.get("phase", PHASE_HAND_PLAY))
	result.starter_card_ids = Array(data.get("starter_card_ids", [])).duplicate()
	result.starter_revealed_ids = Array(data.get("starter_revealed_ids", [])).duplicate()
	result.starter_player_card_id = String(data.get("starter_player_card_id", ""))
	result.starter_ai_card_id = String(data.get("starter_ai_card_id", ""))
	result.starter_winner_card_id = String(data.get("starter_winner_card_id", ""))
	result.deal_attempt = int(data.get("deal_attempt", 0))
	result.pending_card_id = String(data.get("pending_card_id", ""))
	result.pending_card_source = String(data.get("pending_card_source", ""))
	result.pending_actor_id = int(data.get("pending_actor_id", -1))
	result.pending_match_ids = Array(data.get("pending_match_ids", [])).duplicate()
	result.previous_score_snapshots = Array(data.get("previous_score_snapshots", [{}, {}])).duplicate(true)
	if result.previous_score_snapshots.size() != 2:
		result.previous_score_snapshots = [{}, {}]
	result.koi_koi_declared = bool(data.get("koi_koi_declared", false))
	result.koi_koi_players = Array(data.get("koi_koi_players", [false, false])).duplicate()
	if result.koi_koi_players.size() != 2:
		result.koi_koi_players = [false, false]
	result.last_event = Dictionary(data.get("last_event", {})).duplicate(true)
	result.terminal_result = Dictionary(data.get("terminal_result", {})).duplicate(true)
	return result
