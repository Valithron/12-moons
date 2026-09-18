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

func validate_manifest() -> Array:
	var errors: Array = []
	var card_ids := ids()
	if card_ids.size() != 48:
		errors.append("Expected 48 cards, got %d" % card_ids.size())
	if _by_month.size() != 12:
		errors.append("Expected 12 months, got %d" % _by_month.size())
	for month in range(1, 13):
		var month_cards := cards_for_month(month)
		if month_cards.size() != 4:
			errors.append("Month %d has %d cards, expected 4" % [month, month_cards.size()])
		for card_id in month_cards:
			var definition := get_card(String(card_id))
			if definition == null:
				errors.append("Month %d references missing card: %s" % [month, card_id])
			elif definition.month != month:
				errors.append("Card %s has month %d but is indexed under month %d" % [card_id, definition.month, month])
	var allowed_classes := ["bright", "animal", "ribbon", "chaff"]
	for card_id in card_ids:
		var definition := get_card(String(card_id))
		if definition == null:
			continue
		if not allowed_classes.has(definition.base_class):
			errors.append("Card %s has invalid class: %s" % [card_id, definition.base_class])
	return errors

func duplicate_art_mappings() -> Array:
	var by_art: Dictionary = {}
	for card_id in ids():
		var definition := get_card(String(card_id))
		if definition == null or definition.art_path.is_empty():
			continue
		if not by_art.has(definition.art_path):
			by_art[definition.art_path] = []
		by_art[definition.art_path].append(String(card_id))
	var duplicates: Array = []
	for art_path in by_art.keys():
		var mapped_ids: Array = by_art[art_path]
		if mapped_ids.size() > 1:
			duplicates.append("%s -> %s" % [art_path, ", ".join(mapped_ids)])
	return duplicates
