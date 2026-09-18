extends Control

signal february_placeholder_reached

var run_controller: RunController
var match_result: MatchResult
var root_column: VBoxContainer
var content_column: VBoxContainer
var status_label: Label
var focus_key: String = ""

const BACKGROUND := Color(0.045, 0.075, 0.11)
const GOLD := Color(0.95, 0.84, 0.56)
const TEXT := Color(0.91, 0.90, 0.82)
const MUTED := Color(0.70, 0.78, 0.84)
const ERROR := Color(1.0, 0.56, 0.47)

func configure(controller: RunController, result: MatchResult = null) -> void:
	run_controller = controller
	match_result = result
	if is_inside_tree():
		_render()

func _ready() -> void:
	if run_controller != null:
		_render()

func _render() -> void:
	for child in get_children():
		child.queue_free()
	var profile := MonthPresentationProfile.february_placeholder() if run_controller != null and run_controller.state.phase == RunState.PHASE_FEBRUARY_PLACEHOLDER else MonthPresentationProfile.january()
	var background := ColorRect.new()
	background.color = profile.background
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	root_column = VBoxContainer.new()
	root_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	root_column.add_theme_constant_override("separation", 12)
	add_child(root_column)
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 72)
	root_column.add_child(header)
	_add_label(header, "12 MOONS  •  BETWEEN MONTH", 26, GOLD, true)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	if run_controller != null:
		_add_label(header, "BANKROLL  $%d" % run_controller.state.bankroll, 18, TEXT, false)
	var rail := HBoxContainer.new()
	rail.custom_minimum_size = Vector2(0, 36)
	rail.add_theme_constant_override("separation", 6)
	root_column.add_child(rail)
	for phase in [RunState.PHASE_SETTLEMENT, RunState.PHASE_LIQUIDATION, RunState.PHASE_REWARD, RunState.PHASE_CARRY, RunState.PHASE_SHOP, RunState.PHASE_FINALIZE, RunState.PHASE_TRANSITION]:
		var phase_label := Label.new()
		phase_label.text = ("▶ " if run_controller != null and run_controller.state.phase == phase else "") + phase.to_upper().replace("_", " ")
		phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		phase_label.add_theme_font_size_override("font_size", 12)
		phase_label.add_theme_color_override("font_color", GOLD if run_controller != null and run_controller.state.phase == phase else MUTED)
		rail.add_child(phase_label)
	root_column.add_child(HSeparator.new())
	content_column = VBoxContainer.new()
	content_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_column.add_theme_constant_override("separation", 10)
	root_column.add_child(content_column)
	if run_controller == null:
		_add_body("No run is loaded.", ERROR)
		return
	_add_label(content_column, _phase_title(), 28, GOLD, true)
	_add_label(content_column, "Active %d/%d   •   Reserve %d/%d" % [run_controller.state.active_count(), run_controller.state.unlocked_active_capacity, run_controller.state.reserve_count(), run_controller.state.reserve_capacity], 16, MUTED, false)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 42)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", TEXT)
	content_column.add_child(status_label)
	_render_phase()

func _phase_title() -> String:
	match run_controller.state.phase:
		RunState.PHASE_SETTLEMENT: return "JANUARY SETTLEMENT"
		RunState.PHASE_LIQUIDATION: return "LIQUIDATION"
		RunState.PHASE_REWARD: return "REWARD"
		RunState.PHASE_CARRY: return "CARRY PREPARATION"
		RunState.PHASE_SHOP: return "SHOP"
		RunState.PHASE_FINALIZE: return "FINALIZE BUILD"
		RunState.PHASE_TRANSITION: return "MONTH TRANSITION"
		RunState.PHASE_FEBRUARY_PLACEHOLDER: return "FEBRUARY PLACEHOLDER"
	return run_controller.state.phase.to_upper().replace("_", " ")

func _render_phase() -> void:
	match run_controller.state.phase:
		RunState.PHASE_SETTLEMENT:
			var result := MatchResult.from_dict(run_controller.state.last_match_result)
			status_label.text = "January result committed: YOU %d  •  OPPONENT %d. Resolve the settlement to update bankroll and unlock the next active slot." % [result.resolved_player_score(), result.resolved_ai_score()]
			_add_action("SETTLE JANUARY", "settle", RunAction.new(RunAction.SETTLE))
		RunState.PHASE_LIQUIDATION:
			var pending := PendingSettlement.from_dict(run_controller.state.pending_settlement)
			status_label.text = "January loss requires $%d more to settle. %d owned modifier(s) remain available for an approved liquidation quote. The run is stopped at BM-B05 rather than guessing a sale value." % [pending.amount_due, run_controller.state.active_count() + run_controller.state.reserve_count()]
			status_label.add_theme_color_override("font_color", ERROR)
		RunState.PHASE_REWARD:
			var reward := RewardState.from_dict(run_controller.state.reward_state)
			if not reward.generated:
				var rules := run_controller.state.rules()
				if rules.reward_policy.is_empty() or rules.duplicate_modifier_policy.is_empty():
					status_label.text = "Reward offers cannot be generated until Sterling selects the reward policy and duplicate policy (BM-B01/BM-B02)."
					status_label.add_theme_color_override("font_color", ERROR)
				else:
					status_label.text = "The configured reward policy is ready to generate deterministic persisted offers."
					_add_action("GENERATE REWARD", "generate_reward", RunAction.new(RunAction.GENERATE_REWARD))
			else:
				status_label.text = "Choose one persisted offer or refuse it for the configured cash value."
				for raw_offer in reward.offers:
					var offer := RewardOffer.from_dict(raw_offer)
					_add_action("%s  [%s]" % [offer.definition_id, offer.offer_id], "reward_%s" % offer.offer_id, RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer.offer_id}))
				if not reward.selection_committed:
					_add_action("REFUSE REWARD", "refuse_reward", RunAction.new(RunAction.REFUSE_REWARD))
		RunState.PHASE_CARRY:
			status_label.text = "Select a modifier, inspect its description, then choose an active or reserve destination. Drag is optional; the action is authoritative."
			_render_carry()
			_add_action("OPEN SIX-SLOT SHOP", "enter_shop", RunAction.new(RunAction.ENTER_SHOP, 0, {"duplicate_policy": ""}))
		RunState.PHASE_SHOP:
			_render_shop()
		RunState.PHASE_FINALIZE:
			status_label.text = "Review active and reserve placement before committing the January build."
			_add_action("FINALIZE BUILD", "finalize", RunAction.new(RunAction.FINALIZE_BUILD))
		RunState.PHASE_TRANSITION:
			status_label.text = "The committed January build crosses the month boundary."
			_add_action("BEGIN FEBRUARY", "february", RunAction.new(RunAction.BEGIN_FEBRUARY))
		RunState.PHASE_FEBRUARY_PLACEHOLDER:
			status_label.text = "Snow Moon placeholder reached. February gameplay is explicitly deferred by the roadmap."
			status_label.add_theme_color_override("font_color", MUTED)
			february_placeholder_reached.emit()

func _render_shop() -> void:
	var shop := ShopState.from_dict(run_controller.state.shop_state)
	status_label.text = "Offers persist until purchased or rerolled. Routine transactions stay quiet and keep the carry tray visible."
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content_column.add_child(grid)
	for raw_offer in shop.offers:
		var offer := ShopOffer.from_dict(raw_offer)
		var button := Button.new()
		button.name = "Shop_%s" % offer.slot_id
		button.text = "%s\n%s\n%s" % [offer.slot_id.to_upper().replace("_", " "), offer.definition_id if offer.available else "UNAVAILABLE", ("$%d" % offer.price) if offer.available else "policy/content pending"]
		button.custom_minimum_size = Vector2(0, 84)
		button.disabled = not offer.available or offer.consumed
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(func(): _submit(RunAction.new(RunAction.BUY_OFFER, 0, {"offer_id": offer.offer_id}), "shop_%s" % offer.offer_id))
		grid.add_child(button)
	_add_label(content_column, "OWNED MODIFIERS", 18, GOLD, false)
	_render_shop_owned(run_controller.state.active_modifier_ids)
	_render_shop_owned(run_controller.state.reserve_modifier_ids)
	_add_action("REROLL SHOP", "reroll", RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": ""}))
	_add_action("EXIT SHOP", "exit_shop", RunAction.new(RunAction.EXIT_SHOP))

func _render_shop_owned(instance_ids: Array) -> void:
	for raw_instance_id in instance_ids:
		var instance_id := String(raw_instance_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_add_label(row, _modifier_description(instance_id), 15, TEXT, true)
		var action_key := "sell_%s" % instance_id
		var sell_button := Button.new()
		sell_button.text = "SELL"
		sell_button.custom_minimum_size = Vector2(120, 42)
		sell_button.focus_mode = Control.FOCUS_ALL
		var action := RunAction.new(RunAction.SELL_MODIFIER, 0, {"instance_id": instance_id})
		sell_button.pressed.connect(func() -> void: _submit(action, action_key))
		row.add_child(sell_button)
		content_column.add_child(row)
		if focus_key == action_key:
			sell_button.call_deferred("grab_focus")

func _render_carry() -> void:
	_add_label(content_column, "ACTIVE MODIFIERS", 18, GOLD, false)
	_render_modifier_location(run_controller.state.active_modifier_ids, "reserve")
	_add_label(content_column, "RESERVE MODIFIERS", 18, GOLD, false)
	_render_modifier_location(run_controller.state.reserve_modifier_ids, "active")

func _render_modifier_location(instance_ids: Array, destination: String) -> void:
	if instance_ids.is_empty():
		_add_label(content_column, "Empty", 15, MUTED, false)
		return
	for raw_instance_id in instance_ids:
		var instance_id := String(raw_instance_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var description := _modifier_description(instance_id)
		_add_label(row, description, 15, TEXT, true)
		var action_key := "move_%s_%s" % [instance_id, destination]
		var move_button := Button.new()
		move_button.text = "MOVE TO %s" % destination.to_upper()
		move_button.custom_minimum_size = Vector2(180, 42)
		move_button.focus_mode = Control.FOCUS_ALL
		var action := RunAction.new(RunAction.MOVE_MODIFIER, 0, {"instance_id": instance_id, "destination": destination})
		move_button.pressed.connect(func() -> void: _submit(action, action_key))
		row.add_child(move_button)
		content_column.add_child(row)
		if focus_key == action_key:
			move_button.call_deferred("grab_focus")

func _modifier_description(instance_id: String) -> String:
	var raw_instance = run_controller.state.modifier_instances.get(instance_id, {})
	if not raw_instance is Dictionary:
		return instance_id
	var definition_id := String(raw_instance.get("definition_id", instance_id))
	var registry: ModifierRegistry = run_controller.modifier_registry
	if registry != null and registry.has_definition(definition_id):
		var definition := registry.get_definition(definition_id)
		return "%s — %s" % [definition_id, definition.description]
	return definition_id

func _add_action(text_value: String, key: String, action: RunAction) -> void:
	var button := Button.new()
	button.name = "Action_%s" % key
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(func(): _submit(action, key))
	content_column.add_child(button)
	if focus_key == key:
		button.call_deferred("grab_focus")

func _submit(action: RunAction, key: String = "") -> void:
	focus_key = key
	var result := run_controller.submit_action(action)
	if not result.accepted:
		if status_label != null:
			status_label.text = result.reason
			status_label.add_theme_color_override("font_color", ERROR)
		return
	_render()

func _add_body(text_value: String, color: Color) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	content_column.add_child(label)

func _add_label(parent: Node, text_value: String, font_size: int, color: Color, expand: bool) -> void:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
