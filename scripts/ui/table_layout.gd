class_name MoonTableLayout
extends RefCounted

const VIEW_SIZE := Vector2(1280, 720)

const REGION_RECTS := {
	"header": Rect2(18, 8, 1244, 58),
	"status": Rect2(300, 67, 680, 14),
	"opponent_captures": Rect2(18, 82, 286, 222),
	"opponent_hand": Rect2(320, 82, 620, 122),
	"scores": Rect2(958, 82, 304, 210),
	"field": Rect2(318, 214, 606, 334),
	"draw": Rect2(958, 300, 304, 150),
	"player_captures": Rect2(18, 470, 286, 236),
	"player_hand": Rect2(318, 558, 606, 148)
}

const REGION_COLORS := {
	"header": Color(0.10, 0.16, 0.22, 0.96),
	"status": Color(0.13, 0.20, 0.26, 0.94),
	"opponent_captures": Color(0.10, 0.15, 0.20, 0.90),
	"opponent_hand": Color(0.08, 0.13, 0.18, 0.82),
	"scores": Color(0.10, 0.15, 0.20, 0.94),
	"field": Color(0.07, 0.20, 0.17, 0.96),
	"draw": Color(0.09, 0.14, 0.19, 0.96),
	"player_captures": Color(0.10, 0.15, 0.20, 0.90),
	"player_hand": Color(0.08, 0.13, 0.18, 0.94)
}

var root: Control
var regions: Dictionary = {}

func build(parent: Control) -> Control:
	root = Control.new()
	root.name = "TableLayout"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)

	var background := ColorRect.new()
	background.name = "TableBackground"
	background.color = Color(0.045, 0.075, 0.11)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)

	for region_name in REGION_RECTS.keys():
		_create_region(String(region_name))
	return root

func content(region_name: String) -> Control:
	return regions.get(region_name)

func _create_region(region_name: String) -> void:
	var region := Control.new()
	region.name = String(region_name).capitalize()
	var rect: Rect2 = REGION_RECTS[region_name]
	region.position = rect.position
	region.size = rect.size
	region.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(region)

	var surface := ColorRect.new()
	surface.name = "Surface"
	surface.color = REGION_COLORS[region_name]
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region.add_child(surface)

	var content_node := Control.new()
	content_node.name = "Content"
	content_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region.add_child(content_node)
	regions[region_name] = content_node
