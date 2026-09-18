class_name RunRules
extends RefCounted

const CONFIG_VERSION := "run-rules-v1"
const REWARD_POLICY_WHOLE_POOL := "whole_pool"
const REWARD_POLICY_FAMILY_QUOTAS := "family_quotas"

var starting_bankroll: int = 20
var reserve_capacity: int = 4
var maximum_active_capacity: int = 8
var reward_refusal_cash: int = 2
var shop_reroll_costs: Array = [1, 2]
var reward_policy: String = REWARD_POLICY_WHOLE_POOL
var duplicate_modifier_policy: String = "unique_definition"
var reward_wider_choice: bool = false
var active_unlock_schedule: Dictionary = {
	"1": 1,
	"2": 2,
	"3": 3,
	"4": 4,
	"5": 5,
	"6": 6,
	"7": 7,
	"8": 8
}

static func prototype() -> RunRules:
	return RunRules.new()

func active_capacity_after_month(completed_month: int) -> int:
	return clampi(int(active_unlock_schedule.get(str(completed_month), 0)), 0, maximum_active_capacity)

func to_dict() -> Dictionary:
	return {
		"config_version": CONFIG_VERSION,
		"starting_bankroll": starting_bankroll,
		"reserve_capacity": reserve_capacity,
		"maximum_active_capacity": maximum_active_capacity,
		"reward_refusal_cash": reward_refusal_cash,
		"shop_reroll_costs": shop_reroll_costs.duplicate(),
		"reward_policy": reward_policy,
		"duplicate_modifier_policy": duplicate_modifier_policy,
		"reward_wider_choice": reward_wider_choice,
		"active_unlock_schedule": active_unlock_schedule.duplicate(true)
	}

static func from_dict(data: Dictionary) -> RunRules:
	var result := RunRules.new()
	result.starting_bankroll = int(data.get("starting_bankroll", result.starting_bankroll))
	result.reserve_capacity = int(data.get("reserve_capacity", result.reserve_capacity))
	result.maximum_active_capacity = int(data.get("maximum_active_capacity", result.maximum_active_capacity))
	result.reward_refusal_cash = int(data.get("reward_refusal_cash", result.reward_refusal_cash))
	result.shop_reroll_costs = Array(data.get("shop_reroll_costs", result.shop_reroll_costs)).duplicate()
	result.reward_policy = String(data.get("reward_policy", result.reward_policy))
	if result.reward_policy.is_empty():
		result.reward_policy = REWARD_POLICY_WHOLE_POOL
	result.duplicate_modifier_policy = String(data.get("duplicate_modifier_policy", result.duplicate_modifier_policy))
	if result.duplicate_modifier_policy.is_empty():
		result.duplicate_modifier_policy = "unique_definition"
	result.reward_wider_choice = bool(data.get("reward_wider_choice", result.reward_wider_choice))
	var raw_schedule = data.get("active_unlock_schedule", result.active_unlock_schedule)
	if raw_schedule is Dictionary:
		result.active_unlock_schedule = raw_schedule.duplicate(true)
	return result

func invariant_errors() -> Array:
	var errors: Array = []
	if starting_bankroll < 0:
		errors.append("Starting bankroll cannot be negative")
	if reserve_capacity < 0:
		errors.append("Reserve capacity cannot be negative")
	if maximum_active_capacity < 0:
		errors.append("Maximum active capacity cannot be negative")
	if reward_refusal_cash < 0:
		errors.append("Reward refusal cash cannot be negative")
	if reward_policy != REWARD_POLICY_WHOLE_POOL and reward_policy != REWARD_POLICY_FAMILY_QUOTAS:
		errors.append("Reward policy is invalid")
	if duplicate_modifier_policy != "unique_definition" and duplicate_modifier_policy != "allow_definition_duplicates":
		errors.append("Duplicate modifier policy is invalid")
	for raw_cost in shop_reroll_costs:
		if int(raw_cost) < 0:
			errors.append("Shop reroll costs cannot be negative")
	return errors
