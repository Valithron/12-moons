class_name MoonCardMotionController
extends RefCounted

## Reusable physical-card motion primitives. All tweens are bound to the
## owning screen and are cancellable without touching authoritative state.

var host: Node
var timings: MoonMotionTimings
var _generation: int = 0
var _active_tweens: Array = []
var _card_tweens: Dictionary = {}

func _init(host_node: Node, motion_timings: MoonMotionTimings = null) -> void:
	host = host_node
	timings = motion_timings if motion_timings != null else MoonMotionTimings.new()

func cancel_all() -> void:
	_generation += 1
	for tween_variant in _active_tweens.duplicate():
		var tween: Tween = tween_variant
		if tween != null and tween.is_valid():
			tween.kill()
	_active_tweens.clear()
	_card_tweens.clear()

func hold(seconds: float) -> void:
	var wait_seconds := timings.duration(seconds)
	if wait_seconds <= 0.0 or host == null or not is_instance_valid(host):
		return
	await host.get_tree().create_timer(wait_seconds).timeout

func move(card: MoonCardView, target: Vector2, seconds: float, transition: int = Tween.TRANS_QUAD, ease_type: int = Tween.EASE_OUT) -> void:
	if not _valid_control(card):
		return
	_kill_card_tween(card)
	card.set_slot_position(target)
	var wait_seconds := timings.duration(seconds)
	if wait_seconds <= 0.0:
		card.position = target
		return
	var token := _generation
	var tween: Tween = _create_tween()
	tween.tween_property(card, "position", target, wait_seconds).set_trans(transition).set_ease(ease_type)
	await _wait_for_tween(tween, token)

func move_group(cards: Array, targets: Dictionary, seconds: float, transition: int = Tween.TRANS_QUAD, ease_type: int = Tween.EASE_OUT) -> void:
	var valid_cards: Array = []
	for card_variant in cards:
		var card: MoonCardView = card_variant
		if _valid_control(card) and targets.has(card):
			valid_cards.append(card)
	if valid_cards.is_empty():
		return
	var wait_seconds := timings.duration(seconds)
	if wait_seconds <= 0.0:
		for card in valid_cards:
			var target: Vector2 = targets[card]
			card.set_slot_position(target)
			card.position = target
		return
	var token := _generation
	var tween: Tween = _create_tween()
	tween.set_parallel(true)
	for card in valid_cards:
		_kill_card_tween(card)
		var target: Vector2 = targets[card]
		card.set_slot_position(target)
		tween.tween_property(card, "position", target, wait_seconds).set_trans(transition).set_ease(ease_type)
	await _wait_for_tween(tween, token)

func move_staggered(cards: Array, targets: Dictionary, seconds: float, stagger: float) -> void:
	var valid_cards: Array = []
	for card_variant in cards:
		var card: MoonCardView = card_variant
		if _valid_control(card) and targets.has(card):
			valid_cards.append(card)
	if valid_cards.is_empty():
		return
	var travel := timings.duration(seconds)
	var delay_step := timings.duration(stagger)
	if travel <= 0.0:
		for card in valid_cards:
			var instant_target: Vector2 = targets[card]
			card.set_slot_position(instant_target)
			card.position = instant_target
		return
	var token := _generation
	var tween: Tween = _create_tween()
	tween.set_parallel(true)
	for index in range(valid_cards.size()):
		var card: MoonCardView = valid_cards[index]
		_kill_card_tween(card)
		var target: Vector2 = targets[card]
		card.set_slot_position(target)
		tween.tween_property(card, "position", target, travel).set_delay(index * delay_step).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _wait_for_tween(tween, token)

func flip(card: MoonCardView, face_up: bool, seconds: float = MoonMotionTimings.DRAW_FLIP) -> void:
	if not _valid_control(card):
		return
	_kill_card_tween(card)
	if card.has_method("set_face_up") and timings.is_reduced():
		card.set_face_up(face_up)
		return
	var token := _generation
	var original_scale := card.scale
	var half := maxf(0.01, timings.duration(seconds) * 0.5)
	var first: Tween = _create_tween()
	first.tween_property(card, "scale", Vector2(original_scale.x * 0.045, original_scale.y), half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _wait_for_tween(first, token)
	if token != _generation or not _valid_control(card):
		return
	if card.has_method("set_face_up"):
		card.set_face_up(face_up)
	var second: Tween = _create_tween()
	second.tween_property(card, "scale", original_scale, half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _wait_for_tween(second, token)

func impact(card: MoonCardView, seconds: float = MoonMotionTimings.CAPTURE_IMPACT) -> void:
	if not _valid_control(card):
		return
	_kill_card_tween(card)
	if timings.is_reduced():
		return
	var token := _generation
	var base_scale := card.scale
	var base_rotation := card.rotation
	var impact_seconds := timings.duration(seconds)
	var tween: Tween = _create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", base_scale * 1.045, impact_seconds * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "rotation", base_rotation + deg_to_rad(2.0), impact_seconds * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _wait_for_tween(tween, token)
	if token != _generation or not _valid_control(card):
		return
	var settle: Tween = _create_tween()
	settle.set_parallel(true)
	settle.tween_property(card, "scale", base_scale, impact_seconds * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	settle.tween_property(card, "rotation", base_rotation, impact_seconds * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await _wait_for_tween(settle, token)

func pulse(control: Control, seconds: float = MoonMotionTimings.YAKU_FEEDBACK) -> void:
	if not _valid_control(control) or timings.is_reduced():
		return
	var token := _generation
	var base_scale := control.scale
	control.pivot_offset = control.size * 0.5
	var pulse_seconds := timings.duration(seconds)
	var tween: Tween = _create_tween()
	tween.tween_property(control, "scale", base_scale * 1.045, pulse_seconds * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", base_scale, pulse_seconds * 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await _wait_for_tween(tween, token)

func fade(control: CanvasItem, alpha: float, seconds: float = MoonMotionTimings.MODAL_DISMISS) -> void:
	if control == null or not is_instance_valid(control):
		return
	var wait_seconds := timings.duration(seconds)
	if wait_seconds <= 0.0:
		control.modulate.a = alpha
		return
	var token := _generation
	var tween: Tween = _create_tween()
	tween.tween_property(control, "modulate:a", alpha, wait_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _wait_for_tween(tween, token)

func hover(card: MoonCardView, entered: bool) -> void:
	if not _valid_control(card):
		return
	_kill_card_tween(card)
	var token := _generation
	var target_position := card.slot_position
	var target_scale := Vector2.ONE
	if entered:
		target_position += Vector2(0, -12)
		target_scale = Vector2(1.025, 1.025)
		card.z_index = 120
	else:
		card.z_index = card.resting_z_index
	var wait_seconds := timings.duration(MoonMotionTimings.HAND_HOVER)
	if wait_seconds <= 0.0:
		card.position = target_position
		card.scale = target_scale
		return
	var tween: Tween = _create_tween()
	_card_tweens[card.get_instance_id()] = tween
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_position, wait_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", target_scale, wait_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _wait_for_tween(tween, token)
	if _card_tweens.get(card.get_instance_id()) == tween:
		_card_tweens.erase(card.get_instance_id())

func _create_tween() -> Tween:
	if host == null or not is_instance_valid(host):
		return null
	var tween := host.create_tween().bind_node(host)
	_active_tweens.append(tween)
	return tween

func _wait_for_tween(tween: Tween, token: int) -> void:
	if tween == null:
		return
	while token == _generation and host != null and is_instance_valid(host) and tween.is_valid() and tween.is_running():
		await host.get_tree().process_frame
	_active_tweens.erase(tween)

func _kill_card_tween(card: MoonCardView) -> void:
	if card == null:
		return
	var key := card.get_instance_id()
	if not _card_tweens.has(key):
		return
	var tween: Tween = _card_tweens[key]
	_card_tweens.erase(key)
	if tween != null and tween.is_valid():
		tween.kill()

func _valid_control(control: Control) -> bool:
	return control != null and is_instance_valid(control) and control.is_inside_tree()
