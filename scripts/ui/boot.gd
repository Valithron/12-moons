extends Node

func _ready() -> void:
	var label := Label.new()
	label.text = "12 Moons\nOpen-Source Foundation Prototype\nGodot 4.7.2"
	label.position = Vector2(32, 32)
	label.add_theme_font_size_override("font_size", 26)
	add_child(label)
