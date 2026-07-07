extends GutTest


func test_access_detail_and_action_reflect_open_locked_closed_states() -> void:
	var entity := RuleEntityStub.new("object_chest", {"open_conditions": [{"flag": "has_key"}]})
	var chunks := ChunkStub.new()
	var conditions := ConditionStub.new(false)

	assert_eq(
		ObjectInteractionRules.container_detail(entity, chunks, conditions),
		"Container: locked"
	)
	assert_eq(ObjectInteractionRules.access_action_text(entity, chunks, conditions), "Locked")
	assert_eq(
		ObjectInteractionRules.access_detail(entity, chunks, ConditionStub.new(true), "Door"),
		"Door: closed"
	)

	chunks.opened = true

	assert_eq(ObjectInteractionRules.container_detail(entity, chunks, conditions), "Container: opened")
	assert_eq(ObjectInteractionRules.access_action_text(entity, chunks, conditions), "Opened")


func test_locked_text_uses_authored_text_with_default_fallback() -> void:
	var conditions := ConditionStub.new(false)

	assert_eq(
		ObjectInteractionRules.access_locked_text(
			{"open_conditions": [{}], "locked_text": "Needs a brass key."},
			conditions
		),
		"Needs a brass key."
	)
	assert_eq(
		ObjectInteractionRules.access_locked_text(
			{"open_conditions": [{}], "locked_text": ""}, conditions
		),
		"It is locked."
	)
	assert_eq(ObjectInteractionRules.access_locked_text({}, conditions), "")


class RuleEntityStub:
	extends RefCounted

	var data: Dictionary
	var global_tile := Vector2i(3, 4)
	var entity_id: String

	func _init(id: String, entity_data: Dictionary) -> void:
		entity_id = id
		data = entity_data

	func get_entity_id() -> String:
		return entity_id


class ChunkStub:
	extends RefCounted

	var opened := false

	func is_object_opened(_entity_id: String, _tile: Vector2i) -> bool:
		return opened


class ConditionStub:
	extends RefCounted

	var result := false

	func _init(value: bool) -> void:
		result = value

	func evaluate_all(_conditions: Array) -> bool:
		return result
