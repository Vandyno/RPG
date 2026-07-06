class_name ContentItemValidator
extends RefCounted

const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")


static func validate(content, errors: Array[String]) -> void:
	_validate_items(content, errors)
	_validate_readables(content, errors)
	_validate_shops(content, errors)
	_validate_status_effects(content, errors)
	_validate_spells(content, errors)


static func _validate_items(content, errors: Array[String]) -> void:
	for item_id in content.items:
		var item: Dictionary = content.items[item_id]
		content._validate_keyed_id(item, String(item_id), "Item", errors)
		if String(item.get("name", "")).is_empty():
			errors.append("Item %s is missing name." % item_id)
		content._validate_required_positive_number(item, "max_stack", "Item %s" % item_id, errors)
		content._validate_optional_non_negative_number(item, "value", "Item %s" % item_id, errors)
		_validate_item_equipment_fields(content, item, String(item_id), errors)
		content._validate_effect_list(item, "effects_on_use", "item %s" % item_id, errors)


static func _validate_item_equipment_fields(
	content, item: Dictionary, item_id: String, errors: Array[String]
) -> void:
	if not item.has("equipment_slot"):
		return
	var slot := String(item.get("equipment_slot", ""))
	if not EquipmentSlots.is_supported(slot):
		errors.append("Item %s has unsupported equipment_slot %s." % [item_id, slot])
	content._validate_optional_non_negative_number(
		item, "damage_bonus", "Item %s" % item_id, errors
	)
	content._validate_optional_positive_number(
		item, "guard_counter_multiplier", "Item %s" % item_id, errors
	)
	if String(item.get("type", "")) == "weapon":
		var attack = item.get("weapon_attack", {})
		if not attack is Dictionary:
			errors.append("Item %s weapon_attack must be a dictionary." % item_id)
		else:
			content._validate_required_positive_number(
				attack, "attack_interval_seconds", "Item %s weapon_attack" % item_id, errors
			)
	_validate_item_avatar_visual(item, item_id, errors)


static func _validate_item_avatar_visual(
	item: Dictionary, item_id: String, errors: Array[String]
) -> void:
	if not item.has("equipment_slot"):
		return
	var visual_value: Variant = item.get("avatar_visual", {})
	if not visual_value is Dictionary:
		errors.append("Item %s avatar_visual must be a dictionary." % item_id)
		return
	var visual: Dictionary = visual_value
	var avatar_slot := String(visual.get("avatar_slot", ""))
	if avatar_slot.is_empty():
		errors.append("Item %s avatar_visual is missing avatar_slot." % item_id)
	elif not EquipmentSlots.accepts(avatar_slot, String(item.get("equipment_slot", ""))):
		errors.append("Item %s avatar_visual avatar_slot does not match equipment_slot." % item_id)
	var layer_id := String(visual.get("visual_layer_id", ""))
	var accepted_placeholder := bool(visual.get("accepted_placeholder", false))
	if layer_id.is_empty():
		errors.append("Item %s avatar_visual is missing visual_layer_id." % item_id)
	if not accepted_placeholder and String(visual.get("paperdoll_sprite_id", "")).is_empty():
		errors.append(
			"Item %s avatar_visual needs paperdoll_sprite_id or accepted_placeholder." % item_id
		)


static func _validate_readables(content, errors: Array[String]) -> void:
	for readable_id in content.readables:
		var readable: Dictionary = content.readables[readable_id]
		content._validate_keyed_id(readable, String(readable_id), "Readable", errors)
		if String(readable.get("title", "")).is_empty():
			errors.append("Readable %s is missing title." % readable_id)
		if String(readable.get("body", "")).is_empty():
			errors.append("Readable %s is missing body." % readable_id)
		content._validate_effect_list(
			readable, "effects_on_read", "readable %s" % readable_id, errors
		)


static func _validate_shops(content, errors: Array[String]) -> void:
	for shop_id in content.shops:
		var shop: Dictionary = content.shops[shop_id]
		content._validate_keyed_id(shop, String(shop_id), "Shop", errors)
		if String(shop.get("name", "")).is_empty():
			errors.append("Shop %s is missing name." % shop_id)
		content._validate_optional_bounded_number(
			shop, "open_hour", "Shop %s" % shop_id, 0.0, 23.0, errors
		)
		content._validate_optional_bounded_number(
			shop, "close_hour", "Shop %s" % shop_id, 0.0, 23.0, errors
		)
		var stock_value: Variant = shop.get("stock", [])
		var stock: Array = content._array_field(stock_value)
		if not stock_value is Array or stock.is_empty():
			errors.append("Shop %s must have stock." % shop_id)
			continue
		for stock_entry in stock:
			if not stock_entry is Dictionary:
				errors.append("Shop %s has malformed stock entry." % shop_id)
				continue
			var item_id := String(stock_entry.get("item_id", ""))
			if not content.items.has(item_id):
				errors.append("Shop %s references missing item %s." % [shop_id, item_id])
			content._validate_optional_positive_number(
				stock_entry, "price", "Shop %s stock %s" % [shop_id, item_id], errors
			)


static func _validate_status_effects(content, errors: Array[String]) -> void:
	for status_id in content.status_effects:
		var status: Dictionary = content.status_effects[status_id]
		var owner := "Status effect %s" % status_id
		content._validate_keyed_id(status, String(status_id), "Status effect", errors)
		if String(status.get("name", "")).is_empty():
			errors.append("%s is missing name." % owner)
		if String(status.get("description", "")).is_empty():
			errors.append("%s is missing description." % owner)
		content._validate_required_positive_number(status, "attack_charges", owner, errors)
		content._validate_optional_non_negative_number(status, "damage_bonus", owner, errors)
		content._validate_optional_positive_number(status, "guard_counter_multiplier", owner, errors)


static func _validate_spells(content, errors: Array[String]) -> void:
	for spell_id in content.spells:
		var spell: Dictionary = content.spells[spell_id]
		var owner := "Spell %s" % spell_id
		content._validate_keyed_id(spell, String(spell_id), "Spell", errors)
		if String(spell.get("name", "")).is_empty():
			errors.append("%s is missing name." % owner)
		if String(spell.get("school", "")).is_empty():
			errors.append("%s is missing school." % owner)
		content._validate_required_positive_number(spell, "mana_cost", owner, errors)
		if String(spell.get("range", "")).is_empty():
			errors.append("%s is missing range." % owner)
		if String(spell.get("behavior", "")).is_empty():
			errors.append("%s is missing behavior." % owner)
