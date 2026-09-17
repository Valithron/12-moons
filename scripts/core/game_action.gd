class_name GameAction
extends RefCounted

const SELECT_STARTER := "select_starter"
const PLAY_CARD := "play_card"
const CHOOSE_MATCH := "choose_match"
const STOP := "stop"
const KOI_KOI := "koi_koi"

var action_type: String = PLAY_CARD
var actor_id: int = 0
var card_id: String = ""
var target_card_id: String = ""

func _init(type: String = PLAY_CARD, actor: int = 0, played_card: String = "", target: String = "") -> void:
	action_type = type
	actor_id = actor
	card_id = played_card
	target_card_id = target

func to_dict() -> Dictionary:
	return {
		"action_type": action_type,
		"actor_id": actor_id,
		"card_id": card_id,
		"target_card_id": target_card_id
	}

static func from_dict(data: Dictionary) -> GameAction:
	return GameAction.new(
		String(data.get("action_type", PLAY_CARD)),
		int(data.get("actor_id", 0)),
		String(data.get("card_id", "")),
		String(data.get("target_card_id", ""))
	)

func equals(other: GameAction) -> bool:
	return other != null and to_dict() == other.to_dict()
