class_name RunAction
extends RefCounted

const RESOLVE_MONTH := "resolve_month"
const SETTLE := "settle"
const LIQUIDATE := "liquidate"
const GENERATE_REWARD := "generate_reward"
const CHOOSE_REWARD := "choose_reward"
const REFUSE_REWARD := "refuse_reward"
const PLACE_PENDING_ACQUISITION := "place_pending_acquisition"
const MOVE_MODIFIER := "move_modifier"
const ATTACH_CARD_UPGRADE := "attach_card_upgrade"
const DETACH_CARD_UPGRADE := "detach_card_upgrade"
const ENTER_SHOP := "enter_shop"
const BUY_OFFER := "buy_offer"
const SELL_MODIFIER := "sell_modifier"
const REROLL_SHOP := "reroll_shop"
const EXIT_SHOP := "exit_shop"
const FINALIZE_BUILD := "finalize_build"
const BEGIN_FEBRUARY := "begin_february"

var action_type: String = ""
var actor_id: int = 0
var payload: Dictionary = {}

func _init(type: String = "", actor: int = 0, data: Dictionary = {}) -> void:
	action_type = type
	actor_id = actor
	payload = data.duplicate(true)

func to_dict() -> Dictionary:
	return {"action_type": action_type, "actor_id": actor_id, "payload": payload.duplicate(true)}

static func from_dict(data: Dictionary) -> RunAction:
	var raw_payload = data.get("payload", {})
	return RunAction.new(String(data.get("action_type", "")), int(data.get("actor_id", 0)), raw_payload if raw_payload is Dictionary else {})
