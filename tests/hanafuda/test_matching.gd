extends GdUnitTestSuite

var catalog: CardCatalog

func before() -> void:
	catalog = CardCatalog.new()

func test_zero_available_month_matches() -> void:
	var matches := MatchingRules.matching_field_cards(
		"m01_pine_january_crane",
		["m02_plum_february_chaff_a"],
		catalog
	)
	assert_int(matches.size()).is_equal(0)
	assert_str(MatchingRules.resolution_for_matches("m01_pine_january_crane", matches)["kind"]).is_equal("place")

func test_one_available_month_match() -> void:
	var matches := MatchingRules.matching_field_cards(
		"m01_pine_january_crane",
		["m01_pine_january_poetry_ribbon", "m02_plum_february_chaff_a"],
		catalog
	)
	assert_int(matches.size()).is_equal(1)
	assert_str(MatchingRules.resolution_for_matches("m01_pine_january_crane", matches)["kind"]).is_equal("capture_one")

func test_two_matches_expose_two_active_player_choices() -> void:
	var matches := MatchingRules.matching_field_cards(
		"m01_pine_january_crane",
		["m01_pine_january_poetry_ribbon", "m01_pine_january_chaff_a"],
		catalog
	)
	var resolution := MatchingRules.resolution_for_matches("m01_pine_january_crane", matches)
	assert_int(matches.size()).is_equal(2)
	assert_str(resolution["kind"]).is_equal("choose_one")
	assert_int(resolution["choices"].size()).is_equal(2)

func test_three_matches_capture_all_four_cards() -> void:
	var field := [
		"m01_pine_january_poetry_ribbon",
		"m01_pine_january_chaff_a",
		"m01_pine_january_chaff_b"
	]
	var matches := MatchingRules.matching_field_cards("m01_pine_january_crane", field, catalog)
	var resolution := MatchingRules.resolution_for_matches("m01_pine_january_crane", matches)
	assert_int(matches.size()).is_equal(3)
	assert_str(resolution["kind"]).is_equal("capture_all")
	assert_int(resolution["choices"].size()).is_equal(3)
