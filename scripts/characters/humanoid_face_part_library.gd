class_name HumanoidFacePartLibrary
extends RefCounted

const CATALOG_PATH := "res://data/humanoid_face_parts.json"
const LEGACY_EYE_ID := "eyes_dark"
const STANDARD_PART_IDS := ["eyes", "brows", "noses", "mouths", "facial_marks"]

static var _catalog: Dictionary = {}
static var _loaded := false


static func catalog() -> Dictionary:
	if not _loaded:
		_catalog = _load_catalog()
		_loaded = true
	return _catalog.duplicate(true)


static func part_ids(people_id: String, part_id: String) -> Array[String]:
	var part := _part_definition(people_id, part_id)
	var result: Array[String] = []
	for value in part.get("ids", []):
		var entry := String(value)
		if not entry.is_empty():
			result.append(entry)
	return result


static func default_id(people_id: String, part_id: String) -> String:
	return String(_part_definition(people_id, part_id).get("default", ""))


static func resolve_id(people_id: String, part_id: String, requested_id: String) -> String:
	if part_id == "eyes" and requested_id == LEGACY_EYE_ID:
		return default_id(people_id, part_id)
	var valid_ids := part_ids(people_id, part_id)
	if valid_ids.has(requested_id):
		return requested_id
	return default_id(people_id, part_id)


static func display_name(part_value: String) -> String:
	if part_value.is_empty():
		return "None"
	return part_value.trim_prefix("face_mark_").replace("_", " ").capitalize()


static func reset_for_tests() -> void:
	_catalog.clear()
	_loaded = false


static func _part_definition(people_id: String, part_id: String) -> Dictionary:
	var people: Dictionary = catalog().get("people", {})
	var definition: Dictionary = people.get(people_id, {})
	var parts: Dictionary = definition.get("parts", {})
	return Dictionary(parts.get(part_id, {}))


static func _load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {}
	return (parser.data as Dictionary).duplicate(true)
