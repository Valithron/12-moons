extends SceneTree

func _initialize() -> void:
	call_deferred("_run_flow")

func _run_flow() -> void:
	var boot: Node = load("res://scenes/title/title.tscn").instantiate()
	root.add_child(boot)
	await process_frame

	var title: Node = boot.get("screen")
	var start_button := _find_button(title, "START JANUARY")
	if start_button == null:
		_fail("title screen did not expose START JANUARY")
		return
	start_button.emit_signal("pressed")
	await process_frame

	var intro: Node = boot.get("screen")
	var continue_button := _find_button(intro, "CONTINUE")
	if continue_button == null:
		_fail("January intro did not expose CONTINUE")
		return
	continue_button.emit_signal("pressed")
	await process_frame

	var match_screen: Node = boot.get("screen")
	var controller: MatchController = match_screen.get("controller")
	if controller == null:
		_fail("January match screen did not receive its controller")
		return
	if match_screen.get("overlay_layer").mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("empty overlay layer is intercepting card input")
		return
	match_screen.set("ai_cooldown", 0.0)

	var guard := 0
	while controller.state.phase != GameState.PHASE_MONTH_COMPLETE and guard < 5000:
		guard += 1
		if controller.state.current_player == 0:
			var actions: Array = controller.legal_actions(0)
			if actions.is_empty():
				_fail("player had no legal action in phase %s" % controller.state.phase)
				return
			var action: GameAction = actions[0]
			var target_id := action.target_card_id if action.action_type == GameAction.CHOOSE_MATCH else action.card_id
			var card := _find_selectable_card(match_screen, target_id)
			if card == null:
				_fail("selectable card %s was not rendered in phase %s" % [target_id, controller.state.phase])
				return
			# Exercise the same button signal path used by a real click:
			# Button.pressed -> MoonCardView.card_clicked -> match screen.
			card.emit_signal("pressed")
		await process_frame
		match_screen.set("ai_cooldown", 0.0)

	if controller.state.phase != GameState.PHASE_MONTH_COMPLETE:
		_fail("January did not reach month complete within the guard limit")
		return

	await process_frame
	var result_screen: Node = boot.get("screen")
	var play_again_button := _find_button(result_screen, "PLAY AGAIN")
	if play_again_button == null:
		_fail("January result did not expose PLAY AGAIN")
		return
	var return_button := _find_button(result_screen, "RETURN TO TITLE")
	if return_button == null:
		_fail("January completed without showing the result screen")
		return
	return_button.emit_signal("pressed")
	await process_frame
	if _find_button(boot.get("screen"), "START JANUARY") == null:
		_fail("result screen did not return to the title screen")
		return

	print("12 Moons UI flow validation passed: title -> intro -> January -> result -> replay/title controls")
	boot.queue_free()
	quit(0)

func _find_button(node: Node, target_text: String) -> Button:
	if node == null:
		return null
	for child in node.get_children():
		if child is Button and child.text == target_text:
			return child
		var nested: Button = _find_button(child, target_text)
		if nested != null:
			return nested
	return null

func _find_selectable_card(node: Node, target_id: String) -> MoonCardView:
	if node == null:
		return null
	if node is MoonCardView and node.card_id == target_id and node.selectable and not node.disabled:
		return node
	for child in node.get_children():
		var nested: MoonCardView = _find_selectable_card(child, target_id)
		if nested != null:
			return nested
	return null

func _fail(message: String) -> void:
	push_error("UI flow validation failed: " + message)
	quit(1)
