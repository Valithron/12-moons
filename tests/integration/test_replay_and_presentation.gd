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
	var starter_action: GameAction = controller.legal_actions(0)[0]
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

func test_table_layout_regions_fit_without_baseline_overlap() -> void:
	var layout_script = preload("res://scripts/ui/table_layout.gd")
	var layout = layout_script.new()
	var root := Control.new()
	root.size = layout_script.VIEW_SIZE
	layout.build(root)
	var rects: Dictionary = layout_script.REGION_RECTS
	for region_name in rects.keys():
		var rect: Rect2 = rects[region_name]
		assert_bool(rect.position.x >= 0.0 and rect.position.y >= 0.0).is_true()
		assert_bool(rect.end.x <= layout_script.VIEW_SIZE.x and rect.end.y <= layout_script.VIEW_SIZE.y).is_true()
	var names := rects.keys()
	for first_index in range(names.size()):
		for second_index in range(first_index + 1, names.size()):
			var first_name: String = names[first_index]
			var second_name: String = names[second_index]
			assert_bool(not (rects[first_name] as Rect2).intersects(rects[second_name] as Rect2)).is_true()
	root.free()

func test_score_decision_overlay_is_modal() -> void:
	var match_scene := load("res://scenes/match/match.tscn")
	var match_screen: Control = match_scene.instantiate()
	var controller := MatchController.new(77, CardCatalog.new())
	controller.state.phase = GameState.PHASE_SCORE_DECISION
	controller.state.current_player = 0
	match_screen.configure(controller)
	add_child(match_screen)
	await get_tree().process_frame
	var overlay: Control = match_screen.get("overlay_layer")
	assert_int(overlay.get_child_count()).is_equal(2)
	assert_int(overlay.get_child(0).mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	assert_int(overlay.get_child(1).mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	var panel: Control = overlay.get_child(1)
	var stop_button := _find_button(panel, "STOP")
	var koi_button := _find_button(panel, "KOI-KOI")
	assert_object(stop_button).is_not_null()
	assert_object(koi_button).is_not_null()
	match_screen.queue_free()

func _find_button(node: Node, target_text: String) -> Button:
	if node == null:
		return null
	for child in node.get_children():
		if child is Button and child.text == target_text:
			return child
		var nested: Button = _find_button(child, target_text)
		if nested != null:
			return nested
	return null
