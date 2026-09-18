class_name DrawRevealDecisionRequest
extends RefCounted

var actor_id: int = 0
var revealed_card_id: String = ""
var legal_action_ids: Array = []
var reason: String = ""

func to_dict() -> Dictionary:
	return {"actor_id": actor_id, "revealed_card_id": revealed_card_id, "legal_action_ids": legal_action_ids.duplicate(), "reason": reason}
