extends GdUnitTestSuite

func test_replay_reproduces_final_state_hash() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(42, catalog)
	var first_card := state.deck.draw_card()
	state.players[0].hand_ids = [first_card]
	var controller := MatchController.new(state.seed, catalog, state)
	var action := GameAction.new(GameAction.PLAY_CARD, 0, first_card, "")
	var result := controller.submit_action(action)
	assert_bool(result.accepted).is_true()
	assert_str(controller.replay_log.replay_final_hash(catalog)).is_equal(controller.state.state_hash())

func test_full_january_autoplay_is_legal_and_replayable() -> void:
	var catalog := CardCatalog.new()
	var controller := MatchController.new(202601, catalog)
	controller.begin_january(202601)
	assert_bool(controller.state.invariants_ok(catalog)).is_true()
	var starter_action := controller.legal_actions(0)[0]
	assert_bool(controller.submit_action(starter_action).accepted).is_true()
	while controller.advance_automatic():
		pass
	var guard := 0
	while controller.state.phase != GameState.PHASE_MONTH_COMPLETE and guard < 300:
		guard += 1
		var actor_id := controller.state.current_player
		var actions := controller.legal_actions(actor_id)
		assert_bool(actions.is_empty()).is_false()
		var action: GameAction
		if actor_id == 1:
			action = SimpleAI.choose_action(PublicStateView.for_actor(controller.state, 1, catalog), actions, catalog)
		elif controller.state.phase == GameState.PHASE_SCORE_DECISION:
			action = actions[1] if actions.size() > 1 else actions[0]
		else:
			action = actions[0]
		assert_object(action).is_not_null()
		var result := controller.submit_action(action)
		assert_bool(result.accepted).is_true()
		assert_bool(controller.state.invariants_ok(catalog)).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_MONTH_COMPLETE)
	assert_bool(guard < 300).is_true()
	assert_str(controller.replay_log.replay_final_hash(catalog)).is_equal(controller.state.state_hash())

func test_presentation_round_trip_keeps_canonical_card_id() -> void:
	var catalog := CardCatalog.new()
	var definition := catalog.get_card("m01_pine_january_crane")
	var card_node := MoonCardPresentation.create_card_node(definition)
	assert_str(MoonCardPresentation.card_id_from_node(card_node)).is_equal(definition.card_id)
	var hand := MoonCardPresentation.create_hand_container()
	var pile := MoonCardPresentation.create_pile_container()
	assert_object(card_node).is_not_null()
	assert_object(hand).is_not_null()
	assert_object(pile).is_not_null()
	card_node.free()
	hand.free()
	pile.free()

func test_visual_movement_does_not_mutate_authoritative_state() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(5, catalog)
	var before_hash := state.state_hash()
	var card_node := MoonCardPresentation.create_card_node(catalog.get_card("m01_pine_january_crane"))
	card_node.position = Vector2(240, 120)
	assert_str(state.state_hash()).is_equal(before_hash)
	card_node.free()
