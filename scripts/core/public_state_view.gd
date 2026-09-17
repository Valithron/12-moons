class_name PublicStateView
extends RefCounted

static func for_actor(state: GameState, actor_id: int) -> Dictionary:
	var view_players: Array = []
	for player_state in state.players:
		var public_player := {
			"player_id": player_state.player_id,
			"capture_ids": player_state.captured_ids.duplicate(),
			"hand_count": player_state.hand_ids.size()
		}
		if player_state.player_id == actor_id:
			public_player["hand_ids"] = player_state.hand_ids.duplicate()
		view_players.append(public_player)
	return {
		"seed": state.seed,
		"players": view_players,
		"field_ids": state.field_ids.duplicate(),
		"draw_remaining_count": state.deck.remaining_count(),
		"turn_index": state.turn_index,
		"current_player": state.current_player,
		"terminal_result": state.terminal_result.duplicate(true)
	}
