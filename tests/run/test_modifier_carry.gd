extends GdUnitTestSuite

func _controller() -> RunController:
	var controller := RunController.new(3)
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	controller.state.modifier_instances["mod_a"] = {"instance_id": "mod_a", "definition_id": "wider_choice", "location": "active", "source": "reward", "attached_card_ids": []}
	controller.state.active_modifier_ids = ["mod_a"]
	return controller

func test_registry_contains_wider_choice_and_future_seams() -> void:
	var registry := ModifierRegistry.new()
	assert_array(registry.validate()).is_empty()
	assert_bool(registry.has_definition("wider_choice")).is_true()
	assert_bool(registry.get_definition("sweep_seam").effect_seams.has("capture_plan")).is_true()

func test_active_modifier_can_move_to_reserve_atomically() -> void:
	var controller := _controller()
	var result := controller.submit_action(RunAction.new(RunAction.MOVE_MODIFIER, 0, {"instance_id": "mod_a", "destination": "reserve"}))
	assert_bool(result.accepted).is_true()
	assert_array(controller.state.active_modifier_ids).is_empty()
	assert_array(controller.state.reserve_modifier_ids).is_equal(["mod_a"])
	assert_str(controller.state.modifier_instances["mod_a"].get("location", "")).is_equal("reserve")
	assert_bool(controller.state.invariants_ok(null, controller.modifier_registry)).is_true()

func test_full_active_capacity_rejects_move_and_preserves_hash() -> void:
	var controller := _controller()
	controller.state.modifier_instances["mod_b"] = {"instance_id": "mod_b", "definition_id": "wider_choice", "location": "active"}
	controller.state.active_modifier_ids.append("mod_b")
	var before := controller.state.state_hash()
	var result := controller.submit_action(RunAction.new(RunAction.MOVE_MODIFIER, 0, {"instance_id": "mod_a", "destination": "active"}))
	assert_bool(result.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)

func test_reserve_is_not_an_active_effect_location() -> void:
	var controller := _controller()
	assert_array(controller.state.active_modifier_ids).is_equal(["mod_a"])
	assert_array(controller.state.reserve_modifier_ids).is_empty()
	assert_int(controller.state.reserve_count()).is_equal(0)
	assert_bool(controller.state.invariants_ok(null, controller.modifier_registry)).is_true()

func test_attachment_index_requires_a_card_upgrade_and_preserves_one_physical_target() -> void:
	var registry := ModifierRegistry.new()
	var state := RunState.fresh(19)
	state.unlocked_active_capacity = 1
	state.modifier_instances["upgrade"] = {"instance_id": "upgrade", "definition_id": "chaff_point_upgrade_seam", "location": "active", "source": "test", "acquired_month": 1, "attached_card_ids": ["card_a"]}
	state.active_modifier_ids = ["upgrade"]
	state.card_upgrade_attachments["card_a"] = ["upgrade"]
	assert_bool(state.invariants_ok(null, registry)).is_true()
	state.card_upgrade_attachments["card_a"] = ["upgrade", "upgrade"]
	assert_bool(state.invariants_ok(null, registry)).is_false()

func test_card_upgrade_type_can_target_two_physical_cards_but_not_the_same_card_twice() -> void:
	var controller := RunController.new(20)
	controller.modifier_registry = ModifierRegistry.new()
	var definition := ModifierDefinition.new()
	definition.definition_id = "synthetic_upgrade"
	definition.display_name = "Synthetic Upgrade"
	definition.family = "card_upgrade"
	definition.description = "A deterministic card upgrade fixture"
	definition.source = "test"
	controller.modifier_registry._definitions[definition.definition_id] = definition
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 3
	for instance_id in ["upgrade_a", "upgrade_b", "upgrade_c"]:
		controller.state.modifier_instances[instance_id] = {"instance_id": instance_id, "definition_id": "synthetic_upgrade", "location": "active", "source": "reward", "attached_card_ids": []}
		controller.state.active_modifier_ids.append(instance_id)
	assert_bool(controller.submit_action(RunAction.new(RunAction.ATTACH_CARD_UPGRADE, 0, {"instance_id": "upgrade_a", "card_id": "physical_a"})).accepted).is_true()
	assert_bool(controller.submit_action(RunAction.new(RunAction.ATTACH_CARD_UPGRADE, 0, {"instance_id": "upgrade_b", "card_id": "physical_b"})).accepted).is_true()
	var before := controller.state.state_hash()
	var rejected := controller.submit_action(RunAction.new(RunAction.ATTACH_CARD_UPGRADE, 0, {"instance_id": "upgrade_c", "card_id": "physical_a"}))
	assert_bool(rejected.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)
	assert_bool(controller.submit_action(RunAction.new(RunAction.DETACH_CARD_UPGRADE, 0, {"instance_id": "upgrade_a", "card_id": "physical_a"})).accepted).is_true()
