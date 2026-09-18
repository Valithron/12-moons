class_name ShopState
extends RefCounted

const SLOT_IDS := ["card_upgrade", "hand_mechanic", "strategic_meta", "wildcard_a", "wildcard_b", "special"]

var month: int = 1
var generation_id: int = 0
var reroll_count: int = 0
var entered: bool = false
var offers: Array = []
var preserved_offer: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"month": month,
		"generation_id": generation_id,
		"reroll_count": reroll_count,
		"entered": entered,
		"offers": offers.duplicate(true),
		"preserved_offer": preserved_offer.duplicate(true)
	}

static func from_dict(data: Dictionary) -> ShopState:
	var result := ShopState.new()
	result.month = int(data.get("month", 1))
	result.generation_id = int(data.get("generation_id", 0))
	result.reroll_count = int(data.get("reroll_count", 0))
	result.entered = bool(data.get("entered", false))
	result.offers = Array(data.get("offers", [])).duplicate(true)
	var raw_preserved = data.get("preserved_offer", {})
	if raw_preserved is Dictionary:
		result.preserved_offer = raw_preserved.duplicate(true)
	return result

func offer(offer_id: String) -> ShopOffer:
	for raw_offer in offers:
		if raw_offer is Dictionary:
			var candidate := ShopOffer.from_dict(raw_offer)
			if candidate.offer_id == offer_id:
				return candidate
	return null

func invariant_errors() -> Array:
	var errors: Array = []
	var ids: Dictionary = {}
	var slots: Dictionary = {}
	for raw_offer in offers:
		if not raw_offer is Dictionary:
			errors.append("Shop offer must be an object")
			continue
		var offer := ShopOffer.from_dict(raw_offer)
		if offer.offer_id.is_empty() or ids.has(offer.offer_id):
			errors.append("Shop offer IDs must be unique and non-empty")
		ids[offer.offer_id] = true
		if not SLOT_IDS.has(offer.slot_id):
			errors.append("Unknown shop slot: %s" % offer.slot_id)
		if slots.has(offer.slot_id):
			errors.append("Shop slot is duplicated: %s" % offer.slot_id)
		slots[offer.slot_id] = true
		if offer.price < 0:
			errors.append("Shop offer price cannot be negative")
	if not offers.is_empty() and offers.size() != SLOT_IDS.size():
		errors.append("Shop must contain exactly six offers")
	if not offers.is_empty() and slots.size() != SLOT_IDS.size():
		errors.append("Shop must contain all six slot categories")
	if reroll_count < 0:
		errors.append("Shop reroll count cannot be negative")
	if not preserved_offer.is_empty():
		var preserved := ShopOffer.from_dict(preserved_offer)
		if preserved.offer_id.is_empty() or preserved.definition_id.is_empty():
			errors.append("Preserved shop offer must identify an offer and definition")
		if not SLOT_IDS.has(preserved.slot_id):
			errors.append("Preserved shop offer has an unknown slot: %s" % preserved.slot_id)
		if preserved.consumed or preserved.available:
			errors.append("Preserved shop offer must be unavailable and unconsumed")
	return errors
