extends GdUnitTestSuite

func _catalog() -> CardCatalog:
	return CardCatalog.new()

func test_manifest_has_48_unique_physical_cards() -> void:
	var catalog := _catalog()
	assert_array(catalog.validate_manifest()).is_empty()
	var ids := catalog.ids()
	assert_int(ids.size()).is_equal(48)
	var unique_ids: Dictionary = {}
	for card_id in ids:
		unique_ids[card_id] = true
	assert_int(unique_ids.size()).is_equal(48)

func test_manifest_has_twelve_months_and_four_cards_each() -> void:
	var catalog := _catalog()
	assert_int(catalog.month_count()).is_equal(12)
	for month in range(1, 13):
		assert_int(catalog.cards_for_month(month).size()).is_equal(4)

func test_five_brights_and_special_named_pieces_are_identifiable() -> void:
	var catalog := _catalog()
	assert_int(catalog.cards_with_tag("bright").size()).is_equal(5)
	assert_int(catalog.cards_with_tag("rain_bright").size()).is_equal(1)
	assert_int(catalog.cards_with_tag("boar").size()).is_equal(1)
	assert_int(catalog.cards_with_tag("deer").size()).is_equal(1)
	assert_int(catalog.cards_with_tag("butterfly").size()).is_equal(1)
	assert_int(catalog.cards_with_tag("poetry_ribbon").size()).is_equal(3)
	assert_int(catalog.cards_with_tag("blue_ribbon").size()).is_equal(3)
	assert_int(catalog.cards_with_tag("lightning_chaff").size()).is_equal(1)
	var curtain := catalog.get_card("m03_cherry_march_curtain")
	assert_bool(curtain.has_tag("bright")).is_true()
	assert_bool(curtain.has_tag("flower_viewing_piece")).is_true()
	var sake := catalog.get_card("m09_chrysanthemum_september_sake_cup")
	assert_bool(sake.has_tag("sake_cup")).is_true()
	assert_bool(sake.has_tag("animal")).is_true()
	assert_bool(sake.has_tag("flower_viewing_piece")).is_true()
	assert_bool(sake.has_tag("moon_viewing_piece")).is_true()
	assert_bool(sake.has_tag("chaff")).is_false()
	var moon := catalog.get_card("m08_pampas_august_moon")
	assert_bool(moon.has_tag("bright")).is_true()
	assert_bool(moon.has_tag("moon_viewing_piece")).is_true()
	var rain := catalog.get_card("m11_willow_november_rain_man")
	assert_bool(rain.has_tag("bright")).is_true()
	assert_bool(rain.has_tag("rain_bright")).is_true()
	var lightning := catalog.get_card("m11_willow_november_lightning_chaff")
	assert_bool(lightning.has_tag("chaff")).is_true()
	assert_bool(lightning.has_tag("lightning_chaff")).is_true()

func test_every_physical_card_resolves_to_face_art() -> void:
	var catalog := _catalog()
	assert_array(catalog.validate_art_assets()).is_empty()
	assert_array(catalog.duplicate_art_mappings()).is_empty()
	for card_id in catalog.ids():
		var definition := catalog.get_card(String(card_id))
		assert_bool(definition.art_path.begins_with("res://assets/cards/")).is_true()
		assert_bool(FileAccess.file_exists(definition.art_path)).is_true()

func test_november_has_a_red_ribbon_and_distinct_face_art() -> void:
	var catalog := _catalog()
	var november := catalog.cards_for_month(11)
	assert_int(november.size()).is_equal(4)
	var ribbon := catalog.get_card("m11_willow_november_chaff")
	assert_str(ribbon.base_class).is_equal("ribbon")
	assert_bool(ribbon.has_tag("red_ribbon")).is_true()
	assert_str(ribbon.art_path).is_equal("res://assets/cards/prototype/thaw/hanafuda/november/willow-red-ribbon.webp")
	assert_bool(FileAccess.file_exists(ribbon.art_path)).is_true()
	assert_str(catalog.get_card("m11_willow_november_lightning_chaff").art_path).is_not_equal(ribbon.art_path)
