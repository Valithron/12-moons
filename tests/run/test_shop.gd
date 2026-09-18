extends GdUnitTestSuite

func _registry() -> ModifierRegistry:
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
		definition.description = "Synthetic deterministic test definition"
		definition.source = "test"
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
