class_name ContentDatabase
extends Node

const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")

var items: Dictionary = {}
var readables: Dictionary = {}
var quests: Dictionary = {}
var npcs: Dictionary = {}
var dialogues: Dictionary = {}
var locations: Dictionary = {}
var factions: Dictionary = {}
var shops: Dictionary = {}
var status_effects: Dictionary = {}
var spells: Dictionary = {}
var world_objects: Array[Dictionary] = []
var world_terrain: Dictionary = {}


func load_all() -> void:
	items = _load_dictionary("res://data/items.json")
	readables = _load_dictionary("res://data/readables.json")
	quests = _load_dictionary("res://data/quests.json")
	npcs = _load_dictionary("res://data/npcs.json")
	dialogues = _load_dictionary("res://data/dialogues.json")
	locations = _load_dictionary("res://data/locations.json")
	factions = _load_dictionary("res://data/factions.json")
	shops = _load_dictionary("res://data/shops.json")
	status_effects = _load_dictionary("res://data/status_effects.json")
	spells = _load_dictionary("res://data/spells.json")
	world_objects = _load_array("res://data/world_objects.json")
	world_terrain = _load_dictionary("res://data/world_terrain.json")


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_readable(readable_id: String) -> Dictionary:
	return readables.get(readable_id, {})


func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})


func get_npc(npc_id: String) -> Dictionary:
	return npcs.get(npc_id, {})


func get_dialogue(dialogue_id: String) -> Dictionary:
	return dialogues.get(dialogue_id, {})


func get_location(location_id: String) -> Dictionary:
	return locations.get(location_id, {})


func get_faction(faction_id: String) -> Dictionary:
	return factions.get(faction_id, {})


func get_shop(shop_id: String) -> Dictionary:
	return shops.get(shop_id, {})


func get_status_effect(status_id: String) -> Dictionary:
	return status_effects.get(status_id, {})


func get_spell(spell_id: String) -> Dictionary:
	return spells.get(spell_id, {})


func validate_all() -> Array[String]:
	var errors: Array[String] = []
	_validate_items(errors)
	_validate_readables(errors)
	_validate_quests(errors)
	_validate_factions(errors)
	_validate_npcs(errors)
	_validate_dialogues(errors)
	_validate_locations(errors)
	_validate_shops(errors)
	_validate_status_effects(errors)
	_validate_spells(errors)
	_validate_world_objects(errors)
	_validate_world_terrain(errors)
	return errors


func _load_dictionary(path: String) -> Dictionary:
	var parsed: Variant = _load_json(path)
	if parsed is Dictionary:
		return parsed
	push_warning("Expected dictionary JSON at %s" % path)
	return {}


func _load_array(path: String) -> Array[Dictionary]:
	var parsed: Variant = _load_json(path)
	var result: Array[Dictionary] = []
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary:
				result.append(entry)
		return result
	push_warning("Expected array JSON at %s" % path)
	return result


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Missing content file: %s" % path)
		return null
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null:
		push_warning("Invalid JSON: %s" % path)
	return parsed


func _validate_items(errors: Array[String]) -> void:
	for item_id in items:
		var item: Dictionary = items[item_id]
		_validate_keyed_id(item, String(item_id), "Item", errors)
		if String(item.get("name", "")).is_empty():
			errors.append("Item %s is missing name." % item_id)
		_validate_required_positive_number(item, "max_stack", "Item %s" % item_id, errors)
		_validate_optional_non_negative_number(item, "value", "Item %s" % item_id, errors)
		_validate_item_equipment_fields(item, String(item_id), errors)
		_validate_effect_list(item, "effects_on_use", "item %s" % item_id, errors)


func _validate_item_equipment_fields(
	item: Dictionary, item_id: String, errors: Array[String]
) -> void:
	if not item.has("equipment_slot"):
		return
	var slot := String(item.get("equipment_slot", ""))
	if not EquipmentSlots.is_supported(slot):
		errors.append("Item %s has unsupported equipment_slot %s." % [item_id, slot])
	_validate_optional_non_negative_number(item, "damage_bonus", "Item %s" % item_id, errors)
	_validate_optional_positive_number(
		item, "guard_counter_multiplier", "Item %s" % item_id, errors
	)


func _validate_readables(errors: Array[String]) -> void:
	for readable_id in readables:
		var readable: Dictionary = readables[readable_id]
		_validate_keyed_id(readable, String(readable_id), "Readable", errors)
		if String(readable.get("title", "")).is_empty():
			errors.append("Readable %s is missing title." % readable_id)
		if String(readable.get("body", "")).is_empty():
			errors.append("Readable %s is missing body." % readable_id)
		_validate_effect_list(readable, "effects_on_read", "readable %s" % readable_id, errors)


func _validate_quests(errors: Array[String]) -> void:
	for quest_id in quests:
		var quest: Dictionary = quests[quest_id]
		_validate_keyed_id(quest, String(quest_id), "Quest", errors)
		if String(quest.get("title", "")).is_empty():
			errors.append("Quest %s is missing title." % quest_id)
		var start_stage := String(quest.get("start_stage", ""))
		var stages_value: Variant = quest.get("stages", {})
		var stages := _dictionary_field(stages_value)
		if not stages_value is Dictionary or stages.is_empty():
			errors.append("Quest %s must have at least one stage." % quest_id)
		if start_stage.is_empty():
			errors.append("Quest %s is missing start_stage." % quest_id)
		elif not stages.has(start_stage):
			errors.append("Quest %s references missing start_stage %s." % [quest_id, start_stage])
		for stage_id in stages:
			var stage_key := String(stage_id)
			var stage_owner := "Quest %s stage %s" % [quest_id, stage_key]
			if stage_key.is_empty():
				errors.append("Quest %s has stage with missing id." % quest_id)
			var stage_value: Variant = stages[stage_id]
			if not stage_value is Dictionary:
				errors.append("%s must be a dictionary." % stage_owner)
				continue
			var stage: Dictionary = stage_value
			var objectives_value: Variant = stage.get("objectives", {})
			var objectives := _dictionary_field(objectives_value)
			if not objectives_value is Dictionary or objectives.is_empty():
				errors.append("%s must have at least one objective." % stage_owner)
				continue
			for objective_id in objectives:
				var objective_key := String(objective_id)
				if objective_key.is_empty():
					errors.append("%s has objective with missing id." % stage_owner)
				var objective_value: Variant = objectives[objective_id]
				var objective_text := _objective_text(objective_value)
				if objective_text.is_empty():
					errors.append("%s objective %s is missing text." % [stage_owner, objective_key])
				var target_id := _objective_target_id(objective_value)
				if not target_id.is_empty() and not _world_object_id_exists(target_id):
					errors.append(
						(
							"%s objective %s references missing target %s."
							% [stage_owner, objective_key, target_id]
						)
					)
		_validate_effect_list(quest, "rewards", "quest %s" % quest_id, errors)


func _validate_npcs(errors: Array[String]) -> void:
	for npc_id in npcs:
		var npc: Dictionary = npcs[npc_id]
		_validate_keyed_id(npc, String(npc_id), "NPC", errors)
		if String(npc.get("name", "")).is_empty():
			errors.append("NPC %s is missing name." % npc_id)
		var quest_id := String(npc.get("quest_id", ""))
		if not quest_id.is_empty() and not quests.has(quest_id):
			errors.append("NPC %s references missing quest %s." % [npc_id, quest_id])
		var faction_id := String(npc.get("faction", ""))
		if not faction_id.is_empty() and not factions.has(faction_id):
			errors.append("NPC %s references missing faction %s." % [npc_id, faction_id])
		var dialogue_id := String(npc.get("dialogue_id", ""))
		if not dialogues.has(dialogue_id):
			errors.append("NPC %s references missing dialogue %s." % [npc_id, dialogue_id])
		var shop_id := String(npc.get("shop_id", ""))
		if not shop_id.is_empty() and not shops.has(shop_id):
			errors.append("NPC %s references missing shop %s." % [npc_id, shop_id])
		_validate_condition_list(npc, "completion_conditions", "NPC %s" % npc_id, errors)
		_validate_effect_list(npc, "completion_effects", "NPC %s" % npc_id, errors)


func _validate_factions(errors: Array[String]) -> void:
	for faction_id in factions:
		var faction: Dictionary = factions[faction_id]
		_validate_keyed_id(faction, String(faction_id), "Faction", errors)
		if String(faction.get("name", "")).is_empty():
			errors.append("Faction %s is missing name." % faction_id)
		if String(faction.get("description", "")).is_empty():
			errors.append("Faction %s is missing description." % faction_id)
		_validate_optional_bounded_number(
			faction, "starting_reputation", "Faction %s" % faction_id, -100.0, 100.0, errors
		)


func _validate_dialogues(errors: Array[String]) -> void:
	for dialogue_id in dialogues:
		var dialogue: Dictionary = dialogues[dialogue_id]
		_validate_keyed_id(dialogue, String(dialogue_id), "Dialogue", errors)
		var lines: Array = _array_field(dialogue.get("lines", []))
		if lines.is_empty():
			errors.append("Dialogue %s must have at least one line." % dialogue_id)
		var seen_line_ids: Dictionary = {}
		for line in lines:
			if not line is Dictionary:
				errors.append("Dialogue %s has malformed line." % dialogue_id)
				continue
			var line_id := String(line.get("id", ""))
			var owner := "Dialogue %s line %s" % [dialogue_id, line_id]
			if line_id.is_empty():
				errors.append("Dialogue %s has line with missing id." % dialogue_id)
			elif seen_line_ids.has(line_id):
				errors.append("Dialogue %s has duplicate line id %s." % [dialogue_id, line_id])
			seen_line_ids[line_id] = true
			if String(line.get("speaker", "")).is_empty():
				errors.append("%s is missing speaker." % owner)
			if String(line.get("text", "")).is_empty():
				errors.append("%s is missing text." % owner)
			_validate_condition_list(line, "conditions", owner, errors)
			_validate_effect_list(line, "effects", owner, errors)
			_validate_dialogue_choices(line, owner, errors)


func _validate_dialogue_choices(line: Dictionary, owner: String, errors: Array[String]) -> void:
	if not line.has("choices"):
		return
	var choices_value: Variant = line.get("choices", [])
	if not choices_value is Array:
		errors.append("%s choices must be an array." % owner)
		return
	var seen_choice_ids: Dictionary = {}
	for choice in choices_value:
		if not choice is Dictionary:
			errors.append("%s choices has malformed choice." % owner)
			continue
		var choice_id := String(choice.get("id", ""))
		var choice_owner := "%s choice %s" % [owner, choice_id]
		if choice_id.is_empty():
			errors.append("%s has choice with missing id." % owner)
		elif seen_choice_ids.has(choice_id):
			errors.append("%s has duplicate choice id %s." % [owner, choice_id])
		seen_choice_ids[choice_id] = true
		if String(choice.get("text", "")).is_empty():
			errors.append("%s is missing text." % choice_owner)
		_validate_condition_list(choice, "conditions", choice_owner, errors)
		_validate_effect_list(choice, "effects", choice_owner, errors)


func _validate_locations(errors: Array[String]) -> void:
	for location_id in locations:
		var location: Dictionary = locations[location_id]
		_validate_keyed_id(location, String(location_id), "Location", errors)
		if String(location.get("name", "")).is_empty():
			errors.append("Location %s is missing name." % location_id)
		if String(location.get("region", "")).is_empty():
			errors.append("Location %s is missing region." % location_id)
		if String(location.get("description", "")).is_empty():
			errors.append("Location %s is missing description." % location_id)


func _validate_shops(errors: Array[String]) -> void:
	for shop_id in shops:
		var shop: Dictionary = shops[shop_id]
		_validate_keyed_id(shop, String(shop_id), "Shop", errors)
		if String(shop.get("name", "")).is_empty():
			errors.append("Shop %s is missing name." % shop_id)
		_validate_optional_bounded_number(shop, "open_hour", "Shop %s" % shop_id, 0.0, 23.0, errors)
		_validate_optional_bounded_number(
			shop, "close_hour", "Shop %s" % shop_id, 0.0, 23.0, errors
		)
		var stock_value: Variant = shop.get("stock", [])
		var stock := _array_field(stock_value)
		if not stock_value is Array or stock.is_empty():
			errors.append("Shop %s must have stock." % shop_id)
			continue
		for stock_entry in stock:
			if not stock_entry is Dictionary:
				errors.append("Shop %s has malformed stock entry." % shop_id)
				continue
			var item_id := String(stock_entry.get("item_id", ""))
			if not items.has(item_id):
				errors.append("Shop %s references missing item %s." % [shop_id, item_id])
			_validate_optional_positive_number(
				stock_entry, "price", "Shop %s stock %s" % [shop_id, item_id], errors
			)


func _validate_status_effects(errors: Array[String]) -> void:
	for status_id in status_effects:
		var status: Dictionary = status_effects[status_id]
		var owner := "Status effect %s" % status_id
		_validate_keyed_id(status, String(status_id), "Status effect", errors)
		if String(status.get("name", "")).is_empty():
			errors.append("%s is missing name." % owner)
		if String(status.get("description", "")).is_empty():
			errors.append("%s is missing description." % owner)
		_validate_required_positive_number(status, "attack_charges", owner, errors)
		_validate_optional_non_negative_number(status, "damage_bonus", owner, errors)
		_validate_optional_positive_number(status, "guard_counter_multiplier", owner, errors)


func _validate_spells(errors: Array[String]) -> void:
	for spell_id in spells:
		var spell: Dictionary = spells[spell_id]
		var owner := "Spell %s" % spell_id
		_validate_keyed_id(spell, String(spell_id), "Spell", errors)
		if String(spell.get("name", "")).is_empty():
			errors.append("%s is missing name." % owner)
		if String(spell.get("school", "")).is_empty():
			errors.append("%s is missing school." % owner)
		_validate_required_positive_number(spell, "mana_cost", owner, errors)
		if String(spell.get("range", "")).is_empty():
			errors.append("%s is missing range." % owner)
		if String(spell.get("behavior", "")).is_empty():
			errors.append("%s is missing behavior." % owner)


func _validate_world_objects(errors: Array[String]) -> void:
	var seen_ids: Dictionary = {}
	for entry in world_objects:
		var object_id := String(entry.get("id", ""))
		if object_id.is_empty():
			errors.append("World object is missing id.")
			continue
		if seen_ids.has(object_id):
			errors.append("Duplicate world object id %s." % object_id)
		seen_ids[object_id] = true
		_validate_global_tile(entry, "World object %s" % object_id, errors)
		if String(entry.get("name", "")).is_empty():
			errors.append("World object %s is missing name." % object_id)
		_validate_optional_positive_number(
			entry, "interaction_radius", "World object %s" % object_id, errors
		)

		var kind := String(entry.get("kind", ""))
		match kind:
			"readable":
				var readable_id := String(entry.get("readable_id", ""))
				if not readables.has(readable_id):
					errors.append(
						"World object %s references missing readable %s." % [object_id, readable_id]
					)
			"npc":
				var npc_id := String(entry.get("npc_id", ""))
				if not npcs.has(npc_id):
					errors.append(
						"World object %s references missing NPC %s." % [object_id, npc_id]
					)
			"pickup":
				var item_id := String(entry.get("item_id", ""))
				if not items.has(item_id):
					errors.append(
						"World object %s references missing item %s." % [object_id, item_id]
					)
				_validate_optional_positive_number(
					entry, "count", "World object %s" % object_id, errors
				)
			"container":
				var effects := _array_field(entry.get("effects_on_open", []))
				if effects.is_empty():
					errors.append("Container %s must have effects_on_open." % object_id)
				_validate_effect_list(
					entry, "effects_on_open", "world object %s" % object_id, errors
				)
			"door":
				_validate_effect_list(
					entry, "effects_on_open", "world object %s" % object_id, errors
				)
			"enemy":
				_validate_required_positive_number(
					entry, "max_health", "Enemy %s" % object_id, errors
				)
				_validate_required_positive_number(
					entry, "damage_taken_per_hit", "Enemy %s" % object_id, errors
				)
				_validate_required_non_negative_number(
					entry, "attack_damage", "Enemy %s" % object_id, errors
				)
			"rest":
				_validate_required_positive_number(
					entry, "heal_amount", "Rest object %s" % object_id, errors
				)
				_validate_optional_positive_number(
					entry, "rest_hours", "Rest object %s" % object_id, errors
				)
			"poi":
				if String(entry.get("description", "")).is_empty():
					errors.append("POI %s is missing description." % object_id)
				var location_id := String(entry.get("location_id", ""))
				if not location_id.is_empty() and not locations.has(location_id):
					errors.append(
						"POI %s references missing location %s." % [object_id, location_id]
					)
				var shop_id := String(entry.get("shop_id", ""))
				if not shop_id.is_empty() and not shops.has(shop_id):
					errors.append("POI %s references missing shop %s." % [object_id, shop_id])
				var system_tab := String(entry.get("system_tab", ""))
				if not system_tab.is_empty() and not _supported_system_tabs().has(system_tab):
					errors.append("POI %s has unsupported system_tab %s." % [object_id, system_tab])
				if system_tab == "trade" and shop_id.is_empty():
					errors.append("POI %s has trade system_tab without shop_id." % object_id)
				_validate_action_list(entry, "actions", "POI %s" % object_id, errors)
				_validate_effect_list(
					entry, "effects_on_discover", "world object %s" % object_id, errors
				)
			"location":
				var location_id := String(entry.get("location_id", ""))
				if not locations.has(location_id):
					errors.append(
						(
							"Location object %s references missing location %s."
							% [object_id, location_id]
						)
					)
				_validate_optional_positive_number(
					entry, "discovery_radius", "Location object %s" % object_id, errors
				)
			_:
				errors.append("World object %s has unsupported kind %s." % [object_id, kind])

		_validate_effect_list(entry, "effects_on_pickup", "world object %s" % object_id, errors)
		_validate_effect_list(entry, "effects_on_defeat", "world object %s" % object_id, errors)
		_validate_condition_list(entry, "conditions", "world object %s" % object_id, errors)
		_validate_condition_list(entry, "open_conditions", "world object %s" % object_id, errors)


func _validate_world_terrain(errors: Array[String]) -> void:
	if world_terrain.is_empty():
		return
	var areas_value: Variant = world_terrain.get("areas", [])
	var areas := _array_field(areas_value)
	if not areas_value is Array or areas.is_empty():
		errors.append("World terrain must define at least one area.")
		return
	var seen_ids: Dictionary = {}
	for area_value in areas:
		if not area_value is Dictionary:
			errors.append("World terrain has malformed area.")
			continue
		var area: Dictionary = area_value
		var area_id := String(area.get("id", ""))
		var owner := "World terrain area %s" % area_id
		if area_id.is_empty():
			errors.append("World terrain area is missing id.")
		elif seen_ids.has(area_id):
			errors.append("Duplicate world terrain area id %s." % area_id)
		seen_ids[area_id] = true
		_validate_terrain_bounds(area.get("bounds", {}), owner, errors)
		_validate_terrain_kind(area, "default_kind", owner, errors)
		_validate_terrain_regions(area, owner, errors)


func _validate_terrain_regions(
	area: Dictionary, owner: String, errors: Array[String]
) -> void:
	var regions_value: Variant = area.get("regions", [])
	var regions := _array_field(regions_value)
	if not regions_value is Array or regions.is_empty():
		errors.append("%s must define regions." % owner)
		return
	var seen_ids: Dictionary = {}
	for region_value in regions:
		if not region_value is Dictionary:
			errors.append("%s has malformed region." % owner)
			continue
		var region: Dictionary = region_value
		var region_id := String(region.get("id", ""))
		var region_owner := "%s region %s" % [owner, region_id]
		if region_id.is_empty():
			errors.append("%s has region with missing id." % owner)
		elif seen_ids.has(region_id):
			errors.append("%s has duplicate region id %s." % [owner, region_id])
		seen_ids[region_id] = true
		_validate_terrain_kind(region, "kind", region_owner, errors)
		var has_rect := region.has("rect")
		var has_tiles := region.has("tiles")
		if not has_rect and not has_tiles:
			errors.append("%s must define rect or tiles." % region_owner)
		if has_rect:
			_validate_terrain_rect(region.get("rect", {}), region_owner, errors)
		if has_tiles:
			_validate_terrain_tiles(region.get("tiles", []), region_owner, errors)


func _validate_terrain_bounds(value: Variant, owner: String, errors: Array[String]) -> void:
	var bounds := _dictionary_field(value)
	if bounds.is_empty():
		errors.append("%s must define bounds." % owner)
		return
	_validate_numeric_pair(bounds.get("min", []), "%s bounds min" % owner, errors)
	_validate_numeric_pair(bounds.get("max", []), "%s bounds max" % owner, errors)


func _validate_terrain_rect(value: Variant, owner: String, errors: Array[String]) -> void:
	var rect := _dictionary_field(value)
	if rect.is_empty():
		errors.append("%s rect must be a dictionary." % owner)
		return
	_validate_numeric_pair(rect.get("position", []), "%s rect position" % owner, errors)
	_validate_positive_pair(rect.get("size", []), "%s rect size" % owner, errors)


func _validate_terrain_tiles(value: Variant, owner: String, errors: Array[String]) -> void:
	var tiles := _array_field(value)
	if not value is Array or tiles.is_empty():
		errors.append("%s tiles must be a non-empty array." % owner)
		return
	for tile in tiles:
		_validate_numeric_pair(tile, "%s tile" % owner, errors)


func _validate_terrain_kind(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	var kind := String(entry.get(field_id, ""))
	if not _supported_terrain_kinds().has(kind):
		errors.append("%s has unsupported terrain kind %s." % [owner, kind])


func _validate_effect_list(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	var effects: Variant = entry.get(field_id, [])
	if not effects is Array:
		errors.append("%s %s must be an array." % [owner, field_id])
		return
	for effect in effects:
		var effect_owner := "%s %s" % [owner, field_id]
		if effect is Dictionary:
			_validate_effect(effect, effect_owner, errors)
		else:
			errors.append("%s has malformed effect." % effect_owner)


func _validate_condition_list(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	var conditions: Variant = entry.get(field_id, [])
	if not conditions is Array:
		errors.append("%s %s must be an array." % [owner, field_id])
		return
	for condition in conditions:
		var condition_owner := "%s %s" % [owner, field_id]
		if condition is Dictionary:
			_validate_condition(condition, condition_owner, errors)
		else:
			errors.append("%s has malformed condition." % condition_owner)


func _validate_action_list(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	var actions: Variant = entry.get(field_id, [])
	if not actions is Array:
		errors.append("%s %s must be an array." % [owner, field_id])
		return
	var seen_ids: Dictionary = {}
	for action in actions:
		if not action is Dictionary:
			errors.append("%s %s has malformed action." % [owner, field_id])
			continue
		var action_id := String(action.get("id", ""))
		var action_owner := "%s %s action %s" % [owner, field_id, action_id]
		if action_id.is_empty():
			errors.append("%s %s has action with missing id." % [owner, field_id])
		elif seen_ids.has(action_id):
			errors.append("%s %s has duplicate action id %s." % [owner, field_id, action_id])
		seen_ids[action_id] = true
		if String(action.get("text", "")).is_empty():
			errors.append("%s is missing text." % action_owner)
		if (
			String(action.get("response", "")).is_empty()
			and _array_field(action.get("effects", [])).is_empty()
		):
			errors.append("%s must have effects or response." % action_owner)
		_validate_condition_list(action, "conditions", action_owner, errors)
		_validate_effect_list(action, "effects", action_owner, errors)


func _validate_effect(effect: Dictionary, owner: String, errors: Array[String]) -> void:
	var effect_type := String(effect.get("type", ""))
	match effect_type:
		"set_flag":
			if String(effect.get("flag_id", "")).is_empty():
				errors.append("%s has set_flag with missing flag_id." % owner)
		"discover_location":
			var location_id := String(effect.get("location_id", ""))
			if not locations.has(location_id):
				errors.append("%s references missing location %s." % [owner, location_id])
		"start_quest", "complete_quest", "fail_quest":
			var quest_id := String(effect.get("quest_id", ""))
			if not quests.has(quest_id):
				errors.append("%s references missing quest %s." % [owner, quest_id])
		"set_quest_stage":
			var quest_id := String(effect.get("quest_id", ""))
			var stage_id := String(effect.get("stage", ""))
			var quest: Dictionary = quests.get(quest_id, {})
			var stages: Dictionary = quest.get("stages", {})
			if quest.is_empty():
				errors.append("%s references missing quest %s." % [owner, quest_id])
			elif not stages.has(stage_id):
				errors.append(
					"%s references missing quest stage %s:%s." % [owner, quest_id, stage_id]
				)
		"add_item", "remove_item":
			var item_id := String(effect.get("item_id", ""))
			if not items.has(item_id):
				errors.append("%s references missing item %s." % [owner, item_id])
			_validate_optional_positive_number(
				effect, "count", "%s %s" % [owner, effect_type], errors
			)
		"heal_player":
			_validate_required_positive_number(effect, "amount", "%s heal_player" % owner, errors)
		"change_reputation":
			var faction_id := String(effect.get("faction_id", ""))
			if not factions.has(faction_id):
				errors.append("%s references missing faction %s." % [owner, faction_id])
			_validate_required_number(effect, "amount", "%s change_reputation" % owner, errors)
		"add_experience":
			_validate_required_positive_number(
				effect, "amount", "%s add_experience" % owner, errors
			)
		"advance_time":
			if not effect.has("minutes") and not effect.has("hours"):
				errors.append("%s advance_time requires minutes or hours." % owner)
			_validate_optional_positive_number(effect, "minutes", "%s advance_time" % owner, errors)
			_validate_optional_positive_number(effect, "hours", "%s advance_time" % owner, errors)
		"apply_status":
			var status_id := String(effect.get("status_id", ""))
			if not status_effects.has(status_id):
				errors.append("%s references missing status %s." % [owner, status_id])
			_validate_optional_positive_number(effect, "charges", "%s apply_status" % owner, errors)
		_:
			errors.append("%s has unsupported effect type %s." % [owner, effect_type])


func _validate_condition(condition: Dictionary, owner: String, errors: Array[String]) -> void:
	var condition_type := String(condition.get("type", ""))
	match condition_type:
		"has_flag", "not_flag":
			if String(condition.get("flag_id", "")).is_empty():
				errors.append("%s has %s with missing flag_id." % [owner, condition_type])
		"has_item":
			var item_id := String(condition.get("item_id", ""))
			if not items.has(item_id):
				errors.append("%s references missing item %s." % [owner, item_id])
			_validate_optional_positive_number(condition, "count", "%s has_item" % owner, errors)
		"quest_state":
			var quest_id := String(condition.get("quest_id", ""))
			var state := String(condition.get("state", ""))
			if not quests.has(quest_id):
				errors.append("%s references missing quest %s." % [owner, quest_id])
			if not ["inactive", "active", "completed", "failed"].has(state):
				errors.append("%s has quest_state with invalid state %s." % [owner, state])
		"quest_stage":
			var quest_id := String(condition.get("quest_id", ""))
			var stage := String(condition.get("stage", ""))
			var quest: Dictionary = quests.get(quest_id, {})
			var stages: Dictionary = quest.get("stages", {})
			if quest.is_empty():
				errors.append("%s references missing quest %s." % [owner, quest_id])
			elif not stages.has(stage):
				errors.append("%s references missing quest stage %s:%s." % [owner, quest_id, stage])
		"read_readable":
			var readable_id := String(condition.get("readable_id", ""))
			if not readables.has(readable_id):
				errors.append("%s references missing readable %s." % [owner, readable_id])
		"location_discovered":
			var location_id := String(condition.get("location_id", ""))
			if not locations.has(location_id):
				errors.append("%s references missing location %s." % [owner, location_id])
		"faction_reputation_at_least":
			var faction_id := String(condition.get("faction_id", ""))
			if not factions.has(faction_id):
				errors.append("%s references missing faction %s." % [owner, faction_id])
			_validate_required_number(condition, "reputation", owner, errors)
		"player_level_at_least":
			_validate_required_positive_number(condition, "level", owner, errors)
		"stat_at_least":
			if String(condition.get("stat_id", "")).is_empty():
				errors.append("%s has stat_at_least with missing stat_id." % owner)
			_validate_required_positive_number(condition, "rank", owner, errors)
		"time_phase":
			var phase := String(condition.get("phase", ""))
			if not ["Morning", "Afternoon", "Evening", "Night"].has(phase):
				errors.append("%s has time_phase with invalid phase %s." % [owner, phase])
		"time_hour_between":
			_validate_required_bounded_number(condition, "start_hour", owner, 0.0, 23.0, errors)
			_validate_required_bounded_number(condition, "end_hour", owner, 0.0, 23.0, errors)
		_:
			errors.append("%s has unsupported condition type %s." % [owner, condition_type])


func _validate_keyed_id(
	entry: Dictionary, key: String, label: String, errors: Array[String]
) -> void:
	var declared_id := String(entry.get("id", ""))
	if declared_id.is_empty():
		errors.append("%s %s is missing id." % [label, key])
	elif declared_id != key:
		errors.append("%s %s has mismatched id %s." % [label, key, declared_id])


func _validate_global_tile(entry: Dictionary, owner: String, errors: Array[String]) -> void:
	var tile: Variant = entry.get("global_tile", [])
	_validate_numeric_pair(tile, "%s global_tile" % owner, errors)


func _validate_numeric_pair(value: Variant, owner: String, errors: Array[String]) -> void:
	if not (value is Array) or value.size() < 2:
		errors.append("%s must be [x, y]." % owner)
		return
	if not _is_number(value[0]) or not _is_number(value[1]):
		errors.append("%s values must be numeric." % owner)


func _validate_positive_pair(value: Variant, owner: String, errors: Array[String]) -> void:
	if not (value is Array) or value.size() < 2:
		errors.append("%s must be [width, height]." % owner)
		return
	if not _is_number(value[0]) or not _is_number(value[1]):
		errors.append("%s values must be numeric." % owner)
		return
	if float(value[0]) <= 0.0 or float(value[1]) <= 0.0:
		errors.append("%s values must be positive." % owner)


func _validate_required_positive_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) <= 0.0:
		errors.append("%s must have positive %s." % [owner, field_id])


func _validate_optional_positive_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) <= 0.0:
		errors.append("%s has non-positive %s." % [owner, field_id])


func _validate_required_non_negative_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) < 0.0:
		errors.append("%s must have non-negative %s." % [owner, field_id])


func _validate_required_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])


func _validate_required_bounded_number(
	entry: Dictionary,
	field_id: String,
	owner: String,
	min_value: float,
	max_value: float,
	errors: Array[String]
) -> void:
	if not entry.has(field_id) or not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	var value := float(entry[field_id])
	if value < min_value or value > max_value:
		errors.append(
			"%s %s must be between %.0f and %.0f." % [owner, field_id, min_value, max_value]
		)


func _validate_optional_non_negative_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) < 0.0:
		errors.append("%s must have non-negative %s." % [owner, field_id])


func _validate_optional_bounded_number(
	entry: Dictionary,
	field_id: String,
	owner: String,
	min_value: float,
	max_value: float,
	errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	var value := float(entry[field_id])
	if value < min_value or value > max_value:
		errors.append(
			"%s %s must be between %.0f and %.0f." % [owner, field_id, min_value, max_value]
		)


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _objective_text(value: Variant) -> String:
	if value is Dictionary:
		return String(value.get("text", ""))
	return String(value)


func _objective_target_id(value: Variant) -> String:
	if value is Dictionary:
		return String(value.get("target_id", ""))
	return ""


func _world_object_id_exists(object_id: String) -> bool:
	if object_id.is_empty():
		return false
	for entry in world_objects:
		if String(entry.get("id", "")) == object_id:
			return true
	return false


func _supported_system_tabs() -> Array[String]:
	return ["inventory", "character", "trade", "quests", "map", "journal", "world", "log"]


func _supported_terrain_kinds() -> Array[String]:
	return [
		"grass",
		"water",
		"bridge",
		"stone_wall",
		"wood_wall",
		"wood_floor",
		"forest",
		"hill",
		"road"
	]


func _is_number(value: Variant) -> bool:
	return value is int or value is float
