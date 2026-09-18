extends Control

signal february_placeholder_reached

var run_controller: RunController
var match_result: MatchResult
var root_column: VBoxContainer
var content_column: VBoxContainer
var shop_content_column: VBoxContainer
var shop_scroll: ScrollContainer
var shop_action_bar: HBoxContainer
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
		RunState.PHASE_BANKRUPT: return "BANKRUPT"
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
			status_label.text = "January loss requires $%d more. Select an owned modifier to liquidate at its authoritative resale value." % pending.amount_due
			status_label.add_theme_color_override("font_color", ERROR)
			_render_liquidation()
		RunState.PHASE_REWARD:
			var reward := RewardState.from_dict(run_controller.state.reward_state)
			if not reward.generated:
				status_label.text = "Generate three persisted offers from the eligible modifier pool. Wider Choice makes this four."
				_add_action("GENERATE REWARD", "generate_reward", RunAction.new(RunAction.GENERATE_REWARD))
			else:
				status_label.text = "Choose one persisted offer or refuse it for +$%d." % run_controller.state.rules().reward_refusal_cash
				if not reward.selection_committed:
					for raw_offer in reward.offers:
						var offer := RewardOffer.from_dict(raw_offer)
						_add_action("%s  [%s]" % [offer.definition_id, offer.offer_id], "reward_%s" % offer.offer_id, RunAction.new(RunAction.CHOOSE_REWARD, 0, {"offer_id": offer.offer_id}))
				if not reward.selection_committed:
					_add_action("REFUSE REWARD", "refuse_reward", RunAction.new(RunAction.REFUSE_REWARD))
		RunState.PHASE_CARRY:
			var carry_reward := RewardState.from_dict(run_controller.state.reward_state)
			if not carry_reward.pending_acquisition.is_empty():
				status_label.text = "Carry is full. Replace and sell one owned modifier, or refuse the selected reward for +$%d." % run_controller.state.rules().reward_refusal_cash
				_render_carry()
				_render_pending_reward(carry_reward)
				_add_action("REFUSE REWARD", "refuse_pending_reward", RunAction.new(RunAction.REFUSE_REWARD))
			else:
				status_label.text = _last_event_message("Select a modifier, inspect its description, then choose an active or reserve destination.")
				_render_carry()
				_add_action("OPEN SIX-SLOT SHOP", "enter_shop", RunAction.new(RunAction.ENTER_SHOP))
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
		RunState.PHASE_BANKRUPT:
			status_label.text = "The January settlement cannot be completed. This run is bankrupt."
			status_label.add_theme_color_override("font_color", ERROR)

func _render_shop() -> void:
	var shop := ShopState.from_dict(run_controller.state.shop_state)
	status_label.text = _last_event_message("Offers persist until purchased or rerolled. Routine transactions stay quiet and keep the carry tray visible.")
	shop_scroll = ScrollContainer.new()
	shop_scroll.name = "ShopContentScroll"
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_scroll.custom_minimum_size = Vector2(0, 180)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_column.add_child(shop_scroll)
	shop_content_column = VBoxContainer.new()
	shop_content_column.name = "ShopScrollableContent"
	shop_content_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content_column.add_theme_constant_override("separation", 10)
	shop_scroll.add_child(shop_content_column)
	var grid := GridContainer.new()
	grid.name = "ShopOfferGrid"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var rain_check_active := run_controller.active_effect_seams().has(ModifierEffectRegistry.SEAM_SHOP_OFFER_PRESERVATION)
	var preserved_offer_exists := not shop.preserved_offer.is_empty()
	shop_content_column.add_child(grid)
	for raw_offer in shop.offers:
		var offer := ShopOffer.from_dict(raw_offer)
		var offer_card := VBoxContainer.new()
		offer_card.add_theme_constant_override("separation", 4)
		var button := Button.new()
		button.name = "Shop_%s" % offer.slot_id
		var offer_status := "PRESERVED FOR NEXT MONTH" if offer.preserved else (offer.definition_id if offer.available else "UNAVAILABLE")
		button.text = "%s\n%s\n%s" % [offer.slot_id.to_upper().replace("_", " "), offer_status, ("$%d" % offer.price) if offer.available else "content pending"]
		button.custom_minimum_size = Vector2(0, 84)
		button.disabled = not offer.available or offer.consumed
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(func(): _submit(RunAction.new(RunAction.BUY_OFFER, 0, {"offer_id": offer.offer_id}), "shop_%s" % offer.offer_id))
		offer_card.add_child(button)
		if rain_check_active and not preserved_offer_exists and offer.available and not offer.consumed:
			var preserve_button := Button.new()
			preserve_button.name = "Preserve_%s" % offer.slot_id
			preserve_button.text = "PRESERVE"
			preserve_button.custom_minimum_size = Vector2(0, 36)
			preserve_button.focus_mode = Control.FOCUS_ALL
			var preserve_key := "preserve_%s" % offer.offer_id
			preserve_button.pressed.connect(func(): _submit(RunAction.new(RunAction.PRESERVE_SHOP_OFFER, 0, {"offer_id": offer.offer_id}), preserve_key))
			offer_card.add_child(preserve_button)
		grid.add_child(offer_card)
	_add_label(shop_content_column, "OWNED MODIFIERS", 18, GOLD, false)
	_render_shop_owned(run_controller.state.active_modifier_ids)
	_render_shop_owned(run_controller.state.reserve_modifier_ids)
	_render_shop_action_bar(shop)

func _render_shop_action_bar(shop: ShopState) -> void:
	shop_action_bar = HBoxContainer.new()
	shop_action_bar.name = "ShopActionBar"
	shop_action_bar.custom_minimum_size = Vector2(0, 58)
	shop_action_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_action_bar.add_theme_constant_override("separation", 10)
	root_column.add_child(shop_action_bar)
	_add_action("REROLL SHOP", "reroll", RunAction.new(RunAction.REROLL_SHOP, 0, {"duplicate_policy": ""}), shop_action_bar, true)
	var can_continue := shop.entered and shop.offers.size() == ShopState.SLOT_IDS.size()
	var continue_button := _add_action("CONTINUE TO FINALIZE", "exit_shop", RunAction.new(RunAction.EXIT_SHOP), shop_action_bar, true)
	continue_button.disabled = not can_continue
	if not can_continue:
		continue_button.tooltip_text = "The six shop slots are not ready yet."
		status_label.text = "Shop state is incomplete. Resolve the six-slot shop before continuing to finalize."
		status_label.add_theme_color_override("font_color", ERROR)

func _render_liquidation() -> void:
	for raw_instance_id in run_controller.state.active_modifier_ids + run_controller.state.reserve_modifier_ids:
		var instance_id := String(raw_instance_id)
		var instance: Dictionary = run_controller.state.modifier_instances.get(instance_id, {})
		var proceeds := ModifierResalePolicy.quote(instance, run_controller.modifier_registry)
		if proceeds < 0:
			continue
		_add_action("LIQUIDATE %s  (+$%d)" % [_modifier_description(instance_id), proceeds], "liquidate_%s" % instance_id, RunAction.new(RunAction.LIQUIDATE, 0, {"instance_id": instance_id}))

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
		_add_salvage_button(row, instance_id)
		shop_content_column.add_child(row)
		if focus_key == action_key:
			sell_button.call_deferred("grab_focus")

func _render_carry() -> void:
	_add_label(content_column, "ACTIVE MODIFIERS", 18, GOLD, false)
	_render_modifier_location(run_controller.state.active_modifier_ids, "reserve")
	_add_label(content_column, "RESERVE MODIFIERS", 18, GOLD, false)
	_render_modifier_location(run_controller.state.reserve_modifier_ids, "active")

func _render_pending_reward(reward: RewardState) -> void:
	var offer := RewardOffer.from_dict(reward.pending_acquisition.get("offer", {}))
	_add_label(content_column, "SELECTED REWARD: %s" % offer.definition_id, 17, GOLD, false)
	for raw_instance_id in run_controller.state.active_modifier_ids + run_controller.state.reserve_modifier_ids:
		var instance_id := String(raw_instance_id)
		var instance: Dictionary = run_controller.state.modifier_instances.get(instance_id, {})
		var proceeds := ModifierResalePolicy.quote(instance, run_controller.modifier_registry)
		if proceeds < 0 or not Array(instance.get("attached_card_ids", [])).is_empty():
			continue
		_add_action("REPLACE %s  (+$%d)" % [_modifier_description(instance_id), proceeds], "replace_%s" % instance_id, RunAction.new(RunAction.REPLACE_PENDING_REWARD, 0, {"instance_id": instance_id}))

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
		_add_salvage_button(row, instance_id)
		content_column.add_child(row)
		if focus_key == action_key:
			move_button.call_deferred("grab_focus")

func _add_salvage_button(row: HBoxContainer, instance_id: String) -> void:
	if not run_controller.active_effect_seams().has(ModifierEffectRegistry.SEAM_SALVAGE_TRANSACTION):
		return
	var instance: Dictionary = run_controller.state.modifier_instances.get(instance_id, {})
	var proceeds := ModifierResalePolicy.salvage_quote(instance, run_controller.modifier_registry)
	if proceeds < 0:
		return
	var action_key := "salvage_%s" % instance_id
	var salvage_button := Button.new()
	salvage_button.text = "SALVAGE (+$%d)" % proceeds
	salvage_button.custom_minimum_size = Vector2(170, 42)
	salvage_button.focus_mode = Control.FOCUS_ALL
	var action := RunAction.new(RunAction.SALVAGE_MODIFIER, 0, {"instance_id": instance_id})
	salvage_button.pressed.connect(func() -> void: _submit(action, action_key))
	row.add_child(salvage_button)
	if focus_key == action_key:
		salvage_button.call_deferred("grab_focus")

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

func _last_event_message(fallback: String) -> String:
	var message := String(run_controller.state.last_event.get("message", ""))
	return message if not message.is_empty() else fallback

func _add_action(text_value: String, key: String, action: RunAction, parent: Node = null, expand_horizontal: bool = false) -> Button:
	var button := Button.new()
	button.name = "Action_%s" % key
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48)
	if expand_horizontal:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(func(): _submit(action, key))
	var target := content_column if parent == null else parent
	target.add_child(button)
	if focus_key == key:
		button.call_deferred("grab_focus")
	return button

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
