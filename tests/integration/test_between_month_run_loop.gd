extends GdUnitTestSuite

func _registry() -> ModifierRegistry:
	var registry := ModifierRegistry.new()
	for entry in [
		{"id": "synthetic_card", "family": "card_upgrade"},
		{"id": "synthetic_hand", "family": "hand_mechanic"},
		{"id": "synthetic_meta", "family": "strategic_meta"},
		{"id": "synthetic_service", "family": "service"},
		{"id": "synthetic_meta_two", "family": "strategic_meta"}
	]:
		var definition := ModifierDefinition.new()
		definition.definition_id = entry["id"]
		definition.display_name = entry["id"]
		definition.family = entry["family"]
		definition.description = "Synthetic deterministic integration definition"
		definition.source = "test"
		registry._definitions[definition.definition_id] = definition
	return registry

func _controller(seed_value: int, bankroll: int) -> RunController:
	var rules := RunRules.prototype()
	rules.reward_policy = RunRules.REWARD_POLICY_WHOLE_POOL
	rules.duplicate_modifier_policy = "unique_definition"
	var controller := RunController.new(seed_value, null, rules)
	controller.modifier_registry = _registry()
	controller.state.bankroll = bankroll
	return controller

func _result(match_id: String, player_score: int, ai_score: int) -> MatchResult:
	var result := MatchResult.new()
	result.match_id = match_id
	result.source_match_hash = "source_%s" % match_id
	result.month = 1
	result.moon_id = "wolf_moon"
	result.winner_id = 0 if player_score > ai_score else (1 if ai_score > player_score else -1)
	result.player_score = {"final_score": player_score}
	result.ai_score = {"final_score": ai_score}
	return result

func _submit(controller: RunController, action_type: String, payload: Dictionary = {}) -> void:
	var result := controller.submit_action(RunAction.new(action_type, 0, payload))
	assert_bool(result.accepted).is_true()

func _choose_first_reward(controller: RunController) -> void:
	var reward := RewardState.from_dict(controller.state.reward_state)
	var offer := RewardOffer.from_dict(reward.offers[0])
	_submit(controller, RunAction.CHOOSE_REWARD, {"offer_id": offer.offer_id})

func test_configured_win_path_reaches_february_placeholder() -> void:
	var controller := _controller(1601, 20)
	assert_bool(controller.ingest_match_result(_result("win_loop", 8, 3)).accepted).is_true()
	_submit(controller, RunAction.SETTLE)
	_submit(controller, RunAction.GENERATE_REWARD)
	_choose_first_reward(controller)
	_submit(controller, RunAction.ENTER_SHOP)
	assert_int(ShopState.from_dict(controller.state.shop_state).offers.size()).is_equal(6)
	_submit(controller, RunAction.EXIT_SHOP)
	_submit(controller, RunAction.FINALIZE_BUILD)
	_submit(controller, RunAction.BEGIN_FEBRUARY)
	assert_str(controller.state.phase).is_equal(RunState.PHASE_FEBRUARY_PLACEHOLDER)
	assert_int(controller.state.month).is_equal(2)
	assert_str(controller.replay_final_hash()).is_equal(controller.state.state_hash())

func test_authoritative_liquidation_path_reaches_february_placeholder() -> void:
	var controller := _controller(1602, 0)
	controller.state.unlocked_active_capacity = 1
	controller.state.modifier_instances["liquidation_target"] = {
		"instance_id": "liquidation_target",
		"definition_id": "synthetic_meta",
		"location": "active",
		"source": "test",
		"acquired_month": 1,
		"attached_card_ids": []
	}
	controller.state.active_modifier_ids = ["liquidation_target"]
	controller.state.modifier_instances["liquidation_target"]["source"] = "shop"
	controller.state.modifier_instances["liquidation_target"]["purchase_price"] = 6
	controller.journal = RunJournal.new(controller.state.root_seed, controller.state.to_dict())
	assert_bool(controller.ingest_match_result(_result("loss_loop", 3, 8)).accepted).is_true()
	_submit(controller, RunAction.SETTLE)
	assert_str(controller.state.phase).is_equal(RunState.PHASE_LIQUIDATION)
	_submit(controller, RunAction.LIQUIDATE, {"instance_id": "liquidation_target"})
	_submit(controller, RunAction.GENERATE_REWARD)
	_choose_first_reward(controller)
	_submit(controller, RunAction.ENTER_SHOP)
	_submit(controller, RunAction.EXIT_SHOP)
	_submit(controller, RunAction.FINALIZE_BUILD)
	_submit(controller, RunAction.BEGIN_FEBRUARY)
	assert_str(controller.state.phase).is_equal(RunState.PHASE_FEBRUARY_PLACEHOLDER)
	assert_int(controller.state.month).is_equal(2)
	assert_str(controller.replay_final_hash()).is_equal(controller.state.state_hash())
