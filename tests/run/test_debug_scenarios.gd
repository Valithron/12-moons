extends GdUnitTestSuite

func test_all_required_debug_scenarios_are_valid_and_stable() -> void:
	for scenario in DebugScenarioFactory.SCENARIOS:
		var first := DebugScenarioFactory.create_controller(String(scenario), 404)
		var second := DebugScenarioFactory.create_controller(String(scenario), 404)
		assert_bool(first.state.invariants_ok(null, first.modifier_registry)).is_true()
		assert_str(first.state.state_hash()).is_equal(second.state.state_hash())
		var inspection := DebugScenarioFactory.inspect(first)
		assert_int(int(inspection.get("root_seed", 0))).is_equal(404)
		assert_str(String(inspection.get("phase", ""))).is_equal(first.state.phase)

func test_scenario_mutations_use_normal_actions() -> void:
	var controller := DebugScenarioFactory.create_controller("initial_shop", 505)
	assert_str(controller.state.phase).is_equal(RunState.PHASE_SHOP)
	var before := controller.state.state_hash()
	var rejected := controller.submit_action(RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": "unique_definition"}))
	assert_bool(rejected.accepted).is_true()
	assert_bool(before != controller.state.state_hash()).is_true()
