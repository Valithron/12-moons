extends Control

signal month_finished(result: Dictionary)

const GOLD := Color(0.95, 0.84, 0.56)
const TEXT := Color(0.91, 0.93, 0.90)
const MUTED := Color(0.63, 0.71, 0.76)
const ACCENT := Color(1.0, 0.82, 0.22)
const TABLE_LAYOUT_SCRIPT := preload("res://scripts/ui/table_layout.gd")

var controller: MatchController
var catalog: CardCatalog
var table_layer: Control
var overlay_layer: Control
var ceremony_layer: Control
var layout
var last_rendered_hash: String = ""
var ai_cooldown: float = 0.8
var result_sent: bool = false
var ui_message: String = ""
var last_draw_card_id: String = ""

func _ready() -> void:
	catalog = CardCatalog.new()
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

	overlay_layer = Control.new()
	overlay_layer.name = "ModalOverlay"
	overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.z_index = 100
	add_child(overlay_layer)

func configure(match_controller: MatchController) -> void:
	controller = match_controller
	catalog = controller.catalog
	last_rendered_hash = ""
	result_sent = false
	ai_cooldown = 0.8
	ui_message = ""
	last_draw_card_id = ""

func _process(delta: float) -> void:
	if controller == null:
		return
	if controller.state.phase == GameState.PHASE_MONTH_COMPLETE:
		if not result_sent:
			_render()
			result_sent = true
			month_finished.emit(controller.state.terminal_result.duplicate(true))
		return

	var phase := controller.state.phase
	if phase == GameState.PHASE_STARTER_AI_REVEAL or phase == GameState.PHASE_STARTER_RESULT:
		ai_cooldown -= delta
		if ai_cooldown <= 0.0:
			if controller.advance_automatic():
				ui_message = String(controller.state.last_event.get("message", ""))
				ai_cooldown = 1.0 if phase == GameState.PHASE_STARTER_AI_REVEAL else 0.45
			else:
				ai_cooldown = 0.25
	elif controller.state.current_player == 1:
		ai_cooldown -= delta
		if ai_cooldown <= 0.0:
			_drive_ai()
			ai_cooldown = 0.95
	else:
		ai_cooldown = minf(ai_cooldown, 0.1)

	var current_hash := controller.state.state_hash()
	if current_hash != last_rendered_hash:
		_render()

func _drive_ai() -> void:
	var view := PublicStateView.for_actor(controller.state, 1, catalog)
	var actions := controller.legal_actions(1)
	var action := SimpleAI.choose_action(view, actions, catalog)
	if action == null:
		ui_message = "House has no legal action."
		return
	var result := controller.submit_action(action)
	if result.accepted:
		_remember_draw_card()
		ui_message = _describe_action(action, result, "House")
	else:
		ui_message = "House action rejected: %s" % result.reason

func _render() -> void:
	_clear(overlay_layer)
	_clear(ceremony_layer)
	for region_name in TABLE_LAYOUT_SCRIPT.REGION_RECTS.keys():
		_clear(layout.content(String(region_name)))
	last_rendered_hash = controller.state.state_hash()
	if ui_message.is_empty():
		ui_message = String(controller.state.last_event.get("message", ""))

	var state := controller.state
	if state.phase == GameState.PHASE_STARTER_PLAYER_SELECT or state.phase == GameState.PHASE_STARTER_AI_REVEAL or state.phase == GameState.PHASE_STARTER_RESULT:
		layout.root.visible = false
		ceremony_layer.visible = true
		_render_starter_ceremony(state)
		return

	layout.root.visible = true
	ceremony_layer.visible = false
	_render_table(state)
	if state.phase == GameState.PHASE_SCORE_DECISION and state.current_player == 0:
		var player_score := YakuEvaluator.evaluate(state.players[0].captured_ids, catalog, state.moon_id)
		_render_score_decision(player_score)

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
	var card_size := Vector2(66, 94)
	var spacing := 70.0
	var total_width := maxf(0.0, (state.players[1].hand_ids.size() - 1) * spacing + card_size.x)
	var origin_x := (620.0 - total_width) * 0.5
	for index in range(state.players[1].hand_ids.size()):
		var back := MoonCardView.new()
		back.position = Vector2(origin_x + index * spacing, 25)
		parent.add_child(back)
		back.configure(null, false, false, false, card_size)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _render_field(parent: Control, state: GameState) -> void:
	_add_label(parent, "FIELD  •  %d CARDS" % state.field_ids.size(), Vector2(12, 6), Vector2(582, 22), 14, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var card_size := Vector2(84, 114)
	var columns := 4
	if state.field_ids.size() > 10:
		columns = 5
		card_size = Vector2(76, 100)
	if state.field_ids.size() > 15:
		columns = 6
		card_size = Vector2(68, 92)
	var gap := 8.0
	if state.field_ids.size() > 18:
		columns = 8
		card_size = Vector2(56, 66)
	if state.field_ids.size() > 32:
		card_size = Vector2(48, 58)
		gap = 4.0
	var total_width := columns * card_size.x + (columns - 1) * gap
	var origin_x := (606.0 - total_width) * 0.5
	for index in range(state.field_ids.size()):
		var field_id := String(state.field_ids[index])
		var row := int(index / columns)
		var column := index % columns
		var selectable := state.current_player == 0 and (state.phase == GameState.PHASE_HAND_MATCH_CHOICE or state.phase == GameState.PHASE_DRAW_MATCH_CHOICE) and state.pending_match_ids.has(field_id)
		var field_card := _add_card(parent, field_id, Vector2(origin_x + column * (card_size.x + gap), 36 + row * (card_size.y + gap)), card_size, true, selectable, selectable)
		if field_card != null:
			field_card.z_index = 2

func _render_draw_area(parent: Control, state: GameState) -> void:
	_add_label(parent, "DRAW / RESOLUTION", Vector2(8, 5), Vector2(288, 20), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var pile := MoonCardView.new()
	pile.position = Vector2(32, 32)
	parent.add_child(pile)
	pile.configure(null, false, false, false, Vector2(70, 102))
	pile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_label(parent, "%d left" % state.deck.remaining_count(), Vector2(26, 133), Vector2(82, 17), 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	var resolution_id := state.pending_card_id
	var resolution_label := "RESOLVING"
	if resolution_id.is_empty():
		resolution_id = last_draw_card_id
		resolution_label = "LAST DRAW" if not resolution_id.is_empty() else "WAITING"
	elif state.pending_card_source == "hand":
		resolution_label = "PLAYED"
	if not resolution_id.is_empty():
		_add_card(parent, resolution_id, Vector2(202, 32), Vector2(70, 102), true, false, state.pending_card_source == "draw")
	_add_label(parent, resolution_label, Vector2(188, 133), Vector2(98, 17), 11, ACCENT if state.pending_card_source == "draw" else MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _render_player_hand(parent: Control, state: GameState) -> void:
	var selectable := state.current_player == 0 and state.phase == GameState.PHASE_HAND_PLAY
	var count: int = state.players[0].hand_ids.size()
	_add_label(parent, "YOUR HAND  •  %d CARDS" % count, Vector2(8, 5), Vector2(590, 18), 13, ACCENT if selectable else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	if count == 0:
		_add_label(parent, "No cards remaining", Vector2(8, 64), Vector2(590, 24), 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var card_size := Vector2(66, 100)
	var spacing := minf(72.0, 590.0 / float(count))
	var total_width: float = (count - 1) * spacing + card_size.x
	var origin_x: float = (606.0 - total_width) * 0.5
	for index in range(count):
		var hand_id := String(state.players[0].hand_ids[index])
		_add_card(parent, hand_id, Vector2(origin_x + index * spacing, 31), card_size, true, selectable, false)

func _render_scores(parent: Control, state: GameState) -> void:
	_add_label(parent, "YAKU / SCORE", Vector2(8, 5), Vector2(288, 20), 13, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var player_score := YakuEvaluator.evaluate(state.players[0].captured_ids, catalog, state.moon_id)
	var house_score := YakuEvaluator.evaluate(state.players[1].captured_ids, catalog, state.moon_id)
	_render_score_panel(parent, "PLAYER", player_score, Vector2(8, 30), Color(0.15, 0.25, 0.33, 0.96))
	_render_score_panel(parent, "HOUSE", house_score, Vector2(158, 30), Color(0.13, 0.19, 0.25, 0.96))

func _render_score_panel(parent: Control, title: String, score: Dictionary, position_value: Vector2, color: Color) -> void:
	var panel := ColorRect.new()
	panel.position = position_value
	panel.size = Vector2(138, 170)
	panel.color = color
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
	var grouped: Dictionary = {"bright": [], "animal": [], "ribbon": [], "chaff": []}
	for raw_id in captured_ids:
		var card_id := String(raw_id)
		var definition := catalog.get_card(card_id)
		if definition != null and grouped.has(definition.base_class):
			grouped[definition.base_class].append(card_id)
	var classes := ["bright", "animal", "ribbon", "chaff"]
	var labels := ["BRIGHT", "ANIMAL / SEED", "RIBBON", "CHAFF"]
	for class_index in range(classes.size()):
		var group_name: String = String(classes[class_index])
		var ids: Array = grouped[group_name]
		var row_y := 29.0 + class_index * 51.0
		_add_label(parent, labels[class_index], Vector2(7, row_y + 17), Vector2(54, 18), 8, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		if ids.is_empty():
			_add_label(parent, "—", Vector2(66, row_y + 17), Vector2(20, 18), 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
			continue
		var card_size := Vector2(42, 56)
		var available_width := 211.0
		var offset := card_size.x + 5.0
		if ids.size() > 1:
			offset = minf(offset, (available_width - card_size.x) / float(ids.size() - 1))
		for card_index in range(ids.size()):
			var spread_card := _add_card(parent, ids[card_index], Vector2(66 + card_index * offset, row_y), card_size, true, false, false)
			if spread_card != null:
				spread_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	var card_size := Vector2(132, 188)
	var start_x := 430.0
	for index in range(state.starter_card_ids.size()):
		var card_id := String(state.starter_card_ids[index])
		var revealed := state.starter_revealed_ids.has(card_id)
		var selectable := state.phase == GameState.PHASE_STARTER_PLAYER_SELECT and state.current_player == 0
		_add_card(ceremony_layer, card_id, Vector2(start_x + index * 160, 242), card_size, revealed, selectable, selectable)
		if revealed:
			var definition := catalog.get_card(card_id)
			if definition != null:
				_add_label(ceremony_layer, definition.display_name, Vector2(start_x - 15 + index * 160, 438), Vector2(162, 30), 13, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(ceremony_layer, "The three ceremony cards return to the 48-card deck before the legal 8 / 8 / 8 deal.", Vector2(0, 628), Vector2(1280, 26), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)

func _render_score_decision(score: Dictionary) -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.015, 0.025, 0.04, 0.82)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.add_child(dimmer)
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.20, 0.27)
	panel.position = Vector2(320, 150)
	panel.size = Vector2(640, 390)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.add_child(panel)
	_add_label(panel, "YAKU IMPROVED", Vector2(0, 22), Vector2(640, 36), 28, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(panel, "Choose how to close this hand", Vector2(0, 60), Vector2(640, 24), 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var current := "Current score: %d\n" % int(score.get("additive_subtotal", 0))
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		current += "%s  +%d\n" % [entry.get("name", ""), int(entry.get("points", 0))]
	_add_label(panel, current, Vector2(44, 98), Vector2(552, 122), 16, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(panel, "STOP banks the current score. KOI-KOI keeps January alive for a higher score.", Vector2(48, 225), Vector2(544, 44), 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var stop := Button.new()
	stop.text = "STOP"
	stop.position = Vector2(78, 302)
	stop.size = Vector2(210, 54)
	stop.add_theme_font_size_override("font_size", 20)
	stop.mouse_filter = Control.MOUSE_FILTER_STOP
	stop.pressed.connect(_on_stop_pressed)
	panel.add_child(stop)
	var koi := Button.new()
	koi.text = "KOI-KOI"
	koi.position = Vector2(352, 302)
	koi.size = Vector2(210, 54)
	koi.add_theme_font_size_override("font_size", 20)
	koi.mouse_filter = Control.MOUSE_FILTER_STOP
	koi.pressed.connect(_on_koi_koi_pressed)
	panel.add_child(koi)

func _on_stop_pressed() -> void:
	_submit_human(GameAction.new(GameAction.STOP, 0))

func _on_koi_koi_pressed() -> void:
	_submit_human(GameAction.new(GameAction.KOI_KOI, 0))

func _on_card_clicked(card_id: String) -> void:
	if controller == null or controller.state.current_player != 0:
		return
	var state := controller.state
	if state.phase == GameState.PHASE_STARTER_PLAYER_SELECT and state.starter_card_ids.has(card_id):
		_submit_human(GameAction.new(GameAction.SELECT_STARTER, 0, card_id, ""))
	elif state.phase == GameState.PHASE_HAND_PLAY and state.players[0].hand_ids.has(card_id):
		_submit_human(GameAction.new(GameAction.PLAY_CARD, 0, card_id, ""))
	elif (state.phase == GameState.PHASE_HAND_MATCH_CHOICE or state.phase == GameState.PHASE_DRAW_MATCH_CHOICE) and state.pending_match_ids.has(card_id):
		_submit_human(GameAction.new(GameAction.CHOOSE_MATCH, 0, state.pending_card_id, card_id))

func _submit_human(action: GameAction) -> void:
	var result := controller.submit_action(action)
	if not result.accepted:
		ui_message = result.reason
		last_rendered_hash = ""
		return
	_remember_draw_card()
	ui_message = _describe_action(action, result, "You")
	ai_cooldown = 1.0
	last_rendered_hash = ""

func _describe_action(action: GameAction, result: ActionResult, actor_name: String) -> String:
	match action.action_type:
		GameAction.SELECT_STARTER:
			return "%s revealed %s." % [actor_name, _card_name(action.card_id)]
		GameAction.PLAY_CARD:
			var message := "%s played %s." % [actor_name, _card_name(action.card_id)]
			if not result.captured_ids.is_empty():
				message += " Captured %d card%s." % [result.captured_ids.size(), "s" if result.captured_ids.size() != 1 else ""]
			if not last_draw_card_id.is_empty():
				message += " Draw: %s." % _card_name(last_draw_card_id)
			return message
		GameAction.CHOOSE_MATCH:
			return "%s matched %s with %s." % [actor_name, _card_name(action.card_id), _card_name(action.target_card_id)]
		GameAction.STOP:
			return "%s chose STOP." % actor_name
		GameAction.KOI_KOI:
			return "%s declared KOI-KOI. The month continues." % actor_name
	return String(controller.state.last_event.get("message", "Action resolved."))

func _remember_draw_card() -> void:
	var event := controller.state.last_event
	if String(event.get("source", "")) == "draw":
		last_draw_card_id = String(event.get("card_id", ""))
	elif not String(event.get("draw_card_id", "")).is_empty():
		last_draw_card_id = String(event.get("draw_card_id", ""))

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

func _add_card(parent: Node, card_id: String, position_value: Vector2, requested_size: Vector2, face_up: bool, selectable: bool, highlighted: bool) -> MoonCardView:
	var definition := catalog.get_card(card_id)
	if definition == null:
		return null
	var card := MoonCardView.new()
	card.position = position_value
	parent.add_child(card)
	card.configure(definition, face_up, selectable, highlighted, requested_size)
	card.card_clicked.connect(_on_card_clicked)
	return card

func _clear(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
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
