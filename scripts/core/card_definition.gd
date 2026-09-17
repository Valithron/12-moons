class_name CardDefinition
extends RefCounted

var card_id: String = ""
var month: int = 0
var flower: String = ""
var base_class: String = ""
var display_name: String = ""
var tags: Array = []

static func from_dict(data: Dictionary) -> CardDefinition:
	var definition := CardDefinition.new()
	definition.card_id = String(data.get("id", ""))
	definition.month = int(data.get("month", 0))
	definition.flower = String(data.get("flower", ""))
	definition.base_class = String(data.get("base_class", ""))
	definition.display_name = String(data.get("display_name", definition.card_id))
	definition.tags = Array(data.get("tags", [])).duplicate()
	return definition

func has_tag(tag: String) -> bool:
	return tags.has(tag)

func to_dict() -> Dictionary:
	return {
		"id": card_id,
		"month": month,
		"flower": flower,
		"base_class": base_class,
		"display_name": display_name,
		"tags": tags.duplicate()
	}
