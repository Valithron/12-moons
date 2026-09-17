class_name MatchController
extends RefCounted

var catalog: CardCatalog
var state: GameState
var replay_log: ReplayLog
var postcondition_probe: Callable = Callable()

func _init(seed_value: int = 0, card_catalog: CardCatalog = null, initial_state: GameState = null, create_replay: bool = true) -> void:
	catalog = card_catalog if card_catalog != null else CardCatalog.new()
	state = initial_state if initial_state != null else GameState.fresh(seed_value, catalog)
	if create_replay:
		replay_log = ReplayLog.new(state.seed, state.to_dict())

func begin_january(seed_value: int = -2147483648) -> void:
	var actual_seed := state.seed if seed_value == -2147483648 else seed_value
	state = JanuarySetup.create_ceremony_state(actual_seed, catalog)
	replay_log = ReplayLog.new(state.seed, state.to_dict())

func legal_actions(actor_id: int) -> Array:
	return ActionGenerator.generate(state, actor_id, catalog)

func is_legal_action(action: GameAction) -> bool:
	if action == null:
		return false
	for candidate in legal_actions(action.actor_id):
		if candidate.equals(action):
			return true
	if action.action_type == GameAction.PLAY_CARD and state.phase == GameState.PHASE_HAND_PLAY and action.actor_id == state.current_player:
		var actor := state.player(action.actor_id)
		if actor == null or not actor.hand_ids.has(action.card_id):
			return false
		var matches := MatchingRules.matching_field_cards(action.card_id, state.field_ids, catalog)
		if action.target_card_id.is_empty():
			return true
		return matches.size() <= 2 and matches.has(action.target_card_id)
	return false

func submit_action(action: GameAction, record: bool = true) -> ActionResult:
	if action == null:
		return ActionResult.rejected("Action is null")
	if not state.invariants_ok(catalog):
		return ActionResult.rejected("Authoritative state is already invalid")
	if not is_legal_action(action):
		return ActionResult.rejected("Action is not legal in the authoritative state")

	var candidate := GameState.from_dict(state.to_dict())
	var outcome := _apply_action(candidate, action)
	if not bool(outcome.get("ok", false)):
		return ActionResult.rejected(String(outcome.get("reason", "Action could not be applied")))
	if postcondition_probe.is_valid():
		postcondition_probe.call(candidate)
	var errors := candidate.invariant_errors(catalog)
	if not errors.is_empty():
		return ActionResult.rejected("State invariant failed: %s" % "; ".join(errors))

	state = candidate
	if record and replay_log != null:
		replay_log.record_action(action)
		if state.phase == GameState.PHASE_MONTH_COMPLETE:
			replay_log.set_terminal_result(state.terminal_result)
	return ActionResult.accepted_action(action, state.state_hash(), Array(outcome.get("captured_ids", [])))

func advance_automatic(record: bool = true) -> bool:
	if state.phase == GameState.PHASE_STARTER_AI_REVEAL:
		var actions := ActionGenerator.generate(state, 1, catalog)
		if actions.is_empty():
			return false
		var chosen := _choose_starter_action(actions)
		var result := submit_action(chosen, record)
		return result.accepted
	if state.phase == GameState.PHASE_STARTER_RESULT:
		var candidate := GameState.from_dict(state.to_dict())
		JanuarySetup.apply_opening_deal(candidate, catalog)
		var errors := candidate.invariant_errors(catalog)
		if not errors.is_empty():
			return false
		state = candidate
		return true
	return false

func _choose_starter_action(actions: Array) -> GameAction:
	# The ceremony cards are face-down. Stable order is the only legal heuristic.
	return actions[0]

func _apply_action(candidate: GameState, action: GameAction) -> Dictionary:
	match action.action_type:
		GameAction.SELECT_STARTER:
			return _apply_starter_selection(candidate, action)
		GameAction.PLAY_CARD:
			return _apply_play_card(candidate, action)
		GameAction.CHOOSE_MATCH:
			return _apply_match_choice(candidate, action)
		GameAction.STOP:
			return _apply_stop(candidate, action)
		GameAction.KOI_KOI:
			return _apply_koi_koi(candidate, action)
	return {"ok": false, "reason": "Unsupported action type"}

func _apply_starter_selection(candidate: GameState, action: GameAction) -> Dictionary:
	if action.actor_id == 0 and candidate.phase == GameState.PHASE_STARTER_PLAYER_SELECT:
		if not candidate.starter_card_ids.has(action.card_id):
			return {"ok": false, "reason": "Starter card is not available"}
		candidate.starter_player_card_id = action.card_id
		candidate.starter_revealed_ids = [action.card_id]
		candidate.current_player = 1
		candidate.phase = GameState.PHASE_STARTER_AI_REVEAL
		candidate.last_event = {
			"kind": "starter_player_reveal",
			"card_id": action.card_id,
			"message": "Your card is revealed. The house chooses from the remaining cards."
		}
		return {"ok": true}
	if action.actor_id == 1 and candidate.phase == GameState.PHASE_STARTER_AI_REVEAL:
		if action.card_id == candidate.starter_player_card_id or not candidate.starter_card_ids.has(action.card_id):
			return {"ok": false, "reason": "Starter card is not available to the house"}
		candidate.starter_ai_card_id = action.card_id
		candidate.starter_revealed_ids.append(action.card_id)
		candidate.starter_winner_card_id = candidate.starter_player_card_id
		var player_definition := catalog.get_card(candidate.starter_player_card_id)
		var ai_definition := catalog.get_card(candidate.starter_ai_card_id)
		if ai_definition != null and player_definition != null and ai_definition.month < player_definition.month:
			candidate.starter_winner_card_id = candidate.starter_ai_card_id
		var winner_definition := catalog.get_card(candidate.starter_winner_card_id)
		candidate.first_player = 0 if candidate.starter_winner_card_id == candidate.starter_player_card_id else 1
		candidate.current_player = candidate.first_player
		candidate.phase = GameState.PHASE_STARTER_RESULT
		candidate.last_event = {
			"kind": "starter_result",
			"card_id": candidate.starter_ai_card_id,
			"message": "Earlier revealed month: %s. %s opens January." % [
				winner_definition.display_name if winner_definition != null else candidate.starter_winner_card_id,
				"Player" if candidate.first_player == 0 else "House"
			]
		}
		return {"ok": true}
	return {"ok": false, "reason": "Starter selection is not active"}

func _apply_play_card(candidate: GameState, action: GameAction) -> Dictionary:
	if candidate.phase != GameState.PHASE_HAND_PLAY or action.actor_id != candidate.current_player:
		return {"ok": false, "reason": "A hand card cannot be played in this phase"}
	var actor := candidate.player(action.actor_id)
	if actor == null or not actor.hand_ids.has(action.card_id):
		return {"ok": false, "reason": "Card is not in the acting hand"}
	var matches := MatchingRules.matching_field_cards(action.card_id, candidate.field_ids, catalog)
	actor.hand_ids.erase(action.card_id)
	candidate.pending_card_id = action.card_id
	candidate.pending_card_source = "hand"
	candidate.pending_actor_id = action.actor_id
	candidate.pending_match_ids = matches.duplicate()
	var captured: Array = []
	if matches.size() == 2 and action.target_card_id.is_empty():
		candidate.phase = GameState.PHASE_HAND_MATCH_CHOICE
		candidate.last_event = {
			"kind": "hand_match_choice",
			"card_id": action.card_id,
			"message": "Choose one of the two matching field cards."
		}
		return {"ok": true, "captured_ids": captured}
	if matches.size() == 2 and not action.target_card_id.is_empty():
		if not matches.has(action.target_card_id):
			return {"ok": false, "reason": "Target is not one of the two matching cards"}
		captured.append_array(_resolve_pending_card(candidate, action.target_card_id))
	elif matches.size() == 0:
		captured.append_array(_resolve_pending_card(candidate, ""))
	elif matches.size() == 1:
		if not action.target_card_id.is_empty() and action.target_card_id != matches[0]:
			return {"ok": false, "reason": "Target does not match the only legal target"}
		captured.append_array(_resolve_pending_card(candidate, String(matches[0])))
	elif matches.size() == 3:
		if not action.target_card_id.is_empty():
			return {"ok": false, "reason": "Three matches capture all four cards"}
		captured.append_array(_resolve_pending_card(candidate, ""))
	else:
		return {"ok": false, "reason": "Invalid number of field matches"}
	_begin_draw_and_progress(candidate)
	return {"ok": true, "captured_ids": captured}

func _apply_match_choice(candidate: GameState, action: GameAction) -> Dictionary:
	if (candidate.phase != GameState.PHASE_HAND_MATCH_CHOICE and candidate.phase != GameState.PHASE_DRAW_MATCH_CHOICE) or action.actor_id != candidate.current_player:
		return {"ok": false, "reason": "A match choice is not active"}
	if candidate.pending_match_ids.size() != 2 or not candidate.pending_match_ids.has(action.target_card_id):
		return {"ok": false, "reason": "Target is not a legal matching field card"}
	var source := candidate.pending_card_source
	var captured := _resolve_pending_card(candidate, action.target_card_id)
	if source == "hand":
		_begin_draw_and_progress(candidate)
	else:
		_finish_turn(candidate)
	return {"ok": true, "captured_ids": captured}

func _resolve_pending_card(candidate: GameState, target_card_id: String) -> Array:
	var captured: Array = []
	var pending_id := candidate.pending_card_id
	var source := candidate.pending_card_source
	var actor := candidate.player(candidate.pending_actor_id)
	if actor == null:
		return captured
	var matches: Array = candidate.pending_match_ids.duplicate()
	if matches.size() == 0:
		candidate.field_ids.append(pending_id)
	elif matches.size() == 1:
		var match_id := String(matches[0])
		candidate.field_ids.erase(match_id)
		captured = [pending_id, match_id]
		actor.captured_ids.append_array(captured)
	elif matches.size() == 2:
		if target_card_id.is_empty() or not matches.has(target_card_id):
			return captured
		candidate.field_ids.erase(target_card_id)
		captured = [pending_id, target_card_id]
		actor.captured_ids.append_array(captured)
	elif matches.size() == 3:
		for match_id in matches:
			candidate.field_ids.erase(match_id)
			captured.append(match_id)
		captured.push_front(pending_id)
		actor.captured_ids.append_array(captured)
	else:
		return captured
	candidate.last_event = {
		"kind": "card_resolution",
		"card_id": pending_id,
		"source": source,
		"captured_ids": captured.duplicate(),
		"message": "Card resolved."
	}
	candidate.pending_card_id = ""
	candidate.pending_card_source = ""
	candidate.pending_actor_id = -1
	candidate.pending_match_ids.clear()
	return captured

func _begin_draw_and_progress(candidate: GameState) -> void:
	candidate.phase = GameState.PHASE_DRAW_REVEAL
	var drawn_id := candidate.deck.draw_card()
	if drawn_id.is_empty():
		candidate.last_event = {
			"kind": "draw_empty",
			"message": "The draw pile is empty."
		}
		_finish_turn(candidate)
		return
	candidate.pending_card_id = drawn_id
	candidate.pending_card_source = "draw"
	candidate.pending_actor_id = candidate.current_player
	candidate.pending_match_ids = MatchingRules.matching_field_cards(drawn_id, candidate.field_ids, catalog)
	candidate.last_event = {
		"kind": "draw_reveal",
		"card_id": drawn_id,
		"source": "draw",
		"message": "Draw card revealed."
	}
	if candidate.pending_match_ids.size() == 2:
		candidate.phase = GameState.PHASE_DRAW_MATCH_CHOICE
		candidate.last_event["message"] = "Choose one of the two matching field cards for the draw."
		return
	var target := String(candidate.pending_match_ids[0]) if candidate.pending_match_ids.size() == 1 else ""
	_resolve_pending_card(candidate, target)
	_finish_turn(candidate)

func _finish_turn(candidate: GameState) -> void:
	var actor := candidate.player(candidate.current_player)
	if actor == null:
		return
	var score := YakuEvaluator.evaluate(actor.captured_ids, catalog, candidate.moon_id)
	var previous: Dictionary = candidate.previous_score_snapshots[candidate.current_player]
	var can_continue := _can_continue(candidate)
	if YakuEvaluator.is_improvement(previous, score) and can_continue:
		candidate.phase = GameState.PHASE_SCORE_DECISION
		candidate.last_event = {
			"kind": "score_decision",
			"message": "Your yaku improved. Stop or Koi-Koi?",
			"score": score.duplicate(true)
		}
		return
	candidate.previous_score_snapshots[candidate.current_player] = score.duplicate(true)
	if actor.hand_ids.is_empty() or candidate.deck.remaining_count() == 0:
		_end_month(candidate, "exhaustion", -1)
		return
	_pass_turn(candidate)

func _can_continue(candidate: GameState) -> bool:
	var actor := candidate.player(candidate.current_player)
	if actor == null or actor.hand_ids.is_empty():
		return false
	return candidate.deck.remaining_count() > 0

func _pass_turn(candidate: GameState) -> void:
	candidate.turn_index += 1
	candidate.current_player = 1 - candidate.current_player
	candidate.phase = GameState.PHASE_HAND_PLAY
	candidate.pending_card_id = ""
	candidate.pending_card_source = ""
	candidate.pending_actor_id = -1
	candidate.pending_match_ids.clear()

func _apply_stop(candidate: GameState, action: GameAction) -> Dictionary:
	if candidate.phase != GameState.PHASE_SCORE_DECISION or action.actor_id != candidate.current_player:
		return {"ok": false, "reason": "Stop is not currently available"}
	_end_month(candidate, "stop", action.actor_id)
	return {"ok": true}

func _apply_koi_koi(candidate: GameState, action: GameAction) -> Dictionary:
	if candidate.phase != GameState.PHASE_SCORE_DECISION or action.actor_id != candidate.current_player:
		return {"ok": false, "reason": "Koi-Koi is not currently available"}
	candidate.koi_koi_declared = true
	candidate.koi_koi_players[action.actor_id] = true
	var actor := candidate.player(action.actor_id)
	candidate.previous_score_snapshots[action.actor_id] = YakuEvaluator.evaluate(actor.captured_ids, catalog, candidate.moon_id)
	_pass_turn(candidate)
	candidate.last_event = {
		"kind": "koi_koi",
		"message": "Koi-Koi declared. The month continues."
	}
	return {"ok": true}

func _end_month(candidate: GameState, ended_by: String, stop_player_id: int) -> void:
	var settlement := YakuEvaluator.settle(
		candidate.players[0].captured_ids,
		candidate.players[1].captured_ids,
		catalog,
		candidate.moon_id,
		candidate.koi_koi_declared
	)
	settlement["month"] = candidate.month
	settlement["moon_id"] = candidate.moon_id
	settlement["ended_by"] = ended_by
	settlement["stop_player_id"] = stop_player_id
	candidate.terminal_result = settlement
	candidate.phase = GameState.PHASE_MONTH_COMPLETE
	candidate.pending_card_id = ""
	candidate.pending_card_source = ""
	candidate.pending_actor_id = -1
	candidate.pending_match_ids.clear()
	candidate.last_event = {
		"kind": "month_complete",
		"message": "January is complete.",
		"ended_by": ended_by
	}
