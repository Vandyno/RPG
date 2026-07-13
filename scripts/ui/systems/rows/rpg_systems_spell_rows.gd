class_name RpgSystemsSpellRows
extends RefCounted

const RpgSystemsRowData = preload("res://scripts/ui/systems/rows/rpg_systems_row_data.gd")
const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")


static func category_labels() -> Array:
	return ["All", "Fire", "Frost", "Storm", "Restore", "Necromancy", "Utility"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var tab := SystemsTabState.spells(state)
	var rows_data: Array[Dictionary] = []
	for spell in RpgSystemsRowData.array_field(tab.get("spells", [])):
		if not spell is Dictionary:
			continue
		var school := String(spell.get("school", "Utility"))
		if category != "all" and category != school.to_lower():
			continue
		var name := String(spell.get("name", "Spell"))
		var spell_id := String(spell.get("spell_id", ""))
		var assigned := String(spell.get("assigned_label", ""))
		var assignment := "Unassigned" if assigned.is_empty() else "Assigned: %s" % assigned
		var mana := int(spell.get("mana_cost", 0))
		var drain := float(spell.get("mana_drain_per_second", mana))
		rows_data.append({
			"id": "spell_%s" % spell_id,
			"spell_id": spell_id,
			"title": name,
			"subtitle": "%s school - %s" % [school, assignment],
			"meta": "%s MP/s" % RpgSystemsRowData.format_float(drain),
			"detail": _spell_detail(spell)
		})
	if rows_data.is_empty():
		rows_data.append({
			"id": "spells_empty_%s" % category,
			"title": "No Spells",
			"subtitle": "No known magic here.",
			"meta": "Spells",
			"detail": "No spells available."
		})
	return rows_data


static func _spell_detail(spell: Dictionary) -> String:
	var assigned := String(spell.get("assigned_label", ""))
	var drain := float(spell.get("mana_drain_per_second", spell.get("mana_cost", 0)))
	return "\n".join([
		String(spell.get("name", "Spell")),
		"School: %s" % String(spell.get("school", "Utility")),
		"Mana cost/drain: %s per second" % RpgSystemsRowData.format_float(drain),
		"Range: %s" % String(spell.get("range", "")),
		"Behavior: %s" % String(spell.get("behavior", "")),
		"Assigned slot: %s" % ("None" if assigned.is_empty() else assigned)
	])
