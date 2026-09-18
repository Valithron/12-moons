extends Node

var run_number: int = 0
var screen: Node = null

func _ready() -> void:
	_show_title()

func _clear_screen() -> void:
	if is_instance_valid(screen):
		# Screen transitions can be triggered from a Button.pressed signal on
		# the screen being replaced. Freeing that node synchronously while its
		# signal is still being emitted causes Godot's "locked object" error.
		screen.queue_free()
	screen = null

func _show_title() -> void:
	_clear_screen()
	var root := Control.new()
	root.size = Vector2(1280, 720)
	add_child(root)
	screen = root

	var background := ColorRect.new()
	background.color = Color(0.07, 0.11, 0.16)
	background.size = Vector2(1280, 720)
	root.add_child(background)
	_add_label(root, "12 MOONS", Vector2(0, 170), Vector2(1280, 66), 56, Color(0.95, 0.84, 0.56), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(root, "A hanafuda game of risk, yaku, and changing moons.", Vector2(0, 246), Vector2(1280, 34), 20, Color(0.78, 0.82, 0.83), HORIZONTAL_ALIGNMENT_CENTER)

	var start := Button.new()
	start.text = "START JANUARY"
	start.position = Vector2(500, 390)
	start.size = Vector2(280, 68)
	start.add_theme_font_size_override("font_size", 22)
	start.pressed.connect(_show_january_intro)
	root.add_child(start)
	_add_label(root, "Prototype 0.2.0-prototype.5", Vector2(0, 646), Vector2(1280, 24), 14, Color(0.58, 0.66, 0.71), HORIZONTAL_ALIGNMENT_CENTER)

func _show_january_intro() -> void:
	_clear_screen()
	var intro = load("res://scenes/moon_intro/moon_intro.tscn").instantiate()
	add_child(intro)
	screen = intro
	intro.continue_pressed.connect(_begin_january)

func _begin_january() -> void:
	_clear_screen()
	run_number += 1
	var controller := MatchController.new(12012000 + run_number)
	controller.begin_january(12012000 + run_number)
	var match_screen = load("res://scenes/match/match.tscn").instantiate()
	add_child(match_screen)
	screen = match_screen
	match_screen.configure(controller)
	match_screen.month_finished.connect(_show_result)

func _show_result(result: Dictionary) -> void:
	_clear_screen()
	var result_screen = load("res://scenes/result/result.tscn").instantiate()
	add_child(result_screen)
	screen = result_screen
	result_screen.setup(result)
	result_screen.play_again_pressed.connect(_begin_january)
	result_screen.return_title_pressed.connect(_show_title)

func _add_label(parent: Node, value: String, position_value: Vector2, size_value: Vector2, font_size: int, color: Color, alignment: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = position_value
	label.size = size_value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
