extends Control

signal month_finished(result: Dictionary)

const GOLD := Color(0.95, 0.84, 0.56)
const TEXT := Color(0.91, 0.93, 0.90)
const MUTED := Color(0.63, 0.71, 0.76)
const ACCENT := Color(1.0, 0.82, 0.22)
const TABLE_LAYOUT_SCRIPT := preload("res://scripts/ui/table_layout.gd")
const CAPTURE_REGIONS := {0: "player_captures", 1: "opponent_captures"}

var controller: MatchController
var catalog: CardCatalog
var table_layer: Control
var card_layer: Control
var overlay_layer: Control
var ceremony_layer: Control
var draw_pile_view: MoonCardView
var layout
var motion_timings: MoonMotionTimings
var motion: MoonCardMotionController
var presentation_queue: MoonPresentationQueue
var card_registry: Dictionary = {}

var last_rendered_hash: String = ""
## Kept as a compatibility/debug hook for the existing headless flow. It is no
## longer the gate for presentation; queue completion is the gate.
var ai_cooldown: float = 0.0
var presentation_busy: bool = false
var result_sent: bool = false
var ui_message: String = ""
var last_draw_card_id: String = ""
var _presentation_generation: int = 0

func _ready() -> void:
	catalog = CardCatalog.new()
	motion_timings = MoonMotionTimings.new()

	table_layer = Control.new()
	table_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	table_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(table_layer)
	layout = TABLE_LAYOUT_SCRIPT.new()
	layout.build(table_layer)

	ceremony_layer = Control.new()
	ceremony_layer.name = "StarterCeremony"
	ceremony_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ceremony_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ceremony_layer.visible = false
	table_layer.add_child(ceremony_layer)

	# Gameplay cards live on one full-screen layer. They are never children of a
	# hand/field/capture container, so their screen position survives every zone
	# transition and temporary z-order raise without creating a visual duplicate.
	card_layer = Control.new()
	card_layer.name = "CardMotionLayer"
	card_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_layer.z_index = 10
	add_child(card_layer)
	draw_pile_view = MoonCardView.new()
	card_layer.add_child(draw_pile_view)
	draw_pile_view.configure(null, false, false, false, Vector2(70, 102))
	draw_pile_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw_pile_view.z_index = 2

	overlay_layer = Control.new()
	overlay_layer.name = "ModalOverlay"
	overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.z_index = 100
	add_child(overlay_layer)

	presentation_queue = MoonPresentationQueue.new()
	presentation_queue.name = "PresentationQueue"
	add_child(presentation_queue)
	presentation_queue.busy_changed.connect(_on_queue_busy_changed)
	motion = MoonCardMotionController.new(self, motion_timings)

	if controller != null:
		call_deferred("_refresh_from_state", true, true)

func _exit_tree() -> void:
	_cancel_presentation()

func configure(match_controller: MatchController) -> void:
	_cancel_presentation()
	_clear_card_registry()
	controller = match_controller
	catalog = controller.catalog
	last_rendered_hash = ""
	result_sent = false
	ai_cooldown = 0.0
	presentation_busy = false
	ui_message = ""
	last_draw_card_id = ""
	_presentation_generation += 1
	if is_inside_tree():
		_refresh_from_state(true, true)

func _process(delta: float) -> void:
	if controller == null or presentation_busy:
		return

	var state := controller.state
	var current_hash := state.state_hash()
	if current_hash != last_rendered_hash:
		_refresh_from_state(true, true)

	if state.phase == GameState.PHASE_MONTH_COMPLETE:
		if not result_sent:
			_emit_month_finished()
		return

	if state.phase == GameState.PHASE_STARTER_AI_REVEAL or state.phase == GameState.PHASE_STARTER_RESULT:
		ai_cooldown -= delta
		if ai_cooldown <= 0.0:
			_drive_automatic_phase()
		return

	if state.current_player == 1:
		ai_cooldown -= delta
		if ai_cooldown <= 0.0:
			_drive_ai()
	else:
		ai_cooldown = minf(ai_cooldown, 0.0)

func _drive_automatic_phase() -> void:
	if controller.state.phase == GameState.PHASE_STARTER_AI_REVEAL:
		var actions := controller.legal_actions(1)
		if not actions.is_empty():
			_submit_action(actions[0], "House")
		return
	if controller.state.phase == GameState.PHASE_STARTER_RESULT:
		_advance_opening_deal()

func _advance_opening_deal() -> void:
	if presentation_busy:
		return
	var before := _copy_state(controller.state)
	if not controller.advance_automatic():
		return
	var after := _copy_state(controller.state)
	ui_message = String(after.last_event.get("message", "January is dealt."))
	var worker := Callable(self, "_present_initial_deal").bind(before, after)
	_begin_presentation("initial_deal", before, after, worker)

func _drive_ai() -> void:
	if presentation_busy:
		return
	var view := PublicStateView.for_actor(controller.state, 1, catalog)
	var actions := controller.legal_actions(1)
	var action := SimpleAI.choose_action(view, actions, catalog)
	if action == null:
		ui_message = "House has no legal action."
		return
	_submit_action(action, "House")

func _submit_human(action: GameAction) -> void:
	if presentation_busy:
		return
	_submit_action(action, "You")

func _submit_action(action: GameAction, actor_name: String) -> void:
	if controller == null or action == null or presentation_busy:
		return
	var before := _copy_state(controller.state)
	var result := controller.submit_action(action)
	if not result.accepted:
		ui_message = result.reason
		last_rendered_hash = ""
		return
	var after := _copy_state(controller.state)
	_remember_draw_card(after)
	ui_message = _describe_action(action, result, actor_name, after)
	var worker := Callable(self, "_present_action").bind(before, action, result, after)
	_begin_presentation(action.action_type, before, after, worker)

func _begin_presentation(label: String, before: GameState, after: GameState, worker: Callable) -> void:
	if presentation_queue == null or motion == null:
		return
	_presentation_generation += 1
	var token := _presentation_generation
	presentation_busy = true
	last_rendered_hash = after.state_hash()
	_lock_input()
	# Labels follow the authoritative result immediately while cards are still
	# traveling. Card positions remain controlled by the active sequence.
	_render_static(after)
	_apply_card_targets(before, true)
	presentation_queue.enqueue(label, Callable(self, "_run_presentation").bind(worker, after, token))

func _run_presentation(worker: Callable, after: GameState, token: int) -> void:
	await worker.call()
	if token != _presentation_generation or not is_inside_tree():
		return
	_refresh_from_state(true, true)
	if after.phase == GameState.PHASE_MONTH_COMPLETE:
		await motion.hold(MoonMotionTimings.RESULT_HOLD)
		if token == _presentation_generation and is_inside_tree():
			presentation_busy = false
			_emit_month_finished()
		return
	presentation_busy = false
	ai_cooldown = 0.20 if after.current_player == 1 else 0.0

func _on_queue_busy_changed(is_busy: bool) -> void:
	# presentation_busy is set synchronously by _begin_presentation so a second
	# click cannot sneak in before the deferred queue drain starts.
	if is_busy:
		presentation_busy = true

func _present_action(before: GameState, action: GameAction, result: ActionResult, after: GameState) -> void:
	match action.action_type:
		GameAction.SELECT_STARTER:
			await _present_starter_action(action, after)
		GameAction.PLAY_CARD:
			await _present_play_action(before, action, result, after)
		GameAction.CHOOSE_MATCH:
			await _present_match_choice(before, action, result, after)
		GameAction.STOP, GameAction.KOI_KOI:
			await _present_score_action()

func _present_starter_action(action: GameAction, after: GameState) -> void:
	var selected := _ensure_card(action.card_id, false)
	if selected == null:
		return
	selected.set_selectable(false)
	selected.z_index = 140
	await motion.flip(selected, true, MoonMotionTimings.CEREMONY_FLIP)
	await motion.hold(MoonMotionTimings.CEREMONY_HOLD * 0.55)
	if after.phase == GameState.PHASE_STARTER_RESULT and not after.starter_winner_card_id.is_empty():
		var winner := _ensure_card(after.starter_winner_card_id, true)
		if winner != null:
			winner.z_index = 145
			await motion.pulse(winner, MoonMotionTimings.CEREMONY_HOLD)
			await motion.hold(MoonMotionTimings.CEREMONY_HOLD)

func _present_initial_deal(_before: GameState, after: GameState) -> void:
	var targets := _card_targets(after)
	var origin := _draw_pile_position()
	var order := _opening_deal_order(after)
	var moving_cards: Array = []
	var move_targets: Dictionary = {}
	for card_id in order:
		var card := _ensure_card(String(card_id), false)
		if card == null or not targets.has(String(card_id)):
			continue
		var target_info: Dictionary = targets[String(card_id)]
		var target_position: Vector2 = target_info["position"]
		var target_size: Vector2 = target_info["size"]
		var target_face := bool(target_info["face_up"])
		card.visible = true
		card.set_display(target_size, target_face, false, false)
		card.position = origin
		card.set_slot_position(origin)
		card.resting_z_index = 30
		card.z_index = 90 + moving_cards.size()
		moving_cards.append(card)
		move_targets[card] = target_position
	for card_variant in card_registry.values():
		var card: MoonCardView = card_variant
		if card != null and is_instance_valid(card) and not targets.has(card.card_id):
			card.visible = false
	await motion.move_staggered(moving_cards, move_targets, MoonMotionTimings.DEAL_TRAVEL, MoonMotionTimings.DEAL_STAGGER)

func _present_play_action(before: GameState, action: GameAction, result: ActionResult, after: GameState) -> void:
	var before_targets := _card_targets(before)
	var after_targets := _card_targets(after)
	var played := _ensure_card(action.card_id, action.actor_id == 0)
	if played == null:
		return
	played.set_selectable(false)
	played.z_index = 150
	var move_cards: Array = [played]
	var move_targets: Dictionary = {played: _play_resolution_position()}
	var actor_after_hand: Array = after.players[action.actor_id].hand_ids
	for raw_id in actor_after_hand:
		var card_id := String(raw_id)
		var hand_card := _card_from_registry(card_id)
		if hand_card != null and after_targets.has(card_id):
			move_cards.append(hand_card)
			move_targets[hand_card] = after_targets[card_id]["position"]
	await motion.move_group(move_cards, move_targets, MoonMotionTimings.PLAY_TRAVEL)
	if action.actor_id == 1:
		await motion.flip(played, true, MoonMotionTimings.DRAW_FLIP)

	if after.phase == GameState.PHASE_HAND_MATCH_CHOICE:
		_set_choice_visuals(after)
		await motion.hold(MoonMotionTimings.CHOICE_HOLD)
		return

	await _present_resolution_capture(before, result.captured_ids, played, after, after_targets, before_targets)
	var draw_id := _draw_card_id(after)
	if not draw_id.is_empty():
		await _present_draw_resolution(after, draw_id, after_targets)
	if after.phase == GameState.PHASE_SCORE_DECISION:
		await _present_yaku_feedback(after)

func _present_match_choice(before: GameState, action: GameAction, result: ActionResult, after: GameState) -> void:
	var before_targets := _card_targets(before)
	var after_targets := _card_targets(after)
	var pending := _ensure_card(action.card_id, true)
	if pending == null:
		return
	pending.set_selectable(false)
	pending.z_index = 150
	var target_view := _card_from_registry(action.target_card_id)
	var impact_position := target_view.position if target_view != null else _play_resolution_position()
	await motion.move(pending, impact_position, MoonMotionTimings.CAPTURE_APPROACH)
	await motion.impact(pending, MoonMotionTimings.CAPTURE_IMPACT)
	await motion.hold(MoonMotionTimings.CAPTURE_PAUSE)
	await _animate_capture_packet(result.captured_ids, impact_position, after, after_targets)
	if before.pending_card_source == "hand":
		var draw_id := _draw_card_id(after)
		if not draw_id.is_empty():
			await _present_draw_resolution(after, draw_id, after_targets)
	if after.phase == GameState.PHASE_SCORE_DECISION:
		await _present_yaku_feedback(after)

func _present_resolution_capture(before: GameState, captured_ids: Array, played: MoonCardView, after: GameState, after_targets: Dictionary, before_targets: Dictionary) -> void:
	if captured_ids.is_empty():
		await _move_existing_to_after(after, after_targets, [played.card_id])
		if after_targets.has(played.card_id):
			await motion.move(played, after_targets[played.card_id]["position"], MoonMotionTimings.FIELD_REFLOW)
		return
	var impact_id := ""
	for raw_id in captured_ids:
		var card_id := String(raw_id)
		if card_id != played.card_id:
			impact_id = card_id
			break
	var impact_position: Vector2 = before_targets[impact_id]["position"] if not impact_id.is_empty() and before_targets.has(impact_id) else _play_resolution_position()
	await motion.move(played, impact_position, MoonMotionTimings.CAPTURE_APPROACH)
	await motion.impact(played, MoonMotionTimings.CAPTURE_IMPACT)
	await motion.hold(MoonMotionTimings.CAPTURE_PAUSE)
	await _animate_capture_packet(captured_ids, impact_position, after, after_targets)

func _present_draw_resolution(after: GameState, draw_id: String, after_targets: Dictionary) -> void:
	var draw_card := _ensure_card(draw_id, false)
	if draw_card == null:
		return
	draw_card.visible = true
	draw_card.set_display(Vector2(70, 102), false, false, true)
	draw_card.position = _draw_pile_position()
	draw_card.set_slot_position(draw_card.position)
	draw_card.z_index = 155
	await motion.move(draw_card, _draw_resolution_position(), MoonMotionTimings.DRAW_TRAVEL)
	await motion.flip(draw_card, true, MoonMotionTimings.DRAW_FLIP)
	await motion.hold(MoonMotionTimings.DRAW_HOLD)
	if after.phase == GameState.PHASE_DRAW_MATCH_CHOICE:
		_set_choice_visuals(after)
		return

	var draw_captured := _draw_captured_ids(after)
	if not draw_captured.is_empty():
		var impact_id := ""
		for raw_id in draw_captured:
			var card_id := String(raw_id)
			if card_id != draw_id:
				impact_id = card_id
				break
		var impact_view := _card_from_registry(impact_id)
		var impact_position := impact_view.position if impact_view != null else _draw_resolution_position()
		await motion.move(draw_card, impact_position, MoonMotionTimings.CAPTURE_APPROACH)
		await motion.impact(draw_card, MoonMotionTimings.CAPTURE_IMPACT)
		await motion.hold(MoonMotionTimings.CAPTURE_PAUSE)
		await _animate_capture_packet(draw_captured, impact_position, after, after_targets)
	else:
		await _move_existing_to_after(after, after_targets, [draw_id])
		if after_targets.has(draw_id):
			await motion.move(draw_card, after_targets[draw_id]["position"], MoonMotionTimings.FIELD_REFLOW)

func _animate_capture_packet(captured_ids: Array, impact_position: Vector2, after: GameState, after_targets: Dictionary) -> void:
	var packet_cards: Array = []
	var packet_targets: Dictionary = {}
	for index in range(captured_ids.size()):
		var card_id := String(captured_ids[index])
		var card := _ensure_card(card_id, true)
		if card == null:
			continue
		card.visible = true
		card.set_selectable(false)
		card.z_index = 160 + index
		packet_cards.append(card)
		packet_targets[card] = impact_position + Vector2(index * 8.0, index * 5.0)
	if packet_cards.is_empty():
		return
	await motion.move_group(packet_cards, packet_targets, MoonMotionTimings.CAPTURE_PAUSE)
	var final_cards: Array = packet_cards.duplicate()
	var final_targets: Dictionary = {}
	for card_variant in packet_cards:
		var card: MoonCardView = card_variant
		final_targets[card] = after_targets[card.card_id]["position"] if after_targets.has(card.card_id) else impact_position
	for raw_id in after.field_ids:
		_add_existing_reflow_target(String(raw_id), after_targets, final_cards, final_targets)
	for player_state in after.players:
		for raw_id in player_state.captured_ids:
			_add_existing_reflow_target(String(raw_id), after_targets, final_cards, final_targets)
	await motion.move_group(final_cards, final_targets, MoonMotionTimings.CAPTURE_TRANSFER)

func _move_existing_to_after(after: GameState, after_targets: Dictionary, excluded_ids: Array) -> void:
	var cards: Array = []
	var targets: Dictionary = {}
	for card_id_variant in after_targets.keys():
		var card_id := String(card_id_variant)
		if excluded_ids.has(card_id):
			continue
		var card := _card_from_registry(card_id)
		if card == null or not card.visible:
			continue
		cards.append(card)
		targets[card] = after_targets[card_id]["position"]
	await motion.move_group(cards, targets, MoonMotionTimings.FIELD_REFLOW)

func _add_existing_reflow_target(card_id: String, after_targets: Dictionary, final_cards: Array, final_targets: Dictionary) -> void:
	for card_variant in final_cards:
		var existing: MoonCardView = card_variant
		if existing.card_id == card_id:
			return
	if not after_targets.has(card_id):
		return
	var card := _card_from_registry(card_id)
	if card == null or not card.visible:
		return
	final_cards.append(card)
	final_targets[card] = after_targets[card_id]["position"]

func _present_yaku_feedback(state: GameState) -> void:
	var score: Dictionary = state.last_event.get("score", {})
	if score.is_empty():
		score = YakuEvaluator.evaluate(state.players[state.current_player].captured_ids, catalog, state.moon_id)
	var banner := ColorRect.new()
	banner.name = "YakuFeedback"
	banner.color = Color(0.13, 0.24, 0.28, 0.96)
	banner.position = Vector2(370, 92)
	banner.size = Vector2(540, 54)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 120
	overlay_layer.add_child(banner)
	var names: Array = []
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		names.append(String(entry.get("name", "Yaku")))
	_add_label(banner, "YAKU IMPROVED  •  " + (", ".join(names) if not names.is_empty() else "SCORE RAISED"), Vector2(10, 0), Vector2(520, 54), 16, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	await motion.pulse(banner, MoonMotionTimings.YAKU_FEEDBACK)
	await motion.hold(0.08)
	if is_instance_valid(banner):
		banner.queue_free()

func _present_score_action() -> void:
	if overlay_layer.get_child_count() > 0:
		await motion.fade(overlay_layer, 0.0, MoonMotionTimings.MODAL_DISMISS)
	await motion.hold(0.08)

func _refresh_from_state(immediate: bool = true, show_modal: bool = true) -> void:
	if controller == null:
		return
	last_rendered_hash = controller.state.state_hash()
	overlay_layer.modulate = Color.WHITE
	_clear(overlay_layer)
	_render_static(controller.state)
	_apply_card_targets(controller.state, immediate)
	if controller.state.phase == GameState.PHASE_SCORE_DECISION and controller.state.current_player == 0 and show_modal:
		var player_score := YakuEvaluator.evaluate(controller.state.players[0].captured_ids, catalog, controller.state.moon_id)
		_render_score_decision(player_score)

func _render_static(state: GameState) -> void:
	_clear(ceremony_layer)
	for region_name in TABLE_LAYOUT_SCRIPT.REGION_RECTS.keys():
		_clear(layout.content(String(region_name)))
	if _is_ceremony_phase(state):
		layout.root.visible = false
		ceremony_layer.visible = true
		_render_starter_ceremony(state)
		if draw_pile_view != null:
			draw_pile_view.visible = false
		return
	layout.root.visible = true
	ceremony_layer.visible = false
	_render_table(state)
	if draw_pile_view != null:
		draw_pile_view.visible = true
		draw_pile_view.position = _draw_pile_position()
		draw_pile_view.set_slot_position(draw_pile_view.position)

func _render_table(state: GameState) -> void:
	var header: Control = layout.content("header")
	_add_label(header, "12 MOONS  •  JANUARY  •  WOLF MOON", Vector2(16, 4), Vector2(450, 26), 19, GOLD)
	var turn_text := "TURN: " + ("PLAYER" if state.current_player == 0 else "HOUSE")
	if state.phase == GameState.PHASE_SCORE_DECISION:
		turn_text = "SCORE DECISION: " + ("PLAYER" if state.current_player == 0 else "HOUSE")
	_add_label(header, turn_text, Vector2(510, 4), Vector2(250, 26), 18, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(header, "DRAW PILE  %02d" % state.deck.remaining_count(), Vector2(1010, 4), Vector2(214, 26), 17, MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

	var status: Control = layout.content("status")
	var status_text := _phase_instruction(state)
	if not ui_message.is_empty():
		status_text += "  •  " + ui_message
	_add_label(status, status_text, Vector2(8, 0), Vector2(664, 14), 10, ACCENT if _is_player_choice(state) else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_render_opponent_hand(layout.content("opponent_hand"), state)
	_render_capture_groups(layout.content("opponent_captures"), state.players[1].captured_ids, "HOUSE CAPTURES")
	_render_field(layout.content("field"), state)
	_render_draw_area(layout.content("draw"), state)
	_render_capture_groups(layout.content("player_captures"), state.players[0].captured_ids, "YOUR CAPTURES")
	_render_player_hand(layout.content("player_hand"), state)
	_render_scores(layout.content("scores"), state)

func _render_opponent_hand(parent: Control, state: GameState) -> void:
	_add_label(parent, "HOUSE HAND  •  %d CARDS" % state.players[1].hand_ids.size(), Vector2(10, 6), Vector2(600, 18), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _render_field(parent: Control, state: GameState) -> void:
	_add_label(parent, "FIELD  •  %d CARDS" % state.field_ids.size(), Vector2(12, 6), Vector2(582, 22), 14, TEXT, HORIZONTAL_ALIGNMENT_CENTER)

func _render_draw_area(parent: Control, state: GameState) -> void:
	_add_label(parent, "DRAW / RESOLUTION", Vector2(8, 5), Vector2(288, 20), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(parent, "%d left" % state.deck.remaining_count(), Vector2(26, 133), Vector2(82, 17), 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var resolution_label := "WAITING"
	if state.pending_card_source == "draw":
		resolution_label = "DRAW REVEAL"
	elif state.pending_card_source == "hand":
		resolution_label = "PLAYED"
	elif not last_draw_card_id.is_empty():
		resolution_label = "LAST DRAW"
	_add_label(parent, resolution_label, Vector2(188, 133), Vector2(98, 17), 11, ACCENT if state.pending_card_source == "draw" else MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _render_player_hand(parent: Control, state: GameState) -> void:
	var selectable := state.current_player == 0 and state.phase == GameState.PHASE_HAND_PLAY
	_add_label(parent, "YOUR HAND  •  %d CARDS" % state.players[0].hand_ids.size(), Vector2(8, 5), Vector2(590, 18), 13, ACCENT if selectable else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	if state.players[0].hand_ids.is_empty():
		_add_label(parent, "No cards remaining", Vector2(8, 64), Vector2(590, 24), 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _render_scores(parent: Control, state: GameState) -> void:
	_add_label(parent, "YAKU / SCORE", Vector2(8, 5), Vector2(288, 20), 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var player_score := YakuEvaluator.evaluate(state.players[0].captured_ids, catalog, state.moon_id)
	var house_score := YakuEvaluator.evaluate(state.players[1].captured_ids, catalog, state.moon_id)
	_render_score_panel(parent, "PLAYER", player_score, Vector2(8, 30), Color(0.15, 0.25, 0.33, 0.96))
	_render_score_panel(parent, "HOUSE", house_score, Vector2(158, 30), Color(0.13, 0.19, 0.25, 0.96))

func _render_score_panel(parent: Control, title: String, score: Dictionary, position_value: Vector2, color: Color) -> void:
	var panel := ColorRect.new()
	panel.color = color
	panel.position = position_value
	panel.size = Vector2(138, 170)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	_add_label(panel, title, Vector2(4, 5), Vector2(130, 18), 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(panel, "SCORE  %d" % int(score.get("additive_subtotal", 0)), Vector2(4, 24), Vector2(130, 22), 16, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var counts := "B %d   A %d\nR %d   C %d" % [int(score.get("bright_count", 0)), int(score.get("animal_count", 0)), int(score.get("ribbon_count", 0)), int(score.get("chaff_count", 0))]
	_add_label(panel, counts, Vector2(8, 49), Vector2(122, 32), 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var lines: Array = []
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		lines.append("%s  %d" % [entry.get("name", ""), int(entry.get("points", 0))])
	if lines.is_empty():
		lines.append("No yaku yet")
	_add_label(panel, "\n".join(lines), Vector2(7, 84), Vector2(124, 76), 9, TEXT, HORIZONTAL_ALIGNMENT_LEFT)

func _render_capture_groups(parent: Control, captured_ids: Array, title: String) -> void:
	_add_label(parent, title, Vector2(8, 5), Vector2(270, 18), 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var grouped: Dictionary = _group_captured(captured_ids)
	var classes := ["bright", "animal", "ribbon", "chaff"]
	var labels := ["BRIGHT", "ANIMAL / SEED", "RIBBON", "CHAFF"]
	for class_index in range(classes.size()):
		var group_name: String = String(classes[class_index])
		var ids: Array = grouped[group_name]
		var row_y := 29.0 + class_index * 51.0
		_add_label(parent, labels[class_index], Vector2(7, row_y + 17), Vector2(54, 18), 8, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		if ids.is_empty():
			_add_label(parent, "—", Vector2(66, row_y + 17), Vector2(20, 18), 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _render_starter_ceremony(state: GameState) -> void:
	var background := ColorRect.new()
	background.color = Color(0.045, 0.075, 0.11)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ceremony_layer.add_child(background)
	_add_label(ceremony_layer, "12 MOONS  •  JANUARY", Vector2(0, 72), Vector2(1280, 30), 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(ceremony_layer, "STARTING PLAYER", Vector2(0, 112), Vector2(1280, 46), 34, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var instruction := "Choose one face-down card. The earlier revealed month opens January."
	if state.phase == GameState.PHASE_STARTER_AI_REVEAL:
		instruction = "Your card is revealed. The house is choosing its card."
	elif state.phase == GameState.PHASE_STARTER_RESULT:
		instruction = String(state.last_event.get("message", "The starting player is decided."))
	_add_label(ceremony_layer, instruction, Vector2(150, 172), Vector2(980, 34), 17, ACCENT if state.phase == GameState.PHASE_STARTER_PLAYER_SELECT else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(ceremony_layer, "The three ceremony cards return to the 48-card deck before the legal 8 / 8 / 8 deal.", Vector2(0, 628), Vector2(1280, 26), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _render_score_decision(score: Dictionary) -> void:
	var dimmer := ColorRect.new()
	# Keep the table readable and spatially stable. The decision is a tray over
	# the lower edge, not a full-screen modal that hides the causal board state.
	dimmer.color = Color(0.015, 0.025, 0.04, 0.10)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(dimmer)
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.20, 0.27)
	panel.position = Vector2(280, 484)
	panel.size = Vector2(720, 190)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.add_child(panel)
	_add_label(panel, "YAKU IMPROVED  •  CHOOSE HOW TO CLOSE THIS HAND", Vector2(0, 14), Vector2(720, 30), 22, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var current := "Current score: %d\n" % int(score.get("additive_subtotal", 0))
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		current += "%s  +%d\n" % [entry.get("name", ""), int(entry.get("points", 0))]
	_add_label(panel, current, Vector2(32, 52), Vector2(300, 86), 14, TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(panel, "STOP banks the current score. KOI-KOI keeps January alive for a higher score.", Vector2(350, 56), Vector2(334, 50), 13, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	var stop := Button.new()
	stop.text = "STOP"
	stop.position = Vector2(350, 118)
	stop.size = Vector2(148, 48)
	stop.add_theme_font_size_override("font_size", 20)
	stop.focus_mode = Control.FOCUS_ALL
	stop.mouse_filter = Control.MOUSE_FILTER_STOP
	stop.pressed.connect(_on_stop_pressed)
	panel.add_child(stop)
	var koi := Button.new()
	koi.text = "KOI-KOI"
	koi.position = Vector2(520, 118)
	koi.size = Vector2(148, 48)
	koi.add_theme_font_size_override("font_size", 20)
	koi.focus_mode = Control.FOCUS_ALL
	koi.mouse_filter = Control.MOUSE_FILTER_STOP
	koi.pressed.connect(_on_koi_koi_pressed)
	panel.add_child(koi)
	stop.call_deferred("grab_focus")

func _on_stop_pressed() -> void:
	_submit_human(GameAction.new(GameAction.STOP, 0))

func _on_koi_koi_pressed() -> void:
	_submit_human(GameAction.new(GameAction.KOI_KOI, 0))

func _on_card_clicked(card_id: String) -> void:
	if controller == null or presentation_busy or controller.state.current_player != 0:
		return
	var state := controller.state
	if state.phase == GameState.PHASE_STARTER_PLAYER_SELECT and state.starter_card_ids.has(card_id):
		_submit_human(GameAction.new(GameAction.SELECT_STARTER, 0, card_id, ""))
	elif state.phase == GameState.PHASE_HAND_PLAY and state.players[0].hand_ids.has(card_id):
		_submit_human(GameAction.new(GameAction.PLAY_CARD, 0, card_id, ""))
	elif (state.phase == GameState.PHASE_HAND_MATCH_CHOICE or state.phase == GameState.PHASE_DRAW_MATCH_CHOICE) and state.pending_match_ids.has(card_id):
		_submit_human(GameAction.new(GameAction.CHOOSE_MATCH, 0, state.pending_card_id, card_id))

func _on_card_hover_changed(card: MoonCardView, entered: bool) -> void:
	if presentation_busy or card == null or not card.selectable:
		return
	motion.hover(card, entered)

func _lock_input() -> void:
	for card_variant in card_registry.values():
		var card: MoonCardView = card_variant
		if card != null and is_instance_valid(card):
			card.set_selectable(false)
	for button in _find_buttons(overlay_layer):
		button.disabled = true

func _apply_card_targets(state: GameState, immediate: bool) -> void:
	var targets := _card_targets(state)
	for card_id_variant in targets.keys():
		var card_id := String(card_id_variant)
		var target_info: Dictionary = targets[card_id]
		var card := _ensure_card(card_id, bool(target_info["face_up"]))
		if card == null:
			continue
		card.visible = true
		card.set_display(target_info["size"], target_info["face_up"], target_info["selectable"], target_info["highlighted"])
		card.resting_z_index = int(target_info["z_index"])
		card.z_index = card.resting_z_index
		card.set_slot_position(target_info["position"])
		if immediate:
			card.position = target_info["position"]
			card.scale = Vector2.ONE
			card.rotation = 0.0
	for card_variant in card_registry.values():
		var card: MoonCardView = card_variant
		if card == null or not is_instance_valid(card):
			continue
		if not targets.has(card.card_id):
			card.visible = false
			card.set_selectable(false)
	if draw_pile_view != null:
		draw_pile_view.visible = not _is_ceremony_phase(state)
		draw_pile_view.position = _draw_pile_position()
		draw_pile_view.set_slot_position(draw_pile_view.position)

func _set_choice_visuals(state: GameState) -> void:
	for raw_id in state.pending_match_ids:
		var card := _card_from_registry(String(raw_id))
		if card != null:
			card.set_highlighted(true)
			card.z_index = 90

func _card_targets(state: GameState) -> Dictionary:
	var result: Dictionary = {}
	if _is_ceremony_phase(state):
		for index in range(state.starter_card_ids.size()):
			var card_id := String(state.starter_card_ids[index])
			_add_target(result, card_id, _ceremony_position(index), Vector2(132, 188), state.starter_revealed_ids.has(card_id), state.phase == GameState.PHASE_STARTER_PLAYER_SELECT and state.current_player == 0, state.phase == GameState.PHASE_STARTER_PLAYER_SELECT and state.current_player == 0, 70 + index)
		return result

	var field_geometry := _field_geometry(state.field_ids.size())
	for index in range(state.field_ids.size()):
		var card_id := String(state.field_ids[index])
		var row: int = field_geometry["rows"][index]
		var column: int = field_geometry["columns"][index]
		var position := TABLE_LAYOUT_SCRIPT.REGION_RECTS["field"].position + Vector2(float(field_geometry["origin_x"]) + column * (field_geometry["card_size"].x + field_geometry["gap"]), 36.0 + row * (field_geometry["card_size"].y + field_geometry["gap"]))
		var selectable := state.current_player == 0 and (state.phase == GameState.PHASE_HAND_MATCH_CHOICE or state.phase == GameState.PHASE_DRAW_MATCH_CHOICE) and state.pending_match_ids.has(card_id)
		_add_target(result, card_id, position, field_geometry["card_size"], true, selectable, selectable, 35)

	var capture_positions := _capture_positions(state)
	for card_id_variant in capture_positions.keys():
		var card_id := String(card_id_variant)
		_add_target(result, card_id, capture_positions[card_id], Vector2(42, 56), true, false, false, 20)

	var player_hand := _hand_positions(state.players[0].hand_ids.size(), "player_hand", Vector2(66, 100), 31.0)
	for index in range(state.players[0].hand_ids.size()):
		var card_id := String(state.players[0].hand_ids[index])
		_add_target(result, card_id, player_hand[index], Vector2(66, 100), true, state.current_player == 0 and state.phase == GameState.PHASE_HAND_PLAY, false, 50 + index)

	var opponent_hand := _hand_positions(state.players[1].hand_ids.size(), "opponent_hand", Vector2(66, 94), 25.0)
	for index in range(state.players[1].hand_ids.size()):
		var card_id := String(state.players[1].hand_ids[index])
		_add_target(result, card_id, opponent_hand[index], Vector2(66, 94), false, false, false, 50 + index)

	if not state.pending_card_id.is_empty() and not result.has(state.pending_card_id):
		_add_target(result, state.pending_card_id, _draw_resolution_position(), Vector2(70, 102), true, false, state.pending_card_source == "draw", 140)
	return result

func _add_target(targets: Dictionary, card_id: String, position: Vector2, size: Vector2, face_up: bool, selectable: bool, highlighted: bool, z_index: int) -> void:
	if card_id.is_empty() or targets.has(card_id):
		return
	targets[card_id] = {"position": position, "size": size, "face_up": face_up, "selectable": selectable, "highlighted": highlighted, "z_index": z_index}

func _field_geometry(count: int) -> Dictionary:
	var card_size := Vector2(84, 114)
	var columns := 4
	if count > 10:
		columns = 5
		card_size = Vector2(76, 100)
	if count > 15:
		columns = 6
		card_size = Vector2(68, 92)
	var gap := 8.0
	if count > 18:
		columns = 8
		card_size = Vector2(56, 66)
	if count > 32:
		card_size = Vector2(48, 58)
		gap = 4.0
	var origin_x := (606.0 - (columns * card_size.x + (columns - 1) * gap)) * 0.5
	var rows: Array = []
	var column_values: Array = []
	for index in range(count):
		rows.append(int(index / columns))
		column_values.append(index % columns)
	return {"card_size": card_size, "columns": column_values, "rows": rows, "origin_x": origin_x, "gap": gap}

func _hand_positions(count: int, region_name: String, card_size: Vector2, y: float) -> Array:
	var result: Array = []
	if count <= 0:
		return result
	var spacing := minf(72.0 if region_name == "player_hand" else 70.0, 590.0 / float(count))
	var total_width := (count - 1) * spacing + card_size.x
	var origin_x := (606.0 - total_width) * 0.5
	var region_origin: Vector2 = TABLE_LAYOUT_SCRIPT.REGION_RECTS[region_name].position
	for index in range(count):
		result.append(region_origin + Vector2(origin_x + index * spacing, y))
	return result

func _capture_positions(state: GameState) -> Dictionary:
	var result: Dictionary = {}
	for actor_id in range(2):
		var grouped: Dictionary = _group_captured(state.players[actor_id].captured_ids)
		var region_origin: Vector2 = TABLE_LAYOUT_SCRIPT.REGION_RECTS[CAPTURE_REGIONS[actor_id]].position
		for class_index in range(4):
			var group_name: String = ["bright", "animal", "ribbon", "chaff"][class_index]
			var ids: Array = grouped[group_name]
			var card_size := Vector2(42, 56)
			var available_width := 211.0
			var offset := card_size.x + 5.0
			if ids.size() > 1:
				offset = minf(offset, (available_width - card_size.x) / float(ids.size() - 1))
			var row_y := 29.0 + class_index * 51.0
			for card_index in range(ids.size()):
				result[String(ids[card_index])] = region_origin + Vector2(66.0 + card_index * offset, row_y)
	return result

func _group_captured(captured_ids: Array) -> Dictionary:
	var grouped: Dictionary = {"bright": [], "animal": [], "ribbon": [], "chaff": []}
	for raw_id in captured_ids:
		var definition := catalog.get_card(String(raw_id))
		if definition != null and grouped.has(definition.base_class):
			grouped[definition.base_class].append(String(raw_id))
	return grouped

func _opening_deal_order(state: GameState) -> Array:
	var result: Array = []
	var seen: Dictionary = {}
	var arrays := [state.players[0].hand_ids, state.players[1].hand_ids, state.field_ids]
	var maximum := 0
	for values in arrays:
		maximum = maxi(maximum, values.size())
	for index in range(maximum):
		for values in arrays:
			if index >= values.size():
				continue
			var card_id := String(values[index])
			if not seen.has(card_id):
				seen[card_id] = true
				result.append(card_id)
	for player_state in state.players:
		for raw_id in player_state.captured_ids:
			var card_id := String(raw_id)
			if not seen.has(card_id):
				seen[card_id] = true
				result.append(card_id)
	return result

func _ensure_card(card_id: String, face_up: bool) -> MoonCardView:
	if card_id.is_empty() or catalog.get_card(card_id) == null:
		return null
	var card: MoonCardView = card_registry.get(card_id)
	if card == null or not is_instance_valid(card):
		card = MoonCardView.new()
		card.name = "Card_%s" % card_id
		card_layer.add_child(card)
		card.card_clicked.connect(_on_card_clicked)
		card.hover_changed.connect(_on_card_hover_changed)
		card_registry[card_id] = card
		card.configure(catalog.get_card(card_id), face_up, false, false, Vector2(66, 100))
	return card

func _card_from_registry(card_id: String) -> MoonCardView:
	var card: MoonCardView = card_registry.get(card_id)
	if card == null or not is_instance_valid(card):
		return null
	return card

func _draw_pile_position() -> Vector2:
	return TABLE_LAYOUT_SCRIPT.REGION_RECTS["draw"].position + Vector2(32, 32)

func _draw_resolution_position() -> Vector2:
	return TABLE_LAYOUT_SCRIPT.REGION_RECTS["draw"].position + Vector2(202, 32)

func _play_resolution_position() -> Vector2:
	return Vector2(620, 346)

func _ceremony_position(index: int) -> Vector2:
	return Vector2(430 + index * 160, 242)

func _draw_card_id(state: GameState) -> String:
	if state.pending_card_source == "draw" and not state.pending_card_id.is_empty():
		return state.pending_card_id
	if String(state.last_event.get("source", "")) == "draw":
		return String(state.last_event.get("card_id", ""))
	return String(state.last_event.get("draw_card_id", ""))

func _draw_captured_ids(state: GameState) -> Array:
	if state.last_event.has("draw_captured_ids"):
		return Array(state.last_event.get("draw_captured_ids", [])).duplicate()
	if String(state.last_event.get("source", "")) == "draw":
		return Array(state.last_event.get("captured_ids", [])).duplicate()
	return []

func _remember_draw_card(state: GameState) -> void:
	var draw_id := _draw_card_id(state)
	if not draw_id.is_empty():
		last_draw_card_id = draw_id

func _describe_action(action: GameAction, result: ActionResult, actor_name: String, after: GameState) -> String:
	match action.action_type:
		GameAction.SELECT_STARTER:
			return "%s revealed %s." % [actor_name, _card_name(action.card_id)]
		GameAction.PLAY_CARD:
			var message := "%s played %s." % [actor_name, _card_name(action.card_id)]
			if not result.captured_ids.is_empty():
				message += " Captured %d card%s." % [result.captured_ids.size(), "s" if result.captured_ids.size() != 1 else ""]
			var draw_id := _draw_card_id(after)
			if not draw_id.is_empty():
				message += " Draw: %s." % _card_name(draw_id)
			return message
		GameAction.CHOOSE_MATCH:
			return "%s matched %s with %s." % [actor_name, _card_name(action.card_id), _card_name(action.target_card_id)]
		GameAction.STOP:
			return "%s chose STOP." % actor_name
		GameAction.KOI_KOI:
			return "%s declared KOI-KOI. The month continues." % actor_name
	return String(after.last_event.get("message", "Action resolved."))

func _card_name(card_id: String) -> String:
	var definition := catalog.get_card(card_id)
	return definition.display_name if definition != null else card_id

func _phase_instruction(state: GameState) -> String:
	if state.phase == GameState.PHASE_HAND_MATCH_CHOICE or state.phase == GameState.PHASE_DRAW_MATCH_CHOICE:
		return "SELECT A HIGHLIGHTED MATCHING FIELD CARD"
	if state.phase == GameState.PHASE_DRAW_REVEAL:
		return "DRAW REVEALED  •  WATCH THE RESOLUTION SLOT"
	if state.phase == GameState.PHASE_SCORE_DECISION:
		return "STOP / KOI-KOI DECISION"
	if state.current_player == 0:
		return "YOUR TURN  •  SELECT A HIGHLIGHTED HAND CARD"
	return "HOUSE TURN  •  WATCH THE PLAY AND DRAW RESOLVE"

func _is_player_choice(state: GameState) -> bool:
	return state.current_player == 0 and state.phase != GameState.PHASE_MONTH_COMPLETE

func _is_ceremony_phase(state: GameState) -> bool:
	return state.phase == GameState.PHASE_STARTER_PLAYER_SELECT or state.phase == GameState.PHASE_STARTER_AI_REVEAL or state.phase == GameState.PHASE_STARTER_RESULT

func _copy_state(state: GameState) -> GameState:
	return GameState.from_dict(state.to_dict())

func _emit_month_finished() -> void:
	if result_sent or controller == null or controller.state.phase != GameState.PHASE_MONTH_COMPLETE:
		return
	result_sent = true
	var payload := controller.state.terminal_result.duplicate(true)
	payload["match_result"] = MatchResult.from_game_state(controller.state).to_dict()
	month_finished.emit(payload)

func _cancel_presentation() -> void:
	_presentation_generation += 1
	if presentation_queue != null:
		presentation_queue.cancel()
	if motion != null:
		motion.cancel_all()
	presentation_busy = false

func _clear_card_registry() -> void:
	for card_variant in card_registry.values():
		var card: MoonCardView = card_variant
		if card != null and is_instance_valid(card):
			card.queue_free()
	card_registry.clear()

func _find_buttons(node: Node) -> Array:
	var result: Array = []
	if node == null:
		return result
	for child in node.get_children():
		if child is Button:
			result.append(child)
		result.append_array(_find_buttons(child))
	return result

func _clear(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.free()

func _add_label(parent: Node, value: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
