class_name MoonCardView
extends Button

signal card_clicked(card_id: String)
signal hover_changed(card: MoonCardView, entered: bool)

var card_id: String = ""
var definition: CardDefinition = null
var face_up: bool = false
var selectable: bool = false
var highlighted: bool = false
var card_texture: Texture2D = null
var card_size: Vector2 = Vector2(64, 96)
var slot_position: Vector2 = Vector2.ZERO
var resting_z_index: int = 0
var _hovered: bool = false

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func configure(card_definition: CardDefinition = null, show_face: bool = true, can_select: bool = false, show_highlight: bool = false, requested_size: Vector2 = Vector2(64, 96)) -> void:
	definition = card_definition
	card_id = definition.card_id if definition != null else ""
	set_display(requested_size, show_face, can_select, show_highlight)
	tooltip_text = definition.display_name if definition != null else "Draw pile"

func set_display(requested_size: Vector2, show_face: bool, can_select: bool, show_highlight: bool) -> void:
	card_size = requested_size
	custom_minimum_size = card_size
	size = card_size
	pivot_offset = card_size * 0.5
	highlighted = show_highlight
	set_selectable(can_select)
	set_face_up(show_face)

func set_face_up(show_face: bool) -> void:
	face_up = show_face and definition != null
	card_texture = null
	if face_up and definition != null and not definition.art_path.is_empty():
		card_texture = load(definition.art_path) as Texture2D
	queue_redraw()

func set_selectable(can_select: bool) -> void:
	selectable = can_select
	disabled = not selectable
	mouse_filter = Control.MOUSE_FILTER_STOP if selectable else Control.MOUSE_FILTER_IGNORE
	if not selectable:
		set_hovered(false)
	queue_redraw()

func set_highlighted(show_highlight: bool) -> void:
	highlighted = show_highlight
	queue_redraw()

func set_slot_position(value: Vector2) -> void:
	slot_position = value

func get_slot_position() -> Vector2:
	return slot_position

func set_hovered(value: bool) -> void:
	if _hovered == value:
		return
	_hovered = value
	hover_changed.emit(self, _hovered)
	queue_redraw()

func _on_pressed() -> void:
	if selectable and not card_id.is_empty():
		card_clicked.emit(card_id)

func _on_mouse_entered() -> void:
	if selectable:
		set_hovered(true)
		queue_redraw()

func _on_mouse_exited() -> void:
	if _hovered:
		set_hovered(false)
	if selectable:
		queue_redraw()

func _on_focus_entered() -> void:
	queue_redraw()

func _on_focus_exited() -> void:
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
	if has_focus() and selectable:
		draw_rect(bounds.grow(-1.0), Color(0.98, 0.87, 0.38), false, 3.0)
	var border_color := Color(0.33, 0.20, 0.08)
	var border_width := 2.0
	if highlighted:
		border_color = Color(1.0, 0.82, 0.22)
		border_width = 4.0
	elif selectable and is_hovered():
		border_color = Color(0.72, 0.93, 1.0)
		border_width = 3.0
	draw_rect(bounds.grow(-1), border_color, false, border_width)
