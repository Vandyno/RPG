class_name ContentHumanoidFaceValidator
extends RefCounted

const HumanoidFacePartLibrary = preload(
	"res://scripts/characters/humanoid_face_part_library.gd"
)


static func validate(content: ContentDatabase, errors: Array[String]) -> void:
	var catalog: Dictionary = content.humanoid_face_parts
	if int(catalog.get("version", 0)) != 1:
		errors.append("Humanoid face catalog version must be 1.")
		return
	var people_value: Variant = catalog.get("people", {})
	if not people_value is Dictionary:
		errors.append("Humanoid face catalog people must be a dictionary.")
		return
	var people: Dictionary = people_value
	for people_id in content.people_ids():
		var definition_value: Variant = people.get(people_id, {})
		if not definition_value is Dictionary:
			errors.append("Humanoid face catalog is missing people %s." % people_id)
			continue
		_validate_people_parts(String(people_id), definition_value, errors)
	for people_id in people:
		if not content.has_people(String(people_id)):
			errors.append(
				"Humanoid face catalog references unknown people %s." % String(people_id)
			)


static func _validate_people_parts(
	people_id: String, value: Dictionary, errors: Array[String]
) -> void:
	var parts_value: Variant = value.get("parts", {})
	if not parts_value is Dictionary:
		errors.append("Humanoid face catalog %s parts must be a dictionary." % people_id)
		return
	var parts: Dictionary = parts_value
	for part_id in HumanoidFacePartLibrary.STANDARD_PART_IDS:
		var part_value: Variant = parts.get(part_id, {})
		if not part_value is Dictionary:
			errors.append("Humanoid face catalog %s is missing %s." % [people_id, part_id])
			continue
		var part: Dictionary = part_value
		if not part.get("default", "") is String:
			errors.append("Humanoid face catalog %s %s default must be a string." % [people_id, part_id])
		var ids_value: Variant = part.get("ids", [])
		if not ids_value is Array or (ids_value as Array).is_empty():
			errors.append("Humanoid face catalog %s %s ids must be a nonempty array." % [people_id, part_id])
			continue
		for entry in ids_value:
			if not entry is String or String(entry).is_empty():
				errors.append("Humanoid face catalog %s %s has a blank id." % [people_id, part_id])
