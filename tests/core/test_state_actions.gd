extends GdUnitTestSuite

var catalog: CardCatalog

func before() -> void:
	catalog = CardCatalog.new()

func _state_for(hand_ids: Array, field_ids: Array) -> GameState:
	var state := GameState.new()
	state.seed = 77
	var used: Dictionary = {}
	for card_id in hand_ids + field_ids:
		used[String(card_id)] = true
	var remaining: Array = []
	for card_id in catalog.ids():
		if not used.has(card_id):
			remaining.append(card_id)
	state.deck = DeckState.new(remaining, state.seed, false)
	state.players = [PlayerState.new(0), PlayerState.new(1)]
	state.players[0].hand_ids = hand_ids.duplicate()
	state.field_ids = field_ids.duplicate()
	return state

func test_fresh_seeded_decks_are_identical() -> void:
	var first := GameState.fresh(12345, catalog)
	var second := GameState.fresh(12345, catalog)
	assert_array(first.deck.cards).is_equal(second.deck.cards)
	assert_str(first.state_hash()).is_equal(second.state_hash())

func test_fresh_deck_contains_all_48_unique_cards() -> void:
	var state := GameState.fresh(1, catalog)
	assert_int(state.deck.cards.size()).is_equal(48)
	assert_bool(state.invariants_ok(catalog)).is_true()

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

func test_accepted_action_mutates_only_through_controller() -> void:
	var state := _state_for(
		["m01_pine_january_crane"],
		["m01_pine_january_poetry_ribbon"]
	)
	var controller := MatchController.new(state.seed, catalog, state)
	var action := GameAction.new(GameAction.PLAY_CARD, 0, "m01_pine_january_crane", "m01_pine_january_poetry_ribbon")
	var result := controller.submit_action(action)
	assert_bool(result.accepted).is_true()
	assert_bool(controller.state.players[0].hand_ids.is_empty()).is_true()
	assert_int(controller.state.players[0].captured_ids.size()).is_equal(2)
	assert_bool(controller.state.field_ids.is_empty()).is_true()
