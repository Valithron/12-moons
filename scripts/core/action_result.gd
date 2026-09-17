class_name ActionResult
extends RefCounted

var accepted: bool = false
var reason: String = ""
var action: GameAction
var captured_ids: Array = []
var state_hash: String = ""

static func rejected(message: String) -> ActionResult:
	var result := ActionResult.new()
	result.accepted = false
	result.reason = message
	return result

static func accepted_action(submitted: GameAction, resulting_hash: String, captured: Array) -> ActionResult:
	var result := ActionResult.new()
	result.accepted = true
	result.action = submitted
	result.state_hash = resulting_hash
	result.captured_ids = captured.duplicate()
	return result
