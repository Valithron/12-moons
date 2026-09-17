class_name SimpleAI
extends RefCounted

static func choose_action(public_view: Dictionary, legal_actions: Array, catalog: CardCatalog) -> GameAction:
	if legal_actions.is_empty():
		return null
	var phase := String(public_view.get("phase", ""))
	if phase == GameState.PHASE_STARTER_AI_REVEAL:
		return _choose_starter(legal_actions, catalog)
	if phase == GameState.PHASE_HAND_PLAY:
		return _choose_hand_play(public_view, legal_actions, catalog)
	if phase == GameState.PHASE_HAND_MATCH_CHOICE or phase == GameState.PHASE_DRAW_MATCH_CHOICE:
		return _choose_match(public_view, legal_actions, catalog)
	if phase == GameState.PHASE_SCORE_DECISION:
		return _choose_score_decision(public_view, legal_actions)
	return legal_actions[0]

static func _choose_starter(legal_actions: Array, catalog: CardCatalog) -> GameAction:
	# Ceremony cards remain face-down to the AI. Choose stable first available.
	return legal_actions[0]

static func _choose_hand_play(public_view: Dictionary, legal_actions: Array, catalog: CardCatalog) -> GameAction:
	var field_ids: Array = Array(public_view.get("field_ids", []))
	var actor_id := int(public_view.get("actor_id", 1))
	var actor_view := _player_view(public_view, actor_id)
	var ranked: Array = []
	for raw_action in legal_actions:
		var action: GameAction = raw_action
		var definition := catalog.get_card(action.card_id)
		var matches := MatchingRules.matching_field_cards(action.card_id, field_ids, catalog)
		var capture_bonus := 1000 if not matches.is_empty() else 0
		var score := capture_bonus + _card_priority(definition) + matches.size() * 25
		ranked.append({"score": score, "card_id": action.card_id, "action": action})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["score"]) != int(b["score"]):
			return int(a["score"]) > int(b["score"])
		return String(a["card_id"]) < String(b["card_id"])
	)
	if ranked.is_empty():
		return legal_actions[0]
	return ranked[0]["action"]

static func _choose_match(public_view: Dictionary, legal_actions: Array, catalog: CardCatalog) -> GameAction:
	var ranked: Array = []
	for raw_action in legal_actions:
		var action: GameAction = raw_action
		var definition := catalog.get_card(action.target_card_id)
		var score := _card_priority(definition)
		ranked.append({"score": score, "card_id": action.target_card_id, "action": action})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["score"]) != int(b["score"]):
			return int(a["score"]) > int(b["score"])
		return String(a["card_id"]) < String(b["card_id"])
	)
	return ranked[0]["action"] if not ranked.is_empty() else legal_actions[0]

static func _choose_score_decision(public_view: Dictionary, legal_actions: Array) -> GameAction:
	var actor_id := int(public_view.get("actor_id", 1))
	var players: Array = Array(public_view.get("players", []))
	var scores: Array = Array(public_view.get("scores", []))
	var hand_count := 0
	if actor_id >= 0 and actor_id < players.size():
		hand_count = int(players[actor_id].get("hand_count", 0))
	var current_score := 0
	if actor_id >= 0 and actor_id < scores.size():
		current_score = int(scores[actor_id].get("additive_subtotal", 0))
	for raw_action in legal_actions:
		var action: GameAction = raw_action
		if action.action_type == GameAction.STOP and (current_score >= 5 or hand_count <= 2):
			return action
	for raw_action in legal_actions:
		var action: GameAction = raw_action
		if action.action_type == GameAction.KOI_KOI:
			return action
	return legal_actions[0]

static func _player_view(public_view: Dictionary, actor_id: int) -> Dictionary:
	var players: Array = Array(public_view.get("players", []))
	if actor_id < 0 or actor_id >= players.size():
		return {}
	return players[actor_id]

static func _card_priority(definition: CardDefinition) -> int:
	if definition == null:
		return 0
	var score := 0
	if definition.has_tag("bright"):
		score += 100
	if definition.has_tag("sake_cup"):
		score += 95
	if definition.has_tag("boar") or definition.has_tag("deer") or definition.has_tag("butterfly"):
		score += 85
	if definition.base_class == "animal":
		score += 65
	if definition.base_class == "ribbon":
		score += 45
	if definition.base_class == "chaff":
		score += 10
	if definition.has_tag("poetry_ribbon") or definition.has_tag("blue_ribbon"):
		score += 12
	return score
