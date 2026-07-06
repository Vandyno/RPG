class_name RpgSystemsCharacterRows
extends RefCounted


static func category_labels() -> Array:
	return ["Overview", "Training", "Gear", "Effects"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	return RpgSystemsRowBuilder.category_filtered_rows(_character_rows(state), category)


static func _character_rows(state: Dictionary) -> Array[Dictionary]:
	var health := String(state.get("player_health", "Health unknown"))
	var mana := String(state.get("player_mana", "Mana unknown"))
	var progression := String(state.get("progression", "Level 1"))
	var equipment := String(state.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty"))
	var statuses := String(state.get("statuses", "none"))
	var rows_data: Array[Dictionary] = [
		{
			"id": "character_health",
			"title": "Vitals",
			"subtitle": "Health %s - Mana %s" % [health, mana],
			"meta": "Vitals",
			"detail": "Vitals\nCurrent Health: %s\nCurrent Mana: %s\nCondition: Stable" % [
				health, mana
			]
		},
		{
			"id": "character_progression",
			"title": "Training",
			"subtitle": progression,
			"meta": "Progression",
			"detail": RpgSystemsRowBuilder.first_non_empty(
				String(state.get("progression_details", "")),
				progression
			)
		},
		{
			"id": "character_equipment",
			"title": "Equipment",
			"subtitle": RpgSystemsRowBuilder.first_line(equipment),
			"meta": "Gear",
			"detail": "Equipped Gear\n%s\n\nDrag gear onto body slots to equip." % equipment
		},
		{
			"id": "character_effects",
			"title": "Active Effects",
			"subtitle": "None" if statuses == "none" else statuses,
			"meta": "Status",
			"detail": RpgSystemsRowBuilder.first_non_empty(
				String(state.get("status_details", "")),
				"No active effects."
			)
		}
	]
	var actions := RpgSystemsRowBuilder.array_field(state.get("progression_actions", []))
	if not actions.is_empty() and actions[0] is Dictionary:
		rows_data[1]["title"] = String(actions[0].get("text", "Training"))
		rows_data[1]["action_id"] = String(actions[0].get("id", ""))
	return rows_data
