extends GdUnitTestSuite

func test_fresh_run_uses_prototype_defaults() -> void:
	var state := RunState.fresh(1234)
	assert_int(state.month).is_equal(1)
	assert_str(state.phase).is_equal(RunState.PHASE_MONTH_MATCH)
	assert_int(state.bankroll).is_equal(20)
	assert_int(state.unlocked_active_capacity).is_equal(0)
	assert_int(state.reserve_capacity).is_equal(4)
	assert_str(state.rules().reward_policy).is_equal(RunRules.REWARD_POLICY_WHOLE_POOL)
	assert_str(state.rules().duplicate_modifier_policy).is_equal("unique_definition")
	assert_bool(state.invariants_ok()).is_true()

func test_run_state_round_trip_and_hash_are_stable() -> void:
	var state := RunState.fresh(77)
	state.last_event = {"kind": "test", "value": 3}
	var restored := RunState.from_dict(state.to_dict())
	assert_str(restored.canonical_json()).is_equal(state.canonical_json())
	assert_str(restored.state_hash()).is_equal(state.state_hash())

func test_invalid_run_state_reports_capacity_and_bankroll_errors() -> void:
	var state := RunState.fresh(1)
	state.bankroll = -1
	state.unlocked_active_capacity = 9
	var errors := state.invariant_errors()
	assert_bool(errors.any(func(error: String) -> bool: return error.contains("negative"))).is_true()
	assert_bool(errors.any(func(error: String) -> bool: return error.contains("capacity"))).is_true()

func test_deterministic_rng_scopes_are_stable_and_isolated() -> void:
	var first := DeterministicRng.scope_seed(99, "reward", 1, "generation")
	var second := DeterministicRng.scope_seed(99, "reward", 1, "generation")
	var other := DeterministicRng.scope_seed(99, "shop", 1, "initial")
	assert_int(first).is_equal(second)
	assert_bool(first != other).is_true()
