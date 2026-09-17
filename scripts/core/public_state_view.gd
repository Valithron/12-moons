class_name PublicStateView
extends RefCounted

static func for_actor(state: GameState, actor_id: int, card_catalog: CardCatalog = null) -> Dictionary:
	var catalog := card_catalog if card_catalog != null else CardCatalog.new()
	var view_players: Array = []
	for player_state in state.players:
		var public_player := {
			"player_id": player_state.player_id,
			"capture_ids": player_state.captured_ids.duplicate(),
			"captured_ids": player_state.captured_ids.duplicate(),
			"hand_count": player_state.hand_ids.size()
		}
		if player_state.player_id == actor_id:
			public_player["hand_ids"] = player_state.hand_ids.duplicate()
		view_players.append(public_player)

	var score_views: Array = []
	for player_state in state.players:
		score_views.append(YakuEvaluator.evaluate(player_state.captured_ids, catalog, state.moon_id))

	var view := {
		"players": view_players,
		"field_ids": state.field_ids.duplicate(),
		"draw_remaining_count": state.deck.remaining_count(),
		"turn_index": state.turn_index,
		"current_player": state.current_player,
		"phase": state.phase,
		"month": state.month,
		"moon_id": state.moon_id,
		"scores": score_views,
		"koi_koi_declared": state.koi_koi_declared,
		"pending_card_id": state.pending_card_id,
		"pending_card_source": state.pending_card_source,
		"pending_match_ids": state.pending_match_ids.duplicate(),
		"starter_revealed_ids": state.starter_revealed_ids.duplicate(),
		"starter_player_card_id": state.starter_player_card_id,
		"starter_ai_card_id": state.starter_ai_card_id,
		"terminal_result": state.terminal_result.duplicate(true)
	}
	if actor_id < 0 or actor_id >= view_players.size():
		view["actor_id"] = actor_id
	else:
		view["actor_id"] = actor_id
	return view
