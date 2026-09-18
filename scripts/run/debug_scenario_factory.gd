class_name DebugScenarioFactory
extends RefCounted

const SCENARIOS := [
	"terminal_january_win",
	"terminal_january_loss",
	"liquidation_required",
	"bankruptcy",
	"reward_phase",
	"carry_management",
	"initial_shop",
	"shop_after_reroll_1",
	"shop_after_reroll_2",
	"full_capacity",
	"february_placeholder"
]

static func create_controller(scenario: String, seed_value: int = 1201) -> RunController:
	var controller := RunController.new(seed_value)
	match scenario:
		"terminal_january_win":
			_prepare_result(controller, 8, 3)
		"terminal_january_loss":
			_prepare_result(controller, 3, 8)
		"liquidation_required":
			_prepare_result(controller, 30, 31)
			controller.state.modifier_instances["scenario_modifier"] = _modifier("scenario_modifier", "wider_choice", "active")
			controller.state.active_modifier_ids = ["scenario_modifier"]
			controller.state.unlocked_active_capacity = 1
			controller.liquidation_quote_provider = func(_instance_id: String, _state: RunState) -> int: return 30
			_reset_journal(controller)
			controller.submit_action(RunAction.new(RunAction.SETTLE))
		"bankruptcy":
			_prepare_result(controller, 30, 31)
			controller.state.modifier_instances["scenario_modifier"] = _modifier("scenario_modifier", "wider_choice", "active")
			controller.state.active_modifier_ids = ["scenario_modifier"]
			controller.state.unlocked_active_capacity = 1
			controller.liquidation_quote_provider = func(_instance_id: String, _state: RunState) -> int: return 0
			_reset_journal(controller)
			controller.submit_action(RunAction.new(RunAction.SETTLE))
			controller.submit_action(RunAction.new(RunAction.LIQUIDATE, 0, {"instance_id": "scenario_modifier"}))
		"reward_phase":
			controller.state.phase = RunState.PHASE_REWARD
			controller.state.unlocked_active_capacity = 1
			_prepare_reward_offer(controller)
		"carry_management":
			_prepare_carry(controller)
		"initial_shop":
			_prepare_carry(controller)
			controller.submit_action(RunAction.new(RunAction.ENTER_SHOP, 0, {"duplicate_policy": "unique_definition"}))
		"shop_after_reroll_1":
			_prepare_carry(controller)
			controller.submit_action(RunAction.new(RunAction.ENTER_SHOP, 0, {"duplicate_policy": "unique_definition"}))
			controller.submit_action(RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": "unique_definition"}))
		"shop_after_reroll_2":
			_prepare_carry(controller)
			controller.submit_action(RunAction.new(RunAction.ENTER_SHOP, 0, {"duplicate_policy": "unique_definition"}))
			controller.submit_action(RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": "unique_definition"}))
			controller.submit_action(RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": "unique_definition"}))
		"full_capacity":
			_prepare_full_capacity(controller)
		"february_placeholder":
			controller.state.month = 2
			controller.state.phase = RunState.PHASE_FEBRUARY_PLACEHOLDER
			controller.state.last_event = {"kind": "february_placeholder_started", "message": "February placeholder scenario."}
			_reset_journal(controller)
		_:
			controller.state.last_event = {"kind": "unknown_scenario", "scenario": scenario}
	return controller

static func inspect(controller: RunController) -> Dictionary:
	if controller == null:
		return {}
	return {
		"root_seed": controller.state.root_seed,
		"run_hash": controller.state.state_hash(),
		"phase": controller.state.phase,
		"month": controller.state.month,
		"bankroll": controller.state.bankroll,
		"active_capacity": controller.state.unlocked_active_capacity,
		"reserve_capacity": controller.state.reserve_capacity,
		"active_modifier_ids": controller.state.active_modifier_ids.duplicate(),
		"reserve_modifier_ids": controller.state.reserve_modifier_ids.duplicate(),
		"attachments": controller.state.card_upgrade_attachments.duplicate(true),
		"reward_offer_ids": _offer_ids(controller.state.reward_state, "offers"),
		"shop_offer_ids": _offer_ids(controller.state.shop_state, "offers"),
		"rng_scopes": controller.state.generation_counters.duplicate(true),
		"action_journal": controller.journal.entries.duplicate(true),
		"match_hash": String(controller.state.last_match_result.get("source_match_hash", ""))
	}

static func _prepare_result(controller: RunController, player_score: int, ai_score: int) -> void:
	var result := MatchResult.new()
	result.match_id = "scenario_match_%d_%d" % [player_score, ai_score]
	result.source_match_hash = "scenario_source_%d_%d" % [player_score, ai_score]
	result.month = 1
	result.moon_id = "wolf_moon"
	result.winner_id = 0 if player_score > ai_score else (1 if ai_score > player_score else -1)
	result.player_score = {"final_score": player_score}
	result.ai_score = {"final_score": ai_score}
	controller.ingest_match_result(result)

static func _prepare_reward_offer(controller: RunController) -> void:
	var reward := RewardState.new()
	reward.generated = true
	var offer := RewardOffer.new()
	offer.offer_id = "scenario_reward_1"
	offer.definition_id = "wider_choice"
	offer.slot_index = 0
	offer.slot_spec = RewardRequest.SLOT_ANY
	offer.source = "scenario"
	reward.offers = [offer.to_dict()]
	controller.state.reward_state = reward.to_dict()
	controller.state.last_event = {"kind": "scenario_reward_ready", "message": "Scenario reward is ready."}
	_reset_journal(controller)

static func _prepare_carry(controller: RunController) -> void:
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	controller.state.last_event = {"kind": "scenario_carry_ready", "message": "Carry management scenario is ready."}
	_reset_journal(controller)

static func _prepare_full_capacity(controller: RunController) -> void:
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	controller.state.reserve_capacity = 4
	controller.state.modifier_instances["scenario_active"] = _modifier("scenario_active", "wider_choice", "active")
	controller.state.active_modifier_ids = ["scenario_active"]
	for index in range(4):
		var id := "scenario_reserve_%d" % index
		controller.state.modifier_instances[id] = _modifier(id, "wider_choice", "reserve")
		controller.state.reserve_modifier_ids.append(id)
	controller.state.last_event = {"kind": "scenario_full_capacity", "message": "Both carry locations are full."}
	_reset_journal(controller)

static func _reset_journal(controller: RunController) -> void:
	controller.journal = RunJournal.new(controller.state.root_seed, controller.state.to_dict())

static func _modifier(instance_id: String, definition_id: String, location: String) -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"location": location,
		"source": "scenario",
		"acquired_month": 1,
		"attached_card_ids": []
	}

static func _offer_ids(container: Dictionary, key: String) -> Array:
	var result: Array = []
	for raw_offer in Array(container.get(key, [])):
		if raw_offer is Dictionary:
			result.append(String(raw_offer.get("offer_id", "")))
	return result
