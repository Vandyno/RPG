extends GutTest

const EventBus = preload("res://scripts/core/event_bus.gd")
const NpcPerceptionManager = preload("res://scripts/managers/content/npc_perception_manager.gd")
const WorldEntity = preload("res://scripts/world/world_entity.gd")


class EntitySet:
	var entities_by_id: Dictionary = {}
	var chunk_manager = ChunkStub.new()


class ChunkStub:
	var opened := false

	func is_object_opened(_entity_id: String, _tile: Vector2i, _layer: String) -> bool:
		return opened


class TimeStub:
	func get_phase() -> String:
		return "Night"


func test_noise_creates_suspicion_sight_detects_and_awareness_decays() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var entities := EntitySet.new()
	var observer := _observer()
	entities.entities_by_id[observer.get_entity_id()] = observer
	var manager := NpcPerceptionManager.new()
	add_child_autofree(manager)
	manager.setup(bus, entities, null, TimeStub.new())

	bus.noise_emitted.emit(
		{
			"kind": "footstep",
			"source_id": "player",
			"world_position": [80, 16],
			"world_layer": "surface",
			"noise_radius": 120,
			"loudness": 1.0,
			"visible": false
		}
	)
	assert_eq(manager.get_awareness_state("observer"), "suspicious")
	assert_true(manager.heard_recently("observer", "player"))
	assert_eq(observer.data.get("perception_awareness_state", ""), "suspicious")

	manager.perceive_event(
		{
			"source_id": "player",
			"world_position": [64, 16],
			"world_layer": "surface",
			"visible": true,
			"noise_radius": 0,
			"light_level": 1.0
		}
	)
	assert_eq(manager.get_awareness_state("observer"), "detected")

	manager._process(20.0)
	assert_eq(manager.get_awareness_state("observer"), "unaware")
	assert_false(observer.data.has("perception_awareness_state"))
	manager.set_debug_visible(true)
	assert_true(observer.data["debug_perception_visible"])
	assert_true(manager.get_debug_snapshot()["debug_visible"])


func test_closed_door_blocks_vision_and_open_door_restores_it() -> void:
	var entities := EntitySet.new()
	var observer := _observer()
	var door := WorldEntity.new()
	add_child_autofree(door)
	door.setup(
		{
			"id": "door",
			"kind": "door",
			"global_tile": [2, 0],
			"world_layer": "surface"
		}
	)
	entities.entities_by_id = {observer.get_entity_id(): observer, door.get_entity_id(): door}
	var manager := NpcPerceptionManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities, null, TimeStub.new())
	var target_position := Vector2(80, 8)

	assert_false(manager.can_see_position(observer, target_position, "surface", {"light_level": 1.0}))
	entities.chunk_manager.opened = true
	assert_true(manager.can_see_position(observer, target_position, "surface", {"light_level": 1.0}))


func _observer() -> WorldEntity:
	var observer := WorldEntity.new()
	add_child_autofree(observer)
	observer.setup(
		{
			"id": "observer_actor",
			"npc_id": "observer",
			"kind": "npc",
			"global_tile": [0, 0],
			"facing_direction": [1, 0],
			"vision_distance": 160,
			"vision_degrees": 120,
			"hearing_radius": 140
		}
	)
	return observer
