extends GdUnitTestSuite

func _result(player_score: int, ai_score: int, match_id: String = "settle_1") -> MatchResult:
	var result := MatchResult.new()
	result.match_id = match_id
	result.source_match_hash = "source_%s" % match_id
	result.month = 1
	result.moon_id = "wolf_moon"
	result.winner_id = 0 if player_score > ai_score else (1 if ai_score > player_score else -1)
	result.player_score = {"final_score": player_score}
	result.ai_score = {"final_score": ai_score}
	return result

func _controller_with_result(player_score: int, ai_score: int) -> RunController:
	var controller := RunController.new(10)
	assert_bool(controller.ingest_match_result(_result(player_score, ai_score)).accepted).is_true()
	return controller

func test_winning_settlement_adds_resolved_score_and_unlocks_january_slot() -> void:
	var controller := _controller_with_result(7, 2)
	var result := controller.submit_action(RunAction.new(RunAction.SETTLE))
	assert_bool(result.accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(27)
	assert_int(controller.state.unlocked_active_capacity).is_equal(1)
	assert_str(controller.state.phase).is_equal(RunState.PHASE_REWARD)
	assert_bool(controller.state.pending_settlement.is_empty()).is_true()

func test_loss_settlement_subtracts_resolved_score_without_negative_bankroll() -> void:
	var controller := _controller_with_result(5, 9)
	var result := controller.submit_action(RunAction.new(RunAction.SETTLE))
	assert_bool(result.accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(15)
	assert_str(controller.state.phase).is_equal(RunState.PHASE_REWARD)

func test_exact_zero_settlement_is_legal() -> void:
	var controller := _controller_with_result(3, 3)
	assert_bool(controller.submit_action(RunAction.new(RunAction.SETTLE)).accepted).is_true()
	assert_int(controller.state.bankroll).is_equal(20)
	assert_str(controller.state.phase).is_equal(RunState.PHASE_REWARD)

func test_unpayable_loss_without_saleable_assets_enters_bankruptcy_without_negative_bankroll() -> void:
	var controller := _controller_with_result(30, 31)
	assert_bool(controller.submit_action(RunAction.new(RunAction.SETTLE)).accepted).is_true()
	assert_str(controller.state.phase).is_equal(RunState.PHASE_BANKRUPT)
	assert_int(controller.state.bankroll).is_equal(20)
	assert_int(PendingSettlement.from_dict(controller.state.pending_settlement).amount_due).is_equal(30)

func test_liquidation_uses_authoritative_resale_and_reaches_reward() -> void:
	var controller := _controller_with_result(25, 26)
	controller.state.modifier_instances["mod_1"] = {"instance_id": "mod_1", "definition_id": "wider_choice", "location": "active", "source": "shop", "purchase_price": 50, "base_shop_price": 4, "attached_card_ids": []}
	controller.state.active_modifier_ids = ["mod_1"]
	controller.state.unlocked_active_capacity = 1
	assert_bool(controller.submit_action(RunAction.new(RunAction.SETTLE)).accepted).is_true()
	var before := controller.state.state_hash()
	var sale := controller.submit_action(RunAction.new(RunAction.LIQUIDATE, 0, {"instance_id": "mod_1"}))
	assert_bool(sale.accepted).is_true()
	assert_str(controller.state.phase).is_equal(RunState.PHASE_REWARD)
	assert_int(controller.state.bankroll).is_equal(20)
	assert_bool(controller.state.modifier_instances.has("mod_1")).is_false()
	assert_bool(before != controller.state.state_hash()).is_true()

func test_free_reward_resale_uses_half_of_normal_base_price() -> void:
	var registry := ModifierRegistry.new()
	var definition := registry.get_definition("wider_choice")
	assert_object(definition).is_not_null()
	var instance := {"definition_id": "wider_choice", "source": "january_reward", "base_shop_price": definition.base_shop_price}
	assert_int(ModifierResalePolicy.quote(instance, registry)).is_equal(2)
