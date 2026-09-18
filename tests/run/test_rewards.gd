extends GdUnitTestSuite

func _registry() -> ModifierRegistry:
	var registry := ModifierRegistry.new()
	for entry in [
		{"id": "synthetic_card", "family": "card_upgrade"},
		{"id": "synthetic_hand", "family": "hand_mechanic"},
		{"id": "synthetic_meta", "family": "strategic_meta"},
		{"id": "synthetic_service", "family": "service"},
		{"id": "wider_choice", "family": "strategic_meta"},
		{"id": "stackable_meta", "family": "strategic_meta", "stackable": true}
	]:
		var definition := ModifierDefinition.new()
		definition.definition_id = entry["id"]
		definition.display_name = entry["id"]
		definition.family = entry["family"]
		definition.stackable = bool(entry.get("stackable", false))
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

func test_wider_choice_transforms_legacy_family_shape_to_full_pool() -> void:
	var wider := RewardRequest.family_quotas(1).with_wider_choice()
	assert_bool(wider.requires_policy_decision).is_false()
	assert_str(wider.reward_policy).is_equal(RewardRequest.POLICY_WHOLE_POOL)
	assert_int(wider.slot_specs.size()).is_equal(4)

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
	controller.state.modifier_instances["existing"] = {"instance_id": "existing", "definition_id": "synthetic_meta", "location": "active", "source": "shop", "purchase_price": 9, "base_shop_price": 4, "attached_card_ids": []}
	controller.state.active_modifier_ids = ["existing"]
	var request := RewardRequest.whole_pool(1)
	assert_bool(controller.submit_action(RunAction.new(RunAction.GENERATE_REWARD, 0, {"request": request.to_dict()})).accepted).is_true()
	var reward := RewardState.from_dict(controller.state.reward_state)
	var offer_id := String(reward.offers[0].get("offer_id", ""))
	assert_bool(controller.submit_action(RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer_id})).accepted).is_true()
	var pending := RewardState.from_dict(controller.state.reward_state)
	assert_bool(pending.pending_acquisition.is_empty()).is_false()
	assert_int(controller.state.modifier_instances.size()).is_equal(1)

func test_default_run_rules_generate_three_full_pool_offers() -> void:
	var controller := RunController.new(700)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	assert_bool(controller.submit_action(RunAction.new(RunAction.GENERATE_REWARD)).accepted).is_true()
	assert_int(RewardState.from_dict(controller.state.reward_state).offers.size()).is_equal(3)

func test_full_capacity_reward_can_replace_for_authoritative_resale() -> void:
	var controller := RunController.new(701)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	controller.state.unlocked_active_capacity = 1
	controller.state.reserve_capacity = 0
	controller.state.modifier_instances["existing"] = {"instance_id": "existing", "definition_id": "synthetic_meta", "location": "active", "source": "shop", "purchase_price": 9, "base_shop_price": 4, "attached_card_ids": []}
	controller.state.active_modifier_ids = ["existing"]
	var reward := RewardState.new()
	reward.generated = true
	var offer := RewardOffer.new()
	offer.offer_id = "replacement_reward"
	offer.definition_id = "synthetic_card"
	offer.slot_spec = RewardRequest.SLOT_ANY
	offer.source = "january_reward"
	reward.offers = [offer.to_dict()]
	controller.state.reward_state = reward.to_dict()
	controller.journal = RunJournal.new(controller.state.root_seed, controller.state.to_dict())
	var chosen := controller.submit_action(RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer.offer_id}))
	assert_bool(chosen.accepted).is_true()
	assert_bool(RewardState.from_dict(controller.state.reward_state).pending_acquisition.is_empty()).is_false()
	var replaced := controller.submit_action(RunAction.new(RunAction.REPLACE_PENDING_REWARD, 0, {"instance_id": "existing"}))
	assert_bool(replaced.accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(24)
	assert_bool(controller.state.modifier_instances.has("existing")).is_false()
	assert_int(controller.state.active_modifier_ids.size()).is_equal(1)
	assert_str(controller.replay_final_hash()).is_equal(controller.state.state_hash())

func test_full_capacity_reward_can_be_refused_once() -> void:
	var controller := RunController.new(702)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	controller.state.unlocked_active_capacity = 1
	controller.state.reserve_capacity = 0
	controller.state.modifier_instances["existing"] = {"instance_id": "existing", "definition_id": "synthetic_meta", "location": "active", "source": "shop", "purchase_price": 9, "base_shop_price": 4, "attached_card_ids": []}
	controller.state.active_modifier_ids = ["existing"]
	var reward := RewardState.new()
	reward.generated = true
	var offer := RewardOffer.new()
	offer.offer_id = "refused_full_reward"
	offer.definition_id = "synthetic_card"
	offer.slot_spec = RewardRequest.SLOT_ANY
	offer.source = "january_reward"
	reward.offers = [offer.to_dict()]
	controller.state.reward_state = reward.to_dict()
	assert_bool(controller.submit_action(RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer.offer_id})).accepted).is_true()
	assert_bool(controller.submit_action(RunAction.new(RunAction.REFUSE_REWARD)).accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(22)
	var before := controller.state.state_hash()
	assert_bool(controller.submit_action(RunAction.new(RunAction.REFUSE_REWARD)).accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)

func test_nonstackable_hand_and_strategic_duplicates_are_rejected() -> void:
	for definition_id in ["synthetic_hand", "synthetic_meta"]:
		var controller := RunController.new(703)
		controller.modifier_registry = _registry()
		controller.state.phase = RunState.PHASE_REWARD
		controller.state.unlocked_active_capacity = 2
		controller.state.modifier_instances["existing"] = {"instance_id": "existing", "definition_id": definition_id, "location": "active", "source": "reward", "attached_card_ids": []}
		controller.state.active_modifier_ids = ["existing"]
		var reward := RewardState.new()
		reward.generated = true
		var offer := RewardOffer.new()
		offer.offer_id = "duplicate_%s" % definition_id
		offer.definition_id = definition_id
		offer.slot_spec = RewardRequest.SLOT_ANY
		offer.source = "january_reward"
		reward.offers = [offer.to_dict()]
		controller.state.reward_state = reward.to_dict()
		var before := controller.state.state_hash()
		var result := controller.submit_action(RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer.offer_id}))
		assert_bool(result.accepted).is_false()
		assert_str(controller.state.state_hash()).is_equal(before)

func test_explicitly_stackable_strategic_definition_can_repeat() -> void:
	var controller := RunController.new(704)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	controller.state.unlocked_active_capacity = 2
	controller.state.modifier_instances["existing"] = {"instance_id": "existing", "definition_id": "stackable_meta", "location": "active", "source": "reward", "attached_card_ids": []}
	controller.state.active_modifier_ids = ["existing"]
	var reward := RewardState.new()
	reward.generated = true
	var offer := RewardOffer.new()
	offer.offer_id = "stackable_repeat"
	offer.definition_id = "stackable_meta"
	offer.slot_spec = RewardRequest.SLOT_ANY
	offer.source = "january_reward"
	reward.offers = [offer.to_dict()]
	controller.state.reward_state = reward.to_dict()
	assert_bool(controller.submit_action(RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer.offer_id})).accepted).is_true()

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

func test_reserve_wider_choice_does_not_change_reward_count() -> void:
	var controller := RunController.new(1705)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_REWARD
	controller.state.reserve_capacity = 1
	controller.state.modifier_instances["reserved_wider"] = {"instance_id": "reserved_wider", "definition_id": "wider_choice", "location": "reserve", "source": "test", "attached_card_ids": []}
	controller.state.reserve_modifier_ids = ["reserved_wider"]
	assert_bool(controller.submit_action(RunAction.new(RunAction.GENERATE_REWARD)).accepted).is_true()
	assert_int(RewardState.from_dict(controller.state.reward_state).offers.size()).is_equal(3)

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
