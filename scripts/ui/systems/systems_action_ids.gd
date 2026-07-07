class_name SystemsActionIds
extends RefCounted

const ACTION_USE := "use"
const ACTION_EQUIP := "equip"
const ACTION_EQUIP_SLOT := "equip_slot"
const ACTION_SWAP_MAINHAND := "swap_mainhand"
const ACTION_UNEQUIP := "unequip"
const ACTION_TRAIN := "train"
const ACTION_BUY := "buy"
const ACTION_SELL := "sell"
const ACTION_WAIT := "wait"
const ACTION_TARGET := "target"
const ACTION_SAVE := "save"
const ACTION_LOAD := "load"
const ACTION_UI := "ui"
const ACTION_ASSIGN_SPELL := "assign_spell"
const ACTION_TAKE := "take"
const ACTION_PUT := "put"


static func build(action: String, target_id: String = "", slot_id: String = "") -> String:
	var parts: Array[String] = [action]
	if not target_id.is_empty():
		parts.append(target_id)
	if not slot_id.is_empty():
		parts.append(slot_id)
	return ":".join(parts)


static func parse(action_id: String) -> Dictionary:
	var parts := action_id.split(":", false)
	if parts.size() <= 1:
		return {"action": ACTION_USE, "target_id": action_id}
	if parts.size() > 2:
		return {"action": String(parts[0]), "target_id": String(parts[1]), "slot_id": String(parts[2])}
	return {"action": String(parts[0]), "target_id": String(parts[1])}


static func use_item(item_id: String) -> String:
	return build(ACTION_USE, item_id)


static func equip_item(item_id: String) -> String:
	return build(ACTION_EQUIP, item_id)


static func equip_slot(item_id: String, slot_id: String) -> String:
	return build(ACTION_EQUIP_SLOT, item_id, slot_id)


static func swap_mainhand_weapon() -> String:
	return build(ACTION_SWAP_MAINHAND, "weapon")


static func unequip_slot(slot_id: String) -> String:
	return build(ACTION_UNEQUIP, slot_id)


static func train_stat(stat_id: String) -> String:
	return build(ACTION_TRAIN, stat_id)


static func buy_item(item_id: String) -> String:
	return build(ACTION_BUY, item_id)


static func sell_item(item_id: String) -> String:
	return build(ACTION_SELL, item_id)


static func assign_spell(spell_id: String, slot_id: String) -> String:
	return build(ACTION_ASSIGN_SPELL, spell_id, slot_id)


static func is_action(action_id: String, action: String) -> bool:
	return String(parse(action_id).get("action", "")) == action
