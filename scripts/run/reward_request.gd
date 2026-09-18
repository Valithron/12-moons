class_name RewardRequest
extends RefCounted

const POLICY_WHOLE_POOL := "whole_pool"
const POLICY_FAMILY_QUOTAS := "family_quotas"
const SLOT_ANY := "ANY_MODIFIER"
const SLOT_CARD_UPGRADE := "CARD_UPGRADE"
const SLOT_HAND_MECHANIC := "HAND_MECHANIC"
const SLOT_STRATEGIC_META := "STRATEGIC_META"
const SLOT_WILDCARD := "WILDCARD"
const SLOT_SERVICE := "SERVICE"

var month: int = 1
var choice_count: int = 3
var slot_specs: Array = []
var reward_policy: String = ""
var duplicate_policy: String = ""
var excluded_definition_ids: Array = []
var source: String = "january_reward"
var generation_id: int = 0
var requires_policy_decision: bool = false
var unresolved_reason: String = ""

static func whole_pool(month_value: int = 1, duplicate_policy_value: String = "unique_definition") -> RewardRequest:
	var result := RewardRequest.new()
	result.month = month_value
	result.choice_count = 3
	result.slot_specs = [SLOT_ANY, SLOT_ANY, SLOT_ANY]
	result.reward_policy = POLICY_WHOLE_POOL
	result.duplicate_policy = duplicate_policy_value
	return result

static func family_quotas(month_value: int = 1, duplicate_policy_value: String = "unique_definition") -> RewardRequest:
	var result := RewardRequest.new()
	result.month = month_value
	result.choice_count = 3
	result.slot_specs = [SLOT_CARD_UPGRADE, SLOT_HAND_MECHANIC, SLOT_STRATEGIC_META]
	result.reward_policy = POLICY_FAMILY_QUOTAS
	result.duplicate_policy = duplicate_policy_value
	return result

func with_wider_choice() -> RewardRequest:
	var result := from_dict(to_dict())
	if result.choice_count != 3:
		return result
	result.choice_count = 4
	# Wider Choice is a whole-pool transformation. Family-quota requests remain
	# accepted as a legacy/test request shape, but do not create a second policy
	# branch for the fourth slot.
	result.reward_policy = POLICY_WHOLE_POOL
	result.slot_specs = [SLOT_ANY, SLOT_ANY, SLOT_ANY, SLOT_ANY]
	result.requires_policy_decision = false
	result.unresolved_reason = ""
	return result

func is_resolvable() -> bool:
	return not requires_policy_decision and choice_count == slot_specs.size() and not reward_policy.is_empty() and not duplicate_policy.is_empty()

func to_dict() -> Dictionary:
	return {
		"month": month,
		"choice_count": choice_count,
		"slot_specs": slot_specs.duplicate(),
		"reward_policy": reward_policy,
		"duplicate_policy": duplicate_policy,
		"excluded_definition_ids": excluded_definition_ids.duplicate(),
		"source": source,
		"generation_id": generation_id,
		"requires_policy_decision": requires_policy_decision,
		"unresolved_reason": unresolved_reason
	}

static func from_dict(data: Dictionary) -> RewardRequest:
	var result := RewardRequest.new()
	result.month = int(data.get("month", 1))
	result.choice_count = int(data.get("choice_count", 3))
	result.slot_specs = Array(data.get("slot_specs", [])).duplicate()
	result.reward_policy = String(data.get("reward_policy", ""))
	result.duplicate_policy = String(data.get("duplicate_policy", ""))
	result.excluded_definition_ids = Array(data.get("excluded_definition_ids", [])).duplicate()
	result.source = String(data.get("source", "january_reward"))
	result.generation_id = int(data.get("generation_id", 0))
	result.requires_policy_decision = bool(data.get("requires_policy_decision", false))
	result.unresolved_reason = String(data.get("unresolved_reason", ""))
	return result
