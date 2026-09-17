extends GdUnitTestSuite

var catalog: CardCatalog

func before() -> void:
	catalog = CardCatalog.new()

func _state_for(hand_ids: Array, field_ids: Array, next_draw_id: String = "", captured_ids: Array = []) -> GameState:
	var state := GameState.new()
	state.seed = 321
	var ai_hand := ["m12_paulownia_december_chaff_c"]
	var consumed: Array = []
	consumed.append_array(captured_ids)
	consumed.append_array(hand_ids)
	consumed.append_array(field_ids)
	consumed.append_array(ai_hand)
	var used: Dictionary = {}
	for card_id in consumed:
		used[String(card_id)] = true
	var remaining: Array = []
	if not next_draw_id.is_empty():
		remaining.append(next_draw_id)
		used[next_draw_id] = true
	for card_id in catalog.ids():
		if not used.has(card_id):
			remaining.append(card_id)
	var deck_cards := consumed.duplicate()
	deck_cards.append_array(remaining)
	state.deck = DeckState.new(deck_cards, state.seed, false)
	state.deck.draw_index = consumed.size()
	state.players = [PlayerState.new(0), PlayerState.new(1)]
	state.players[0].hand_ids = hand_ids.duplicate()
	state.players[0].captured_ids = captured_ids.duplicate()
	state.players[1].hand_ids = ai_hand
	state.field_ids = field_ids.duplicate()
	state.phase = GameState.PHASE_HAND_PLAY
	return state

func _finish_setup(controller: MatchController) -> void:
	while controller.advance_automatic():
		pass

func test_starting_player_ceremony_uses_three_unique_months_and_earlier_revealed_card() -> void:
	var controller := MatchController.new(101, catalog)
	controller.begin_january(101)
	var starter_ids := controller.state.starter_card_ids.duplicate()
	assert_int(starter_ids.size()).is_equal(3)
	var months: Dictionary = {}
	for card_id in starter_ids:
		var definition := catalog.get_card(String(card_id))
		months[definition.month] = true
	assert_int(months.size()).is_equal(3)
	var selected := controller.legal_actions(0)[0]
	var selected_definition := catalog.get_card(selected.card_id)
	assert_bool(controller.submit_action(selected).accepted).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_STARTER_AI_REVEAL)
	assert_int(controller.state.current_player).is_equal(1)
	assert_bool(controller.advance_automatic()).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_STARTER_RESULT)
	assert_int(controller.replay_log.actions.size()).is_equal(2)
	var recorded_ai_action := GameAction.from_dict(controller.replay_log.actions[1])
	assert_int(recorded_ai_action.actor_id).is_equal(1)
	assert_str(recorded_ai_action.action_type).is_equal(GameAction.SELECT_STARTER)
	var ai_definition := catalog.get_card(controller.state.starter_ai_card_id)
	assert_bool(controller.state.starter_ai_card_id != selected.card_id).is_true()
	var expected_first := 0 if selected_definition.month < ai_definition.month else 1
	assert_int(controller.state.first_player).is_equal(expected_first)
	assert_bool(controller.state.invariants_ok(catalog)).is_true()
	assert_bool(controller.advance_automatic()).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_HAND_PLAY)

func test_january_deals_eight_eight_eight_and_redeals_invalid_opening_field() -> void:
	var seed_with_redeal := -1
	for seed in range(0, 20000):
		var deal := JanuarySetup.opening_deal_for_seed(seed, catalog)
		if int(deal["attempt"]) > 0:
			seed_with_redeal = seed
			break
	assert_bool(seed_with_redeal >= 0).is_true()
	var first := JanuarySetup.opening_deal_for_seed(seed_with_redeal, catalog)
	var second := JanuarySetup.opening_deal_for_seed(seed_with_redeal, catalog)
	assert_int(first["player_hand"].size()).is_equal(8)
	assert_int(first["ai_hand"].size()).is_equal(8)
	assert_int(first["field"].size()).is_equal(8)
	assert_bool(JanuarySetup.invalid_initial_field(first["field"], catalog)).is_false()
	assert_int(first["attempt"]).is_equal(second["attempt"])
	assert_array(first["deck"].cards).is_equal(second["deck"].cards)
	var controller := MatchController.new(seed_with_redeal, catalog)
	controller.begin_january(seed_with_redeal)
	assert_bool(controller.submit_action(controller.legal_actions(0)[0]).accepted).is_true()
	_finish_setup(controller)
	assert_int(controller.state.field_ids.size()).is_equal(8)
	assert_int(controller.state.deck.remaining_count()).is_equal(24)
	assert_bool(controller.state.invariants_ok(catalog)).is_true()

func test_four_of_a_month_opening_hand_is_captured_without_instant_win() -> void:
	var month_cards := catalog.cards_for_month(1)
	var state := _state_for(month_cards, [], "m02_plum_february_chaff_a", [])
	JanuarySetup.apply_opening_four_of_month_captures(state, catalog)
	assert_bool(state.players[0].hand_ids.is_empty()).is_true()
	assert_array(state.players[0].captured_ids).is_equal(month_cards)
	assert_bool(state.terminal_result.is_empty()).is_true()
	assert_str(state.phase).is_equal(GameState.PHASE_HAND_PLAY)

func test_two_match_hand_choice_keeps_turn_until_complete_draw_resolution() -> void:
	var state := _state_for(
		["m01_pine_january_crane", "m02_plum_february_chaff_b"],
		["m01_pine_january_poetry_ribbon", "m01_pine_january_chaff_a"],
		"m02_plum_february_chaff_a"
	)
	var controller := MatchController.new(state.seed, catalog, state)
	var played := controller.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", ""))
	assert_bool(played.accepted).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_HAND_MATCH_CHOICE)
	assert_int(controller.state.current_player).is_equal(0)
	assert_bool(controller.state.pending_card_id == "m01_pine_january_crane").is_true()
	var choice := controller.submit_action(controller.legal_actions(0)[0])
	assert_bool(choice.accepted).is_true()
	assert_str(controller.state.last_event.get("source", "")).is_equal("draw")
	assert_int(controller.state.current_player).is_equal(1)
	assert_int(controller.state.turn_index).is_equal(1)

func test_natural_exhaustion_ends_after_last_playable_hand_card() -> void:
	var state := _state_for(
		["m02_plum_february_chaff_a"],
		["m01_pine_january_crane"],
		"m01_pine_january_chaff_a"
	)
	var controller := MatchController.new(state.seed, catalog, state)
	var result := controller.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m02_plum_february_chaff_a", ""))
	assert_bool(result.accepted).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_MONTH_COMPLETE)
	assert_str(controller.state.terminal_result.get("ended_by", "")).is_equal("exhaustion")
	assert_bool(controller.state.invariants_ok(catalog)).is_true()

func test_zero_one_and_three_match_resolution() -> void:
	var zero := MatchController.new(1, catalog, _state_for(["m01_pine_january_crane"], ["m02_plum_february_chaff_a"], "m03_cherry_march_chaff_a"))
	assert_bool(zero.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", "")).accepted).is_true()
	assert_bool(zero.state.field_ids.has("m01_pine_january_crane")).is_true()

	var one_state := _state_for(["m01_pine_january_crane"], ["m01_pine_january_poetry_ribbon"], "m02_plum_february_chaff_a")
	var one := MatchController.new(2, catalog, one_state)
	assert_bool(one.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", "")).accepted).is_true()
	assert_int(one.state.players[0].captured_ids.size()).is_equal(2)

	var three_state := _state_for(
		["m01_pine_january_crane"],
		["m01_pine_january_poetry_ribbon", "m01_pine_january_chaff_a", "m01_pine_january_chaff_b"],
		"m02_plum_february_chaff_a"
	)
	var three := MatchController.new(3, catalog, three_state)
	assert_bool(three.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", "")).accepted).is_true()
	assert_int(three.state.players[0].captured_ids.size()).is_equal(4)

func test_draw_card_with_two_matches_waits_for_the_same_actor_choice() -> void:
	var state := _state_for(
		["m02_plum_february_chaff_a", "m03_cherry_march_chaff_a"],
		["m01_pine_january_poetry_ribbon", "m01_pine_january_chaff_a"],
		"m01_pine_january_crane"
	)
	var controller := MatchController.new(state.seed, catalog, state)
	var result := controller.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m02_plum_february_chaff_a", ""))
	assert_bool(result.accepted).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_DRAW_MATCH_CHOICE)
	assert_str(controller.state.pending_card_source).is_equal("draw")
	assert_int(controller.state.current_player).is_equal(0)
	assert_bool(controller.state.invariants_ok(catalog)).is_true()
	assert_bool(controller.submit_action(controller.legal_actions(0)[0]).accepted).is_true()
	assert_int(controller.state.current_player).is_equal(1)

func test_score_decision_is_after_draw_and_stop_ends_the_month() -> void:
	var nine_chaff := [
		"m01_pine_january_chaff_a", "m01_pine_january_chaff_b",
		"m02_plum_february_chaff_a", "m02_plum_february_chaff_b",
		"m03_cherry_march_chaff_a", "m03_cherry_march_chaff_b",
		"m04_wisteria_april_chaff_a", "m04_wisteria_april_chaff_b",
		"m05_iris_may_chaff_a"
	]
	var state := _state_for(
		["m01_pine_january_crane", "m12_paulownia_december_chaff_b"],
		["m06_peony_june_chaff_a"],
		"m06_peony_june_chaff_b",
		nine_chaff
	)
	var controller := MatchController.new(state.seed, catalog, state)
	controller.state.previous_score_snapshots[0] = YakuEvaluator.evaluate(nine_chaff, catalog, "wolf_moon")
	var result := controller.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", ""))
	assert_bool(result.accepted).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_SCORE_DECISION)
	assert_int(controller.state.deck.draw_index).is_equal(nine_chaff.size() + 5)
	assert_bool(controller.state.pending_card_id.is_empty()).is_true()
	assert_str(controller.state.last_event.get("kind", "")).is_equal("score_decision")
	assert_bool(controller.submit_action(GameAction.new(GameAction.STOP, 0)).accepted).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_MONTH_COMPLETE)
	assert_str(controller.state.terminal_result.get("ended_by", "")).is_equal("stop")
