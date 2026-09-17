class_name ReplayLog
extends RefCounted

var initial_seed: int = 0
var initial_state: Dictionary = {}
var actions: Array = []
var terminal_result: Dictionary = {}

func _init(seed_value: int = 0, state_snapshot: Dictionary = {}) -> void:
	initial_seed = seed_value
	initial_state = state_snapshot.duplicate(true)

func record_action(action: GameAction) -> void:
	actions.append(action.to_dict())

func set_terminal_result(result: Dictionary) -> void:
	terminal_result = result.duplicate(true)

func to_dict() -> Dictionary:
	return {
		"initial_seed": initial_seed,
		"initial_state": initial_state.duplicate(true),
		"actions": actions.duplicate(true),
		"terminal_result": terminal_result.duplicate(true)
	}

func to_json() -> String:
	return JSON.stringify(to_dict())

func replay_final_hash(catalog: CardCatalog) -> String:
	var replay_state := GameState.from_dict(initial_state)
	var controller := MatchController.new(initial_seed, catalog, replay_state, false)
	for action_data in actions:
		# AI ceremony choices are recorded actions. Only the deterministic deal
		# transition after the ceremony is advanced implicitly.
		if controller.state.phase == GameState.PHASE_STARTER_RESULT:
			while controller.advance_automatic(false):
				pass
		var result := controller.submit_action(GameAction.from_dict(action_data), false)
		if not result.accepted:
			return ""
	if controller.state.phase == GameState.PHASE_STARTER_RESULT:
		while controller.advance_automatic(false):
			pass
	return controller.state.state_hash()
