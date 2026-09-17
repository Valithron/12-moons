class_name MatchController
extends RefCounted

var catalog: CardCatalog
var state: GameState
var replay_log: ReplayLog

func _init(seed_value: int = 0, card_catalog: CardCatalog = null, initial_state: GameState = null, create_replay: bool = true) -> void:
	catalog = card_catalog if card_catalog != null else CardCatalog.new()
	state = initial_state if initial_state != null else GameState.fresh(seed_value, catalog)
	if create_replay:
		replay_log = ReplayLog.new(state.seed, state.to_dict())

func legal_actions(actor_id: int) -> Array:
	return ActionGenerator.generate(state, actor_id, catalog)

func is_legal_action(action: GameAction) -> bool:
	for candidate in legal_actions(action.actor_id):
		if candidate.equals(action):
			return true
	return false

func submit_action(action: GameAction, record: bool = true) -> ActionResult:
	if action == null:
		return ActionResult.rejected("Action is null")
	if action.action_type != GameAction.PLAY_CARD:
		return ActionResult.rejected("Unsupported action type")
	if action.actor_id != state.current_player:
		return ActionResult.rejected("It is not this actor's turn")
	if not is_legal_action(action):
		return ActionResult.rejected("Action is not legal in the authoritative state")

	var actor := state.player(action.actor_id)
	var matches := MatchingRules.matching_field_cards(action.card_id, state.field_ids, catalog)
	var captured: Array = [action.card_id]
	actor.hand_ids.erase(action.card_id)

	if matches.size() == 0:
		state.field_ids.append(action.card_id)
	elif matches.size() == 3:
		for match_id in matches:
			state.field_ids.erase(match_id)
			captured.append(match_id)
		actor.captured_ids.append_array(captured)
	else:
		state.field_ids.erase(action.target_card_id)
		captured.append(action.target_card_id)
		actor.captured_ids.append_array(captured)

	state.current_player = 1 - state.current_player
	state.turn_index += 1
	var errors := state.invariant_errors(catalog)
	if not errors.is_empty():
		return ActionResult.rejected("State invariant failed: %s" % "; ".join(errors))
	if record and replay_log != null:
		replay_log.record_action(action)
	return ActionResult.accepted_action(action, state.state_hash(), captured if matches.size() > 0 else [])
