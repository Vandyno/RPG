extends GutTest

const CrimeManager = preload("res://scripts/managers/content/crime_manager.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const WorldEntity = preload("res://scripts/world/world_entity.gd")


class PerceptionStub:
	var witnesses: Array[Dictionary] = []

	func perceive_event(_event: Dictionary) -> Array[Dictionary]:
		return witnesses.duplicate(true)


class EntitySet:
	var entities_by_id: Dictionary = {}

	func get_entity(entity_id: String):
		return entities_by_id.get(entity_id)


class TimeStub:
	var day := 2
	var minute_of_day := 90

	func advance_hours(hours: int) -> void:
		var total := minute_of_day + hours * 60
		day += total / 1440
		minute_of_day = total % 1440


class FactionStub:
	var changes: Array[Dictionary] = []
	var reputation := -15

	func change_reputation(faction_id: String, amount: int) -> bool:
		changes.append({"faction_id": faction_id, "amount": amount})
		reputation += amount
		return true

	func get_reputation(_faction_id: String) -> int:
		return reputation


class InventoryStub:
	var gold := 200

	func has_item(item_id: String, count: int = 1) -> bool:
		return item_id == "item_gold_coin" and gold >= count

	func remove_item(item_id: String, count: int = 1) -> bool:
		if not has_item(item_id, count):
			return false
		gold -= count
		return true

	func get_count(item_id: String) -> int:
		return gold if item_id == "item_gold_coin" else 0


func test_guard_witness_reports_crime_and_memories_survive_resurrection_and_save() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var entities := EntitySet.new()
	var guard := _actor("guard_actor", "npc_guard", "guard")
	var citizen := _actor("citizen_actor", "npc_citizen", "resident")
	var victim := _actor("victim_actor", "npc_victim", "resident")
	victim.data["faction_id"] = "faction_town"
	entities.entities_by_id = {
		guard.get_entity_id(): guard,
		citizen.get_entity_id(): citizen,
		victim.get_entity_id(): victim
	}
	var perception := PerceptionStub.new()
	perception.witnesses = [
		{"entity_id": guard.get_entity_id(), "npc_id": "npc_guard", "sense": "sight", "saw": true, "heard": true},
		{"entity_id": citizen.get_entity_id(), "npc_id": "npc_citizen", "sense": "hearing", "saw": false, "heard": true}
	]
	var factions := FactionStub.new()
	var manager := CrimeManager.new()
	add_child_autofree(manager)
	manager.setup(bus, entities, perception, TimeStub.new(), factions)

	var crime := manager.record_player_crime(
		{
			"kind": "murder",
			"victim_entity_id": "victim_actor",
			"victim_npc_id": "npc_victim",
			"victim_faction_id": "faction_town",
			"world_position": [32, 64],
			"world_layer": "surface",
			"noise_radius": 160
		}
	)

	assert_eq(crime["status"], "reported")
	assert_eq(crime["absolute_minute"], 2970)
	assert_eq(manager.reports.size(), 1)
	assert_eq(manager.bounty, 100)
	assert_eq(manager.get_guard_response("npc_guard")["action"], "arrest")
	assert_eq(factions.changes, [{"faction_id": "faction_town", "amount": -15}])
	assert_eq(manager.get_witness_memory("npc_guard")[0]["kind"], "murder")
	assert_eq(manager.get_witness_memory("npc_citizen")[0]["report_status"], "unknown_offender")
	assert_eq(manager.get_witness_memory("npc_victim")[0]["sense"], "victim")

	victim.set_actor_state("dead")
	victim.set_actor_state("alive")
	assert_eq(manager.get_witness_memory("npc_guard")[0]["kind"], "murder")

	var restored := CrimeManager.new()
	add_child_autofree(restored)
	restored.setup(null, entities, perception, TimeStub.new(), factions)
	restored.load_save_data(manager.get_save_data())
	assert_eq(restored.get_crime(String(crime["id"]))["status"], "reported")
	assert_eq(restored.get_witness_memory("npc_citizen")[0]["offender_id"], "player")
	assert_eq(restored.bounty, 100)


func test_hearing_only_guard_remembers_but_does_not_identify_or_report_player() -> void:
	var entities := EntitySet.new()
	var guard := _actor("guard_actor", "npc_guard", "guard")
	entities.entities_by_id = {guard.get_entity_id(): guard}
	var perception := PerceptionStub.new()
	perception.witnesses = [
		{"entity_id": guard.get_entity_id(), "npc_id": "npc_guard", "sense": "hearing", "saw": false, "heard": true}
	]
	var manager := CrimeManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities, perception, TimeStub.new(), FactionStub.new())

	var crime := manager.record_player_crime(
		{"kind": "theft", "world_position": [0, 0], "world_layer": "surface", "noise_radius": 24}
	)

	assert_eq(crime["status"], "unreported")
	assert_eq(manager.reports, [])
	assert_eq(manager.bounty, 0)
	assert_false(manager.get_witness_memory("npc_guard")[0]["identified_offender"])
	assert_eq(manager.get_witness_memory("npc_guard")[0]["report_status"], "unknown_offender")


func test_civilian_eyewitness_reaches_guard_and_files_report() -> void:
	var entities := EntitySet.new()
	var citizen := _actor("citizen_actor", "npc_citizen", "resident")
	var guard := _actor("guard_actor", "npc_guard", "guard")
	entities.entities_by_id = {
		citizen.get_entity_id(): citizen,
		guard.get_entity_id(): guard
	}
	var perception := PerceptionStub.new()
	perception.witnesses = [
		{"entity_id": citizen.get_entity_id(), "npc_id": "npc_citizen", "sense": "sight", "saw": true, "heard": true}
	]
	var manager := CrimeManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities, perception, TimeStub.new(), FactionStub.new())
	var crime := manager.record_player_crime(
		{"kind": "assault", "world_position": [0, 0], "world_layer": "surface", "noise_radius": 96}
	)

	manager._process(0.1)

	assert_eq(manager.get_crime(String(crime["id"]))["status"], "reported")
	assert_eq(manager.reports[0]["witness_npc_id"], "npc_citizen")
	assert_eq(manager.get_guard_response("npc_guard")["action"], "arrest")


func test_surrender_moves_into_persistent_sentence_then_serving_releases_without_erasing_memory() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var jailed_events: Array[Dictionary] = []
	var released_events: Array[Dictionary] = []
	bus.player_jailed.connect(func(state: Dictionary): jailed_events.append(state))
	bus.player_released_from_jail.connect(func(state: Dictionary): released_events.append(state))
	var entities := EntitySet.new()
	var guard := _actor("guard_actor", "npc_guard", "guard")
	entities.entities_by_id = {guard.get_entity_id(): guard}
	var perception := PerceptionStub.new()
	perception.witnesses = [
		{"entity_id": guard.get_entity_id(), "npc_id": "npc_guard", "sense": "sight", "saw": true, "heard": true}
	]
	var clock := TimeStub.new()
	var inventory := InventoryStub.new()
	var manager := CrimeManager.new()
	add_child_autofree(manager)
	manager.setup(bus, entities, perception, clock, FactionStub.new(), null, null, inventory)
	manager.record_player_crime(
		{"kind": "murder", "victim_npc_id": "npc_victim", "victim_faction_id": "faction_town", "world_position": [0, 0], "world_layer": "surface", "noise_radius": 160}
	)

	var surrender := manager.resolve_guard_response("npc_guard", "submit")

	assert_true(surrender["ok"])
	assert_true(manager.is_player_jailed())
	assert_eq(manager.sentence_remaining_hours(), 32)
	assert_eq(jailed_events[0]["target_layer"], CrimeManager.JAIL_LAYER)
	var restored := CrimeManager.new()
	add_child_autofree(restored)
	restored.setup(bus, entities, perception, clock, FactionStub.new(), null, null, inventory)
	restored.load_save_data(manager.get_save_data())
	assert_true(restored.is_player_jailed())
	assert_eq(restored.get_witness_memory("npc_guard")[0]["kind"], "murder")

	var served := restored.serve_sentence()

	assert_true(served["ok"])
	assert_false(restored.is_player_jailed())
	assert_eq(restored.bounty, 0)
	assert_eq(restored.reports[0]["status"], "resolved")
	assert_eq(released_events.back()["target_layer"], "surface")
	assert_eq(restored.get_witness_memory("npc_guard")[0]["kind"], "murder")


func test_pay_bounty_and_make_amends_cost_gold_and_repair_reputation() -> void:
	var inventory := InventoryStub.new()
	var factions := FactionStub.new()
	var manager := CrimeManager.new()
	add_child_autofree(manager)
	manager.setup(null, EntitySet.new(), PerceptionStub.new(), TimeStub.new(), factions, null, null, inventory)
	manager.bounty = 25
	manager.crimes = [{"victim_faction_id": "faction_town", "status": "reported"}]

	assert_true(manager.pay_bounty()["ok"])
	assert_eq(inventory.gold, 175)
	assert_true(manager.can_make_amends())
	assert_true(manager.make_amends()["ok"])
	assert_eq(inventory.gold, 150)
	assert_eq(factions.reputation, -10)


func _actor(entity_id: String, npc_id: String, role: String) -> WorldEntity:
	var actor := WorldEntity.new()
	add_child_autofree(actor)
	actor.setup(
		{
			"id": entity_id,
			"npc_id": npc_id,
			"kind": "npc",
			"role": role,
			"global_tile": [0, 0],
			"character_profile": {"character_id": "char_%s" % npc_id, "state": "alive"}
		}
	)
	return actor
