class_name RpgSpellSlot
extends Button

signal spell_dropped(slot_id: String, spell_id: String)

var slot_id := ""


func setup_slot(next_slot_id: String) -> void:
	slot_id = next_slot_id
	set_meta("slot_id", slot_id)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and String(data.get("type", "")) == "spell" and not String(
		data.get("spell_id", "")
	).is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(_at_position, data):
		spell_dropped.emit(slot_id, String(data.get("spell_id", "")))
