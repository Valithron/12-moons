extends Control

signal month_finished(result: Dictionary)

var controller: MatchController
var catalog: CardCatalog
var table_layer: Control
var overlay_layer: Control
var last_rendered_hash: String = ""
var ai_cooldown: float = 0.35
var result_sent: bool = false
var ui_message: String = ""

func _ready() -> void:
	catalog = CardCatalog.new()
	table_layer = Control.new()
	table_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(table_layer)
	overlay_layer = Control.new()
	overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay_layer)

func configure(match_controller: MatchController) -> void:
	controller = match_controller
	catalog = controller.catalog
	last_rendered_hash = ""

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
				ai_cooldown = 0.95 if phase == GameState.PHASE_STARTER_AI_REVEAL else 0.1
			else:
				ai_cooldown = 0.25
	elif controller.state.current_player == 1:
		ai_cooldown -= delta
		if ai_cooldown <= 0.0:
			_drive_ai()
			ai_cooldown = 0.45
	else:
		ai_cooldown = min(ai_cooldown, 0.1)

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
	if not result.accepted:
		ui_message = "House action rejected: %s" % result.reason

func _render() -> void:
	_clear(table_layer)
	_clear(overlay_layer)
	var state := controller.state
	last_rendered_hash = state.state_hash()
	if ui_message.is_empty():
		ui_message = String(state.last_event.get("message", ""))

	if state.phase == GameState.PHASE_STARTER_PLAYER_SELECT or state.phase == GameState.PHASE_STARTER_AI_REVEAL or state.phase == GameState.PHASE_STARTER_RESULT:
		_render_starter_ceremony(state)
		return

	var background := ColorRect.new()
	background.color = Color(0.08, 0.13, 0.19)
	background.size = Vector2(960, 540)
	table_layer.add_child(background)

	_add_label(table_layer, "12 MOONS  •  JANUARY  •  WOLF MOON", Vector2(18, 8), Vector2(470, 30), 18, Color(0.95, 0.84, 0.56))
	var turn_text := "TURN: " + ("PLAYER" if state.current_player == 0 else "HOUSE")
	if state.phase == GameState.PHASE_SCORE_DECISION:
		turn_text = "SCORE DECISION: " + ("PLAYER" if state.current_player == 0 else "HOUSE")
	_add_label(table_layer, turn_text, Vector2(500, 8), Vector2(230, 30), 18, Color(0.95, 0.94, 0.86))
	_add_label(table_layer, "DRAW PILE: %d" % state.deck.remaining_count(), Vector2(748, 8), Vector2(195, 30), 17, Color(0.70, 0.78, 0.84), HORIZONTAL_ALIGNMENT_RIGHT)

	_add_label(table_layer, ui_message, Vector2(240, 42), Vector2(500, 28), 15, Color(0.78, 0.82, 0.83), HORIZONTAL_ALIGNMENT_CENTER)

	var player_score := YakuEvaluator.evaluate(state.players[0].captured_ids, catalog, state.moon_id)
	var house_score := YakuEvaluator.evaluate(state.players[1].captured_ids, catalog, state.moon_id)
	_render_score_panel("PLAYER", player_score, Vector2(758, 52), Color(0.20, 0.31, 0.42))
	_render_score_panel("HOUSE", house_score, Vector2(758, 232), Color(0.20, 0.25, 0.31))

	_add_label(table_layer, "HOUSE HAND", Vector2(250, 48), Vector2(460, 22), 12, Color(0.58, 0.66, 0.71), HORIZONTAL_ALIGNMENT_CENTER)
	for index in range(state.players[1].hand_ids.size()):
		var back := MoonCardView.new()
		back.position = Vector2(270 + index * 48, 70)
		table_layer.add_child(back)
		back.configure(null, false, false, false, Vector2(46, 70))

	_render_capture_groups(table_layer, state.players[1].captured_ids, Vector2(18, 102), "HOUSE CAPTURES")

	_add_label(table_layer, "FIELD", Vector2(342, 154), Vector2(268, 22), 12, Color(0.58, 0.66, 0.71), HORIZONTAL_ALIGNMENT_CENTER)
	for index in range(state.field_ids.size()):
		var field_id := String(state.field_ids[index])
		var selectable := state.current_player == 0 and (state.phase == GameState.PHASE_HAND_MATCH_CHOICE or state.phase == GameState.PHASE_DRAW_MATCH_CHOICE) and state.pending_match_ids.has(field_id)
		var field_card := _add_card(table_layer, field_id, Vector2(340 + (index % 4) * 66, 180 + int(index / 4) * 96), Vector2(60, 90), true, selectable, selectable)
		if field_card != null:
			field_card.z_index = 2

	var draw_pile := MoonCardView.new()
	draw_pile.position = Vector2(258, 236)
	table_layer.add_child(draw_pile)
	draw_pile.configure(null, false, false, false, Vector2(62, 94))
	_add_label(table_layer, "DRAW", Vector2(255, 333), Vector2(68, 20), 12, Color(0.70, 0.78, 0.84), HORIZONTAL_ALIGNMENT_CENTER)

	if not state.pending_card_id.is_empty():
		_add_card(table_layer, state.pending_card_id, Vector2(258, 236), Vector2(62, 94), true, false, false)
		_add_label(table_layer, "RESOLVE", Vector2(250, 333), Vector2(78, 20), 12, Color(1.0, 0.82, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	elif String(state.last_event.get("source", "")) == "draw" and not String(state.last_event.get("card_id", "")).is_empty():
		_add_card(table_layer, String(state.last_event.get("card_id", "")), Vector2(258, 236), Vector2(62, 94), true, false, false)
		_add_label(table_layer, "LAST DRAW", Vector2(247, 333), Vector2(84, 20), 11, Color(0.70, 0.78, 0.84), HORIZONTAL_ALIGNMENT_CENTER)

	_render_capture_groups(table_layer, state.players[0].captured_ids, Vector2(18, 350), "PLAYER CAPTURES")

	var hand_selectable := state.current_player == 0 and state.phase == GameState.PHASE_HAND_PLAY
	_add_label(table_layer, "YOUR HAND", Vector2(220, 382), Vector2(520, 22), 12, Color(0.58, 0.66, 0.71), HORIZONTAL_ALIGNMENT_CENTER)
	for index in range(state.players[0].hand_ids.size()):
		var hand_id := String(state.players[0].hand_ids[index])
		_add_card(table_layer, hand_id, Vector2(222 + index * 64, 407), Vector2(58, 88), true, hand_selectable, false)

	if state.phase == GameState.PHASE_HAND_MATCH_CHOICE or state.phase == GameState.PHASE_DRAW_MATCH_CHOICE:
		_add_label(table_layer, "Choose a highlighted matching card.", Vector2(320, 368), Vector2(300, 24), 15, Color(1.0, 0.82, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	if state.phase == GameState.PHASE_SCORE_DECISION and state.current_player == 0:
		_render_score_decision(player_score)

func _render_starter_ceremony(state: GameState) -> void:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.13, 0.19)
	background.size = Vector2(960, 540)
	table_layer.add_child(background)
	_add_label(table_layer, "12 MOONS  •  JANUARY", Vector2(0, 46), Vector2(960, 34), 22, Color(0.95, 0.84, 0.56), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(table_layer, "STARTING PLAYER", Vector2(0, 88), Vector2(960, 40), 30, Color(0.95, 0.94, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
	var instruction := "Choose one card. The earlier revealed month opens January."
	if state.phase == GameState.PHASE_STARTER_AI_REVEAL:
		instruction = "Your card is revealed. The house is choosing its card."
	elif state.phase == GameState.PHASE_STARTER_RESULT:
		instruction = String(state.last_event.get("message", "The starting player is decided."))
	_add_label(table_layer, instruction, Vector2(120, 140), Vector2(720, 32), 17, Color(0.78, 0.82, 0.83), HORIZONTAL_ALIGNMENT_CENTER)

	for index in range(state.starter_card_ids.size()):
		var card_id := String(state.starter_card_ids[index])
		var revealed := state.starter_revealed_ids.has(card_id)
		var selectable := state.phase == GameState.PHASE_STARTER_PLAYER_SELECT and state.current_player == 0
		_add_card(table_layer, card_id, Vector2(320 + index * 110, 220), Vector2(82, 122), revealed, selectable, selectable)
		if revealed:
			var definition := catalog.get_card(card_id)
			if definition != null:
				_add_label(table_layer, definition.display_name, Vector2(300 + index * 110, 348), Vector2(122, 26), 12, Color(0.91, 0.90, 0.82), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(table_layer, "The ceremony cards return to the 48-card deck before the deal.", Vector2(0, 458), Vector2(960, 24), 13, Color(0.58, 0.66, 0.71), HORIZONTAL_ALIGNMENT_CENTER)

func _render_capture_groups(parent: Node, captured_ids: Array, origin: Vector2, title: String) -> void:
	_add_label(parent, title, origin, Vector2(210, 18), 11, Color(0.58, 0.66, 0.71))
	var grouped: Dictionary = {"bright": [], "animal": [], "ribbon": [], "chaff": []}
	for raw_id in captured_ids:
		var card_id := String(raw_id)
		var definition := catalog.get_card(card_id)
		if definition != null and grouped.has(definition.base_class):
			grouped[definition.base_class].append(card_id)
	var classes := ["bright", "animal", "ribbon", "chaff"]
	for class_index in range(classes.size()):
		var group_name: String = String(classes[class_index])
		var ids: Array = grouped[group_name]
		var group_origin := origin + Vector2(class_index * 51, 20)
		_add_label(parent, group_name.to_upper(), group_origin, Vector2(50, 14), 8, Color(0.70, 0.78, 0.84), HORIZONTAL_ALIGNMENT_CENTER)
		for card_index in range(ids.size()):
			var row := int(card_index / 4)
			var column := card_index % 4
			_add_card(parent, ids[card_index], group_origin + Vector2(column * 9, 15 + row * 34), Vector2(32, 48), true, false, false)

func _render_score_panel(title: String, score: Dictionary, position_value: Vector2, color: Color) -> void:
	var panel := ColorRect.new()
	panel.color = color
	panel.position = position_value
	panel.size = Vector2(185, 164)
	table_layer.add_child(panel)
	_add_label(panel, title, Vector2(0, 6), Vector2(185, 22), 16, Color(0.95, 0.84, 0.56), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(panel, "SCORE  %d" % int(score.get("additive_subtotal", 0)), Vector2(8, 31), Vector2(169, 24), 18, Color(0.95, 0.94, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
	var lines: Array = []
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		lines.append("%s  %d" % [entry.get("name", ""), int(entry.get("points", 0))])
	if lines.is_empty():
		lines.append("No yaku yet")
	_add_label(panel, "\n".join(lines), Vector2(8, 60), Vector2(169, 96), 10, Color(0.88, 0.90, 0.88), HORIZONTAL_ALIGNMENT_LEFT)

func _render_score_decision(score: Dictionary) -> void:
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.02, 0.03, 0.05, 0.78)
	dimmer.size = Vector2(960, 540)
	overlay_layer.add_child(dimmer)
	var panel := ColorRect.new()
	panel.color = Color(0.16, 0.23, 0.30)
	panel.position = Vector2(258, 142)
	panel.size = Vector2(444, 238)
	overlay_layer.add_child(panel)
	_add_label_to(panel, "YAKU IMPROVED", Vector2(0, 14), Vector2(444, 32), 24, Color(0.95, 0.84, 0.56), HORIZONTAL_ALIGNMENT_CENTER)
	var current := "Current score: %d\n" % int(score.get("additive_subtotal", 0))
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		current += "%s  +%d\n" % [entry.get("name", ""), int(entry.get("points", 0))]
	_add_label_to(panel, current, Vector2(28, 55), Vector2(388, 98), 15, Color(0.91, 0.90, 0.82), HORIZONTAL_ALIGNMENT_CENTER)
	var stop := Button.new()
	stop.text = "STOP"
	stop.position = Vector2(54, 174)
	stop.size = Vector2(150, 42)
	stop.add_theme_font_size_override("font_size", 18)
	stop.pressed.connect(_on_stop_pressed)
	panel.add_child(stop)
	var koi := Button.new()
	koi.text = "KOI-KOI"
	koi.position = Vector2(240, 174)
	koi.size = Vector2(150, 42)
	koi.add_theme_font_size_override("font_size", 18)
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
	else:
		ui_message = String(controller.state.last_event.get("message", ""))

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
	parent.add_child(label)
	return label

func _add_label_to(parent: Node, value: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color, alignment: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return _add_label(parent, value, position_value, size_value, font_size, color, alignment)
