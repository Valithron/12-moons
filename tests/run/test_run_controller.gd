extends GdUnitTestSuite

func _terminal_result(match_id: String = "match_1") -> MatchResult:
	var result := MatchResult.new()
	result.match_id = match_id
	result.source_match_hash = "source_%s" % match_id
	result.month = 1
	result.moon_id = "wolf_moon"
	result.winner_id = 0
	result.player_score = {"final_score": 4, "active_yaku": ["kasu"]}
	result.ai_score = {"final_score": 1, "active_yaku": []}
	return result

func test_accepted_result_ingestion_commits_once() -> void:
	var controller := RunController.new(42)
	var result := controller.ingest_match_result(_terminal_result())
	assert_bool(result.accepted).is_true()
	assert_str(controller.state.phase).is_equal(RunState.PHASE_SETTLEMENT)
	assert_int(controller.state.ingested_match_ids.size()).is_equal(1)
	assert_str(controller.state.last_match_result.get("match_id", "")).is_equal("match_1")
	assert_int(controller.journal.entries.size()).is_equal(1)

func test_rejected_action_does_not_change_run_hash() -> void:
	var controller := RunController.new(42)
	var before := controller.state.state_hash()
	var rejected := controller.submit_action(RunAction.new(RunAction.SETTLE))
	assert_bool(rejected.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)
	assert_int(controller.journal.entries.size()).is_equal(0)

func test_duplicate_result_is_rejected_without_hash_change() -> void:
	var controller := RunController.new(42)
	var first := _terminal_result()
	assert_bool(controller.ingest_match_result(first).accepted).is_true()
	var before := controller.state.state_hash()
	var duplicate := controller.ingest_match_result(first)
	assert_bool(duplicate.accepted).is_false()
	assert_str(controller.state.state_hash()).is_equal(before)

func test_non_terminal_game_state_cannot_enter_run_layer() -> void:
	var controller := RunController.new(42)
	var match_state := GameState.fresh(42, CardCatalog.new())
	var result := controller.ingest_terminal_game_state(match_state)
	assert_bool(result.accepted).is_false()
