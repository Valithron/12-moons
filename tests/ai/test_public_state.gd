extends GdUnitTestSuite

func test_ai_view_hides_other_hand_and_unrevealed_draw_order() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(9001, catalog)
	var own_card := state.deck.draw_card()
	var hidden_card := state.deck.draw_card()
	state.players[0].hand_ids = [own_card]
	state.players[1].hand_ids = [hidden_card]
	var unrevealed_first: String = String(state.deck.remaining_cards()[0])
	var view := PublicStateView.for_actor(state, 0)
	var serialized := JSON.stringify(view)
	assert_bool(serialized.contains(own_card)).is_true()
	assert_bool(serialized.contains(hidden_card)).is_false()
	assert_bool(serialized.contains(unrevealed_first)).is_false()
	assert_int(view["players"][1]["hand_count"]).is_equal(1)

func test_public_view_preserves_public_field_and_captures() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(7, catalog)
	state.field_ids = ["m01_pine_january_crane"]
	state.players[0].captured_ids = ["m02_plum_february_uguisu"]
	var view := PublicStateView.for_actor(state, 1)
	assert_bool(view["field_ids"].has("m01_pine_january_crane")).is_true()
	assert_bool(view["players"][0]["capture_ids"].has("m02_plum_february_uguisu")).is_true()
