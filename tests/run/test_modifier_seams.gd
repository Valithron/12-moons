extends GdUnitTestSuite

func test_capture_plan_and_score_breakdown_preserve_physical_identity() -> void:
	var plan := CapturePlan.new()
	plan.played_card_id = "m01_pine_january_crane"
	plan.captured_card_ids = ["m01_pine_january_crane", "m01_pine_january_poetry_ribbon"]
	assert_array(plan.invariant_errors()).is_empty()
	var score := ScoreBreakdown.new()
	score.additive_subtotal = 5
	score.add_card_bonus("m01_pine_january_chaff_a", 1, "synthetic_upgrade")
	assert_int(score.final_score).is_equal(6)
	assert_int(score.card_contributions["m01_pine_january_chaff_a"]).is_equal(1)

func test_seam_registry_orders_handlers_and_rejects_conflicting_replacements() -> void:
	var registry := ModifierEffectRegistry.new()
	registry.register_handler(ModifierEffectRegistry.SEAM_CAPTURE_PLAN, "sweep", 20)
	registry.register_handler(ModifierEffectRegistry.SEAM_CAPTURE_PLAN, "test_capture", 10)
	assert_str(registry.handlers_for(ModifierEffectRegistry.SEAM_CAPTURE_PLAN)[0].get("handler_id", "")).is_equal("test_capture")
	registry.register_handler(ModifierEffectRegistry.SEAM_MULTIPLIER_REPLACEMENT, "quad_koi", 10, "koi_koi_multiplier")
	registry.register_handler(ModifierEffectRegistry.SEAM_MULTIPLIER_REPLACEMENT, "other", 20, "koi_koi_multiplier")
	assert_bool(registry.validate().is_empty()).is_false()

func test_reserve_modifier_does_not_project_active_seams() -> void:
	var run := RunController.new(5)
	run.state.phase = RunState.PHASE_CARRY
	run.state.unlocked_active_capacity = 1
	run.state.modifier_instances["active"] = {"instance_id": "active", "definition_id": "sweep_seam", "location": "active"}
	run.state.modifier_instances["reserved"] = {"instance_id": "reserved", "definition_id": "sweep_seam", "location": "reserve"}
	run.state.active_modifier_ids = ["active"]
	run.state.reserve_modifier_ids = ["reserved"]
	var seams := ModifierEffectRegistry.new().active_effect_seams(run.state, run.modifier_registry)
	assert_bool(seams.has(ModifierEffectRegistry.SEAM_CAPTURE_PLAN)).is_true()
	run.state.active_modifier_ids.clear()
	seams = ModifierEffectRegistry.new().active_effect_seams(run.state, run.modifier_registry)
	assert_bool(seams.has(ModifierEffectRegistry.SEAM_CAPTURE_PLAN)).is_false()
