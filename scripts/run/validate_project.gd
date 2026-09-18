extends SceneTree

func _initialize() -> void:
	var catalog := CardCatalog.new()
	var errors: Array = []
	errors.append_array(catalog.validate_manifest())
	errors.append_array(catalog.validate_art_assets())
	errors.append_array(catalog.duplicate_art_mappings())
	var modifier_registry := ModifierRegistry.new()
	errors.append_array(modifier_registry.validate())
	var reward_candidates := modifier_registry.eligible_reward_definition_ids()
	if reward_candidates.size() < 3:
		push_warning("Modifier catalogue currently exposes %d eligible reward definition(s); approved default reward generation needs authored content for three offers." % reward_candidates.size())
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
