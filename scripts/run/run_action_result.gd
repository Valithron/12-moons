class_name RunActionResult
extends RefCounted

var accepted: bool = false
var reason: String = ""
var action: RunAction
var before_hash: String = ""
var state_hash: String = ""
var events: Array = []

static func rejected(message: String, unchanged_hash: String) -> RunActionResult:
	var result := RunActionResult.new()
	result.reason = message
	result.before_hash = unchanged_hash
	result.state_hash = unchanged_hash
	return result

static func accepted_action(submitted: RunAction, before: String, after: String, emitted_events: Array = []) -> RunActionResult:
	var result := RunActionResult.new()
	result.accepted = true
	result.action = submitted
	result.before_hash = before
	result.state_hash = after
	result.events = emitted_events.duplicate(true)
	return result
