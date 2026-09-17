class_name ActionGenerator
extends RefCounted

static func generate(state: GameState, actor_id: int, catalog: CardCatalog) -> Array:
	var result: Array = []
	if actor_id != state.current_player:
		return result

	if state.phase == GameState.PHASE_STARTER_PLAYER_SELECT and actor_id == 0:
		for card_id in state.starter_card_ids:
			result.append(GameAction.new(GameAction.SELECT_STARTER, actor_id, String(card_id), ""))
		return result

	if state.phase == GameState.PHASE_STARTER_AI_REVEAL and actor_id == 1:
		for card_id in state.starter_card_ids:
			if String(card_id) != state.starter_player_card_id:
				result.append(GameAction.new(GameAction.SELECT_STARTER, actor_id, String(card_id), ""))
		return result

	if state.phase == GameState.PHASE_HAND_PLAY:
		var actor := state.player(actor_id)
		if actor == null:
			return result
		for card_id in actor.hand_ids:
			result.append(GameAction.new(GameAction.PLAY_CARD, actor_id, String(card_id), ""))
		return result

	if state.phase == GameState.PHASE_HAND_MATCH_CHOICE or state.phase == GameState.PHASE_DRAW_MATCH_CHOICE:
		for match_id in state.pending_match_ids:
			result.append(GameAction.new(GameAction.CHOOSE_MATCH, actor_id, state.pending_card_id, String(match_id)))
		return result

	if state.phase == GameState.PHASE_SCORE_DECISION:
		result.append(GameAction.new(GameAction.STOP, actor_id))
		result.append(GameAction.new(GameAction.KOI_KOI, actor_id))
	return result
