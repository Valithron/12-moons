extends GdUnitTestSuite

func _catalog() -> CardCatalog:
	return CardCatalog.new()

func test_manifest_has_48_unique_physical_cards() -> void:
	var catalog := _catalog()
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
	var sake := catalog.get_card("m09_chrysanthemum_september_sake_cup")
	assert_bool(sake.has_tag("sake_cup")).is_true()
	assert_bool(sake.has_tag("animal")).is_true()
	assert_bool(sake.has_tag("chaff")).is_false()
