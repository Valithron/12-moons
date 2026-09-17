extends GdUnitTestSuite

var catalog: CardCatalog

func before() -> void:
	catalog = CardCatalog.new()

func _state_for(hand_ids: Array, field_ids: Array, next_draw_id: String = "") -> GameState:
	var state := GameState.new()
	state.seed = 77
	var used: Dictionary = {}
	var consumed: Array = []
	consumed.append_array(hand_ids)
	consumed.append_array(field_ids)
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
	state.field_ids = field_ids.duplicate()
	state.phase = GameState.PHASE_HAND_PLAY
	return state

func _break_candidate(candidate: GameState) -> void:
	if not candidate.players[0].captured_ids.is_empty():
		candidate.field_ids.append(candidate.players[0].captured_ids[0])
	else:
		candidate.field_ids.append(candidate.players[0].hand_ids[0])

func test_fresh_seeded_decks_are_identical() -> void:
	var first := GameState.fresh(12345, catalog)
	var second := GameState.fresh(12345, catalog)
	assert_array(first.deck.cards).is_equal(second.deck.cards)
	assert_str(first.state_hash()).is_equal(second.state_hash())

func test_fresh_deck_contains_all_48_unique_cards() -> void:
	var state := GameState.fresh(1, catalog)
	assert_bool(state.invariants_ok(catalog)).is_true()

func test_lost_authoritative_card_is_rejected_by_invariants() -> void:
	var state := GameState.fresh(2, catalog)
	state.deck.cards.pop_back()
	assert_bool(state.invariants_ok(catalog)).is_false()

func test_duplicate_authoritative_card_is_rejected_by_invariants() -> void:
	var state := _state_for(["m01_pine_january_crane"], [])
	state.field_ids.append("m01_pine_january_crane")
	assert_bool(state.invariants_ok(catalog)).is_false()

func test_legal_actions_and_controller_validation_agree() -> void:
	var state := _state_for(
		["m01_pine_january_crane"],
		["m01_pine_january_poetry_ribbon"]
	)
	var controller := MatchController.new(state.seed, catalog, state)
	var actions := controller.legal_actions(0)
	assert_int(actions.size()).is_equal(1)
	assert_bool(controller.is_legal_action(actions[0])).is_true()

func test_illegal_action_does_not_mutate_authoritative_state() -> void:
	var state := _state_for(
		["m01_pine_january_crane"],
		["m01_pine_january_poetry_ribbon"]
	)
	var controller := MatchController.new(state.seed, catalog, state)
	var before_hash := controller.state.state_hash()
	var illegal := GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", "m02_plum_february_chaff_a")
	var result := controller.submit_action(illegal)
	assert_bool(result.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before_hash)

func test_failed_postcondition_does_not_mutate_authoritative_state() -> void:
	var state := _state_for(
		["m01_pine_january_crane"],
		["m01_pine_january_poetry_ribbon"]
	)
	var controller := MatchController.new(state.seed, catalog, state)
	controller.postcondition_probe = Callable(self, "_break_candidate")
	var before_hash := controller.state.state_hash()
	var result := controller.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", ""))
	assert_bool(result.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before_hash)
	assert_bool(controller.state.invariants_ok(catalog)).is_true()

func test_pending_revealed_card_remains_in_authoritative_zones() -> void:
	var state := _state_for(
		["m01_pine_january_crane"],
		["m01_pine_january_poetry_ribbon", "m01_pine_january_chaff_a"],
		"m02_plum_february_chaff_a"
	)
	var controller := MatchController.new(state.seed, catalog, state)
	var result := controller.submit_action(GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", ""))
	assert_bool(result.accepted).is_true()
	assert_str(controller.state.phase).is_equal(GameState.PHASE_HAND_MATCH_CHOICE)
	assert_str(controller.state.pending_card_id).is_equal("m01_pine_january_crane")
	assert_bool(controller.state.all_authoritative_ids().has("m01_pine_january_crane")).is_true()
	assert_bool(controller.state.invariants_ok(catalog)).is_true()

func test_accepted_action_completes_hand_and_draw_before_passing_turn() -> void:
	var state := _state_for(
		["m01_pine_january_crane", "m02_plum_february_chaff_a"],
		["m01_pine_january_poetry_ribbon"],
		"m03_cherry_march_chaff_a"
	)
	var controller := MatchController.new(state.seed, catalog, state)
	var action := GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", "m01_pine_january_poetry_ribbon")
	var result := controller.submit_action(action)
	assert_bool(result.accepted).is_true()
	assert_int(controller.state.players[0].hand_ids.size()).is_equal(1)
	assert_int(controller.state.players[0].captured_ids.size()).is_equal(2)
	assert_str(controller.state.last_event.get("source", "")).is_equal("draw")
	assert_int(controller.state.turn_index).is_equal(1)
	assert_int(controller.state.current_player).is_equal(1)
	assert_bool(controller.state.invariants_ok(catalog)).is_true()
