class_name CardCatalog
extends RefCounted

const DEFAULT_PATH := "res://data/hanafuda/cards.json"

var manifest_version: String = ""
var _by_id: Dictionary = {}
var _by_month: Dictionary = {}

func _init(source_path: String = DEFAULT_PATH) -> void:
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		push_error("Unable to open card manifest: %s" % source_path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Card manifest must contain a JSON object")
		return
	manifest_version = String(parsed.get("manifest_version", ""))
	for raw_card in parsed.get("cards", []):
		if not raw_card is Dictionary:
			continue
		var definition := CardDefinition.from_dict(raw_card)
		if definition.card_id.is_empty():
			continue
		_by_id[definition.card_id] = definition
		if not _by_month.has(definition.month):
			_by_month[definition.month] = []
		_by_month[definition.month].append(definition.card_id)

func get_card(card_id: String) -> CardDefinition:
	return _by_id.get(card_id)

func has_card(card_id: String) -> bool:
	return _by_id.has(card_id)

func ids() -> Array:
	var result := _by_id.keys()
	result.sort()
	return result

func cards_for_month(month: int) -> Array:
	var result: Array = _by_month.get(month, []).duplicate()
	result.sort()
	return result

func cards_with_tag(tag: String) -> Array:
	var result: Array = []
	for card_id in ids():
		if get_card(card_id).has_tag(tag):
			result.append(card_id)
	return result

func month_count() -> int:
	return _by_month.size()

func validate_art_assets() -> Array:
	var errors: Array = []
	for card_id in ids():
		var definition := get_card(String(card_id))
		if definition.art_path.is_empty():
			errors.append("Card has no art_path: %s" % card_id)
		elif not FileAccess.file_exists(definition.art_path):
			errors.append("Card art is missing: %s -> %s" % [card_id, definition.art_path])
	return errors
