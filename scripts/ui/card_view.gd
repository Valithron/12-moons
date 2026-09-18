class_name MoonCardView
extends Button

signal card_clicked(card_id: String)

var card_id: String = ""
var definition: CardDefinition = null
var face_up: bool = false
var selectable: bool = false
var highlighted: bool = false
var card_texture: Texture2D = null
var card_size: Vector2 = Vector2(64, 96)

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func configure(card_definition: CardDefinition = null, show_face: bool = true, can_select: bool = false, show_highlight: bool = false, requested_size: Vector2 = Vector2(64, 96)) -> void:
	definition = card_definition
	card_id = definition.card_id if definition != null else ""
	face_up = show_face and definition != null
	selectable = can_select
	highlighted = show_highlight
	card_size = requested_size
	custom_minimum_size = card_size
	size = card_size
	disabled = not selectable
	mouse_filter = Control.MOUSE_FILTER_STOP if selectable else Control.MOUSE_FILTER_IGNORE
	tooltip_text = definition.display_name if definition != null else "Draw pile"
	card_texture = null
	if face_up and definition != null and not definition.art_path.is_empty():
		card_texture = load(definition.art_path) as Texture2D
	queue_redraw()

func _on_pressed() -> void:
	if selectable and not card_id.is_empty():
		card_clicked.emit(card_id)

func _on_mouse_entered() -> void:
	if selectable:
		queue_redraw()

func _on_mouse_exited() -> void:
	if selectable:
		queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color(0.92, 0.84, 0.67), true)
	if face_up and card_texture != null:
		var inset := 3.0
		draw_texture_rect(card_texture, Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0), false)
	else:
		draw_rect(Rect2(3, 3, size.x - 6, size.y - 6), Color(0.17, 0.27, 0.38), true)
		var center := size * 0.5
		draw_circle(center, min(size.x, size.y) * 0.22, Color(0.48, 0.34, 0.20))
		draw_circle(center, min(size.x, size.y) * 0.15, Color(0.91, 0.78, 0.49))
		draw_line(Vector2(10, 10), Vector2(size.x - 10, size.y - 10), Color(0.91, 0.78, 0.49), 1.0)
		draw_line(Vector2(size.x - 10, 10), Vector2(10, size.y - 10), Color(0.91, 0.78, 0.49), 1.0)
	var border_color := Color(0.33, 0.20, 0.08)
	var border_width := 2.0
	if highlighted:
		border_color = Color(1.0, 0.82, 0.22)
		border_width = 4.0
	elif selectable and is_hovered():
		border_color = Color(0.72, 0.93, 1.0)
		border_width = 3.0
	draw_rect(bounds.grow(-1), border_color, false, border_width)
