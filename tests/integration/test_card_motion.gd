extends GdUnitTestSuite

const TABLE_LAYOUT_SCRIPT := preload("res://scripts/ui/table_layout.gd")

func test_presentation_queue_runs_semantic_jobs_in_order_and_unlocks() -> void:
	var queue := MoonPresentationQueue.new()
	add_child(queue)
	var events: Array = []
	var busy_states: Array = []
	queue.busy_changed.connect(func(is_busy: bool) -> void: busy_states.append(is_busy))
	queue.sequence_finished.connect(func(label: String) -> void: events.append("finished:" + label))
	queue.enqueue("deal", Callable(self, "_record_queue_job").bind(events, "deal"))
	queue.enqueue("capture", Callable(self, "_record_queue_job").bind(events, "capture"))
	for _frame in range(12):
		await get_tree().process_frame
	assert_bool(queue.is_busy()).is_false()
	assert_int(events.size()).is_equal(6)
	assert_str(events[0]).is_equal("start:deal")
	assert_str(events[1]).is_equal("end:deal")
	assert_str(events[2]).is_equal("finished:deal")
	assert_str(events[3]).is_equal("start:capture")
	assert_str(events[4]).is_equal("end:capture")
	assert_str(events[5]).is_equal("finished:capture")
	assert_int(busy_states.size()).is_equal(2)
	assert_bool(busy_states[0]).is_true()
	assert_bool(busy_states[1]).is_false()
	queue.free()

func test_presentation_queue_cancel_clears_pending_jobs() -> void:
	var queue := MoonPresentationQueue.new()
	add_child(queue)
	var events: Array = []
	queue.enqueue("long", Callable(self, "_record_long_queue_job").bind(events))
	queue.enqueue("never", Callable(self, "_record_queue_job").bind(events, "never"))
	await get_tree().process_frame
	queue.cancel()
	for _frame in range(4):
		await get_tree().process_frame
	assert_bool(queue.is_busy()).is_false()
	assert_int(queue.pending_count()).is_equal(0)
	assert_int(events.size()).is_equal(1)
	assert_str(events[0]).is_equal("started-long")
	queue.free()

func test_presentation_queue_cancel_and_restore_runs_finalizer_once() -> void:
	var queue := MoonPresentationQueue.new()
	add_child(queue)
	var events: Array = []
	queue.enqueue("long", Callable(self, "_record_long_queue_job").bind(events))
	await get_tree().process_frame
	queue.cancel_and_restore(func() -> void: events.append("restored"))
	for _frame in range(4):
		await get_tree().process_frame
	assert_bool(queue.is_busy()).is_false()
	assert_int(queue.pending_count()).is_equal(0)
	assert_int(events.count("restored")).is_equal(1)
	assert_bool(events.has("ended-long")).is_false()
	queue.free()

func test_card_registry_reuses_one_visual_node_per_stable_id() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(17, catalog)
	var card_ids := ["m11_willow_november_lightning_chaff", "m01_pine_january_crane", "m02_plum_february_uguisu", "m03_cherry_march_curtain"]
	state.players[0].hand_ids = [card_ids[0], card_ids[1]]
	state.players[1].hand_ids = [card_ids[2]]
	state.field_ids = [card_ids[3]]
	var controller := MatchController.new(state.seed, catalog, state)
	var match_scene := load("res://scenes/match/match.tscn")
	var match_screen: Control = match_scene.instantiate()
	match_screen.configure(controller)
	add_child(match_screen)
	await get_tree().process_frame
	var registry: Dictionary = match_screen.get("card_registry")
	assert_int(registry.size()).is_equal(card_ids.size())
	var original_instance_ids: Dictionary = {}
	for card_id in card_ids:
		var card: MoonCardView = registry[card_id]
		assert_object(card).is_not_null()
		original_instance_ids[card_id] = card.get_instance_id()
	match_screen.call("_refresh_from_state", true, true)
	var refreshed_registry: Dictionary = match_screen.get("card_registry")
	for card_id in card_ids:
		var refreshed_card: MoonCardView = refreshed_registry[card_id]
		assert_int(refreshed_card.get_instance_id()).is_equal(original_instance_ids[card_id])
		assert_bool(refreshed_card.get_slot_position() != Vector2.ZERO).is_true()
	match_screen.queue_free()

func test_capture_targets_stay_with_their_owner_region() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(31, catalog)
	var player_card := "m01_pine_january_crane"
	var house_card := "m02_plum_february_uguisu"
	state.players[0].captured_ids = [player_card]
	state.players[1].captured_ids = [house_card]
	var match_scene := load("res://scenes/match/match.tscn")
	var match_screen: Control = match_scene.instantiate()
	add_child(match_screen)
	await get_tree().process_frame
	var positions: Dictionary = match_screen.call("_capture_positions", state)
	var player_region: Rect2 = TABLE_LAYOUT_SCRIPT.REGION_RECTS["player_captures"]
	var house_region: Rect2 = TABLE_LAYOUT_SCRIPT.REGION_RECTS["opponent_captures"]
	assert_bool(player_region.has_point(positions[player_card])).is_true()
	assert_bool(house_region.has_point(positions[house_card])).is_true()
	assert_bool(house_region.has_point(positions[player_card])).is_false()
	assert_bool(player_region.has_point(positions[house_card])).is_false()
	match_screen.queue_free()

func test_presentation_busy_blocks_duplicate_card_submission() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(23, catalog)
	var card_id := "m01_pine_january_crane"
	state.players[0].hand_ids = [card_id]
	var controller := MatchController.new(state.seed, catalog, state)
	var match_scene := load("res://scenes/match/match.tscn")
	var match_screen: Control = match_scene.instantiate()
	match_screen.configure(controller)
	add_child(match_screen)
	await get_tree().process_frame
	var turn_before := controller.state.turn_index
	match_screen.set("presentation_busy", true)
	match_screen.call("_on_card_clicked", card_id)
	assert_int(controller.state.turn_index).is_equal(turn_before)
	match_screen.queue_free()

func test_accepted_action_unlocks_after_play_draw_and_hand_reflow() -> void:
	var catalog := CardCatalog.new()
	var state := GameState.fresh(29, catalog)
	var first_card: String = state.deck.draw_card()
	var second_card: String = state.deck.draw_card()
	state.players[0].hand_ids = [first_card, second_card]
	state.field_ids = []
	var controller := MatchController.new(state.seed, catalog, state)
	var match_scene := load("res://scenes/match/match.tscn")
	var match_screen: Control = match_scene.instantiate()
	match_screen.configure(controller)
	add_child(match_screen)
	await get_tree().process_frame
	match_screen.call("_submit_human", GameAction.new(GameAction.PLAY_CARD, 0, first_card, ""))
	for _frame in range(240):
		await get_tree().process_frame
		if not match_screen.get("presentation_busy"):
			break
	assert_bool(match_screen.get("presentation_busy")).is_false()
	assert_bool(controller.state.players[0].hand_ids.has(second_card)).is_true()
	var registry: Dictionary = match_screen.get("card_registry")
	var remaining_card: MoonCardView = registry[second_card]
	var targets: Dictionary = match_screen.call("_card_targets", controller.state)
	assert_bool(targets.has(second_card)).is_true()
	assert_bool(remaining_card.position.distance_to(targets[second_card]["position"]) < 0.1).is_true()
	match_screen.queue_free()

func test_motion_timings_expose_fast_and_reduced_modes() -> void:
	var timings := MoonMotionTimings.new()
	var normal_duration := timings.duration(MoonMotionTimings.PLAY_TRAVEL)
	timings.mode = MoonMotionTimings.Mode.FAST
	assert_bool(timings.duration(MoonMotionTimings.PLAY_TRAVEL) < normal_duration).is_true()
	timings.mode = MoonMotionTimings.Mode.REDUCED
	assert_float(timings.duration(MoonMotionTimings.PLAY_TRAVEL)).is_equal(0.0)
	assert_bool(timings.is_reduced()).is_true()

func _record_queue_job(events: Array, label: String) -> void:
	events.append("start:" + label)
	await get_tree().process_frame
	events.append("end:" + label)

func _record_long_queue_job(events: Array) -> void:
	events.append("started-long")
	await get_tree().create_timer(0.5).timeout
	events.append("ended-long")
