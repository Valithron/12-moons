class_name RewardState
extends RefCounted

var request: Dictionary = {}
var offers: Array = []
var generated: bool = false
var selection_committed: bool = false
var selected_offer_id: String = ""
var refused: bool = false
var pending_acquisition: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"request": request.duplicate(true),
		"offers": offers.duplicate(true),
		"generated": generated,
		"selection_committed": selection_committed,
		"selected_offer_id": selected_offer_id,
		"refused": refused,
		"pending_acquisition": pending_acquisition.duplicate(true)
	}

static func from_dict(data: Dictionary) -> RewardState:
	var result := RewardState.new()
	var raw_request = data.get("request", {})
	if raw_request is Dictionary:
		result.request = raw_request.duplicate(true)
	result.offers = Array(data.get("offers", [])).duplicate(true)
	result.generated = bool(data.get("generated", false))
	result.selection_committed = bool(data.get("selection_committed", false))
	result.selected_offer_id = String(data.get("selected_offer_id", ""))
	result.refused = bool(data.get("refused", false))
	var raw_pending = data.get("pending_acquisition", {})
	if raw_pending is Dictionary:
		result.pending_acquisition = raw_pending.duplicate(true)
	return result

func offer(offer_id: String) -> RewardOffer:
	for raw_offer in offers:
		var candidate := RewardOffer.from_dict(raw_offer)
		if candidate.offer_id == offer_id:
			return candidate
	return null

func invariant_errors() -> Array:
	var errors: Array = []
	var ids: Dictionary = {}
	for raw_offer in offers:
		var candidate := RewardOffer.from_dict(raw_offer)
		if candidate.offer_id.is_empty() or ids.has(candidate.offer_id):
			errors.append("Reward offer IDs must be unique and non-empty")
		ids[candidate.offer_id] = true
	if selection_committed and selected_offer_id.is_empty() and not refused:
		errors.append("Committed reward selection has no offer ID")
	if selection_committed and refused and not selected_offer_id.is_empty():
		errors.append("Refused reward cannot also select an offer")
	return errors
