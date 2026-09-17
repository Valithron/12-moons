extends SceneTree

func _initialize() -> void:
	var catalog := CardCatalog.new()
	var errors: Array = []
	if catalog.ids().size() != 48:
		errors.append("Expected 48 cards, got %d" % catalog.ids().size())
	if catalog.month_count() != 12:
		errors.append("Expected 12 months, got %d" % catalog.month_count())
	for month in range(1, 13):
		if catalog.cards_for_month(month).size() != 4:
			errors.append("Month %d does not contain exactly four cards" % month)
	errors.append_array(catalog.validate_art_assets())
	var ceremony := JanuarySetup.create_ceremony_state(12, catalog)
	if not ceremony.invariants_ok(catalog):
		errors.append_array(ceremony.invariant_errors(catalog))
	if errors.is_empty():
		print("12 Moons January manifest and core smoke validation passed")
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)
