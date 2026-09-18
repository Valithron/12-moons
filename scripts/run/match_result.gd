class_name MatchResult
extends RefCounted

var match_id: String = ""
var source_match_hash: String = ""
var month: int = 1
var moon_id: String = ""
var winner_id: int = -1
var ended_by: String = ""
var stop_player_id: int = -1
var player_score: Dictionary = {}
var ai_score: Dictionary = {}
var koi_koi_declared: bool = false

static func from_game_state(game_state: GameState) -> MatchResult:
	var result := MatchResult.new()
	result.source_match_hash = game_state.state_hash()
	result.match_id = "match_%s" % result.source_match_hash.substr(0, 16)
	var terminal := game_state.terminal_result.duplicate(true)
	result.month = int(terminal.get("month", game_state.month))
	result.moon_id = String(terminal.get("moon_id", game_state.moon_id))
	result.winner_id = int(terminal.get("winner_id", -1))
	result.ended_by = String(terminal.get("ended_by", ""))
	result.stop_player_id = int(terminal.get("stop_player_id", -1))
	var scores: Array = Array(terminal.get("player_scores", []))
	if scores.size() > 0:
		if scores[0] is Dictionary:
			result.player_score = scores[0].duplicate(true)
	if scores.size() > 1:
		if scores[1] is Dictionary:
			result.ai_score = scores[1].duplicate(true)
	result.koi_koi_declared = bool(terminal.get("koi_koi_declared", false))
	return result

static func from_dict(data: Dictionary) -> MatchResult:
	var result := MatchResult.new()
	result.match_id = String(data.get("match_id", ""))
	result.source_match_hash = String(data.get("source_match_hash", ""))
	result.month = int(data.get("month", 1))
	result.moon_id = String(data.get("moon_id", ""))
	result.winner_id = int(data.get("winner_id", -1))
	result.ended_by = String(data.get("ended_by", ""))
	result.stop_player_id = int(data.get("stop_player_id", -1))
	var raw_player_score = data.get("player_score", {})
	if raw_player_score is Dictionary:
		result.player_score = raw_player_score.duplicate(true)
	var raw_ai_score = data.get("ai_score", {})
	if raw_ai_score is Dictionary:
		result.ai_score = raw_ai_score.duplicate(true)
	result.koi_koi_declared = bool(data.get("koi_koi_declared", false))
	return result

func resolved_player_score() -> int:
	return int(player_score.get("final_score", 0))

func resolved_ai_score() -> int:
	return int(ai_score.get("final_score", 0))

func to_dict() -> Dictionary:
	return {
		"match_id": match_id,
		"source_match_hash": source_match_hash,
		"month": month,
		"moon_id": moon_id,
		"winner_id": winner_id,
		"ended_by": ended_by,
		"stop_player_id": stop_player_id,
		"player_score": player_score.duplicate(true),
		"ai_score": ai_score.duplicate(true),
		"koi_koi_declared": koi_koi_declared
	}

func valid_terminal_result() -> bool:
	return not match_id.is_empty() and not source_match_hash.is_empty() and month >= 1 and not player_score.is_empty() and not ai_score.is_empty()
