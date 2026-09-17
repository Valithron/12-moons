extends GdUnitTestSuite

var catalog: CardCatalog

func before() -> void:
	catalog = CardCatalog.new()

func _score(ids: Array, moon_id: String = "") -> Dictionary:
	return YakuEvaluator.evaluate(ids, catalog, moon_id)

func _has_yaku(score: Dictionary, yaku_id: String) -> bool:
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		if String(entry.get("id", "")) == yaku_id:
			return true
	return false

func _points(score: Dictionary, yaku_id: String) -> int:
	for raw_entry in Array(score.get("yaku", [])):
		var entry: Dictionary = raw_entry
		if String(entry.get("id", "")) == yaku_id:
			return int(entry.get("points", 0))
	return 0

func _chaff_ten() -> Array:
	return [
		"m01_pine_january_chaff_a", "m01_pine_january_chaff_b",
		"m02_plum_february_chaff_a", "m02_plum_february_chaff_b",
		"m03_cherry_march_chaff_a", "m03_cherry_march_chaff_b",
		"m04_wisteria_april_chaff_a", "m04_wisteria_april_chaff_b",
		"m05_iris_may_chaff_a", "m05_iris_may_chaff_b"
	]

func test_ten_chaff_and_additional_chaff() -> void:
	var ten := _score(_chaff_ten())
	assert_int(ten["chaff_count"]).is_equal(10)
	assert_int(_points(ten, "kasu")).is_equal(1)
	var eleven_ids := _chaff_ten()
	eleven_ids.append("m06_peony_june_chaff_a")
	var eleven := _score(eleven_ids)
	assert_int(eleven["chaff_count"]).is_equal(11)
	assert_int(_points(eleven, "kasu")).is_equal(2)

func test_lightning_chaff_counts_twice_and_sake_is_not_chaff() -> void:
	var lightning_ids := [
		"m01_pine_january_chaff_a", "m01_pine_january_chaff_b",
		"m02_plum_february_chaff_a", "m02_plum_february_chaff_b",
		"m03_cherry_march_chaff_a", "m03_cherry_march_chaff_b",
		"m04_wisteria_april_chaff_a", "m04_wisteria_april_chaff_b",
		"m11_willow_november_lightning_chaff"
	]
	var lightning := _score(lightning_ids)
	assert_int(lightning["chaff_count"]).is_equal(10)
	assert_int(_points(lightning, "kasu")).is_equal(1)
	var nine_plus_sake := [
		"m01_pine_january_chaff_a", "m01_pine_january_chaff_b",
		"m02_plum_february_chaff_a", "m02_plum_february_chaff_b",
		"m03_cherry_march_chaff_a", "m03_cherry_march_chaff_b",
		"m04_wisteria_april_chaff_a", "m04_wisteria_april_chaff_b",
		"m05_iris_may_chaff_a",
		"m09_chrysanthemum_september_sake_cup"
	]
	var sake_score := _score(nine_plus_sake)
	assert_int(sake_score["chaff_count"]).is_equal(9)
	assert_bool(_has_yaku(sake_score, "kasu")).is_false()
	assert_int(sake_score["animal_count"]).is_equal(1)

func test_generic_ribbons_and_animals_stack_with_extras() -> void:
	var ribbons := _score([
		"m01_pine_january_poetry_ribbon", "m02_plum_february_poetry_ribbon",
		"m03_cherry_march_poetry_ribbon", "m04_wisteria_april_ribbon",
		"m05_iris_may_ribbon", "m06_peony_june_blue_ribbon"
	])
	assert_int(_points(ribbons, "generic_ribbons")).is_equal(2)
	var animals := _score([
		"m02_plum_february_uguisu", "m04_wisteria_april_cuckoo",
		"m05_iris_may_eight_plank_bridge", "m06_peony_june_butterfly",
		"m07_clover_july_boar", "m08_pampas_august_geese"
	])
	assert_int(_points(animals, "generic_animals")).is_equal(2)

func test_named_ribbon_yaku_and_combination_stack() -> void:
	var poetry := _score([
		"m01_pine_january_poetry_ribbon", "m02_plum_february_poetry_ribbon",
		"m03_cherry_march_poetry_ribbon"
	])
	assert_int(_points(poetry, "akatan")).is_equal(5)
	var blue := _score([
		"m06_peony_june_blue_ribbon", "m09_chrysanthemum_september_blue_ribbon",
		"m10_maple_october_blue_ribbon"
	])
	assert_int(_points(blue, "aotan")).is_equal(5)
	var both := _score([
		"m01_pine_january_poetry_ribbon", "m02_plum_february_poetry_ribbon",
		"m03_cherry_march_poetry_ribbon",
		"m06_peony_june_blue_ribbon", "m09_chrysanthemum_september_blue_ribbon",
		"m10_maple_october_blue_ribbon"
	])
	assert_bool(_has_yaku(both, "akatan")).is_true()
	assert_bool(_has_yaku(both, "aotan")).is_true()
	assert_int(_points(both, "generic_ribbons")).is_equal(2)
	assert_int(both["additive_subtotal"]).is_equal(12)

func test_ino_shika_cho_and_viewing_yaku() -> void:
	var animals := _score([
		"m06_peony_june_butterfly", "m07_clover_july_boar", "m10_maple_october_deer"
	])
	assert_int(_points(animals, "ino_shika_cho")).is_equal(5)
	var flower := _score([
		"m03_cherry_march_curtain", "m09_chrysanthemum_september_sake_cup"
	])
	assert_int(_points(flower, "hanami_zake")).is_equal(5)
	var moon := _score([
		"m08_pampas_august_moon", "m09_chrysanthemum_september_sake_cup"
	])
	assert_int(_points(moon, "tsukimi_zake")).is_equal(5)
	var both := _score([
		"m03_cherry_march_curtain", "m08_pampas_august_moon",
		"m09_chrysanthemum_september_sake_cup"
	])
	assert_bool(_has_yaku(both, "hanami_zake")).is_true()
	assert_bool(_has_yaku(both, "tsukimi_zake")).is_true()
	assert_int(both["additive_subtotal"]).is_equal(10)

func test_bright_yaku_are_mutually_exclusive_and_rain_is_excluded_from_three() -> void:
	var three := _score([
		"m01_pine_january_crane", "m03_cherry_march_curtain",
		"m12_paulownia_december_phoenix"
	])
	assert_int(_points(three, "sanko")).is_equal(5)
	assert_bool(_has_yaku(three, "ame_shiko")).is_false()
	var rainy_four := _score([
		"m01_pine_january_crane", "m03_cherry_march_curtain",
		"m12_paulownia_december_phoenix", "m11_willow_november_rain_man"
	])
	assert_int(_points(rainy_four, "ame_shiko")).is_equal(7)
	assert_bool(_has_yaku(rainy_four, "sanko")).is_false()
	var four := _score([
		"m01_pine_january_crane", "m03_cherry_march_curtain",
		"m08_pampas_august_moon", "m12_paulownia_december_phoenix"
	])
	assert_int(_points(four, "four_brights")).is_equal(8)
	var five := _score([
		"m01_pine_january_crane", "m03_cherry_march_curtain",
		"m08_pampas_august_moon", "m11_willow_november_rain_man",
		"m12_paulownia_december_phoenix"
	])
	assert_int(_points(five, "five_brights")).is_equal(10)
	assert_int(five["active_yaku"].size()).is_equal(1)

func test_wolf_moon_only_doubles_chaff_contribution() -> void:
	var base := _score(_chaff_ten())
	var wolf := _score(_chaff_ten(), "wolf_moon")
	assert_int(base["normal_additive_subtotal"]).is_equal(1)
	assert_int(base["moon_additive_bonus"]).is_equal(0)
	assert_int(wolf["chaff_count"]).is_equal(10)
	assert_int(wolf["moon_additive_bonus"]).is_equal(1)
	assert_int(wolf["additive_subtotal"]).is_equal(2)
	var eleven_ids := _chaff_ten()
	eleven_ids.append("m06_peony_june_chaff_a")
	var wolf_eleven := _score(eleven_ids, "wolf_moon")
	assert_int(_points(wolf_eleven, "kasu")).is_equal(4)

func test_settlement_applies_seven_plus_then_one_koi_koi_multiplier() -> void:
	var player_ids := _chaff_ten()
	player_ids.append_array([
		"m01_pine_january_crane", "m03_cherry_march_curtain",
		"m12_paulownia_december_phoenix",
		"m02_plum_february_uguisu", "m04_wisteria_april_cuckoo",
		"m05_iris_may_eight_plank_bridge", "m06_peony_june_butterfly",
		"m07_clover_july_boar"
	])
	var settlement := YakuEvaluator.settle(player_ids, [], catalog, "", true)
	var player_score: Dictionary = settlement["player_scores"][0]
	assert_int(settlement["winner_id"]).is_equal(0)
	assert_int(player_score["additive_subtotal"]).is_equal(7)
	assert_int(player_score["seven_plus_multiplier"]).is_equal(2)
	assert_int(player_score["score_after_seven_plus"]).is_equal(14)
	assert_int(player_score["koi_koi_multiplier"]).is_equal(2)
	assert_int(player_score["final_score"]).is_equal(28)
