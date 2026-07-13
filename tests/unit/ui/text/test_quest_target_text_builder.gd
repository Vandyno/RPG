extends GutTest

const QuestTargetTextBuilder = preload("res://scripts/ui/text/quest_target_text_builder.gd")


class QuestManagerStub:
	extends RefCounted

	var objectives: Array = []

	func get_active_objectives_data() -> Array:
		return objectives


class EntityManagerStub:
	extends RefCounted

	var entities := {}
	var hints := {}
	var requested_positions: Array[Vector2] = []

	func get_entity(entity_id: String):
		return entities.get(entity_id)

	func get_navigation_hint(player_world_position: Vector2, entity) -> String:
		requested_positions.append(player_world_position)
		return String(hints.get(entity.id, "near"))


class EntityStub:
	extends RefCounted

	var id := ""
	var display_name := ""

	func _init(p_id: String, p_display_name: String) -> void:
		id = p_id
		display_name = p_display_name

	func get_display_name() -> String:
		return display_name


func test_directions_returns_none_without_required_managers() -> void:
	var quests := QuestManagerStub.new()
	var entities := EntityManagerStub.new()

	assert_eq(QuestTargetTextBuilder.directions(null, entities, Vector2.ZERO), "none")
	assert_eq(QuestTargetTextBuilder.directions(quests, null, Vector2.ZERO), "none")


func test_directions_returns_none_when_no_active_target_resolves() -> void:
	var quests := QuestManagerStub.new()
	quests.objectives = [
		{"title": "No target"},
		{"title": "Missing", "target_id": "gone"},
	]
	var entities := EntityManagerStub.new()

	assert_eq(QuestTargetTextBuilder.directions(quests, entities, Vector2(3, 4)), "none")
	assert_true(entities.requested_positions.is_empty())


func test_directions_formats_each_resolved_target_on_own_line() -> void:
	var quests := QuestManagerStub.new()
	quests.objectives = [
		{"title": "Find Tools", "target_id": "maera"},
		{"target_id": "cache"},
	]
	var entities := EntityManagerStub.new()
	entities.entities = {
		"maera": EntityStub.new("maera", "Maera"),
		"cache": EntityStub.new("cache", "Old Cache"),
	}
	entities.hints = {
		"maera": "north",
		"cache": "west",
	}

	assert_eq(
		QuestTargetTextBuilder.directions(quests, entities, Vector2(10, 20)),
		"Find Tools: north Maera\nQuest: west Old Cache"
	)
	assert_eq(entities.requested_positions, [Vector2(10, 20), Vector2(10, 20)])
