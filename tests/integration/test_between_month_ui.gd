extends GdUnitTestSuite

func _find_button(node: Node, text_value: String) -> Button:
	if node == null:
		return null
	for child in node.get_children():
		if child is Button and child.text == text_value:
			return child
		var nested := _find_button(child, text_value)
		if nested != null:
			return nested
	return null

func _configured_registry() -> ModifierRegistry:
	var registry := ModifierRegistry.new()
	for entry in [
		{"id": "synthetic_card", "family": "card_upgrade"},
		{"id": "synthetic_hand", "family": "hand_mechanic"},
		{"id": "synthetic_meta", "family": "strategic_meta"},
		{"id": "synthetic_service", "family": "service"}
	]:
		var definition := ModifierDefinition.new()
		definition.definition_id = entry["id"]
		definition.display_name = entry["id"]
		definition.family = entry["family"]
		definition.description = "Synthetic deterministic UI test definition"
		definition.source = "test"
		registry._definitions[definition.definition_id] = definition
	return registry

func test_settlement_screen_observes_run_state_and_exposes_one_commit_action() -> void:
	var controller := DebugScenarioFactory.create_controller("terminal_january_win", 1212)
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	assert_str(controller.state.phase).is_equal(RunState.PHASE_SETTLEMENT)
	assert_str(screen.get("status_label").text).contains("YOU 8")
	assert_str(screen.get("status_label").text).contains("OPPONENT 3")
	assert_bool(_find_button(screen, "SETTLE JANUARY") != null).is_true()
	assert_int(controller.state.bankroll).is_equal(20)
	screen.queue_free()

func test_liquidation_screen_exposes_authoritative_sale_actions() -> void:
	var controller := DebugScenarioFactory.create_controller("liquidation_required", 1222)
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	assert_str(controller.state.phase).is_equal(RunState.PHASE_LIQUIDATION)
	assert_str(screen.get("status_label").text).contains("requires $30 more")
	assert_str(screen.get("status_label").text).contains("authoritative resale")
	assert_bool(_find_button(screen, "LIQUIDATE wider_choice — Increase the January reward choice count from three offers to four.  (+$2)") != null).is_true()
	screen.queue_free()

func test_reward_screen_uses_approved_default_policy_without_mutating_run() -> void:
	var controller := RunController.new(1313)
	controller.state.phase = RunState.PHASE_REWARD
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	assert_str(screen.get("status_label").text).contains("three persisted offers")
	screen.queue_free()

func test_configured_reward_screen_submits_empty_payload_and_renders_persisted_offers() -> void:
	var rules := RunRules.prototype()
	rules.reward_policy = RunRules.REWARD_POLICY_WHOLE_POOL
	rules.duplicate_modifier_policy = "unique_definition"
	var controller := RunController.new(1353, null, rules)
	controller.modifier_registry = _configured_registry()
	controller.state.phase = RunState.PHASE_REWARD
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	var generate_button := _find_button(screen, "GENERATE REWARD")
	assert_object(generate_button).is_not_null()
	generate_button.emit_signal("pressed")
	await get_tree().process_frame
	assert_bool(RewardState.from_dict(controller.state.reward_state).generated).is_true()
	assert_int(RewardState.from_dict(controller.state.reward_state).offers.size()).is_equal(3)
	assert_str(screen.get("status_label").text).contains("Choose one")
	screen.queue_free()

func test_configured_carry_screen_enters_shop_and_preserves_six_offer_state() -> void:
	var rules := RunRules.prototype()
	rules.duplicate_modifier_policy = "unique_definition"
	var controller := RunController.new(1363, null, rules)
	controller.state.phase = RunState.PHASE_CARRY
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	var open_shop_button := _find_button(screen, "OPEN SIX-SLOT SHOP")
	assert_object(open_shop_button).is_not_null()
	open_shop_button.emit_signal("pressed")
	await get_tree().process_frame
	assert_str(controller.state.phase).is_equal(RunState.PHASE_SHOP)
	assert_int(ShopState.from_dict(controller.state.shop_state).offers.size()).is_equal(6)
	assert_object(_find_button(screen, "REROLL SHOP")).is_not_null()
	screen.queue_free()

func test_carry_screen_exposes_authoritative_move_action_and_restores_focus_key() -> void:
	var controller := RunController.new(1414)
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	controller.state.modifier_instances["carry_mod"] = {
		"instance_id": "carry_mod",
		"definition_id": "wider_choice",
		"location": "active",
		"source": "scenario",
		"attached_card_ids": []
	}
	controller.state.active_modifier_ids = ["carry_mod"]
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	var move_button := _find_button(screen, "MOVE TO RESERVE")
	assert_object(move_button).is_not_null()
	assert_int(move_button.focus_mode).is_equal(Control.FOCUS_ALL)
	move_button.emit_signal("pressed")
	await get_tree().process_frame
	assert_array(controller.state.active_modifier_ids).is_empty()
	assert_array(controller.state.reserve_modifier_ids).is_equal(["carry_mod"])
	assert_str(screen.get("focus_key")).is_equal("move_carry_mod_reserve")
	screen.queue_free()

func test_rain_check_screen_exposes_preserve_action_and_persists_selection() -> void:
	var controller := RunController.new(1515)
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	controller.state.modifier_instances["rain_effect"] = {
		"instance_id": "rain_effect",
		"definition_id": "rain_check",
		"location": "active",
		"source": "reward",
		"attached_card_ids": []
	}
	controller.state.active_modifier_ids = ["rain_effect"]
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	var open_shop_button := _find_button(screen, "OPEN SIX-SLOT SHOP")
	assert_object(open_shop_button).is_not_null()
	open_shop_button.emit_signal("pressed")
	await get_tree().process_frame
	var preserve_button := _find_button(screen, "PRESERVE")
	assert_object(preserve_button).is_not_null()
	preserve_button.emit_signal("pressed")
	await get_tree().process_frame
	assert_bool(ShopState.from_dict(controller.state.shop_state).preserved_offer.is_empty()).is_false()
	assert_str(screen.get("status_label").text).contains("preserved")
	screen.queue_free()

func test_salvage_screen_exposes_base_value_action_and_removes_owned_modifier() -> void:
	var controller := RunController.new(1616)
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	controller.state.modifier_instances["salvage_effect"] = {
		"instance_id": "salvage_effect",
		"definition_id": "salvage",
		"location": "active",
		"source": "reward",
		"base_shop_price": 8,
		"attached_card_ids": []
	}
	controller.state.modifier_instances["target"] = {
		"instance_id": "target",
		"definition_id": "wider_choice",
		"location": "reserve",
		"source": "reward",
		"base_shop_price": 4,
		"attached_card_ids": []
	}
	controller.state.active_modifier_ids = ["salvage_effect"]
	controller.state.reserve_modifier_ids = ["target"]
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	var salvage_button := _find_button(screen, "SALVAGE (+$2)")
	assert_object(salvage_button).is_not_null()
	salvage_button.emit_signal("pressed")
	await get_tree().process_frame
	assert_bool(controller.state.modifier_instances.has("target")).is_false()
	assert_int(controller.state.bankroll).is_equal(22)
	screen.queue_free()

func test_shop_overflow_is_bounded_and_continue_to_finalize_stays_visible() -> void:
	var controller := DebugScenarioFactory.create_controller("initial_shop", 1717)
	controller.state.unlocked_active_capacity = 8
	for index in range(8):
		var instance_id := "overflow_modifier_%d" % index
		controller.state.modifier_instances[instance_id] = {
			"instance_id": instance_id,
			"definition_id": "wider_choice",
			"location": "active",
			"source": "scenario",
			"attached_card_ids": [],
			"base_shop_price": 4
		}
		controller.state.active_modifier_ids.append(instance_id)
	var screen: Node = load("res://scenes/between_month/between_month.tscn").instantiate()
	add_child(screen)
	screen.configure(controller)
	await get_tree().process_frame
	var shop_scroll: ScrollContainer = screen.get("shop_scroll")
	var shop_content: VBoxContainer = screen.get("shop_content_column")
	var action_bar: HBoxContainer = screen.get("shop_action_bar")
	var continue_button := _find_button(screen, "CONTINUE TO FINALIZE")
	assert_object(shop_scroll).is_not_null()
	assert_object(shop_content).is_not_null()
	assert_object(action_bar).is_not_null()
	assert_object(continue_button).is_not_null()
	assert_bool(shop_content.size.y > shop_scroll.size.y).is_true()
	assert_bool(action_bar.position.y + action_bar.size.y <= screen.size.y).is_true()
	assert_bool(continue_button.visible).is_true()
	assert_bool(continue_button.disabled).is_false()
	assert_object(_find_button(screen, "REROLL SHOP")).is_not_null()
	continue_button.emit_signal("pressed")
	await get_tree().process_frame
	assert_str(controller.state.phase).is_equal(RunState.PHASE_FINALIZE)
	screen.queue_free()
