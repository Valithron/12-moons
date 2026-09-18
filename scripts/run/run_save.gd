class_name RunSave
extends RefCounted

const FORMAT_VERSION := "run-save-v1"

static func envelope(controller: RunController, match_state: GameState = null) -> Dictionary:
	var payload := {
		"format_version": FORMAT_VERSION,
		"run_state": controller.state.to_dict(),
		"run_journal": controller.journal.to_dict(),
		"match_state": match_state.to_dict() if match_state != null else {}
	}
	return {
		"format_version": FORMAT_VERSION,
		"checksum": JSON.stringify(payload).sha256_text(),
		"payload": payload
	}

static func decode(envelope_data: Dictionary, registry: ModifierRegistry = null) -> Dictionary:
	var format_version := String(envelope_data.get("format_version", ""))
	if format_version == RunMigration.LEGACY_VERSION:
		var migrated := RunMigration.migrate(envelope_data)
		if not bool(migrated.get("ok", true)):
			return migrated
		return decode(migrated, registry)
	if format_version != FORMAT_VERSION:
		return {"ok": false, "reason": "Unsupported save format: %s" % format_version}
	var raw_payload = envelope_data.get("payload", {})
	if not raw_payload is Dictionary:
		return {"ok": false, "reason": "Save payload must be an object"}
	var payload: Dictionary = raw_payload
	var expected_checksum := String(envelope_data.get("checksum", ""))
	if expected_checksum.is_empty() or JSON.stringify(payload).sha256_text() != expected_checksum:
		return {"ok": false, "reason": "Save checksum mismatch"}
	var raw_state = payload.get("run_state", {})
	if not raw_state is Dictionary:
		return {"ok": false, "reason": "Save has no run state"}
	var run_state := RunState.from_dict(raw_state)
	var effective_registry := registry if registry != null else ModifierRegistry.new()
	var errors := run_state.invariant_errors(null, effective_registry)
	if not errors.is_empty():
		return {"ok": false, "reason": "Saved run state is invalid: %s" % "; ".join(errors)}
	return {"ok": true, "payload": payload}

static func restore_controller(envelope_data: Dictionary, registry: ModifierRegistry = null, catalog: CardCatalog = null) -> Dictionary:
	var decoded := decode(envelope_data, registry)
	if not bool(decoded.get("ok", false)):
		return decoded
	var payload: Dictionary = decoded["payload"]
	var state := RunState.from_dict(payload["run_state"])
	var controller := RunController.new(state.root_seed, state, null, catalog)
	controller.modifier_registry = registry if registry != null else ModifierRegistry.new()
	controller.journal = RunJournal.from_dict(payload.get("run_journal", {}))
	return {"ok": true, "controller": controller, "match_state": payload.get("match_state", {}).duplicate(true)}

static func save_file(path: String, controller: RunController, match_state: GameState = null) -> Dictionary:
	if path.is_empty() or controller == null:
		return {"ok": false, "reason": "Save path and controller are required"}
	var data := envelope(controller, match_state)
	var temporary_path := "%s.tmp" % path
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "reason": "Unable to open temporary save"}
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var verify_file := FileAccess.open(temporary_path, FileAccess.READ)
	if verify_file == null:
		return {"ok": false, "reason": "Unable to verify temporary save"}
	var verified: Variant = JSON.parse_string(verify_file.get_as_text())
	verify_file.close()
	if not verified is Dictionary or not bool(decode(verified).get("ok", false)):
		return {"ok": false, "reason": "Temporary save verification failed"}
	var backup_path := "%s.bak" % path
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, backup_path)
	var rename_error := DirAccess.rename_absolute(temporary_path, path)
	if rename_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, path)
		return {"ok": false, "reason": "Unable to commit save file"}
	return {"ok": true, "path": path, "checksum": String(data.get("checksum", ""))}

static func load_file(path: String, registry: ModifierRegistry = null) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "reason": "Unable to open save file"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {"ok": false, "reason": "Save file is not valid JSON"}
	return decode(parsed, registry)
