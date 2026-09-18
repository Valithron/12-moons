extends GdUnitTestSuite

func _registry() -> ModifierRegistry:
	var registry := ModifierRegistry.new()
	for entry in [
		{"id": "synthetic_card", "family": "card_upgrade"},
		{"id": "synthetic_hand", "family": "hand_mechanic"},
		{"id": "synthetic_meta", "family": "strategic_meta"},
		{"id": "synthetic_service", "family": "service"},
		{"id": "wider_choice", "family": "strategic_meta"}
	]:
		var definition := ModifierDefinition.new()
		definition.definition_id = entry["id"]
		definition.display_name = entry["id"]
		definition.family = entry["family"]
		definition.description = "Synthetic deterministic test definition"
		definition.source = "test"
		registry._definitions[definition.definition_id] = definition
	return registry

func test_both_reward_request_shapes_are_supported() -> void:
	var registry := _registry()
	var whole := RewardGenerator.generate(RewardRequest.whole_pool(1), 123, registry)
	var family := RewardGenerator.generate(RewardRequest.family_quotas(1), 123, registry)
	assert_bool(whole.get("ok", false)).is_true()
	assert_bool(family.get("ok", false)).is_true()
	assert_int(RewardState.from_dict(whole["state"]).offers.size()).is_equal(3)
	assert_int(RewardState.from_dict(family["state"]).offers.size()).is_equal(3)

func test_reward_generation_is_deterministic_and_wider_choice_changes_only_count() -> void:
	var registry := _registry()
	var request := RewardRequest.whole_pool(1)
	request.generation_id = 2
	var first := RewardGenerator.generate(request, 55, registry)
	var second := RewardGenerator.generate(request, 55, registry)
	assert_str(JSON.stringify(first["state"])).is_equal(JSON.stringify(second["state"]))
	var wider := request.with_wider_choice()
	assert_int(wider.choice_count).is_equal(4)
	assert_int(wider.slot_specs.size()).is_equal(4)
	assert_bool(wider.requires_policy_decision).is_false()

func test_wider_choice_family_quota_shape_surfaces_unresolved_fourth_slot() -> void:
	var wider := RewardRequest.family_quotas(1).with_wider_choice()
	assert_bool(wider.requires_policy_decision).is_true()
	assert_bool(wider.unresolved_reason.contains("BM-B06")).is_true()

func test_reward_selection_is_once_only_and_materializes_owned_instance() -> void:
	var controller := RunController.new(7)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	controller.state.unlocked_active_capacity = 1
	var request := RewardRequest.whole_pool(1)
	assert_bool(controller.submit_action(RunAction.new(RunAction.GENERATE_REWARD, 0, {"request": request.to_dict()})).accepted).is_true()
	var reward := RewardState.from_dict(controller.state.reward_state)
	var offer_id := String(reward.offers[0].get("offer_id", ""))
	var chosen := controller.submit_action(RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer_id}))
	assert_bool(chosen.accepted).is_true()
	assert_str(controller.state.phase).is_equal(RunState.PHASE_CARRY)
	assert_int(controller.state.active_modifier_ids.size()).is_equal(1)
	var before := controller.state.state_hash()
	var duplicate := controller.submit_action(RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer_id}))
	assert_bool(duplicate.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)

func test_reward_refusal_adds_configured_cash_once() -> void:
	var controller := RunController.new(7)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	var request := RewardRequest.whole_pool(1)
	assert_bool(controller.submit_action(RunAction.new(RunAction.GENERATE_REWARD, 0, {"request": request.to_dict()})).accepted).is_true()
	assert_bool(controller.submit_action(RunAction.new(RunAction.REFUSE_REWARD)).accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(22)
	var before := controller.state.state_hash()
	assert_bool(controller.submit_action(RunAction.new(RunAction.REFUSE_REWARD)).accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)

func test_full_active_and_reserve_selection_becomes_pending_without_overflow() -> void:
	var controller := RunController.new(7)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	controller.state.unlocked_active_capacity = 1
	controller.state.reserve_capacity = 0
	controller.state.modifier_instances["existing"] = {"instance_id": "existing", "definition_id": "synthetic_meta", "location": "active"}
	controller.state.active_modifier_ids = ["existing"]
	var request := RewardRequest.whole_pool(1)
	assert_bool(controller.submit_action(RunAction.new(RunAction.GENERATE_REWARD, 0, {"request": request.to_dict()})).accepted).is_true()
	var reward := RewardState.from_dict(controller.state.reward_state)
	var offer_id := String(reward.offers[0].get("offer_id", ""))
	assert_bool(controller.submit_action(RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer_id})).accepted).is_true()
	var pending := RewardState.from_dict(controller.state.reward_state)
	assert_bool(pending.pending_acquisition.is_empty()).is_false()
	assert_int(controller.state.modifier_instances.size()).is_equal(1)

func test_active_wider_choice_and_configured_rules_drive_authoritative_generation() -> void:
	var rules := RunRules.prototype()
	rules.reward_policy = RunRules.REWARD_POLICY_WHOLE_POOL
	rules.duplicate_modifier_policy = "unique_definition"
	var controller := RunController.new(17, null, rules)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	controller.state.unlocked_active_capacity = 1
	controller.state.modifier_instances["wider"] = {"instance_id": "wider", "definition_id": "wider_choice", "location": "active", "source": "test", "attached_card_ids": []}
	controller.state.active_modifier_ids = ["wider"]
	controller.journal = RunJournal.new(controller.state.root_seed, controller.state.to_dict())
	var generated := controller.submit_action(RunAction.new(RunAction.GENERATE_REWARD))
	assert_bool(generated.accepted).is_true()
	assert_int(RewardState.from_dict(controller.state.reward_state).offers.size()).is_equal(4)

func test_configured_duplicate_policy_can_drive_shop_without_action_payload() -> void:
	var rules := RunRules.prototype()
	rules.duplicate_modifier_policy = "unique_definition"
	var controller := RunController.new(18, null, rules)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	controller.journal = RunJournal.new(controller.state.root_seed, controller.state.to_dict())
	var entered := controller.submit_action(RunAction.new(RunAction.ENTER_SHOP))
	assert_bool(entered.accepted).is_true()
	assert_str(controller.state.phase).is_equal(RunState.PHASE_SHOP)
