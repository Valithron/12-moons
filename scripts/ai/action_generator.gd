class_name ActionGenerator
extends RefCounted

static func generate(state: GameState, actor_id: int, catalog: CardCatalog) -> Array:
	var result: Array = []
	var actor := state.player(actor_id)
	if actor == null or actor_id != state.current_player:
		return result
	for card_id in actor.hand_ids:
		var normalized := String(card_id)
		var matches := MatchingRules.matching_field_cards(normalized, state.field_ids, catalog)
		if matches.size() == 2:
			for target in matches:
				result.append(GameAction.new(GameAction.PLAY_CARD, actor_id, normalized, String(target)))
		elif matches.size() == 1:
			result.append(GameAction.new(GameAction.PLAY_CARD, actor_id, normalized, String(matches[0])))
		else:
			result.append(GameAction.new(GameAction.PLAY_CARD, actor_id, normalized, ""))
	return result
