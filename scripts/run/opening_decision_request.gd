class_name OpeningDecisionRequest
extends RefCounted

var actor_id: int = 0
var visible_card_ids: Array = []
var legal_action_ids: Array = []
var reason: String = ""

func to_dict() -> Dictionary:
	return {"actor_id": actor_id, "visible_card_ids": visible_card_ids.duplicate(), "legal_action_ids": legal_action_ids.duplicate(), "reason": reason}
