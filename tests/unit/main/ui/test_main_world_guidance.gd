extends GutTest

const MainWorldGuidance = preload("res://scripts/main/ui/main_world_guidance.gd")


class EntityStub:
	var data := {}
	var id := ""
	var kind := "readable"
	var display_name := ""
	var global_position := Vector2.ZERO

	func _init(
		p_id: String,
		p_kind: String,
		p_display_name: String,
		p_global_position: Vector2,
		p_data: Dictionary = {}
	) -> void:
		id = p_id
		kind = p_kind
		display_name = p_display_name
		global_position = p_global_position
		data = p_data

	func get_entity_id() -> String:
		return id

	func get_kind() -> String:
		return kind

	func get_display_name() -> String:
		return display_name


class EntitiesStub:
	var quest_markers := {}
	var action_hints := {}

	func set_quest_markers(markers: Dictionary) -> void:
		quest_markers = markers

	func set_action_hints(hints: Dictionary) -> void:
		action_hints = hints


class PlayerStub:
	var global_position := Vector2.ZERO
	var facing := Vector2.RIGHT

	func get_facing_direction() -> Vector2:
		return facing


class QuestsStub:
	var objectives := []

	func _init(p_objectives: Array) -> void:
		objectives = p_objectives

	func get_active_objectives_data() -> Array:
		return objectives


class MainStub:
	var entities := EntitiesStub.new()
	var player := PlayerStub.new()
	var quests = null
	var selected_target_id := ""
	var auto_move_active := false
	var chunks = null
	var condition_evaluator = null
	var content = null
	var dialogues = null
	var equipment = null
	var factions = null
	var inventory = null
	var progression = null
	var shops = null
	var world_state = null
	var viewport_width := 1152.0

	func get_viewport_rect() -> Rect2:
		return Rect2(Vector2.ZERO, Vector2(viewport_width, 640.0))


func test_sync_sets_quest_markers_and_clears_hints_while_auto_moving() -> void:
	var main := MainStub.new()
	main.auto_move_active = true
	main.quests = QuestsStub.new([{"target_id": "object_notice"}, {"target_id": ""}, "bad"])

	MainWorldGuidance.sync(main, [])

	assert_eq(main.entities.quest_markers, {"object_notice": {"text": "Quest"}})
	assert_eq(main.entities.action_hints, {})


func test_hint_entries_keep_selected_target_and_rank_forward_unselected() -> void:
	var main := MainStub.new()
	main.selected_target_id = "selected"
	var selected := EntityStub.new("selected", "readable", "Road Notice", Vector2(96.0, -160.0))
	var behind := EntityStub.new("behind", "readable", "Old Sign", Vector2(-64.0, -160.0))
	var ahead := EntityStub.new("ahead", "readable", "Gate Note", Vector2(128.0, 160.0))

	var entries := MainWorldGuidance._hint_entries(
		main,
		[behind, ahead, selected],
		Vector2.ZERO,
		Vector2.RIGHT,
		2
	)

	assert_eq(entries.size(), 2)
	assert_eq(entries[0]["entity"], selected)
	assert_true(entries[0]["selected"])
	assert_eq(entries[1]["entity"], ahead)
	assert_false(entries[1]["selected"])
	assert_eq(entries[1]["offset_y"], 20.0)


func test_hint_text_uses_compact_selected_name_and_action_fallbacks() -> void:
	assert_eq(
		MainWorldGuidance._hint_text_for_width("Rest", "Bridge Campfire", true, 640.0),
		"Bridge Campfire"
	)
	assert_eq(
		MainWorldGuidance._hint_text_for_width("Read", "Road Notice", false, 1152.0),
		"Read Road Notice"
	)
	assert_eq(
		MainWorldGuidance._hint_text_for_width("Inspect", "Ancient Boundary Stone", true, 640.0),
		"Inspect"
	)


func test_sync_limits_compact_hints_and_uses_poi_primary_action() -> void:
	var main := MainStub.new()
	main.viewport_width = 640.0
	var poi := EntityStub.new(
		"stall",
		"poi",
		"Maera's Stall",
		Vector2(128.0, 160.0),
		{"shop_id": "shop_maera"}
	)
	var readable := EntityStub.new("notice", "readable", "Road Notice", Vector2(224.0, 160.0))

	MainWorldGuidance.sync(main, [poi, readable])

	assert_eq(main.entities.action_hints.size(), 1)
	assert_eq(main.entities.action_hints["stall"]["text"], "Trade Maera's Stall")
	assert_false(main.entities.action_hints["stall"]["selected"])
