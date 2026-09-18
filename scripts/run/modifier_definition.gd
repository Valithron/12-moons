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
var stackable: bool = false
var allow_same_card_stack: bool = false
var base_shop_price: int = 4

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
	result.stackable = bool(data.get("stackable", false))
	result.allow_same_card_stack = bool(data.get("allow_same_card_stack", false))
	result.base_shop_price = maxi(0, int(data.get("base_shop_price", result.base_shop_price)))
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
		"sellable": sellable,
		"stackable": stackable,
		"allow_same_card_stack": allow_same_card_stack,
		"base_shop_price": base_shop_price
	}
