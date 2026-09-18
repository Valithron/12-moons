class_name ModifierInstance
extends RefCounted

var instance_id: String = ""
var definition_id: String = ""
var location: String = ""
var source: String = ""
var acquired_month: int = 0
var attached_card_ids: Array = []
var purchase_price: int = 0
var base_shop_price: int = 4

func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"location": location,
		"source": source,
		"acquired_month": acquired_month,
		"attached_card_ids": attached_card_ids.duplicate(),
		"purchase_price": purchase_price,
		"base_shop_price": base_shop_price
	}

static func from_dict(data: Dictionary) -> ModifierInstance:
	var result := ModifierInstance.new()
	result.instance_id = String(data.get("instance_id", ""))
	result.definition_id = String(data.get("definition_id", ""))
	result.location = String(data.get("location", ""))
	result.source = String(data.get("source", ""))
	result.acquired_month = int(data.get("acquired_month", 0))
	result.attached_card_ids = Array(data.get("attached_card_ids", [])).duplicate()
	result.purchase_price = maxi(0, int(data.get("purchase_price", 0)))
	result.base_shop_price = maxi(0, int(data.get("base_shop_price", result.base_shop_price)))
	return result
