class_name ActorRules
extends RefCounted

const ActorState = preload("res://scripts/core/actor_state.gd")

const KIND_NPC := "npc"
const KIND_BODY := "body"
const CATEGORY_HUMANOID := "humanoid"
const HOSTILITY_HOSTILE := "hostile"
const STATE_ALIVE := ActorState.ALIVE
const STATE_DEAD_BODY := ActorState.DEAD_BODY
const DEAD_STATES := ActorState.DEAD_STATES


static func profile(data: Dictionary) -> Dictionary:
	var nested: Variant = data.get("character_profile", {})
	if nested is Dictionary and not nested.is_empty():
		return nested
	if not String(data.get("character_id", "")).is_empty():
		return data
	return {}


static func character_id(data: Dictionary) -> String:
	var direct_id := String(data.get("character_id", ""))
	if not direct_id.is_empty():
		return direct_id
	var profile_character_id := String(profile(data).get("character_id", ""))
	if not profile_character_id.is_empty():
		return profile_character_id
	var profile_id := String(data.get("character_profile_id", ""))
	if not profile_id.is_empty():
		return profile_id
	return ""


static func actor_category(data: Dictionary) -> String:
	var category := String(data.get("actor_category", ""))
	if not category.is_empty():
		return category
	if _has_humanoid_identity(data):
		return CATEGORY_HUMANOID
	return ""


static func is_actor_data(data: Dictionary) -> bool:
	if not actor_category(data).is_empty():
		return true
	if String(data.get("kind", "")) == KIND_NPC:
		return true
	return _has_humanoid_identity(data)


static func is_humanoid_actor_data(data: Dictionary) -> bool:
	return actor_category(data) == CATEGORY_HUMANOID


static func is_living_actor_data(data: Dictionary) -> bool:
	if not is_actor_data(data):
		return false
	if String(data.get("kind", "")) == KIND_BODY:
		return false
	return not DEAD_STATES.has(actor_state(data))


static func is_living_humanoid_data(data: Dictionary) -> bool:
	return is_living_actor_data(data) and is_humanoid_actor_data(data)


static func actor_state(data: Dictionary) -> String:
	var state := String(data.get("state", ""))
	if state.is_empty():
		state = String(profile(data).get("state", STATE_ALIVE))
	return state.to_lower()


static func is_hostile_to_player_data(data: Dictionary) -> bool:
	if _bool_field(data.get("hostile_to_player", false)):
		return true
	return String(data.get("hostility", "")).to_lower() == HOSTILITY_HOSTILE


static func has_combat_behavior_data(data: Dictionary) -> bool:
	if _bool_field(data.get("combat_enabled", false)):
		return true
	return is_hostile_to_player_data(data)


static func is_combat_target_data(data: Dictionary) -> bool:
	return (
		is_living_actor_data(data)
		and is_hostile_to_player_data(data)
		and has_combat_behavior_data(data)
	)


static func is_combat_target_entity(entity: Variant) -> bool:
	if entity == null:
		return false
	if entity is Dictionary:
		var entity_data: Variant = entity.get("data", entity)
		return entity_data is Dictionary and is_combat_target_data(entity_data)
	if not (entity is Object):
		return false
	if entity.has_method("is_combat_target"):
		return bool(entity.is_combat_target())
	var data: Variant = entity.get("data")
	return data is Dictionary and is_combat_target_data(data)


static func can_pickpocket_data(data: Dictionary) -> bool:
	return is_living_humanoid_data(data) and not inventory_owner_id(data).is_empty()


static func inventory_owner_id(data: Dictionary) -> String:
	return _owner_id(data, "inventory_owner_id")


static func equipment_owner_id(data: Dictionary) -> String:
	return _owner_id(data, "equipment_owner_id")


static func spellbook_owner_id(data: Dictionary) -> String:
	return _owner_id(data, "spellbook_owner_id")


static func stats(data: Dictionary) -> Dictionary:
	var value: Variant = profile(data).get("stats", data.get("stats", {}))
	return value if value is Dictionary else {}


static func derived_bonuses(data: Dictionary) -> Dictionary:
	var value: Variant = profile(data).get("derived_bonuses", data.get("derived_bonuses", {}))
	return value if value is Dictionary else {}


static func _owner_id(data: Dictionary, field_id: String) -> String:
	var direct_id := String(data.get(field_id, ""))
	if not direct_id.is_empty():
		return direct_id
	var profile_data := profile(data)
	var profile_owner_id := String(profile_data.get(field_id, ""))
	if not profile_owner_id.is_empty():
		return profile_owner_id
	return character_id(data)


static func _has_humanoid_identity(data: Dictionary) -> bool:
	if not String(data.get("character_profile_id", "")).is_empty():
		return true
	var profile_data := profile(data)
	return (
		not profile_data.is_empty()
		and not String(profile_data.get("character_id", "")).is_empty()
		and not String(profile_data.get("people_id", "")).is_empty()
	)


static func _bool_field(value: Variant) -> bool:
	return value is bool and bool(value)
