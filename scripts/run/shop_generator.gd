class_name ShopGenerator
extends RefCounted

static func generate(month: int, generation_id: int, root_seed: int, registry: ModifierRegistry, duplicate_policy: String = "unique_definition", excluded_definition_ids: Array = []) -> Dictionary:
	if registry == null:
		return {"ok": false, "reason": "Modifier registry is required"}
	var result := ShopState.new()
	result.month = month
	result.generation_id = generation_id
	var used: Dictionary = {}
	for slot_index in range(ShopState.SLOT_IDS.size()):
		var slot_id := String(ShopState.SLOT_IDS[slot_index])
		var candidates := _eligible_ids(slot_id, registry, used, duplicate_policy, excluded_definition_ids)
		var offer := ShopOffer.new()
		offer.slot_id = slot_id
		offer.category = slot_id
		offer.generation_id = generation_id
		offer.source = "shop"
		if candidates.is_empty():
			offer.offer_id = "shop_%d_%d_%s_unavailable" % [month, generation_id, slot_id]
			offer.available = false
			offer.price = 0
		else:
			var rng := DeterministicRng.for_scope(root_seed, "shop", month, "%d/%s" % [generation_id, slot_id])
			var selected_id := String(candidates[rng.randi_range(0, candidates.size() - 1)])
			offer.definition_id = selected_id
			offer.offer_id = "shop_%d_%d_%s_%s" % [month, generation_id, slot_id, selected_id]
			offer.price = _price_for(root_seed, month, generation_id, slot_index)
			var selected_definition := registry.get_definition(selected_id)
			if duplicate_policy == "unique_definition" and selected_definition != null and not selected_definition.stackable:
				used[selected_id] = true
		result.offers.append(offer.to_dict())
	return {"ok": true, "state": result.to_dict()}

static func _eligible_ids(slot_id: String, registry: ModifierRegistry, used: Dictionary, duplicate_policy: String, excluded_definition_ids: Array) -> Array:
	var result: Array = []
	for raw_id in registry.ids():
		var definition_id := String(raw_id)
		if excluded_definition_ids.has(definition_id):
			continue
		var definition := registry.get_definition(definition_id)
		if definition == null or definition.source == "seam":
			continue
		if duplicate_policy == "unique_definition" and used.has(definition_id) and not definition.stackable:
			continue
		if _slot_accepts(slot_id, definition):
			result.append(definition_id)
	return result

static func _slot_accepts(slot_id: String, definition: ModifierDefinition) -> bool:
	match slot_id:
		"card_upgrade": return definition.family == "card_upgrade"
		"hand_mechanic": return definition.family == "hand_mechanic"
		"strategic_meta": return definition.family == "strategic_meta"
		"wildcard_a", "wildcard_b": return definition.family != "service"
		"special": return definition.family == "service"
	return false

static func _price_for(root_seed: int, month: int, generation_id: int, slot_index: int) -> int:
	var rng := DeterministicRng.for_scope(root_seed, "shop_price", month, "%d/%d" % [generation_id, slot_index])
	return 3 + rng.randi_range(0, 4)
