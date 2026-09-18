class_name ModifierEffectRegistry
extends RefCounted

const SEAM_REWARD_REQUEST := "reward_request_transform"
const SEAM_CAPTURE_PLAN := "capture_plan"
const SEAM_SCORE_BREAKDOWN := "score_breakdown"
const SEAM_OPENING_DECISION := "opening_decision"
const SEAM_DRAW_REVEAL_DECISION := "draw_reveal_decision"
const SEAM_MULTIPLIER_REPLACEMENT := "multiplier_replacement"
const SEAM_SALVAGE_TRANSACTION := "salvage_transaction"
const SEAM_SHOP_OFFER_PRESERVATION := "shop_offer_preservation"

var handlers: Dictionary = {}
var replacement_claims: Dictionary = {}

func register_handler(seam_id: String, handler_id: String, priority: int = 0, replacement_name: String = "") -> void:
	if not handlers.has(seam_id):
		handlers[seam_id] = []
	handlers[seam_id].append({"handler_id": handler_id, "priority": priority, "replacement_name": replacement_name})
	if not replacement_name.is_empty():
		if not replacement_claims.has(replacement_name):
			replacement_claims[replacement_name] = []
		replacement_claims[replacement_name].append(handler_id)

func handlers_for(seam_id: String) -> Array:
	var result: Array = handlers.get(seam_id, []).duplicate(true)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("priority", 0)) == int(b.get("priority", 0)):
			return String(a.get("handler_id", "")) < String(b.get("handler_id", ""))
		return int(a.get("priority", 0)) < int(b.get("priority", 0))
	)
	return result

func validate() -> Array:
	var errors: Array = []
	for replacement_name in replacement_claims.keys():
		var claims: Array = replacement_claims[replacement_name]
		if claims.size() > 1:
			errors.append("Conflicting replacement handlers for %s: %s" % [replacement_name, ", ".join(claims)])
	return errors

func active_effect_seams(state: RunState, modifier_registry: ModifierRegistry) -> Array:
	var result: Array = []
	if state == null or modifier_registry == null:
		return result
	for raw_instance_id in state.active_modifier_ids:
		var instance: Dictionary = state.modifier_instances.get(String(raw_instance_id), {})
		var definition := modifier_registry.get_definition(String(instance.get("definition_id", "")))
		if definition == null:
			continue
		for raw_seam in definition.effect_seams:
			if not result.has(String(raw_seam)):
				result.append(String(raw_seam))
	return result
