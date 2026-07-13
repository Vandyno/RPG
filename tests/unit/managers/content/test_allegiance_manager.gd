extends GutTest

const AllegianceManager = preload("res://scripts/managers/content/allegiance_manager.gd")


class ActorStub:
	var id: String
	var data: Dictionary

	func _init(entity_id: String, actor_data: Dictionary) -> void:
		id = entity_id
		data = actor_data


class EntitiesStub:
	var entities_by_id: Dictionary = {}


func test_alert_propagates_to_living_allies_but_never_player_thralls() -> void:
	var victim := _actor("victim", "town_watch")
	var ally := _actor("ally", "town_watch")
	var thrall := _actor("thrall", "town_watch")
	thrall.data["allegiance_owner_id"] = "player"
	var entities := EntitiesStub.new()
	entities.entities_by_id = {"victim": victim, "ally": ally, "thrall": thrall}
	var manager := AllegianceManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities)

	assert_true(manager.alert_actor(victim))

	assert_true(manager.is_alerted("town_watch"))
	assert_eq(ally.data["hostility"], "hostile")
	assert_eq(ally.data["brain_id"], "hostile_basic")
	assert_eq(ally.data["behavior_state"], "chasing")
	assert_eq(thrall.data["hostility"], "neutral")


func test_saved_alert_applies_when_a_linked_actor_streams_in_later() -> void:
	var first := _actor("first", "road_bandits")
	var initial_entities := EntitiesStub.new()
	initial_entities.entities_by_id = {"first": first}
	var manager := AllegianceManager.new()
	add_child_autofree(manager)
	manager.setup(null, initial_entities)
	manager.alert_actor(first)

	var later := _actor("later", "road_bandits")
	var streamed_entities := EntitiesStub.new()
	streamed_entities.entities_by_id = {"later": later}
	var restored := AllegianceManager.new()
	add_child_autofree(restored)
	restored.setup(null, streamed_entities)
	restored.load_save_data(manager.get_save_data())
	restored.update()

	assert_eq(later.data["hostility"], "hostile")
	assert_eq(later.data["_brain_mode"], "engaged")


func _actor(entity_id: String, allegiance_id: String) -> ActorStub:
	return ActorStub.new(
		entity_id,
		{
			"kind": "npc",
			"actor_category": "humanoid",
			"state": "alive",
			"allegiance_id": allegiance_id,
			"hostility": "neutral",
			"combat_enabled": true
		}
	)
