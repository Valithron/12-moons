class_name YakuEvaluator
extends RefCounted

static func evaluate(captured_ids: Array, catalog: CardCatalog, moon_id: String = "") -> Dictionary:
	var tag_counts: Dictionary = {}
	var chaff_count := 0
	var ribbon_count := 0
	var animal_count := 0
	var bright_count := 0
	var non_rain_bright_count := 0

	for raw_id in captured_ids:
		var definition := catalog.get_card(String(raw_id))
		if definition == null:
			continue
		for raw_tag in definition.tags:
			var tag := String(raw_tag)
			tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
		if definition.base_class == "chaff":
			chaff_count += 2 if definition.has_tag("lightning_chaff") else 1
		elif definition.base_class == "ribbon":
			ribbon_count += 1
		elif definition.base_class == "animal":
			animal_count += 1
		if definition.has_tag("bright"):
			bright_count += 1
			if not definition.has_tag("rain_bright"):
				non_rain_bright_count += 1

	var yaku: Array = []
	var normal_additive := 0
	var moon_bonus := 0

	if chaff_count >= 10:
		var normal_chaff := 1 + (chaff_count - 10)
		var scored_chaff := normal_chaff
		if moon_id == "wolf_moon":
			scored_chaff *= 2
		moon_bonus += scored_chaff - normal_chaff
		normal_additive += normal_chaff
		yaku.append({
			"id": "kasu",
			"name": "Kasu / Chaff",
			"count": chaff_count,
			"base_points": normal_chaff,
			"points": scored_chaff
		})

	if ribbon_count >= 5:
		var ribbon_points := 1 + (ribbon_count - 5)
		normal_additive += ribbon_points
		yaku.append({
			"id": "generic_ribbons",
			"name": "Tanzaku / Ribbons",
			"count": ribbon_count,
			"base_points": ribbon_points,
			"points": ribbon_points
		})

	if animal_count >= 5:
		var animal_points := 1 + (animal_count - 5)
		normal_additive += animal_points
		yaku.append({
			"id": "generic_animals",
			"name": "Tane / Seeds & Animals",
			"count": animal_count,
			"base_points": animal_points,
			"points": animal_points
		})

	if int(tag_counts.get("poetry_ribbon", 0)) >= 3:
		normal_additive += 5
		yaku.append({
			"id": "akatan",
			"name": "Akatan / Poetry Ribbons",
			"count": 3,
			"base_points": 5,
			"points": 5
		})

	if int(tag_counts.get("blue_ribbon", 0)) >= 3:
		normal_additive += 5
		yaku.append({
			"id": "aotan",
			"name": "Aotan / Blue Ribbons",
			"count": 3,
			"base_points": 5,
			"points": 5
		})

	if int(tag_counts.get("boar", 0)) > 0 and int(tag_counts.get("deer", 0)) > 0 and int(tag_counts.get("butterfly", 0)) > 0:
		normal_additive += 5
		yaku.append({
			"id": "ino_shika_cho",
			"name": "Ino-Shika-Cho",
			"count": 3,
			"base_points": 5,
			"points": 5
		})

	if int(tag_counts.get("flower_viewing_piece", 0)) >= 2:
		normal_additive += 5
		yaku.append({
			"id": "hanami_zake",
			"name": "Hanami-zake / Flower Viewing",
			"count": 2,
			"base_points": 5,
			"points": 5
		})

	if int(tag_counts.get("moon_viewing_piece", 0)) >= 2:
		normal_additive += 5
		yaku.append({
			"id": "tsukimi_zake",
			"name": "Tsukimi-zake / Moon Viewing",
			"count": 2,
			"base_points": 5,
			"points": 5
		})

	var bright_yaku: Dictionary = {}
	if bright_count >= 5:
		bright_yaku = {
			"id": "five_brights",
			"name": "Goko / Five Brights",
			"count": bright_count,
			"base_points": 10,
			"points": 10
		}
	elif bright_count >= 4 and non_rain_bright_count == 4:
		bright_yaku = {
			"id": "four_brights",
			"name": "Shiko / Four Brights",
			"count": bright_count,
			"base_points": 8,
			"points": 8
		}
	elif bright_count >= 4 and non_rain_bright_count == 3:
		bright_yaku = {
			"id": "ame_shiko",
			"name": "Ame-Shiko / Rainy Four Brights",
			"count": bright_count,
			"base_points": 7,
			"points": 7
		}
	elif non_rain_bright_count >= 3:
		bright_yaku = {
			"id": "sanko",
			"name": "Sanko / Three Brights",
			"count": non_rain_bright_count,
			"base_points": 5,
			"points": 5
		}
	if not bright_yaku.is_empty():
		normal_additive += int(bright_yaku["points"])
		yaku.append(bright_yaku)

	var additive_subtotal := normal_additive + moon_bonus
	var active_yaku: Array = []
	for entry in yaku:
		active_yaku.append(String(entry["id"]))
	return {
		"yaku": yaku,
		"active_yaku": active_yaku,
		"chaff_count": chaff_count,
		"ribbon_count": ribbon_count,
		"animal_count": animal_count,
		"bright_count": bright_count,
		"normal_additive_subtotal": normal_additive,
		"moon_additive_bonus": moon_bonus,
		"additive_subtotal": additive_subtotal,
		"seven_plus_multiplier": 1,
		"koi_koi_multiplier": 1,
		"score_after_seven_plus": additive_subtotal,
		"final_score": additive_subtotal,
		"moon_id": moon_id
	}

static func settle(player_captured_ids: Array, ai_captured_ids: Array, catalog: CardCatalog, moon_id: String = "", koi_koi_declared: bool = false) -> Dictionary:
	var player_score := evaluate(player_captured_ids, catalog, moon_id)
	var ai_score := evaluate(ai_captured_ids, catalog, moon_id)
	_apply_seven_plus(player_score)
	_apply_seven_plus(ai_score)

	var winner_id := -1
	if int(player_score["score_after_seven_plus"]) > int(ai_score["score_after_seven_plus"]):
		winner_id = 0
	elif int(ai_score["score_after_seven_plus"]) > int(player_score["score_after_seven_plus"]):
		winner_id = 1

	var koi_multiplier := 1
	if koi_koi_declared and winner_id != -1:
		koi_multiplier = 2
		var winner_score: Dictionary = player_score if winner_id == 0 else ai_score
		winner_score["koi_koi_multiplier"] = koi_multiplier
		winner_score["final_score"] = int(winner_score["score_after_seven_plus"]) * koi_multiplier

	player_score["final_score"] = int(player_score["final_score"])
	ai_score["final_score"] = int(ai_score["final_score"])
	return {
		"player_scores": [player_score, ai_score],
		"winner_id": winner_id,
		"koi_koi_declared": koi_koi_declared,
		"koi_koi_multiplier": koi_multiplier,
		"tie": winner_id == -1
	}

static func _apply_seven_plus(score: Dictionary) -> void:
	var subtotal := int(score["additive_subtotal"])
	var multiplier := 2 if subtotal >= 7 else 1
	score["seven_plus_multiplier"] = multiplier
	score["score_after_seven_plus"] = subtotal * multiplier
	score["final_score"] = score["score_after_seven_plus"]

static func is_improvement(previous: Dictionary, current: Dictionary) -> bool:
	if current.is_empty():
		return false
	if previous.is_empty():
		return not Array(current.get("active_yaku", [])).is_empty()
	if int(current.get("additive_subtotal", 0)) > int(previous.get("additive_subtotal", 0)):
		return true
	var previous_yaku: Dictionary = {}
	for yaku_id in previous.get("active_yaku", []):
		previous_yaku[String(yaku_id)] = true
	for yaku_id in current.get("active_yaku", []):
		if not previous_yaku.has(String(yaku_id)):
			return true
	return false
