extends GdUnitTestSuite

func _controller() -> RunController:
	var controller := RunController.new(909)
	controller.state.phase = RunState.PHASE_CARRY
	controller.state.unlocked_active_capacity = 1
	controller.journal = RunJournal.new(controller.state.root_seed, controller.state.to_dict())
	return controller

func test_save_envelope_round_trips_state_and_journal() -> void:
	var controller := _controller()
	assert_bool(controller.submit_action(RunAction.new(RunAction.ENTER_SHOP, 0, {"duplicate_policy": "unique_definition"})).accepted).is_true()
	var data := RunSave.envelope(controller)
	var decoded := RunSave.decode(data)
	assert_bool(decoded.get("ok", false)).is_true()
	var restored := RunSave.restore_controller(data)
	assert_bool(restored.get("ok", false)).is_true()
	var restored_controller: RunController = restored["controller"]
	assert_str(restored_controller.state.state_hash()).is_equal(controller.state.state_hash())
	assert_int(restored_controller.journal.entries.size()).is_equal(controller.journal.entries.size())
	assert_str(controller.replay_final_hash()).is_equal(controller.state.state_hash())
	assert_str(restored_controller.replay_final_hash()).is_equal(restored_controller.state.state_hash())

func test_save_checksum_and_unknown_content_are_rejected() -> void:
	var controller := _controller()
	var data := RunSave.envelope(controller)
	var tampered := data.duplicate(true)
	tampered["payload"]["run_state"]["bankroll"] = 999
	assert_bool(RunSave.decode(tampered).get("ok", false)).is_false()
	var invalid := data.duplicate(true)
	invalid["payload"]["run_state"]["modifier_instances"] = {"x": {"instance_id": "x", "definition_id": "missing", "location": "active"}}
	invalid["payload"]["run_state"]["active_modifier_ids"] = ["x"]
	invalid["checksum"] = JSON.stringify(invalid["payload"]).sha256_text()
	assert_bool(RunSave.decode(invalid).get("ok", false)).is_false()

func test_each_between_month_phase_is_serializable() -> void:
	for phase in [RunState.PHASE_SETTLEMENT, RunState.PHASE_LIQUIDATION, RunState.PHASE_REWARD, RunState.PHASE_CARRY, RunState.PHASE_SHOP, RunState.PHASE_FINALIZE, RunState.PHASE_TRANSITION, RunState.PHASE_FEBRUARY_PLACEHOLDER]:
		var controller := _controller()
		controller.state.phase = phase
		var data := RunSave.envelope(controller)
		var restored := RunSave.restore_controller(data)
		assert_bool(restored.get("ok", false)).is_true()
		var restored_controller: RunController = restored["controller"]
		assert_str(restored_controller.state.phase).is_equal(phase)

func test_pending_full_capacity_reward_reloads_without_overflow() -> void:
	var controller := _controller()
	controller.state.reserve_capacity = 0
	controller.state.modifier_instances["existing"] = {"instance_id": "existing", "definition_id": "wider_choice", "location": "active", "source": "shop", "purchase_price": 7, "base_shop_price": 4, "attached_card_ids": []}
	controller.state.active_modifier_ids = ["existing"]
	var reward := RewardState.new()
	reward.generated = true
	reward.selected_offer_id = "pending_reward"
	var offer := RewardOffer.new()
	offer.offer_id = "pending_reward"
	offer.definition_id = "wider_choice"
	offer.source = "january_reward"
	reward.offers = [offer.to_dict()]
	reward.pending_acquisition = {"offer": offer.to_dict(), "reason": "replace_and_sell_or_refuse"}
	controller.state.reward_state = reward.to_dict()
	var data := RunSave.envelope(controller)
	var restored := RunSave.restore_controller(data)
	assert_bool(restored.get("ok", false)).is_true()
	var restored_controller: RunController = restored["controller"]
	var restored_reward := RewardState.from_dict(restored_controller.state.reward_state)
	assert_str(restored_reward.selected_offer_id).is_equal("pending_reward")
	assert_bool(restored_reward.pending_acquisition.is_empty()).is_false()
	assert_int(restored_controller.state.modifier_instances.size()).is_equal(1)

func test_legacy_save_fixture_migrates_to_v1() -> void:
	var legacy_payload := {
		"root_seed": 42,
		"month": 1,
		"phase": RunState.PHASE_CARRY,
		"bankroll": 17,
		"active_modifier_ids": [],
		"reserve_modifier_ids": []
	}
	var legacy := {
		"format_version": RunMigration.LEGACY_VERSION,
		"checksum": JSON.stringify(legacy_payload).sha256_text(),
		"payload": legacy_payload
	}
	var migrated := RunSave.decode(legacy)
	assert_bool(migrated.get("ok", false)).is_true()
	assert_str(String(migrated["payload"].get("format_version", ""))).is_equal(RunMigration.CURRENT_VERSION)
	assert_int(int(migrated["payload"]["run_state"].get("bankroll", 0))).is_equal(17)
