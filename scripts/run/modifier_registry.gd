class_name ModifierRegistry
extends RefCounted

const DEFAULT_PATH := "res://data/modifiers/modifiers.json"

var _definitions: Dictionary = {}
var _load_errors: Array = []

func _init(source_path: String = DEFAULT_PATH) -> void:
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		_load_errors.append("Unable to open modifier manifest: %s" % source_path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_load_errors.append("Modifier manifest must contain an object")
		return
	var seen: Dictionary = {}
	for raw_definition in parsed.get("modifiers", []):
		if not raw_definition is Dictionary:
			_load_errors.append("Modifier entry is not an object")
			continue
		var definition := ModifierDefinition.from_dict(raw_definition)
		if definition.definition_id.is_empty():
			_load_errors.append("Modifier definition has no stable ID")
			continue
		if seen.has(definition.definition_id):
			_load_errors.append("Duplicate modifier definition ID: %s" % definition.definition_id)
			continue
		seen[definition.definition_id] = true
		_definitions[definition.definition_id] = definition

func ids() -> Array:
	var result := _definitions.keys()
	result.sort()
	return result

func get_definition(definition_id: String) -> ModifierDefinition:
	return _definitions.get(definition_id)

func has_definition(definition_id: String) -> bool:
	return _definitions.has(definition_id)

func eligible_reward_definition_ids() -> Array:
	var result: Array = []
	for definition_id in ids():
		var definition: ModifierDefinition = get_definition(String(definition_id))
		if definition != null and definition.source != "seam":
			result.append(definition.definition_id)
	return result

func validate() -> Array:
	var errors := _load_errors.duplicate()
	var valid_families := ["card_upgrade", "hand_mechanic", "strategic_meta", "wildcard", "service"]
	for definition_id in ids():
		var definition: ModifierDefinition = get_definition(String(definition_id))
		if not valid_families.has(definition.family):
			errors.append("Modifier %s has invalid family %s" % [definition.definition_id, definition.family])
		if definition.description.is_empty():
			errors.append("Modifier %s has no readable description" % definition.definition_id)
	return errors
