class_name ShopOffer
extends RefCounted

var offer_id: String = ""
var slot_id: String = ""
var category: String = ""
var definition_id: String = ""
var price: int = 0
var source: String = "shop"
var generation_id: int = 0
var consumed: bool = false
var available: bool = true
var preserved: bool = false

func to_dict() -> Dictionary:
	return {
		"offer_id": offer_id,
		"slot_id": slot_id,
		"category": category,
		"definition_id": definition_id,
		"price": price,
		"source": source,
		"generation_id": generation_id,
		"consumed": consumed,
		"available": available,
		"preserved": preserved
	}

static func from_dict(data: Dictionary) -> ShopOffer:
	var result := ShopOffer.new()
	result.offer_id = String(data.get("offer_id", ""))
	result.slot_id = String(data.get("slot_id", ""))
	result.category = String(data.get("category", ""))
	result.definition_id = String(data.get("definition_id", ""))
	result.price = int(data.get("price", 0))
	result.source = String(data.get("source", "shop"))
	result.generation_id = int(data.get("generation_id", 0))
	result.consumed = bool(data.get("consumed", false))
	result.available = bool(data.get("available", true))
	result.preserved = bool(data.get("preserved", false))
	return result
