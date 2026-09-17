extends GdUnitTestSuite

func test_ai_view_hides_seed_other_hand_and_unrevealed_draw_order() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(9001, catalog)
	var own_card := state.deck.draw_card()
	var hidden_card := state.deck.draw_card()
	state.players[0].hand_ids = [own_card]
	state.players[1].hand_ids = [hidden_card]
	var unrevealed_first: String = String(state.deck.remaining_cards()[0])
	var view := PublicStateView.for_actor(state, 0, catalog)
	var serialized := JSON.stringify(view)
	assert_bool(view.has("seed")).is_false()
	assert_bool(view.has("deck")).is_false()
	assert_bool(serialized.contains(own_card)).is_true()
	assert_bool(serialized.contains(hidden_card)).is_false()
	assert_bool(serialized.contains(unrevealed_first)).is_false()
	assert_int(view["players"][1]["hand_count"]).is_equal(1)

func test_ai_view_contains_only_public_zones_and_own_hand() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(17, catalog)
	var own_card := state.deck.draw_card()
	var hidden_card := state.deck.draw_card()
	state.players[0].hand_ids = [own_card]
	state.players[1].hand_ids = [hidden_card]
	state.field_ids = ["m01_pine_january_crane"]
	state.players[1].captured_ids = ["m02_plum_february_uguisu"]
	var view := PublicStateView.for_actor(state, 0, catalog)
	assert_bool(view["field_ids"].has("m01_pine_january_crane")).is_true()
	assert_bool(view["players"][1]["captured_ids"].has("m02_plum_february_uguisu")).is_true()
	assert_bool(view["players"][0].has("hand_ids")).is_true()
	assert_bool(view["players"][1].has("hand_ids")).is_false()
	assert_bool(view.has("seed")).is_false()
	assert_bool(view.has("deck")).is_false()
