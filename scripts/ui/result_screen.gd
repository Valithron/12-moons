extends Control

signal play_again_pressed
signal return_title_pressed

func setup(result: Dictionary) -> void:
	_build(result)

func _ready() -> void:
	pass

func _build(result: Dictionary) -> void:
	for child in get_children():
		child.free()

	var background := ColorRect.new()
	background.color = Color(0.07, 0.11, 0.16)
	background.size = Vector2(1280, 720)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var winner_id := int(result.get("winner_id", -1))
	var outcome := "TIE"
	if winner_id == 0:
		outcome = "PLAYER WINS"
	elif winner_id == 1:
		outcome = "HOUSE WINS"
	_add_label("JANUARY COMPLETE", Vector2(0, 58), Vector2(1280, 44), 32, Color(0.95, 0.84, 0.56), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(outcome, Vector2(0, 108), Vector2(1280, 46), 38, Color(0.95, 0.94, 0.86), HORIZONTAL_ALIGNMENT_CENTER)

	var ended_by := String(result.get("ended_by", "exhaustion"))
	var end_text := "Ended by " + ("Stop" if ended_by == "stop" else "normal exhaustion")
	if bool(result.get("koi_koi_declared", false)):
		end_text += " • Koi-Koi was declared"
	_add_label(end_text, Vector2(0, 158), Vector2(1280, 28), 17, Color(0.70, 0.78, 0.84), HORIZONTAL_ALIGNMENT_CENTER)

	var player_scores: Array = Array(result.get("player_scores", []))
	if player_scores.size() >= 2:
		_add_score_panel("PLAYER", player_scores[0], Vector2(188, 218))
		_add_score_panel("HOUSE", player_scores[1], Vector2(710, 218))

	var play_again := Button.new()
	play_again.text = "PLAY AGAIN"
	play_again.position = Vector2(470, 630)
	play_again.size = Vector2(160, 52)
	play_again.pressed.connect(_on_play_again)
	add_child(play_again)

	var return_title := Button.new()
	return_title.text = "RETURN TO TITLE"
	return_title.position = Vector2(650, 630)
	return_title.size = Vector2(160, 52)
	return_title.pressed.connect(_on_return_title)
	add_child(return_title)

func _add_score_panel(title: String, score: Dictionary, position_value: Vector2) -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.18, 0.25)
	panel.position = position_value
	panel.size = Vector2(382, 350)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_add_label_to(panel, title, Vector2(0, 12), Vector2(382, 30), 22, Color(0.95, 0.84, 0.56), HORIZONTAL_ALIGNMENT_CENTER)
	var yaku_lines: Array = []
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		yaku_lines.append("%s  +%d" % [entry.get("name", ""), int(entry.get("points", 0))])
	if yaku_lines.is_empty():
		yaku_lines.append("No scoring yaku")
	var body := "Yaku\n" + "\n".join(yaku_lines)
	body += "\n\nBase/additive: %d" % int(score.get("normal_additive_subtotal", 0))
	body += "\nWolf Moon bonus: +%d" % int(score.get("moon_additive_bonus", 0))
	body += "\nAdditive subtotal: %d" % int(score.get("additive_subtotal", 0))
	body += "\n7+ multiplier: x%d" % int(score.get("seven_plus_multiplier", 1))
	body += "\nKoi-Koi multiplier: x%d" % int(score.get("koi_koi_multiplier", 1))
	body += "\nFINAL: %d" % int(score.get("final_score", 0))
	_add_label_to(panel, body, Vector2(18, 50), Vector2(346, 282), 15, Color(0.91, 0.90, 0.82), HORIZONTAL_ALIGNMENT_LEFT)

func _on_play_again() -> void:
	play_again_pressed.emit()

func _on_return_title() -> void:
	return_title_pressed.emit()

func _add_label(value: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color, alignment: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func _add_label_to(parent: Node, value: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color, alignment: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
