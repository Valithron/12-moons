class_name ModifierInstance
extends RefCounted

var instance_id: String = ""
var definition_id: String = ""
var location: String = ""
var source: String = ""
var acquired_month: int = 0
var attached_card_ids: Array = []

func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"location": location,
		"source": source,
		"acquired_month": acquired_month,
		"attached_card_ids": attached_card_ids.duplicate()
	}

static func from_dict(data: Dictionary) -> ModifierInstance:
	var result := ModifierInstance.new()
	result.instance_id = String(data.get("instance_id", ""))
	result.definition_id = String(data.get("definition_id", ""))
	result.location = String(data.get("location", ""))
	result.source = String(data.get("source", ""))
	result.acquired_month = int(data.get("acquired_month", 0))
	result.attached_card_ids = Array(data.get("attached_card_ids", [])).duplicate()
	return result
