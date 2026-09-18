class_name ModifierDefinition
extends RefCounted

var definition_id: String = ""
var display_name: String = ""
var family: String = ""
var description: String = ""
var source: String = ""
var tags: Array = []
var effect_seams: Array = []
var is_free_reward: bool = false
var sellable: bool = true

static func from_dict(data: Dictionary) -> ModifierDefinition:
	var result := ModifierDefinition.new()
	result.definition_id = String(data.get("id", ""))
	result.display_name = String(data.get("display_name", result.definition_id))
	result.family = String(data.get("family", ""))
	result.description = String(data.get("description", ""))
	result.source = String(data.get("source", ""))
	result.tags = Array(data.get("tags", [])).duplicate()
	result.effect_seams = Array(data.get("effect_seams", [])).duplicate()
	result.is_free_reward = bool(data.get("is_free_reward", false))
	result.sellable = bool(data.get("sellable", true))
	return result

func to_dict() -> Dictionary:
	return {
		"id": definition_id,
		"display_name": display_name,
		"family": family,
		"description": description,
		"source": source,
		"tags": tags.duplicate(),
		"effect_seams": effect_seams.duplicate(),
		"is_free_reward": is_free_reward,
		"sellable": sellable
	}
