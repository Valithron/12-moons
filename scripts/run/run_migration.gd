class_name RunMigration
extends RefCounted

const LEGACY_VERSION := "run-save-v0"
const CURRENT_VERSION := "run-save-v1"

static func migrate(envelope_data: Dictionary) -> Dictionary:
	if String(envelope_data.get("format_version", "")) != LEGACY_VERSION:
		return {"ok": false, "reason": "Unsupported migration source"}
	var raw_payload = envelope_data.get("payload", {})
	if not raw_payload is Dictionary:
		return {"ok": false, "reason": "Legacy save payload must be an object"}
	var legacy: Dictionary = raw_payload
	var legacy_checksum := String(envelope_data.get("checksum", ""))
	if legacy_checksum.is_empty() or JSON.stringify(legacy).sha256_text() != legacy_checksum:
		return {"ok": false, "reason": "Legacy save checksum mismatch"}
	var state := RunState.fresh(int(legacy.get("root_seed", 0)))
	state.month = int(legacy.get("month", 1))
	state.phase = String(legacy.get("phase", RunState.PHASE_MONTH_MATCH))
	state.bankroll = int(legacy.get("bankroll", state.bankroll))
	state.active_modifier_ids = Array(legacy.get("active_modifier_ids", [])).duplicate()
	state.reserve_modifier_ids = Array(legacy.get("reserve_modifier_ids", [])).duplicate()
	var migrated_payload := {
		"format_version": CURRENT_VERSION,
		"run_state": state.to_dict(),
		"run_journal": {"root_seed": state.root_seed, "initial_state": state.to_dict(), "entries": []},
		"match_state": {}
	}
	return {
		"format_version": CURRENT_VERSION,
		"checksum": JSON.stringify(migrated_payload).sha256_text(),
		"payload": migrated_payload
	}
