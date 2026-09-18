class_name RewardGenerator
extends RefCounted

static func generate(request: RewardRequest, root_seed: int, registry: ModifierRegistry) -> Dictionary:
	if request == null or not request.is_resolvable():
		return {"ok": false, "reason": request.unresolved_reason if request != null else "RewardRequest is null"}
	if registry == null:
		return {"ok": false, "reason": "Modifier registry is required"}
	var result := RewardState.new()
	result.request = request.to_dict()
	var used_definitions: Dictionary = {}
	for slot_index in range(request.slot_specs.size()):
		var slot_spec := String(request.slot_specs[slot_index])
		var candidates := _eligible_ids(slot_spec, request, registry, used_definitions)
		if candidates.is_empty():
			return {"ok": false, "reason": "No eligible modifier for reward slot %d (%s)" % [slot_index + 1, slot_spec]}
		var rng := DeterministicRng.for_scope(root_seed, "reward", request.month, "%s/%d" % [request.generation_id, slot_index])
		var selected_id := String(candidates[rng.randi_range(0, candidates.size() - 1)])
		var selected_definition := registry.get_definition(selected_id)
		if request.duplicate_policy == "unique_definition" and selected_definition != null and not selected_definition.stackable:
			used_definitions[selected_id] = true
		var offer := RewardOffer.new()
		offer.offer_id = "reward_%d_%d_%d_%s" % [request.month, request.generation_id, slot_index, selected_id]
		offer.definition_id = selected_id
		offer.slot_index = slot_index
		offer.slot_spec = slot_spec
		offer.source = request.source
		offer.generation_id = request.generation_id
		result.offers.append(offer.to_dict())
	result.generated = true
	return {"ok": true, "state": result.to_dict()}

static func _eligible_ids(slot_spec: String, request: RewardRequest, registry: ModifierRegistry, used_definitions: Dictionary) -> Array:
	var result: Array = []
	for raw_id in registry.ids():
		var definition_id := String(raw_id)
		if request.excluded_definition_ids.has(definition_id):
			continue
		var definition := registry.get_definition(definition_id)
		if definition == null:
			continue
		if request.duplicate_policy == "unique_definition" and used_definitions.has(definition_id) and not definition.stackable:
			continue
		if _slot_accepts(slot_spec, definition):
			result.append(definition_id)
	return result

static func _slot_accepts(slot_spec: String, definition: ModifierDefinition) -> bool:
	match slot_spec:
		RewardRequest.SLOT_ANY, RewardRequest.SLOT_WILDCARD:
			return definition.source != "seam"
		RewardRequest.SLOT_CARD_UPGRADE:
			return definition.family == "card_upgrade" and definition.source != "seam"
		RewardRequest.SLOT_HAND_MECHANIC:
			return definition.family == "hand_mechanic" and definition.source != "seam"
		RewardRequest.SLOT_STRATEGIC_META:
			return definition.family == "strategic_meta" and definition.source != "seam"
		RewardRequest.SLOT_SERVICE:
			return definition.family == "service" and definition.source != "seam"
	return false
