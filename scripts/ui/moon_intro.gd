extends Control

signal continue_pressed

func _ready() -> void:
	_build()

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.11, 0.16)
	background.position = Vector2.ZERO
	background.size = Vector2(1280, 720)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_add_label("JANUARY", Vector2(0, 170), Vector2(1280, 58), 48, Color(0.95, 0.84, 0.56), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("Wolf Moon", Vector2(0, 242), Vector2(1280, 46), 30, Color(0.95, 0.94, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("All Chaff points are doubled.", Vector2(0, 322), Vector2(1280, 34), 24, Color(0.91, 0.86, 0.73), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label("Strength of the Pack", Vector2(0, 362), Vector2(1280, 34), 20, Color(0.70, 0.78, 0.84), HORIZONTAL_ALIGNMENT_CENTER)

	var button := Button.new()
	button.text = "CONTINUE"
	button.position = Vector2(500, 470)
	button.size = Vector2(280, 64)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(_on_continue)
	add_child(button)

func _on_continue() -> void:
	continue_pressed.emit()

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
