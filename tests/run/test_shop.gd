extends GdUnitTestSuite

func _registry() -> ModifierRegistry:
	var registry := ModifierRegistry.new()
	for entry in [
		{"id": "synthetic_card", "family": "card_upgrade"},
		{"id": "synthetic_upgrade", "family": "card_upgrade"},
		{"id": "synthetic_hand", "family": "hand_mechanic"},
		{"id": "synthetic_meta", "family": "strategic_meta"},
		{"id": "synthetic_service", "family": "service"},
		{"id": "salvage", "family": "service", "effect_seams": [ModifierEffectRegistry.SEAM_SALVAGE_TRANSACTION]},
		{"id": "rain_check", "family": "service", "effect_seams": [ModifierEffectRegistry.SEAM_SHOP_OFFER_PRESERVATION]}
	]:
		var definition := ModifierDefinition.new()
		definition.definition_id = entry["id"]
		definition.display_name = entry["id"]
		definition.family = entry["family"]
		definition.description = "Synthetic deterministic test definition"
		definition.source = "test"
		definition.effect_seams = Array(entry.get("effect_seams", [])).duplicate()
		registry._definitions[definition.definition_id] = definition
	return registry

func _controller() -> RunController:
	var controller := RunController.new(77)
	controller.modifier_registry = _registry()
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	return controller

func _enter(controller: RunController) -> ShopState:
	assert_bool(controller.submit_action(RunAction.new(RunAction.ENTER_SHOP, 0, {"duplicate_policy": "unique_definition"})).accepted).is_true()
	return ShopState.from_dict(controller.state.shop_state)

func test_shop_has_six_persistent_category_slots() -> void:
	var controller := _controller()
	var shop := _enter(controller)
	assert_str(controller.state.phase).is_equal(RunState.PHASE_SHOP)
	assert_int(shop.offers.size()).is_equal(6)
	for slot_id in ShopState.SLOT_IDS:
		var found := false
		for raw_offer in shop.offers:
			if String(raw_offer.get("slot_id", "")) == String(slot_id):
				found = true
		assert_bool(found).is_true()
	var categories: Array = []
	for raw_offer in shop.offers:
		categories.append(String(raw_offer.get("slot_id", "")))
	assert_array(categories).contains_exactly(ShopState.SLOT_IDS)
	var before := controller.state.state_hash()
	var reopened := controller.submit_action(RunAction.new(RunAction.ENTER_SHOP, 0, {"duplicate_policy": "unique_definition"}))
	assert_bool(reopened.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)

func test_purchase_is_atomic_and_consumes_persisted_offer() -> void:
	var controller := _controller()
	var shop := _enter(controller)
	var target := ShopOffer.from_dict(shop.offers[2])
	assert_bool(target.available).is_true()
	var bankroll := controller.state.bankroll
	var result := controller.submit_action(RunAction.new(RunAction.BUY_OFFER, 0, {"offer_id": target.offer_id, "destination": "active"}))
	assert_bool(result.accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(bankroll - target.price)
	assert_bool(ShopState.from_dict(controller.state.shop_state).offer(target.offer_id).consumed).is_true()
	assert_int(controller.state.active_modifier_ids.size()).is_equal(1)
	var before := controller.state.state_hash()
	var duplicate := controller.submit_action(RunAction.new(RunAction.BUY_OFFER, 0, {"offer_id": target.offer_id, "destination": "active"}))
	assert_bool(duplicate.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)

func test_full_storage_rejects_purchase_without_currency_or_inventory_mutation() -> void:
	var controller := _controller()
	controller.state.reserve_capacity = 0
	controller.state.modifier_instances["existing"] = {"instance_id": "existing", "definition_id": "synthetic_meta", "location": "active", "source": "test", "acquired_month": 1, "attached_card_ids": []}
	controller.state.active_modifier_ids = ["existing"]
	var shop := _enter(controller)
	var target := ShopOffer.from_dict(shop.offers[2])
	var before := controller.state.state_hash()
	var result := controller.submit_action(RunAction.new(RunAction.BUY_OFFER, 0, {"offer_id": target.offer_id}))
	assert_bool(result.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)
	assert_str(result.reason).contains("carry locations are full")

func test_rerolls_are_deterministic_costed_and_limited_to_two() -> void:
	var first := _controller()
	var second := _controller()
	_enter(first)
	_enter(second)
	var first_reroll := first.submit_action(RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": "unique_definition"}))
	var second_reroll := second.submit_action(RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": "unique_definition"}))
	assert_bool(first_reroll.accepted).is_true()
	assert_bool(second_reroll.accepted).is_true()
	assert_str(first.state.state_hash()).is_equal(second.state.state_hash())
	assert_int(first.state.bankroll).is_equal(19)
	assert_bool(first.submit_action(RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": "unique_definition"})).accepted).is_true()
	assert_int(first.state.bankroll).is_equal(17)
	var before := first.state.state_hash()
	assert_bool(first.submit_action(RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": "unique_definition"})).accepted).is_false()
	assert_str(first.state.state_hash()).is_equal(before)

func test_sale_uses_authoritative_resale_and_month_boundary_actions() -> void:
	var controller := _controller()
	var shop := _enter(controller)
	var target := ShopOffer.from_dict(shop.offers[2])
	assert_bool(controller.submit_action(RunAction.new(RunAction.BUY_OFFER, 0, {"offer_id": target.offer_id, "destination": "active"})).accepted).is_true()
	var instance_id := String(controller.state.active_modifier_ids[0])
	assert_bool(controller.submit_action(RunAction.new(RunAction.SELL_MODIFIER, 0, {"instance_id": instance_id})).accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(20 - target.price + floori(target.price / 2.0))
	assert_bool(controller.submit_action(RunAction.new(RunAction.EXIT_SHOP)).accepted).is_true()
	assert_str(controller.state.phase).is_equal(RunState.PHASE_FINALIZE)
	assert_bool(controller.submit_action(RunAction.new(RunAction.FINALIZE_BUILD)).accepted).is_true()
	assert_str(controller.state.phase).is_equal(RunState.PHASE_TRANSITION)
	assert_bool(controller.submit_action(RunAction.new(RunAction.BEGIN_FEBRUARY)).accepted).is_true()
	assert_str(controller.state.phase).is_equal(RunState.PHASE_FEBRUARY_PLACEHOLDER)
	assert_int(controller.state.month).is_equal(2)

func test_salvage_is_active_only_atomic_and_cleans_attachment_indexes() -> void:
	var controller := _controller()
	controller.state.unlocked_active_capacity = 2
	controller.state.modifier_instances["salvage_effect"] = {"instance_id": "salvage_effect", "definition_id": "salvage", "location": "active", "source": "reward", "attached_card_ids": []}
	controller.state.active_modifier_ids = ["salvage_effect"]
	controller.state.modifier_instances["discard_target"] = {"instance_id": "discard_target", "definition_id": "synthetic_upgrade", "location": "reserve", "source": "reward", "base_shop_price": 5, "attached_card_ids": ["physical_a"]}
	controller.state.reserve_modifier_ids = ["discard_target"]
	controller.state.card_upgrade_attachments["physical_a"] = ["discard_target"]
	controller.journal = RunJournal.new(controller.state.root_seed, controller.state.to_dict())
	var before := controller.state.state_hash()
	var inactive := RunController.new(78)
	inactive.modifier_registry = _registry()
	inactive.state.phase = RunState.PHASE_CARRY
	inactive.state.unlocked_active_capacity = 1
	inactive.state.modifier_instances["discard_target"] = {"instance_id": "discard_target", "definition_id": "synthetic_meta", "location": "active", "source": "reward", "attached_card_ids": []}
	inactive.state.active_modifier_ids = ["discard_target"]
	var rejected := inactive.submit_action(RunAction.new(RunAction.SALVAGE_MODIFIER, 0, {"instance_id": "discard_target"}))
	assert_bool(rejected.accepted).is_false()
	var inactive_before := inactive.state.state_hash()
	assert_str(inactive.state.state_hash()).is_equal(inactive_before)
	var result := controller.submit_action(RunAction.new(RunAction.SALVAGE_MODIFIER, 0, {"instance_id": "discard_target"}))
	assert_bool(result.accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(22)
	assert_bool(controller.state.modifier_instances.has("discard_target")).is_false()
	assert_array(controller.state.reserve_modifier_ids).is_empty()
	assert_bool(controller.state.card_upgrade_attachments.has("physical_a")).is_false()
	assert_bool(controller.state.state_hash() == before).is_false()
	assert_str(controller.replay_final_hash()).is_equal(controller.state.state_hash())

func test_rain_check_preserves_one_offer_through_save_and_next_month_generation() -> void:
	var controller := _controller()
	controller.state.unlocked_active_capacity = 2
	controller.state.modifier_instances["rain_effect"] = {"instance_id": "rain_effect", "definition_id": "rain_check", "location": "active", "source": "reward", "attached_card_ids": []}
	controller.state.active_modifier_ids = ["rain_effect"]
	assert_bool(controller.submit_action(RunAction.new(RunAction.ENTER_SHOP)).accepted).is_true()
	var shop := ShopState.from_dict(controller.state.shop_state)
	var target := ShopOffer.new()
	for raw_offer in shop.offers:
		var candidate := ShopOffer.from_dict(raw_offer)
		if candidate.available:
			target = candidate
			break
	assert_bool(target.offer_id.is_empty()).is_false()
	assert_bool(controller.submit_action(RunAction.new(RunAction.PRESERVE_SHOP_OFFER, 0, {"offer_id": target.offer_id})).accepted).is_true()
	var preserved_shop := ShopState.from_dict(controller.state.shop_state)
	assert_str(String(preserved_shop.preserved_offer.get("definition_id", ""))).is_equal(target.definition_id)
	assert_bool(preserved_shop.offer(target.offer_id).available).is_false()
	var restored := RunSave.restore_controller(RunSave.envelope(controller))
	assert_bool(restored.get("ok", false)).is_true()
	var restored_controller: RunController = restored["controller"]
	assert_str(restored_controller.state.state_hash()).is_equal(controller.state.state_hash())
	var next_state := RunState.from_dict(controller.state.to_dict())
	next_state.month = 2
	next_state.phase = RunState.PHASE_CARRY
	var next_controller := RunController.new(next_state.root_seed, next_state)
	next_controller.modifier_registry = _registry()
	assert_bool(next_controller.submit_action(RunAction.new(RunAction.ENTER_SHOP)).accepted).is_true()
	var next_shop := ShopState.from_dict(next_controller.state.shop_state)
	var returned := next_shop.offer("shop_2_0_%s_preserved_%s" % [target.slot_id, target.offer_id])
	assert_object(returned).is_not_null()
	assert_str(returned.definition_id).is_equal(target.definition_id)
	assert_int(returned.price).is_equal(target.price)
	assert_bool(returned.available).is_true()
	assert_bool(returned.preserved).is_true()
