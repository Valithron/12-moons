class_name RunState
extends RefCounted

const SCHEMA_VERSION := "run-state-v1"
const PHASE_MONTH_MATCH := "month_match"
const PHASE_SETTLEMENT := "settlement"
const PHASE_LIQUIDATION := "liquidation"
const PHASE_REWARD := "reward"
const PHASE_CARRY := "carry"
const PHASE_SHOP := "shop"
const PHASE_FINALIZE := "finalize"
const PHASE_TRANSITION := "transition"
const PHASE_BANKRUPT := "bankrupt"
const PHASE_COMPLETE := "complete"
const PHASE_FEBRUARY_PLACEHOLDER := "february_placeholder"

var root_seed: int = 0
var month: int = 1
var phase: String = PHASE_MONTH_MATCH
var bankroll: int = 0
var unlocked_active_capacity: int = 0
var reserve_capacity: int = 4
var maximum_active_capacity: int = 8
var active_modifier_ids: Array = []
var reserve_modifier_ids: Array = []
var modifier_instances: Dictionary = {}
var card_upgrade_attachments: Dictionary = {}
var pending_settlement: Dictionary = {}
var ingested_match_ids: Array = []
var settled_match_ids: Array = []
var last_match_result: Dictionary = {}
var reward_state: Dictionary = {}
var shop_state: Dictionary = {}
var generation_counters: Dictionary = {}
var last_event: Dictionary = {}
var rules_config: Dictionary = {}

static func fresh(seed_value: int, rules: RunRules = null) -> RunState:
	var actual_rules := rules if rules != null else RunRules.prototype()
	var result := RunState.new()
	result.root_seed = seed_value
	result.month = 1
	result.phase = PHASE_MONTH_MATCH
	result.bankroll = actual_rules.starting_bankroll
	result.unlocked_active_capacity = 0
	result.reserve_capacity = actual_rules.reserve_capacity
	result.maximum_active_capacity = actual_rules.maximum_active_capacity
	result.rules_config = actual_rules.to_dict()
	return result

func rules() -> RunRules:
	return RunRules.from_dict(rules_config)

func active_count() -> int:
	return active_modifier_ids.size()

func reserve_count() -> int:
	return reserve_modifier_ids.size()

func occupied_modifier_count() -> int:
	return active_count() + reserve_count()

func canonical_dict() -> Dictionary:
	var canonical_instances: Array = []
	var instance_ids := modifier_instances.keys()
	instance_ids.sort()
	for raw_id in instance_ids:
		var instance: Dictionary = modifier_instances[raw_id].duplicate(true)
		instance["instance_id"] = String(raw_id)
		canonical_instances.append(instance)
	return {
		"schema_version": SCHEMA_VERSION,
		"root_seed": root_seed,
		"month": month,
		"phase": phase,
		"bankroll": bankroll,
		"unlocked_active_capacity": unlocked_active_capacity,
		"reserve_capacity": reserve_capacity,
		"maximum_active_capacity": maximum_active_capacity,
		"active_modifier_ids": _sorted_strings(active_modifier_ids),
		"reserve_modifier_ids": _sorted_strings(reserve_modifier_ids),
		"modifier_instances": canonical_instances,
		"card_upgrade_attachments": _canonical_attachments(),
		"pending_settlement": pending_settlement.duplicate(true),
		"ingested_match_ids": _sorted_strings(ingested_match_ids),
		"settled_match_ids": _sorted_strings(settled_match_ids),
		"last_match_result": last_match_result.duplicate(true),
		"reward_state": reward_state.duplicate(true),
		"shop_state": shop_state.duplicate(true),
		"generation_counters": generation_counters.duplicate(true),
		"last_event": last_event.duplicate(true),
		"rules_config": rules_config.duplicate(true)
	}

func canonical_json() -> String:
	return JSON.stringify(canonical_dict())

func state_hash() -> String:
	return canonical_json().sha256_text()

func to_dict() -> Dictionary:
	var result := canonical_dict()
	result["modifier_instances"] = modifier_instances.duplicate(true)
	result["card_upgrade_attachments"] = card_upgrade_attachments.duplicate(true)
	return result

static func from_dict(data: Dictionary) -> RunState:
	var result := RunState.new()
	result.root_seed = int(data.get("root_seed", 0))
	result.month = int(data.get("month", 1))
	result.phase = String(data.get("phase", PHASE_MONTH_MATCH))
	result.bankroll = int(data.get("bankroll", 0))
	result.unlocked_active_capacity = int(data.get("unlocked_active_capacity", 0))
	result.reserve_capacity = int(data.get("reserve_capacity", 4))
	result.maximum_active_capacity = int(data.get("maximum_active_capacity", 8))
	result.active_modifier_ids = Array(data.get("active_modifier_ids", [])).duplicate()
	result.reserve_modifier_ids = Array(data.get("reserve_modifier_ids", [])).duplicate()
	var raw_instances = data.get("modifier_instances", {})
	if raw_instances is Dictionary:
		result.modifier_instances = raw_instances.duplicate(true)
	var raw_attachments = data.get("card_upgrade_attachments", {})
	if raw_attachments is Dictionary:
		result.card_upgrade_attachments = raw_attachments.duplicate(true)
	var raw_pending = data.get("pending_settlement", {})
	if raw_pending is Dictionary:
		result.pending_settlement = raw_pending.duplicate(true)
	result.ingested_match_ids = Array(data.get("ingested_match_ids", [])).duplicate()
	result.settled_match_ids = Array(data.get("settled_match_ids", [])).duplicate()
	var raw_match_result = data.get("last_match_result", {})
	if raw_match_result is Dictionary:
		result.last_match_result = raw_match_result.duplicate(true)
	var raw_reward = data.get("reward_state", {})
	if raw_reward is Dictionary:
		result.reward_state = raw_reward.duplicate(true)
	var raw_shop = data.get("shop_state", {})
	if raw_shop is Dictionary:
		result.shop_state = raw_shop.duplicate(true)
	var raw_counters = data.get("generation_counters", {})
	if raw_counters is Dictionary:
		result.generation_counters = raw_counters.duplicate(true)
	var raw_event = data.get("last_event", {})
	if raw_event is Dictionary:
		result.last_event = raw_event.duplicate(true)
	var raw_rules = data.get("rules_config", RunRules.prototype().to_dict())
	if raw_rules is Dictionary:
		result.rules_config = raw_rules.duplicate(true)
	return result

func invariant_errors(catalog: CardCatalog = null, registry: ModifierRegistry = null) -> Array:
	var errors: Array = []
	var valid_phases := [PHASE_MONTH_MATCH, PHASE_SETTLEMENT, PHASE_LIQUIDATION, PHASE_REWARD, PHASE_CARRY, PHASE_SHOP, PHASE_FINALIZE, PHASE_TRANSITION, PHASE_BANKRUPT, PHASE_COMPLETE, PHASE_FEBRUARY_PLACEHOLDER]
	if not valid_phases.has(phase):
		errors.append("Unknown run phase: %s" % phase)
	if month < 1 or month > 12:
		errors.append("Month is outside the legal range: %d" % month)
	if bankroll < 0:
		errors.append("Bankroll cannot be negative")
	if unlocked_active_capacity < 0 or unlocked_active_capacity > maximum_active_capacity:
		errors.append("Unlocked active capacity is invalid")
	if maximum_active_capacity < 0 or reserve_capacity < 0:
		errors.append("Carry capacities cannot be negative")
	if active_count() > unlocked_active_capacity:
		errors.append("Active modifiers exceed unlocked active capacity")
	if reserve_count() > reserve_capacity:
		errors.append("Reserve modifiers exceed reserve capacity")
	var seen_locations: Dictionary = {}
	for raw_id in active_modifier_ids:
		var id := String(raw_id)
		if seen_locations.has(id):
			errors.append("Modifier appears in more than one location: %s" % id)
		seen_locations[id] = true
		if not modifier_instances.has(id):
			errors.append("Active modifier instance is missing: %s" % id)
		else:
			var active_instance: Dictionary = modifier_instances[id]
			if String(active_instance.get("location", "")) != "active":
				errors.append("Active modifier location disagrees with its index: %s" % id)
	for raw_id in reserve_modifier_ids:
		var id := String(raw_id)
		if seen_locations.has(id):
			errors.append("Modifier appears in more than one location: %s" % id)
		seen_locations[id] = true
		if not modifier_instances.has(id):
			errors.append("Reserve modifier instance is missing: %s" % id)
		else:
			var reserve_instance: Dictionary = modifier_instances[id]
			if String(reserve_instance.get("location", "")) != "reserve":
				errors.append("Reserve modifier location disagrees with its index: %s" % id)
	for raw_id in modifier_instances.keys():
		var id := String(raw_id)
		var instance: Dictionary = modifier_instances[raw_id]
		if not seen_locations.has(id) and String(instance.get("location", "")).is_empty():
			errors.append("Owned modifier has no location: %s" % id)
		if registry != null and not registry.has_definition(String(instance.get("definition_id", ""))):
			errors.append("Owned modifier references unknown definition: %s" % instance.get("definition_id", ""))
	for raw_card_id in card_upgrade_attachments.keys():
		var card_id := String(raw_card_id)
		if catalog != null and not catalog.has_card(card_id):
			errors.append("Card upgrade references unknown card: %s" % card_id)
		var attached_seen: Dictionary = {}
		for raw_instance_id in Array(card_upgrade_attachments[raw_card_id]):
			var instance_id := String(raw_instance_id)
			if attached_seen.has(instance_id):
				errors.append("Card upgrade is attached to the same modifier twice: %s" % instance_id)
			attached_seen[instance_id] = true
			if not modifier_instances.has(instance_id):
				errors.append("Card attachment references unknown modifier: %s" % raw_instance_id)
				continue
			var attached_instance: Dictionary = modifier_instances[instance_id]
			if registry != null:
				var attached_definition := registry.get_definition(String(attached_instance.get("definition_id", "")))
				if attached_definition == null or attached_definition.family != "card_upgrade":
					errors.append("Only Card Upgrade modifiers may attach to a physical card: %s" % instance_id)
			var declared_cards := Array(attached_instance.get("attached_card_ids", []))
			if not declared_cards.has(card_id):
				errors.append("Card attachment index disagrees with modifier instance: %s" % instance_id)
	for raw_instance_id in modifier_instances.keys():
		var instance_id := String(raw_instance_id)
		var instance: Dictionary = modifier_instances[raw_instance_id]
		for raw_card_id in Array(instance.get("attached_card_ids", [])):
			var card_id := String(raw_card_id)
			if not card_upgrade_attachments.has(card_id) or not Array(card_upgrade_attachments[card_id]).has(instance_id):
				errors.append("Modifier attachment disagrees with card index: %s -> %s" % [instance_id, card_id])
	if not pending_settlement.is_empty():
		var pending := PendingSettlement.from_dict(pending_settlement)
		if pending.match_id.is_empty() or pending.amount_due <= 0:
			errors.append("Pending settlement must identify a positive debt")
	if ingested_match_ids.size() != _unique_string_count(ingested_match_ids):
		errors.append("Duplicate ingested match ID")
	if settled_match_ids.size() != _unique_string_count(settled_match_ids):
		errors.append("Duplicate settled match ID")
	for rule_error in rules().invariant_errors():
		errors.append(String(rule_error))
	if not reward_state.is_empty():
		for reward_error in RewardState.from_dict(reward_state).invariant_errors():
			errors.append(String(reward_error))
	if not shop_state.is_empty():
		for shop_error in ShopState.from_dict(shop_state).invariant_errors():
			errors.append(String(shop_error))
	return errors

func invariants_ok(catalog: CardCatalog = null, registry: ModifierRegistry = null) -> bool:
	return invariant_errors(catalog, registry).is_empty()

func _sorted_strings(values: Array) -> Array:
	var result: Array = []
	for value in values:
		result.append(String(value))
	result.sort()
	return result

func _canonical_attachments() -> Array:
	var result: Array = []
	var card_ids := card_upgrade_attachments.keys()
	card_ids.sort()
	for raw_card_id in card_ids:
		result.append({"card_id": String(raw_card_id), "instance_ids": _sorted_strings(Array(card_upgrade_attachments[raw_card_id]))})
	return result

func _unique_string_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value in values:
		unique[String(value)] = true
	return unique.size()
