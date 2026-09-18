class_name RunController
extends RefCounted

var state: RunState
var journal: RunJournal
var postcondition_probe: Callable = Callable()
var modifier_registry: ModifierRegistry
var card_catalog: CardCatalog

func _init(seed_value: int = 0, initial_state: RunState = null, rules: RunRules = null, catalog: CardCatalog = null) -> void:
	state = initial_state if initial_state != null else RunState.fresh(seed_value, rules)
	journal = RunJournal.new(state.root_seed, state.to_dict())
	modifier_registry = ModifierRegistry.new()
	card_catalog = catalog

func submit_action(action: RunAction) -> RunActionResult:
	var before_hash := state.state_hash()
	if action == null:
		return RunActionResult.rejected("Action is null", before_hash)
	if not state.invariants_ok(null, modifier_registry):
		return RunActionResult.rejected("Authoritative run state is already invalid", before_hash)
	if not _is_legal_action(action):
		return RunActionResult.rejected("Run action is not legal in the authoritative phase", before_hash)
	var candidate := RunState.from_dict(state.to_dict())
	var outcome := _apply_action(candidate, action)
	if not bool(outcome.get("ok", false)):
		return RunActionResult.rejected(String(outcome.get("reason", "Run action could not be applied")), before_hash)
	if postcondition_probe.is_valid():
		postcondition_probe.call(candidate)
	var errors := candidate.invariant_errors(null, modifier_registry)
	if not errors.is_empty():
		return RunActionResult.rejected("Run invariant failed: %s" % "; ".join(errors), before_hash)
	var after_hash := candidate.state_hash()
	state = candidate
	journal.record(action, before_hash, after_hash)
	return RunActionResult.accepted_action(action, before_hash, after_hash, Array(outcome.get("events", [])))

func replay_final_hash() -> String:
	if journal == null:
		return ""
	var replay_state := RunState.from_dict(journal.initial_state)
	var replay := RunController.new(journal.root_seed, replay_state, null, card_catalog)
	replay.modifier_registry = modifier_registry
	for raw_entry in journal.entries:
		if not raw_entry is Dictionary:
			return ""
		var action_data: Variant = raw_entry.get("action", {})
		if not action_data is Dictionary:
			return ""
		var before_hash := String(raw_entry.get("before_hash", ""))
		if replay.state.state_hash() != before_hash:
			return ""
		var result := replay.submit_action(RunAction.from_dict(action_data))
		if not result.accepted or result.state_hash != String(raw_entry.get("after_hash", "")):
			return ""
	return replay.state.state_hash()

func ingest_match_result(result: MatchResult) -> RunActionResult:
	if result == null:
		return RunActionResult.rejected("Match result is null", state.state_hash())
	return submit_action(RunAction.new(RunAction.RESOLVE_MONTH, 0, {"match_result": result.to_dict()}))

func ingest_terminal_game_state(game_state: GameState) -> RunActionResult:
	if game_state == null or game_state.phase != GameState.PHASE_MONTH_COMPLETE or game_state.terminal_result.is_empty():
		return RunActionResult.rejected("Only a terminal January GameState can be ingested", state.state_hash())
	return ingest_match_result(MatchResult.from_game_state(game_state))

func _is_legal_action(action: RunAction) -> bool:
	match action.action_type:
		RunAction.RESOLVE_MONTH:
			return state.phase == RunState.PHASE_MONTH_MATCH
		RunAction.SETTLE:
			return state.phase == RunState.PHASE_SETTLEMENT
		RunAction.LIQUIDATE:
			return state.phase == RunState.PHASE_LIQUIDATION
		RunAction.GENERATE_REWARD, RunAction.CHOOSE_REWARD:
			return state.phase == RunState.PHASE_REWARD
		RunAction.REFUSE_REWARD:
			return state.phase == RunState.PHASE_REWARD or (state.phase == RunState.PHASE_CARRY and not RewardState.from_dict(state.reward_state).pending_acquisition.is_empty())
		RunAction.PLACE_PENDING_ACQUISITION, RunAction.REPLACE_PENDING_REWARD:
			return state.phase == RunState.PHASE_CARRY
		RunAction.MOVE_MODIFIER:
			return state.phase == RunState.PHASE_CARRY or state.phase == RunState.PHASE_SHOP
		RunAction.ATTACH_CARD_UPGRADE, RunAction.DETACH_CARD_UPGRADE:
			return state.phase == RunState.PHASE_CARRY or state.phase == RunState.PHASE_SHOP
		RunAction.ENTER_SHOP:
			return state.phase == RunState.PHASE_CARRY
		RunAction.BUY_OFFER, RunAction.SELL_MODIFIER, RunAction.PRESERVE_SHOP_OFFER, RunAction.REROLL_SHOP, RunAction.EXIT_SHOP:
			return state.phase == RunState.PHASE_SHOP
		RunAction.SALVAGE_MODIFIER:
			return state.phase == RunState.PHASE_CARRY or state.phase == RunState.PHASE_SHOP
		RunAction.FINALIZE_BUILD:
			return state.phase == RunState.PHASE_FINALIZE
		RunAction.BEGIN_FEBRUARY:
			return state.phase == RunState.PHASE_TRANSITION
	return false

func _apply_action(candidate: RunState, action: RunAction) -> Dictionary:
	match action.action_type:
		RunAction.RESOLVE_MONTH:
			return _apply_resolve_month(candidate, action)
		RunAction.SETTLE:
			return _apply_settlement(candidate)
		RunAction.LIQUIDATE:
			return _apply_liquidation(candidate, action)
		RunAction.GENERATE_REWARD:
			return _apply_generate_reward(candidate, action)
		RunAction.CHOOSE_REWARD:
			return _apply_choose_reward(candidate, action)
		RunAction.REFUSE_REWARD:
			return _apply_refuse_reward(candidate)
		RunAction.PLACE_PENDING_ACQUISITION:
			return _apply_place_pending(candidate, action)
		RunAction.REPLACE_PENDING_REWARD:
			return _apply_replace_pending_reward(candidate, action)
		RunAction.MOVE_MODIFIER:
			return _apply_move_modifier(candidate, action)
		RunAction.ATTACH_CARD_UPGRADE, RunAction.DETACH_CARD_UPGRADE:
			return _apply_card_upgrade_attachment(candidate, action)
		RunAction.ENTER_SHOP:
			return _apply_enter_shop(candidate, action)
		RunAction.BUY_OFFER:
			return _apply_buy_offer(candidate, action)
		RunAction.SELL_MODIFIER:
			return _apply_sell_modifier(candidate, action)
		RunAction.SALVAGE_MODIFIER:
			return _apply_salvage_modifier(candidate, action)
		RunAction.PRESERVE_SHOP_OFFER:
			return _apply_preserve_shop_offer(candidate, action)
		RunAction.REROLL_SHOP:
			return _apply_reroll_shop(candidate, action)
		RunAction.EXIT_SHOP:
			return _apply_exit_shop(candidate)
		RunAction.FINALIZE_BUILD:
			return _apply_finalize_build(candidate)
		RunAction.BEGIN_FEBRUARY:
			return _apply_begin_february(candidate)
	return {"ok": false, "reason": "Unsupported run action"}

func _apply_resolve_month(candidate: RunState, action: RunAction) -> Dictionary:
	var raw_result_variant = action.payload.get("match_result", {})
	var raw_result: Dictionary = raw_result_variant if raw_result_variant is Dictionary else {}
	var result := MatchResult.from_dict(raw_result)
	if not result.valid_terminal_result():
		return {"ok": false, "reason": "Terminal MatchResult is incomplete"}
	if result.month != candidate.month:
		return {"ok": false, "reason": "MatchResult month does not match the run month"}
	if candidate.ingested_match_ids.has(result.match_id) or candidate.settled_match_ids.has(result.match_id):
		return {"ok": false, "reason": "MatchResult has already been ingested"}
	candidate.ingested_match_ids.append(result.match_id)
	candidate.last_match_result = result.to_dict()
	candidate.phase = RunState.PHASE_SETTLEMENT
	candidate.last_event = {
		"kind": "month_result_ingested",
		"match_id": result.match_id,
		"month": result.month,
		"message": "January terminal result is ready for settlement."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_generate_reward(candidate: RunState, action: RunAction) -> Dictionary:
	var existing := RewardState.from_dict(candidate.reward_state)
	if existing.generated:
		return {"ok": false, "reason": "Reward offers are already persisted for this month"}
	var raw_request = action.payload.get("request", {})
	var request_data: Dictionary = raw_request if raw_request is Dictionary else {}
	var request := RewardRequest.from_dict(request_data)
	if request_data.is_empty():
		var configured_policy := candidate.rules().reward_policy
		var configured_duplicates := candidate.rules().duplicate_modifier_policy
		if configured_policy == RunRules.REWARD_POLICY_WHOLE_POOL:
			request = RewardRequest.whole_pool(candidate.month, configured_duplicates)
		elif configured_policy == RunRules.REWARD_POLICY_FAMILY_QUOTAS:
			request = RewardRequest.family_quotas(candidate.month, configured_duplicates)
		else:
			return {"ok": false, "reason": "Reward policy is invalid"}
		request.generation_id = int(candidate.generation_counters.get("reward", 0))
	else:
		if request.reward_policy.is_empty():
			request.reward_policy = candidate.rules().reward_policy
		if request.duplicate_policy.is_empty():
			request.duplicate_policy = candidate.rules().duplicate_modifier_policy
		if request.generation_id == 0:
			request.generation_id = int(candidate.generation_counters.get("reward", 0))
	for definition_id in _owned_nonstackable_definition_ids(candidate):
		if not request.excluded_definition_ids.has(definition_id):
			request.excluded_definition_ids.append(definition_id)
	if bool(action.payload.get("wider_choice", false)) or candidate.rules().reward_wider_choice or _active_has_definition(candidate, "wider_choice"):
		request = request.with_wider_choice()
	var generated := RewardGenerator.generate(request, candidate.root_seed, modifier_registry)
	if not bool(generated.get("ok", false)):
		return {"ok": false, "reason": String(generated.get("reason", "Reward generation failed"))}
	var raw_generated_state = generated.get("state", {})
	candidate.reward_state = raw_generated_state.duplicate(true) if raw_generated_state is Dictionary else {}
	candidate.generation_counters["reward"] = request.generation_id
	candidate.last_event = {
		"kind": "reward_generated",
		"offer_ids": _reward_offer_ids(candidate.reward_state),
		"message": "Reward offers are persisted and ready for comparison."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_choose_reward(candidate: RunState, action: RunAction) -> Dictionary:
	var reward := RewardState.from_dict(candidate.reward_state)
	if not reward.generated or reward.selection_committed or not reward.pending_acquisition.is_empty():
		return {"ok": false, "reason": "Reward selection is not available"}
	var offer_id := String(action.payload.get("offer_id", ""))
	var offer_index := _reward_offer_index(reward.offers, offer_id)
	if offer_index < 0:
		return {"ok": false, "reason": "Reward offer does not exist"}
	var offer := RewardOffer.from_dict(reward.offers[offer_index])
	if offer.consumed:
		return {"ok": false, "reason": "Reward offer has already been consumed"}
	if _carry_is_full(candidate):
		reward.selected_offer_id = offer.offer_id
		reward.pending_acquisition = {"offer": offer.to_dict(), "reason": "replace_and_sell_or_refuse"}
		candidate.reward_state = reward.to_dict()
		candidate.phase = RunState.PHASE_CARRY
		candidate.last_event = {
			"kind": "reward_pending_acquisition",
			"offer_id": offer.offer_id,
			"message": "Reward is selected; replace and sell one owned modifier or refuse the reward."
		}
		return {"ok": true, "events": [candidate.last_event.duplicate(true)]}
	var destination := String(action.payload.get("destination", ""))
	if destination.is_empty():
		destination = "active" if candidate.active_count() < candidate.unlocked_active_capacity else "reserve"
	var placement := _materialize_reward(candidate, offer, destination)
	if not bool(placement.get("ok", false)):
		return placement
	offer.consumed = true
	reward.offers[offer_index] = offer.to_dict()
	reward.selection_committed = true
	reward.selected_offer_id = offer.offer_id
	reward.pending_acquisition = {}
	candidate.reward_state = reward.to_dict()
	candidate.phase = RunState.PHASE_CARRY
	candidate.last_event = {
		"kind": "reward_acquired",
		"offer_id": offer.offer_id,
		"instance_id": String(placement.get("instance_id", "")),
		"destination": destination,
		"message": "Selected reward is now owned in the carry layout."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_refuse_reward(candidate: RunState) -> Dictionary:
	var reward := RewardState.from_dict(candidate.reward_state)
	if not reward.generated or reward.selection_committed:
		return {"ok": false, "reason": "Reward refusal is not available"}
	if not reward.pending_acquisition.is_empty():
		var pending_offer := RewardOffer.from_dict(reward.pending_acquisition.get("offer", {}))
		var pending_index := _reward_offer_index(reward.offers, pending_offer.offer_id)
		if pending_index >= 0:
			pending_offer.consumed = true
			reward.offers[pending_index] = pending_offer.to_dict()
		reward.pending_acquisition = {}
	reward.selected_offer_id = ""
	reward.selection_committed = true
	reward.refused = true
	candidate.reward_state = reward.to_dict()
	candidate.bankroll += candidate.rules().reward_refusal_cash
	candidate.phase = RunState.PHASE_CARRY
	candidate.last_event = {
		"kind": "reward_refused",
		"cash_delta": candidate.rules().reward_refusal_cash,
		"bankroll": candidate.bankroll,
		"message": "Reward refused for the configured cash value."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_place_pending(candidate: RunState, action: RunAction) -> Dictionary:
	var reward := RewardState.from_dict(candidate.reward_state)
	if reward.pending_acquisition.is_empty():
		return {"ok": false, "reason": "There is no pending reward acquisition"}
	if String(reward.pending_acquisition.get("reason", "")) == "replace_and_sell_or_refuse":
		return {"ok": false, "reason": "A full carry requires replacing and selling an owned modifier or refusing the reward"}
	var raw_offer = reward.pending_acquisition.get("offer", {})
	if not raw_offer is Dictionary:
		return {"ok": false, "reason": "Pending reward offer is malformed"}
	var destination := String(action.payload.get("destination", ""))
	var placement := _materialize_reward(candidate, RewardOffer.from_dict(raw_offer), destination)
	if not bool(placement.get("ok", false)):
		return placement
	reward.pending_acquisition = {}
	candidate.reward_state = reward.to_dict()
	candidate.last_event = {
		"kind": "pending_reward_placed",
		"offer_id": String(raw_offer.get("offer_id", "")),
		"instance_id": String(placement.get("instance_id", "")),
		"destination": destination,
		"message": "Pending reward is now placed in carry."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_replace_pending_reward(candidate: RunState, action: RunAction) -> Dictionary:
	var reward := RewardState.from_dict(candidate.reward_state)
	if reward.pending_acquisition.is_empty():
		return {"ok": false, "reason": "There is no full-capacity reward awaiting replacement"}
	var raw_offer = reward.pending_acquisition.get("offer", {})
	if not raw_offer is Dictionary:
		return {"ok": false, "reason": "Pending reward offer is malformed"}
	var offer := RewardOffer.from_dict(raw_offer)
	var old_instance_id := String(action.payload.get("instance_id", ""))
	if old_instance_id.is_empty() or not candidate.modifier_instances.has(old_instance_id):
		return {"ok": false, "reason": "Replacement target is not an owned modifier"}
	var old_instance: Dictionary = candidate.modifier_instances[old_instance_id]
	var proceeds := ModifierResalePolicy.quote(old_instance, modifier_registry)
	if proceeds < 0:
		return {"ok": false, "reason": "Replacement target is not currently saleable"}
	if not Array(old_instance.get("attached_card_ids", [])).is_empty():
		return {"ok": false, "reason": "An attached modifier must be detached before replacement"}
	var destination := String(action.payload.get("destination", old_instance.get("location", "")))
	_remove_modifier(candidate, old_instance_id)
	var placement := _materialize_reward(candidate, offer, destination)
	if not bool(placement.get("ok", false)):
		return placement
	var offer_index := _reward_offer_index(reward.offers, offer.offer_id)
	if offer_index >= 0:
		offer.consumed = true
		reward.offers[offer_index] = offer.to_dict()
	reward.pending_acquisition = {}
	reward.selection_committed = true
	reward.selected_offer_id = offer.offer_id
	candidate.bankroll += proceeds
	candidate.reward_state = reward.to_dict()
	candidate.last_event = {
		"kind": "reward_replaced",
		"offer_id": offer.offer_id,
		"removed_instance_id": old_instance_id,
		"instance_id": String(placement.get("instance_id", "")),
		"proceeds": proceeds,
		"destination": destination,
		"bankroll": candidate.bankroll,
		"message": "Owned modifier sold and selected reward placed in the freed carry slot."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _materialize_reward(candidate: RunState, offer: RewardOffer, destination: String) -> Dictionary:
	if destination != "active" and destination != "reserve":
		return {"ok": false, "reason": "Reward destination is invalid"}
	if destination == "active" and candidate.active_count() >= candidate.unlocked_active_capacity:
		return {"ok": false, "reason": "Active carry capacity is full"}
	if destination == "reserve" and candidate.reserve_count() >= candidate.reserve_capacity:
		return {"ok": false, "reason": "Reserve carry capacity is full"}
	var instance_id := "modifier_%s" % offer.offer_id
	if candidate.modifier_instances.has(instance_id):
		return {"ok": false, "reason": "Reward instance ID already exists"}
	var instance := _new_modifier_instance(candidate, offer.definition_id, destination, offer.source, instance_id, 0)
	if not bool(instance.get("ok", false)):
		return instance
	candidate.modifier_instances[instance_id] = instance["instance"]
	if destination == "active":
		candidate.active_modifier_ids.append(instance_id)
	else:
		candidate.reserve_modifier_ids.append(instance_id)
	return {"ok": true, "instance_id": instance_id}

func _carry_is_full(candidate: RunState) -> bool:
	return candidate.active_count() >= candidate.unlocked_active_capacity and candidate.reserve_count() >= candidate.reserve_capacity

func _active_has_definition(candidate: RunState, definition_id: String) -> bool:
	for raw_instance_id in candidate.active_modifier_ids:
		var instance_id := String(raw_instance_id)
		var raw_instance = candidate.modifier_instances.get(instance_id, {})
		if raw_instance is Dictionary and String(raw_instance.get("definition_id", "")) == definition_id:
			return true
	return false

func active_effect_seams() -> Array:
	return ModifierEffectRegistry.new().active_effect_seams(state, modifier_registry)

func _active_has_effect_seam(candidate: RunState, seam_id: String) -> bool:
	return ModifierEffectRegistry.new().active_effect_seams(candidate, modifier_registry).has(seam_id)

func _owned_nonstackable_definition_ids(candidate: RunState) -> Array:
	var result: Array = []
	for raw_instance_id in candidate.modifier_instances.keys():
		var instance: Dictionary = candidate.modifier_instances[raw_instance_id]
		var definition := modifier_registry.get_definition(String(instance.get("definition_id", ""))) if modifier_registry != null else null
		if definition != null and not definition.stackable and (definition.family == "hand_mechanic" or definition.family == "strategic_meta"):
			if not result.has(definition.definition_id):
				result.append(definition.definition_id)
	return result

func _can_acquire_definition(candidate: RunState, definition_id: String, target_card_id: String = "") -> Dictionary:
	var definition := modifier_registry.get_definition(definition_id) if modifier_registry != null else null
	if definition == null:
		return {"ok": false, "reason": "Modifier definition is not registered"}
	if definition.family == "hand_mechanic" or definition.family == "strategic_meta":
		if not definition.stackable:
			for raw_instance in candidate.modifier_instances.values():
				if String(raw_instance.get("definition_id", "")) == definition_id:
					return {"ok": false, "reason": "Duplicate Hand/Mechanic or Strategic/Meta modifier is not allowed"}
	if definition.family == "card_upgrade" and not target_card_id.is_empty() and not definition.allow_same_card_stack:
		for raw_instance_id in Array(candidate.card_upgrade_attachments.get(target_card_id, [])):
			var attached: Dictionary = candidate.modifier_instances.get(String(raw_instance_id), {})
			if String(attached.get("definition_id", "")) == definition_id:
				return {"ok": false, "reason": "The same Card Upgrade type cannot be attached to the same physical card"}
	return {"ok": true}

func _new_modifier_instance(candidate: RunState, definition_id: String, destination: String, source: String, stable_suffix: String, purchase_price: int) -> Dictionary:
	var acquisition := _can_acquire_definition(candidate, definition_id)
	if not bool(acquisition.get("ok", false)):
		return acquisition
	var definition := modifier_registry.get_definition(definition_id)
	if definition == null:
		return {"ok": false, "reason": "Modifier definition is not registered"}
	var instance_id := "modifier_%s" % stable_suffix
	if candidate.modifier_instances.has(instance_id):
		return {"ok": false, "reason": "Modifier instance ID already exists"}
	return {
		"ok": true,
		"instance": {
			"instance_id": instance_id,
			"definition_id": definition_id,
			"location": destination,
			"source": source,
			"acquired_month": candidate.month,
			"attached_card_ids": [],
			"purchase_price": maxi(0, purchase_price) if source == "shop" else 0,
			"base_shop_price": definition.base_shop_price
		}
	}

func _reward_offer_index(offers: Array, offer_id: String) -> int:
	for index in range(offers.size()):
		var raw_offer = offers[index]
		if raw_offer is Dictionary and String(raw_offer.get("offer_id", "")) == offer_id:
			return index
	return -1

func _reward_offer_ids(reward_data: Dictionary) -> Array:
	var result: Array = []
	for raw_offer in Array(reward_data.get("offers", [])):
		if raw_offer is Dictionary:
			result.append(String(raw_offer.get("offer_id", "")))
	return result

func _apply_settlement(candidate: RunState) -> Dictionary:
	var result := MatchResult.from_dict(candidate.last_match_result)
	if not result.valid_terminal_result():
		return {"ok": false, "reason": "Settlement has no valid MatchResult"}
	if candidate.settled_match_ids.has(result.match_id):
		return {"ok": false, "reason": "MatchResult has already been settled"}
	var player_score := result.resolved_player_score()
	var ai_score := result.resolved_ai_score()
	var delta := 0
	if player_score > ai_score:
		delta = player_score
	elif ai_score > player_score:
		delta = -player_score
	if delta >= 0:
		candidate.bankroll += delta
		_complete_settlement(candidate, result)
		return {"ok": true, "events": [candidate.last_event.duplicate(true)]}
	var amount_due := -delta
	if amount_due <= candidate.bankroll:
		candidate.bankroll -= amount_due
		_complete_settlement(candidate, result)
		return {"ok": true, "events": [candidate.last_event.duplicate(true)]}
	candidate.pending_settlement = PendingSettlement.new().to_dict()
	var pending := PendingSettlement.from_dict(candidate.pending_settlement)
	pending.match_id = result.match_id
	pending.amount_due = amount_due
	pending.player_score = player_score
	pending.ai_score = ai_score
	pending.source_result = result.to_dict()
	candidate.pending_settlement = pending.to_dict()
	if _has_saleable_modifier(candidate):
		candidate.phase = RunState.PHASE_LIQUIDATION
		candidate.last_event = {
			"kind": "liquidation_required",
			"match_id": result.match_id,
			"amount_due": amount_due,
			"bankroll": candidate.bankroll,
			"message": "January loss requires legal liquidation before reward selection."
		}
	else:
		candidate.phase = RunState.PHASE_BANKRUPT
		candidate.last_event = {
			"kind": "bankrupt",
			"match_id": result.match_id,
			"remaining_due": amount_due,
			"message": "January settlement cannot be paid and no owned modifier is legally saleable."
		}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_liquidation(candidate: RunState, action: RunAction) -> Dictionary:
	var instance_id := String(action.payload.get("instance_id", ""))
	if instance_id.is_empty() or not candidate.modifier_instances.has(instance_id):
		return {"ok": false, "reason": "Liquidation target is not an owned modifier"}
	var location := ""
	if candidate.active_modifier_ids.has(instance_id):
		location = "active"
	elif candidate.reserve_modifier_ids.has(instance_id):
		location = "reserve"
	if location.is_empty():
		return {"ok": false, "reason": "Liquidation target has no legal location"}
	var instance: Dictionary = candidate.modifier_instances[instance_id]
	if not Array(instance.get("attached_card_ids", [])).is_empty():
		return {"ok": false, "reason": "An attached modifier must be detached before liquidation"}
	var proceeds := ModifierResalePolicy.quote(instance, modifier_registry)
	if proceeds < 0:
		return {"ok": false, "reason": "Liquidation target is not currently saleable"}
	var pending := PendingSettlement.from_dict(candidate.pending_settlement)
	var original_due := pending.amount_due
	candidate.active_modifier_ids.erase(instance_id)
	candidate.reserve_modifier_ids.erase(instance_id)
	candidate.modifier_instances.erase(instance_id)
	pending.amount_due -= proceeds
	if pending.amount_due <= 0:
		candidate.bankroll += proceeds - original_due
		candidate.pending_settlement = {}
		_complete_settlement(candidate, MatchResult.from_dict(pending.source_result))
	else:
		candidate.pending_settlement = pending.to_dict()
		candidate.last_event = {
			"kind": "liquidation_sale",
			"instance_id": instance_id,
			"proceeds": proceeds,
			"remaining_due": pending.amount_due,
			"message": "Modifier sold toward the January settlement debt."
		}
		if not _has_saleable_modifier(candidate):
			candidate.phase = RunState.PHASE_BANKRUPT
			candidate.last_event = {
				"kind": "bankrupt",
				"remaining_due": pending.amount_due,
				"message": "No legal remaining liquidation action can satisfy the settlement."
			}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _complete_settlement(candidate: RunState, result: MatchResult) -> void:
	candidate.pending_settlement = {}
	candidate.settled_match_ids.append(result.match_id)
	candidate.unlocked_active_capacity = maxi(candidate.unlocked_active_capacity, candidate.rules().active_capacity_after_month(candidate.month))
	candidate.phase = RunState.PHASE_REWARD
	var economic_delta := result.resolved_player_score() - result.resolved_ai_score()
	if economic_delta > 0:
		economic_delta = result.resolved_player_score()
	elif economic_delta < 0:
		economic_delta = -result.resolved_player_score()
	candidate.last_event = {
		"kind": "settlement_complete",
		"match_id": result.match_id,
		"economic_delta": economic_delta,
		"bankroll": candidate.bankroll,
		"unlocked_active_capacity": candidate.unlocked_active_capacity,
		"message": "January settlement is complete."
	}

func _has_saleable_modifier(candidate: RunState) -> bool:
	for raw_id in candidate.active_modifier_ids:
		var instance: Dictionary = candidate.modifier_instances.get(String(raw_id), {})
		if Array(instance.get("attached_card_ids", [])).is_empty() and ModifierResalePolicy.quote(instance, modifier_registry) >= 0:
			return true
	for raw_id in candidate.reserve_modifier_ids:
		var instance: Dictionary = candidate.modifier_instances.get(String(raw_id), {})
		if Array(instance.get("attached_card_ids", [])).is_empty() and ModifierResalePolicy.quote(instance, modifier_registry) >= 0:
			return true
	return false

func _apply_move_modifier(candidate: RunState, action: RunAction) -> Dictionary:
	var instance_id := String(action.payload.get("instance_id", ""))
	var destination := String(action.payload.get("destination", ""))
	if not candidate.modifier_instances.has(instance_id):
		return {"ok": false, "reason": "Modifier instance is not owned"}
	if destination != "active" and destination != "reserve":
		return {"ok": false, "reason": "Modifier destination is invalid"}
	var source := ""
	if candidate.active_modifier_ids.has(instance_id):
		source = "active"
	elif candidate.reserve_modifier_ids.has(instance_id):
		source = "reserve"
	if source.is_empty() or source == destination:
		return {"ok": false, "reason": "Modifier source and destination are invalid"}
	if destination == "active" and candidate.active_count() >= candidate.unlocked_active_capacity:
		return {"ok": false, "reason": "Active carry capacity is full"}
	if destination == "reserve" and candidate.reserve_count() >= candidate.reserve_capacity:
		return {"ok": false, "reason": "Reserve carry capacity is full"}
	if source == "active":
		candidate.active_modifier_ids.erase(instance_id)
		candidate.reserve_modifier_ids.append(instance_id)
	else:
		candidate.reserve_modifier_ids.erase(instance_id)
		candidate.active_modifier_ids.append(instance_id)
	var instance: Dictionary = candidate.modifier_instances[instance_id]
	instance["location"] = destination
	candidate.modifier_instances[instance_id] = instance
	candidate.last_event = {
		"kind": "modifier_moved",
		"instance_id": instance_id,
		"source": source,
		"destination": destination,
		"message": "Modifier moved to its new carry location."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_card_upgrade_attachment(candidate: RunState, action: RunAction) -> Dictionary:
	var instance_id := String(action.payload.get("instance_id", ""))
	var card_id := String(action.payload.get("card_id", ""))
	if instance_id.is_empty() or not candidate.modifier_instances.has(instance_id):
		return {"ok": false, "reason": "Card Upgrade instance is not owned"}
	if card_id.is_empty():
		return {"ok": false, "reason": "A physical hanafuda card target is required"}
	if card_catalog != null and not card_catalog.has_card(card_id):
		return {"ok": false, "reason": "Card Upgrade target is not a known physical card"}
	var instance: Dictionary = candidate.modifier_instances[instance_id]
	var definition := modifier_registry.get_definition(String(instance.get("definition_id", "")))
	if definition == null or definition.family != "card_upgrade":
		return {"ok": false, "reason": "Only Card Upgrade modifiers may attach to a physical card"}
	var attached_cards := Array(instance.get("attached_card_ids", [])).duplicate()
	if action.action_type == RunAction.ATTACH_CARD_UPGRADE:
		if not attached_cards.is_empty():
			return {"ok": false, "reason": "A Card Upgrade instance can target only one physical card"}
		var acquisition := _can_acquire_definition(candidate, definition.definition_id, card_id)
		if not bool(acquisition.get("ok", false)):
			return acquisition
		var existing_on_card := Array(candidate.card_upgrade_attachments.get(card_id, []))
		for raw_existing_id in existing_on_card:
			var existing: Dictionary = candidate.modifier_instances.get(String(raw_existing_id), {})
			if String(existing.get("definition_id", "")) != definition.definition_id:
				return {"ok": false, "reason": "Different Card Upgrade stacking on one physical card remains a future policy seam"}
		attached_cards.append(card_id)
		instance["attached_card_ids"] = attached_cards
		candidate.modifier_instances[instance_id] = instance
		var indexed := Array(candidate.card_upgrade_attachments.get(card_id, [])).duplicate()
		indexed.append(instance_id)
		candidate.card_upgrade_attachments[card_id] = indexed
		candidate.last_event = {
			"kind": "card_upgrade_attached",
			"instance_id": instance_id,
			"card_id": card_id,
			"message": "Card Upgrade attached to the selected physical hanafuda card."
		}
	else:
		if not attached_cards.has(card_id):
			return {"ok": false, "reason": "Card Upgrade is not attached to that physical card"}
		attached_cards.erase(card_id)
		instance["attached_card_ids"] = attached_cards
		candidate.modifier_instances[instance_id] = instance
		var indexed := Array(candidate.card_upgrade_attachments.get(card_id, [])).duplicate()
		indexed.erase(instance_id)
		if indexed.is_empty():
			candidate.card_upgrade_attachments.erase(card_id)
		else:
			candidate.card_upgrade_attachments[card_id] = indexed
		candidate.last_event = {
			"kind": "card_upgrade_detached",
			"instance_id": instance_id,
			"card_id": card_id,
			"message": "Card Upgrade detached from the physical hanafuda card."
		}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_enter_shop(candidate: RunState, action: RunAction) -> Dictionary:
	var duplicate_policy := String(action.payload.get("duplicate_policy", ""))
	if duplicate_policy.is_empty():
		duplicate_policy = candidate.rules().duplicate_modifier_policy
	var previous_shop := ShopState.from_dict(candidate.shop_state)
	var generated := ShopGenerator.generate(candidate.month, 0, candidate.root_seed, modifier_registry, duplicate_policy, _owned_nonstackable_definition_ids(candidate), previous_shop.preserved_offer)
	if not bool(generated.get("ok", false)):
		return generated
	var raw_shop = generated.get("state", {})
	var shop := ShopState.from_dict(raw_shop if raw_shop is Dictionary else {})
	shop.entered = true
	shop.preserved_offer = {}
	candidate.shop_state = shop.to_dict()
	candidate.generation_counters["shop"] = shop.generation_id
	candidate.phase = RunState.PHASE_SHOP
	candidate.last_event = {
		"kind": "shop_entered",
		"generation_id": shop.generation_id,
		"offer_ids": _shop_offer_ids(shop),
		"message": "The six-slot shop is ready." 
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_buy_offer(candidate: RunState, action: RunAction) -> Dictionary:
	var shop := ShopState.from_dict(candidate.shop_state)
	var offer_id := String(action.payload.get("offer_id", ""))
	var offer_index := _shop_offer_index(shop.offers, offer_id)
	if offer_index < 0:
		return {"ok": false, "reason": "Shop offer does not exist"}
	var offer := ShopOffer.from_dict(shop.offers[offer_index])
	if not offer.available or offer.definition_id.is_empty():
		return {"ok": false, "reason": "Shop offer is not currently purchasable"}
	if offer.consumed:
		return {"ok": false, "reason": "Shop offer has already been purchased"}
	if candidate.bankroll < offer.price:
		return {"ok": false, "reason": "Bankroll cannot afford this shop offer"}
	if _carry_is_full(candidate):
		return {"ok": false, "reason": "Both carry locations are full; create legal carry space before purchasing"}
	var destination := String(action.payload.get("destination", ""))
	if destination.is_empty():
		destination = "active" if candidate.active_count() < candidate.unlocked_active_capacity else "reserve"
	var placement := _materialize_definition(candidate, offer.definition_id, destination, "shop", offer.offer_id, offer.price)
	if not bool(placement.get("ok", false)):
		return placement
	candidate.bankroll -= offer.price
	offer.consumed = true
	shop.offers[offer_index] = offer.to_dict()
	candidate.shop_state = shop.to_dict()
	candidate.last_event = {
		"kind": "shop_purchase",
		"offer_id": offer.offer_id,
		"instance_id": String(placement.get("instance_id", "")),
		"price": offer.price,
		"bankroll": candidate.bankroll,
		"destination": destination,
		"message": "Shop purchase committed and placed in carry."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_sell_modifier(candidate: RunState, action: RunAction) -> Dictionary:
	var instance_id := String(action.payload.get("instance_id", ""))
	if not candidate.modifier_instances.has(instance_id):
		return {"ok": false, "reason": "Modifier instance is not owned"}
	var instance: Dictionary = candidate.modifier_instances[instance_id]
	if not Array(instance.get("attached_card_ids", [])).is_empty():
		return {"ok": false, "reason": "An attached modifier must be detached before sale"}
	var proceeds := ModifierResalePolicy.quote(instance, modifier_registry)
	if proceeds < 0:
		return {"ok": false, "reason": "Modifier is not currently saleable"}
	_remove_modifier(candidate, instance_id)
	candidate.bankroll += proceeds
	candidate.last_event = {
		"kind": "shop_sale",
		"instance_id": instance_id,
		"proceeds": proceeds,
		"bankroll": candidate.bankroll,
		"message": "Modifier sold for the configured resale value."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_salvage_modifier(candidate: RunState, action: RunAction) -> Dictionary:
	if not _active_has_effect_seam(candidate, ModifierEffectRegistry.SEAM_SALVAGE_TRANSACTION):
		return {"ok": false, "reason": "Salvage is not active in the authoritative build"}
	var instance_id := String(action.payload.get("instance_id", ""))
	if instance_id.is_empty() or not candidate.modifier_instances.has(instance_id):
		return {"ok": false, "reason": "Modifier instance is not owned"}
	if not candidate.active_modifier_ids.has(instance_id) and not candidate.reserve_modifier_ids.has(instance_id):
		return {"ok": false, "reason": "Modifier instance has no legal carry location"}
	var instance: Dictionary = candidate.modifier_instances[instance_id]
	var proceeds := ModifierResalePolicy.salvage_quote(instance, modifier_registry)
	if proceeds < 0:
		return {"ok": false, "reason": "Modifier is not currently salvageable"}
	_remove_modifier(candidate, instance_id)
	candidate.bankroll += proceeds
	candidate.last_event = {
		"kind": "modifier_salvaged",
		"instance_id": instance_id,
		"proceeds": proceeds,
		"bankroll": candidate.bankroll,
		"message": "Modifier permanently discarded for half its base shop value."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_preserve_shop_offer(candidate: RunState, action: RunAction) -> Dictionary:
	if not _active_has_effect_seam(candidate, ModifierEffectRegistry.SEAM_SHOP_OFFER_PRESERVATION):
		return {"ok": false, "reason": "Rain Check is not active in the authoritative build"}
	var shop := ShopState.from_dict(candidate.shop_state)
	if not shop.preserved_offer.is_empty():
		return {"ok": false, "reason": "A shop offer is already preserved for the next month"}
	var offer_id := String(action.payload.get("offer_id", ""))
	var offer_index := _shop_offer_index(shop.offers, offer_id)
	if offer_index < 0:
		return {"ok": false, "reason": "Shop offer does not exist"}
	var offer := ShopOffer.from_dict(shop.offers[offer_index])
	if not offer.available or offer.consumed or offer.definition_id.is_empty():
		return {"ok": false, "reason": "Only an unpurchased available offer can be preserved"}
	offer.available = false
	offer.preserved = true
	shop.offers[offer_index] = offer.to_dict()
	shop.preserved_offer = offer.to_dict()
	candidate.shop_state = shop.to_dict()
	candidate.last_event = {
		"kind": "shop_offer_preserved",
		"offer_id": offer.offer_id,
		"definition_id": offer.definition_id,
		"message": "One unpurchased shop offer is preserved for next month."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_reroll_shop(candidate: RunState, action: RunAction) -> Dictionary:
	var shop := ShopState.from_dict(candidate.shop_state)
	var costs := candidate.rules().shop_reroll_costs
	if shop.reroll_count >= costs.size():
		return {"ok": false, "reason": "No shop rerolls remain"}
	var cost := int(costs[shop.reroll_count])
	if candidate.bankroll < cost:
		return {"ok": false, "reason": "Bankroll cannot afford this shop reroll"}
	var duplicate_policy := String(action.payload.get("duplicate_policy", ""))
	if duplicate_policy.is_empty():
		duplicate_policy = candidate.rules().duplicate_modifier_policy
	var next_generation := shop.generation_id + 1
	var generated := ShopGenerator.generate(candidate.month, next_generation, candidate.root_seed, modifier_registry, duplicate_policy, _owned_nonstackable_definition_ids(candidate))
	if not bool(generated.get("ok", false)):
		return generated
	var next_shop := ShopState.from_dict(generated.get("state", {}))
	next_shop.entered = true
	next_shop.reroll_count = shop.reroll_count + 1
	next_shop.preserved_offer = shop.preserved_offer.duplicate(true)
	candidate.bankroll -= cost
	candidate.shop_state = next_shop.to_dict()
	candidate.generation_counters["shop"] = next_generation
	candidate.last_event = {
		"kind": "shop_rerolled",
		"generation_id": next_generation,
		"reroll_index": next_shop.reroll_count,
		"cost": cost,
		"bankroll": candidate.bankroll,
		"offer_ids": _shop_offer_ids(next_shop),
		"message": "Shop rerolled with the same six category slots."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_exit_shop(candidate: RunState) -> Dictionary:
	var shop := ShopState.from_dict(candidate.shop_state)
	if not shop.entered or shop.offers.size() != ShopState.SLOT_IDS.size():
		return {"ok": false, "reason": "Shop is not ready to exit"}
	candidate.phase = RunState.PHASE_FINALIZE
	candidate.last_event = {
		"kind": "shop_exited",
		"message": "Shop closed; the prepared build can now be finalized."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_finalize_build(candidate: RunState) -> Dictionary:
	if not candidate.reward_state.is_empty() and not RewardState.from_dict(candidate.reward_state).selection_committed:
		return {"ok": false, "reason": "Reward selection must be resolved before finalization"}
	if not candidate.reward_state.is_empty() and not RewardState.from_dict(candidate.reward_state).pending_acquisition.is_empty():
		return {"ok": false, "reason": "Pending reward acquisition must be placed before finalization"}
	candidate.phase = RunState.PHASE_TRANSITION
	candidate.last_event = {
		"kind": "build_finalized",
		"month": candidate.month,
		"bankroll": candidate.bankroll,
		"active_modifier_ids": candidate.active_modifier_ids.duplicate(),
		"reserve_modifier_ids": candidate.reserve_modifier_ids.duplicate(),
		"message": "January build finalized; February is ready to begin."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _apply_begin_february(candidate: RunState) -> Dictionary:
	candidate.month = 2
	candidate.phase = RunState.PHASE_FEBRUARY_PLACEHOLDER
	candidate.last_event = {
		"kind": "february_placeholder_started",
		"month": 2,
		"message": "February placeholder reached; February gameplay is deferred by roadmap."
	}
	return {"ok": true, "events": [candidate.last_event.duplicate(true)]}

func _materialize_definition(candidate: RunState, definition_id: String, destination: String, source: String, stable_suffix: String, purchase_price: int = 0) -> Dictionary:
	if destination != "active" and destination != "reserve":
		return {"ok": false, "reason": "Modifier destination is invalid"}
	if destination == "active" and candidate.active_count() >= candidate.unlocked_active_capacity:
		return {"ok": false, "reason": "Active carry capacity is full"}
	if destination == "reserve" and candidate.reserve_count() >= candidate.reserve_capacity:
		return {"ok": false, "reason": "Reserve carry capacity is full"}
	var instance_id := "modifier_%s" % stable_suffix
	if candidate.modifier_instances.has(instance_id):
		return {"ok": false, "reason": "Modifier instance ID already exists"}
	var instance := _new_modifier_instance(candidate, definition_id, destination, source, stable_suffix, purchase_price)
	if not bool(instance.get("ok", false)):
		return instance
	candidate.modifier_instances[instance_id] = instance["instance"]
	if destination == "active":
		candidate.active_modifier_ids.append(instance_id)
	else:
		candidate.reserve_modifier_ids.append(instance_id)
	return {"ok": true, "instance_id": instance_id}

func _remove_modifier(candidate: RunState, instance_id: String) -> void:
	candidate.active_modifier_ids.erase(instance_id)
	candidate.reserve_modifier_ids.erase(instance_id)
	candidate.modifier_instances.erase(instance_id)
	for raw_card_id in candidate.card_upgrade_attachments.keys():
		var card_id := String(raw_card_id)
		var attached: Array = Array(candidate.card_upgrade_attachments[raw_card_id]).duplicate()
		attached.erase(instance_id)
		if attached.is_empty():
			candidate.card_upgrade_attachments.erase(card_id)
		else:
			candidate.card_upgrade_attachments[card_id] = attached

func _shop_offer_index(offers: Array, offer_id: String) -> int:
	for index in range(offers.size()):
		if offers[index] is Dictionary and String(offers[index].get("offer_id", "")) == offer_id:
			return index
	return -1

func _shop_offer_ids(shop: ShopState) -> Array:
	var result: Array = []
	for raw_offer in shop.offers:
		if raw_offer is Dictionary:
			result.append(String(raw_offer.get("offer_id", "")))
	return result
