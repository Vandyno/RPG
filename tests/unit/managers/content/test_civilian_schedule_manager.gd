extends GutTest

const CivilianScheduleManager = preload("res://scripts/managers/content/civilian_schedule_manager.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const InventoryManager = preload("res://scripts/managers/actors/inventory_manager.gd")
const ShopManager = preload("res://scripts/managers/content/shop_manager.gd")
const TimeManager = preload("res://scripts/managers/content/time_manager.gd")
const WorldEntity = preload("res://scripts/world/world_entity.gd")
const ChunkManager = preload("res://scripts/managers/world/chunk_manager.gd")
const StructureManager = preload("res://scripts/managers/world/structure_manager.gd")
const WorldQuery = preload("res://scripts/world/world_query.gd")

const PROPOSAL_PATH := "res://data/proposals/northgate_civilian_schedule_proposal.json"


class EntitySet:
	var entities_by_id: Dictionary = {}


class CombatStub:
	var health: int = 20

	func get_entity_health(_actor) -> int:
		return health

	func heal_entity(_actor, amount: int) -> int:
		health = mini(100, health + amount)
		return health


class QuestContentStub:
	func get_quest(_quest_id: String) -> Dictionary:
		return {
			"stages": {
				"posted": {
					"npc_routines": [
						{
							"npc_id": "npc_northgate_farmer_proposal",
							"routine_id": "post_notice",
							"destination_id": "northgate_quest_notice",
							"action": "post the missing-tools notice"
						}
					]
				}
			}
		}


class PlayerStub:
	var world_layer := "surface"
	var global_position := Vector2.ZERO


func test_northgate_proposal_shopkeeper_and_farmer_follow_work_meal_relax_home_sleep() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var entities: EntitySet = fixture["entities"]
	var farmer: WorldEntity = entities.entities_by_id["northgate_farmer_actor"]
	var shopkeeper: WorldEntity = entities.entities_by_id["northgate_shopkeeper_actor"]

	assert_eq(manager.get_schedule_debug("npc_northgate_farmer_proposal")["activity"], "work")
	assert_true(
		["hoe_rows", "check_livestock", "carry_hay"].has(
			manager.get_schedule_debug("npc_northgate_farmer_proposal")["activity_action"]
		)
	)
	var farmer_start := farmer.global_position
	manager.update(30.0)
	assert_gt(farmer.global_position.distance_to(farmer_start), 0.0)
	assert_eq(manager.get_schedule_debug("npc_northgate_farmer_proposal")["destination_id"], "northgate_farm_field")
	manager.update(300.0)
	assert_eq(farmer.global_tile, Vector2i(-3148, -3843))

	manager.update(30.0)
	assert_true(manager.is_service_available("service_northgate_general_shop"))
	assert_eq(shopkeeper.data["behavior_state"], "work")

	time.advance_hours(4)
	assert_eq(manager.get_schedule_debug("npc_northgate_farmer_proposal")["activity"], "eat")
	assert_eq(manager.get_schedule_debug("npc_northgate_farmer_proposal")["destination_id"], "northgate_farm_meal")

	time.advance_hours(6)
	assert_eq(manager.get_schedule_debug("npc_northgate_farmer_proposal")["activity"], "relax")
	assert_false(manager.is_service_available("service_northgate_general_shop"))

	time.advance_minutes(270)
	assert_eq(manager.get_schedule_debug("npc_northgate_farmer_proposal")["activity"], "sleep")
	assert_eq(manager.get_schedule_debug("npc_northgate_shopkeeper_proposal")["activity"], "sleep")


func test_farmer_changes_workplace_and_action_for_rain_then_returns_to_field() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var saved := manager.get_save_data()
	var farmer_state: Dictionary = saved["states"]["npc_northgate_farmer_proposal"].duplicate(true)
	farmer_state["needs"] = {"hunger": 0.0, "fatigue": 0.0, "last_updated_absolute": saved["last_absolute_minute"]}
	saved["states"]["npc_northgate_farmer_proposal"] = farmer_state
	manager.load_save_data(saved)
	time.advance_minutes(24 * 60)
	var rainy := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(time.get_weather(), "rain")
	assert_eq(rainy["weather"], "rain")
	assert_eq(rainy["activity"], "work")
	assert_eq(rainy["destination_id"], "northgate_farmer_home")
	assert_eq(rainy["activity_action"], "sort seed indoors")
	saved = manager.get_save_data()
	farmer_state = saved["states"]["npc_northgate_farmer_proposal"].duplicate(true)
	farmer_state["needs"] = {"hunger": 0.0, "fatigue": 0.0, "last_updated_absolute": saved["last_absolute_minute"]}
	saved["states"]["npc_northgate_farmer_proposal"] = farmer_state
	manager.load_save_data(saved)
	time.advance_minutes(24 * 60)
	var clear_again := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(time.get_weather(), "cloudy")
	assert_eq(clear_again["activity"], "work")
	assert_eq(clear_again["destination_id"], "northgate_farm_field")
	assert_ne(clear_again["activity_action"], "sort seed indoors")


func test_local_activity_state_tracks_work_progress_and_household_members() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var bindings: Dictionary = fixture["bindings"].duplicate(true)
	bindings["binding_northgate_shopkeeper_proposal"]["home_destination_id"] = "northgate_farmer_home"
	manager.load_authored_data(fixture["profiles"], bindings, fixture["destinations"])

	var farmer_state := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(farmer_state["activity_status"], "working")
	assert_gt(float(farmer_state["activity_progress"]), 0.0)
	assert_true(farmer_state["household_members"].has("npc_northgate_shopkeeper_proposal"))

	var progress_before := float(farmer_state["activity_progress"])
	time.advance_minutes(30)
	var farmer_after := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_gt(float(farmer_after["activity_progress"]), progress_before)
	assert_eq(farmer_after["activity_status"], "working")


func test_relaxing_civilians_form_a_social_exchange_after_reaching_the_same_anchor() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var bindings: Dictionary = fixture["bindings"].duplicate(true)
	bindings["binding_northgate_shopkeeper_proposal"]["leisure_destination_ids"] = ["northgate_inn_bar"]
	bindings["binding_northgate_farmer_proposal"]["leisure_destination_ids"] = ["northgate_inn_bar"]
	manager.load_authored_data(fixture["profiles"], bindings, fixture["destinations"])
	var social_saved := manager.get_save_data()
	social_saved["work_records"]["npc_northgate_farmer_proposal"] = {
		"npc_id": "npc_northgate_farmer_proposal",
		"total_minutes": 30,
		"last_output": "Tended the field rows."
	}
	manager.load_save_data(social_saved)

	time.advance_minutes(690)
	manager.update(120.0)
	var farmer_state := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	var shopkeeper_state := manager.get_schedule_debug("npc_northgate_shopkeeper_proposal")
	assert_true(farmer_state["at_destination"])
	assert_true(shopkeeper_state["at_destination"])
	assert_eq(farmer_state["social_presence"], "with_companions")
	assert_eq(shopkeeper_state["social_presence"], "with_companions")
	assert_true(farmer_state["companions"].has("npc_northgate_shopkeeper_proposal"))
	assert_true(shopkeeper_state["companions"].has("npc_northgate_farmer_proposal"))
	assert_eq(farmer_state["social_topic"], "Tended the field rows.")
	assert_eq(manager.get_local_rumor("npc_northgate_farmer_proposal"), "Rumor: Tended the field rows.")
	assert_true(["talk", "listen", "laugh", "share_news"].has(farmer_state["social_exchange"]))
	var relationship_key := "npc_northgate_farmer_proposal|npc_northgate_shopkeeper_proposal"
	var saved := manager.get_save_data()
	assert_eq(saved["social_relationships"][relationship_key]["meetings"], 1)
	assert_eq(saved["social_relationships"][relationship_key]["familiarity"], 1.0)
	manager.load_save_data(saved)
	assert_eq(manager.get_save_data()["social_relationships"][relationship_key]["meetings"], 1)


func test_unresolved_incident_becomes_a_social_rumor() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var bindings: Dictionary = fixture["bindings"].duplicate(true)
	bindings["binding_northgate_shopkeeper_proposal"]["leisure_destination_ids"] = ["northgate_inn_bar"]
	bindings["binding_northgate_farmer_proposal"]["leisure_destination_ids"] = ["northgate_inn_bar"]
	manager.load_authored_data(fixture["profiles"], bindings, fixture["destinations"])
	manager.player_memories["npc_northgate_farmer_proposal"] = {
		"unresolved": true,
		"rumor": "Someone entered my home without permission."
	}

	time.advance_minutes(690)
	manager.update(120.0)
	assert_eq(
		manager.get_local_rumor("npc_northgate_shopkeeper_proposal"),
		"Rumor: Someone entered my home without permission."
	)


func test_private_home_trespass_triggers_confrontation_then_schedule_resume() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var destinations: Dictionary = fixture["destinations"].duplicate(true)
	destinations["northgate_farmer_home"]["world_layer"] = "interior:test_farmer_home"
	manager.load_authored_data(fixture["profiles"], fixture["bindings"], destinations)
	var farmer: WorldEntity = fixture["entities"].entities_by_id["northgate_farmer_actor"]
	farmer.set_world_layer("interior:test_farmer_home")
	var player := PlayerStub.new()
	player.world_layer = "interior:test_farmer_home"
	player.global_position = farmer.global_position + Vector2(16.0, 0.0)
	manager.set_player(player)

	manager.update(0.1)
	var reacting := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(reacting["activity"], "investigate")
	assert_eq(reacting["interruption"]["reason"], "trespass")
	assert_eq(reacting["behavior_state"], "confronting")

	time.advance_minutes(2)
	manager.update(0.1)
	var resumed := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_false(resumed.has("interruption"))
	assert_eq(resumed["activity"], "work")


func test_role_work_leaves_a_persistent_output_record() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	manager.update(30.0)
	manager.update(300.0)
	time.advance_minutes(30)
	var record := manager.get_work_record("npc_northgate_farmer_proposal")
	assert_eq(record["total_minutes"], 30)
	assert_true(String(record["last_output"]).begins_with("Tended") or String(record["last_output"]).begins_with("Checked") or String(record["last_output"]).begins_with("Moved"))
	assert_true(manager.get_schedule_debug("npc_northgate_farmer_proposal").has("work_summary"))
	var saved := manager.get_save_data()
	manager.load_save_data(saved)
	assert_eq(manager.get_work_record("npc_northgate_farmer_proposal")["total_minutes"], 30)


func test_quest_routine_takes_over_travel_persists_and_resumes_schedule() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var destinations: Dictionary = fixture["destinations"].duplicate(true)
	destinations["northgate_quest_notice"] = {
		"id": "northgate_quest_notice",
		"world_layer": "surface",
		"global_tile": [-3280, -3900],
		"kind": "quest.notice"
	}
	manager.load_authored_data(fixture["profiles"], fixture["bindings"], destinations)
	assert_true(manager.assign_quest_routine(
		"npc_northgate_farmer_proposal",
		{
			"quest_id": "quest_test_notice",
			"routine_id": "post_notice",
			"destination_id": "northgate_quest_notice",
			"action": "post the missing-tools notice",
			"reason": "quest duty"
		}
	))
	var assigned := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(assigned["activity"], "quest")
	assert_eq(assigned["activity_action"], "post the missing-tools notice")
	assert_eq(assigned["interruption"]["reason"], "quest")
	assert_eq(assigned["destination_id"], "northgate_quest_notice")
	assert_eq(manager.dialogue_block_reason("npc_northgate_farmer_proposal"), "They are occupied with a task.")

	var saved := manager.get_save_data()
	manager.load_save_data(saved)
	assert_eq(manager.get_schedule_debug("npc_northgate_farmer_proposal")["activity"], "quest")
	assert_true(manager.release_quest_routine("npc_northgate_farmer_proposal", "quest_test_notice"))
	var resumed := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_false(resumed.has("interruption"))
	assert_eq(resumed["activity"], "work")


func test_quest_stage_event_authors_and_releases_an_npc_routine() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var bus: EventBus = fixture["bus"]
	var destinations: Dictionary = fixture["destinations"].duplicate(true)
	destinations["northgate_quest_notice"] = {
		"id": "northgate_quest_notice",
		"world_layer": "surface",
		"global_tile": [-3280, -3900],
		"kind": "quest.notice"
	}
	manager.load_authored_data(fixture["profiles"], fixture["bindings"], destinations)
	manager.content = QuestContentStub.new()
	bus.quest_changed.emit("quest_test_notice", {"state": "active", "stage": "posted"})
	var assigned := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(assigned["quest_id"], "quest_test_notice")
	assert_eq(assigned["activity"], "quest")

	bus.quest_changed.emit("quest_test_notice", {"state": "completed", "stage": "completed"})
	var resumed := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_false(resumed.has("quest_routine"))
	assert_false(resumed.has("interruption"))
	assert_eq(resumed["activity"], "work")


func test_player_can_wake_a_sleeping_civilian_until_the_next_schedule_block() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	time.advance_minutes(810)
	var sleeping := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(sleeping["activity"], "sleep")
	assert_true(manager.wake_npc("npc_northgate_farmer_proposal"))
	var woken := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(woken["activity"], "wake")
	assert_eq(woken["activity_action"], "get up when woken")
	assert_true(int(woken["wake_override_until_absolute"]) > time.day * 1440 + time.minute_of_day)

	time.advance_minutes(480)
	var next_block := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(next_block["scheduled_activity"], "wake")
	assert_eq(next_block["activity"], "sleep")
	assert_eq(next_block["need_override"], "sleep")


func test_wait_midnight_and_streamed_out_catch_up_to_current_block() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var bus: EventBus = fixture["bus"]
	var entities: EntitySet = fixture["entities"]

	entities.entities_by_id.clear()
	time.load_save_data({"day": 1, "minute_of_day": 23 * 60 + 59})
	time.advance_minutes(2)
	var offscreen := manager.get_schedule_debug("npc_northgate_farmer_proposal")
	assert_eq(time.day, 2)
	assert_eq(offscreen["activity"], "sleep")
	assert_eq(offscreen["simulation_mode"], "streamed_out")

	var farmer: WorldEntity = _actor(_actor_data("northgate_farmer_actor", "npc_northgate_farmer_proposal", [-3282, -3902]))
	entities.entities_by_id[farmer.get_entity_id()] = farmer
	add_child_autofree(farmer)
	bus.chunks_changed.emit([])
	assert_eq(farmer.data["schedule_state"]["activity"], "sleep")
	assert_eq(farmer.global_tile, Vector2i(-3282, -3902))


func test_waiting_advances_the_schedule_to_the_current_block() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var result := time.wait_hours(4)
	assert_true(result["ok"])
	assert_eq(time.get_time_label(), "12:00")
	assert_eq(manager.get_schedule_debug("npc_northgate_farmer_proposal")["activity"], "eat")


func test_interruption_resume_and_save_load_preserve_schedule_state() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]

	assert_true(manager.interrupt("npc_northgate_shopkeeper_proposal", "quest_scene"))
	assert_false(manager.is_service_available("service_northgate_general_shop"))
	assert_true(manager.resume("npc_northgate_shopkeeper_proposal"))
	assert_false(manager.get_schedule_debug("npc_northgate_shopkeeper_proposal").has("interruption"))

	time.advance_hours(12)
	var saved := manager.get_save_data()
	var saved_position: Array = saved["states"]["npc_northgate_shopkeeper_proposal"]["world_position"]
	var restored: CivilianScheduleManager = CivilianScheduleManager.new()
	add_child_autofree(restored)
	restored.setup(fixture["bus"], null, time, fixture["entities"], null)
	restored.load_authored_data(fixture["profiles"], fixture["bindings"], fixture["destinations"])
	restored.load_save_data(saved)
	var shopkeeper: WorldEntity = fixture["entities"].entities_by_id["northgate_shopkeeper_actor"]
	shopkeeper.set_global_tile(Vector2i.ZERO)
	restored.load_save_data(saved)
	assert_almost_eq(shopkeeper.global_position.x, float(saved_position[0]), 0.1)
	assert_almost_eq(shopkeeper.global_position.y, float(saved_position[1]), 0.1)
	assert_eq(
		restored.get_schedule_debug("npc_northgate_shopkeeper_proposal")["activity"],
		manager.get_schedule_debug("npc_northgate_shopkeeper_proposal")["activity"]
	)


func test_shop_service_requires_the_scheduled_worker_to_be_present() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var bus: EventBus = fixture["bus"]
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	content.shops["shop_northgate_proposal"] = {
		"id": "shop_northgate_proposal",
		"name": "Northgate Shop Proposal",
		"open_hour": 8,
		"close_hour": 18,
		"worker_npc_id": "npc_northgate_shopkeeper_proposal",
		"service_id": "service_northgate_general_shop",
		"stock": []
	}
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(bus, content)
	var shops := ShopManager.new()
	add_child_autofree(shops)
	shops.setup(bus, content, inventory, null, fixture["time"])
	shops.set_schedule_manager(manager)

	fixture["entities"].entities_by_id.clear()
	assert_false(shops.is_shop_open("shop_northgate_proposal"))
	assert_true(shops.shop_unavailable_reason("shop_northgate_proposal").contains("Worker"))

	var shopkeeper: WorldEntity = _actor({
		"id": "northgate_shopkeeper_actor",
		"npc_id": "npc_northgate_shopkeeper_proposal",
		"kind": "npc",
		"brain_id": "civilian_schedule",
		"hostility": "neutral",
		"world_layer": "surface",
		"global_tile": [-3294, -3922],
		"move_speed": 160
	})
	fixture["entities"].entities_by_id[shopkeeper.get_entity_id()] = shopkeeper
	add_child_autofree(shopkeeper)
	manager.load_authored_data(fixture["profiles"], fixture["bindings"], fixture["destinations"])
	manager.update(0.1)
	assert_true(shops.is_shop_open("shop_northgate_proposal"))


func test_shop_service_closes_for_incapacitated_or_hostile_worker() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var shopkeeper: WorldEntity = fixture["entities"].entities_by_id["northgate_shopkeeper_actor"]
	manager.update(30.0)
	assert_true(manager.is_service_available("service_northgate_general_shop"))

	shopkeeper.data["incapacitated"] = true
	assert_false(manager.is_service_available("service_northgate_general_shop"))
	shopkeeper.data["incapacitated"] = false
	shopkeeper.data["hostility"] = "hostile"
	assert_false(manager.is_service_available("service_northgate_general_shop"))


func test_runtime_shopkeeper_crosses_authored_portals_between_home_and_shop() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var time := TimeManager.new()
	add_child_autofree(time)
	time.setup(bus)
	var content := ContentDatabase.new()
	add_child_autofree(content)
	assert_eq(content.load_all(), [])
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	chunks.load_world_terrain(content.world_terrain)
	var structures := StructureManager.new()
	add_child_autofree(structures)
	structures.setup(content)
	var world_query := WorldQuery.new()
	world_query.setup(chunks, structures)
	var entities := EntitySet.new()
	var manager := CivilianScheduleManager.new()
	add_child_autofree(manager)
	manager.setup(bus, content, time, entities, chunks, world_query)
	var shopkeeper := _actor(
		{
			"id": "npc_northgate_shopkeeper_world",
			"npc_id": "npc_northgate_shopkeeper",
			"kind": "npc",
			"brain_id": "civilian_schedule",
			"hostility": "neutral",
			"world_layer": "interior:structure_northgate_west_home_plot",
			"global_tile": [7, 2],
			"move_speed": 220
		}
	)
	entities.entities_by_id[shopkeeper.get_entity_id()] = shopkeeper
	add_child_autofree(shopkeeper)
	manager.update(0.1)
	for _step in range(40):
		manager.update(1.0)
	assert_eq(shopkeeper.world_layer, "interior:structure_northgate_shop_plot")
	assert_true([Vector2i(6, 3), Vector2i(7, 3), Vector2i(6, 4)].has(shopkeeper.global_tile))
	assert_true(manager.get_schedule_debug("npc_northgate_shopkeeper").get("at_destination", false))


func test_combat_promotion_records_schedule_interruption_for_civilian() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var shopkeeper: WorldEntity = fixture["entities"].entities_by_id["northgate_shopkeeper_actor"]
	shopkeeper.data["schedule_brain_id"] = "civilian_schedule"
	shopkeeper.data["brain_id"] = "hostile_basic"
	shopkeeper.data["hostility"] = "hostile"
	shopkeeper.data["hostile_to_player"] = true
	manager.update(0.1)
	var state := manager.get_schedule_debug("npc_northgate_shopkeeper_proposal")
	assert_true(state.has("interruption"))
	assert_eq(state["interruption"]["reason"], "combat")


func test_player_incident_memory_survives_save_load_and_can_be_addressed() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var shopkeeper: WorldEntity = fixture["entities"].entities_by_id["northgate_shopkeeper_actor"]
	var npc_id := "npc_northgate_shopkeeper_proposal"
	shopkeeper.data["schedule_brain_id"] = "civilian_schedule"
	shopkeeper.data["brain_id"] = "hostile_basic"
	shopkeeper.data["hostility"] = "hostile"
	shopkeeper.data["hostile_to_player"] = true
	manager.update(0.1)
	assert_eq(manager.get_player_memory(npc_id)["attack_count"], 1)

	shopkeeper.data["brain_id"] = "civilian_schedule"
	shopkeeper.data["hostility"] = "neutral"
	shopkeeper.data["hostile_to_player"] = false
	assert_true(manager.resume(npc_id))
	assert_eq(manager.dialogue_block_reason(npc_id), "They are wary of you.")
	assert_true(manager.can_address_player_incident(npc_id))

	var saved: Dictionary = manager.get_save_data()
	var restored: CivilianScheduleManager = CivilianScheduleManager.new()
	add_child_autofree(restored)
	restored.setup(fixture["bus"], null, fixture["time"], fixture["entities"], null)
	restored.load_authored_data(fixture["profiles"], fixture["bindings"], fixture["destinations"])
	restored.load_save_data(saved)
	assert_eq(restored.get_player_memory(npc_id)["attack_count"], 1)
	assert_eq(restored.dialogue_block_reason(npc_id), "They are wary of you.")
	assert_true(restored.acknowledge_player_incident(npc_id))
	assert_false(restored.get_player_memory(npc_id)["unresolved"])
	assert_eq(restored.dialogue_block_reason(npc_id), "")


func test_wounded_civilian_flees_home_recovers_and_resumes_schedule() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var shopkeeper: WorldEntity = fixture["entities"].entities_by_id["northgate_shopkeeper_actor"]
	var time: TimeManager = fixture["time"]
	var npc_id := "npc_northgate_shopkeeper_proposal"
	var combat := CombatStub.new()
	manager.combat = combat
	shopkeeper.set_global_tile(Vector2i(-3294, -3922))
	shopkeeper.data["max_health"] = 100
	shopkeeper.data["schedule_brain_id"] = "civilian_schedule"
	shopkeeper.data["brain_id"] = "hostile_basic"
	shopkeeper.data["hostility"] = "hostile"
	shopkeeper.data["hostile_to_player"] = true
	manager.update(0.1)

	var fleeing: Dictionary = manager.get_schedule_debug(npc_id)
	assert_eq(fleeing["activity"], "flee")
	assert_eq(fleeing["interruption"]["reason"], "flee")
	assert_eq(shopkeeper.data["brain_id"], "civilian_schedule")
	assert_eq(shopkeeper.data["hostility"], "neutral")

	for _step in range(30):
		manager.update(1.0)
	var recovering: Dictionary = manager.get_schedule_debug(npc_id)
	assert_eq(recovering["activity"], "recover")
	assert_eq(recovering["interruption"]["reason"], "recovering")
	assert_true(int(recovering["recovery_until_absolute"]) > int(recovering["interruption"]["started_at"]))

	time.advance_minutes(60)
	manager.update(0.1)
	assert_false(manager.get_schedule_debug(npc_id).has("interruption"))
	assert_eq(manager.get_schedule_debug(npc_id)["activity"], "work")
	assert_eq(combat.health, 100)


func test_critical_needs_override_schedule_and_survive_save_load() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var npc_id := "npc_northgate_farmer_proposal"
	var saved := manager.get_save_data()
	var state: Dictionary = saved["states"][npc_id].duplicate(true)
	state["needs"] = {
		"hunger": 95.0,
		"fatigue": 10.0,
		"last_updated_absolute": int(saved["last_absolute_minute"])
	}
	saved["states"][npc_id] = state
	manager.load_save_data(saved)

	var debug := manager.get_schedule_debug(npc_id)
	assert_eq(debug["activity"], "eat")
	assert_eq(debug["need_override"], "eat")
	assert_eq(debug["needs"]["hunger"], 95.0)

	var round_trip := manager.get_save_data()
	var round_trip_state: Dictionary = round_trip["states"][npc_id]
	assert_eq(round_trip_state["needs"]["hunger"], 95.0)
	assert_false(round_trip_state.has("_travel_path"))


func test_eating_recovers_hunger_and_releases_the_critical_override() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var npc_id := "npc_northgate_farmer_proposal"
	var saved: Dictionary = manager.get_save_data()
	var state: Dictionary = saved["states"][npc_id].duplicate(true)
	state["needs"] = {
		"hunger": 95.0,
		"fatigue": 10.0,
		"last_updated_absolute": int(saved["last_absolute_minute"])
	}
	saved["states"][npc_id] = state
	manager.load_save_data(saved)
	assert_eq(manager.get_schedule_debug(npc_id)["activity"], "eat")

	time.advance_minutes(20)
	var debug: Dictionary = manager.get_schedule_debug(npc_id)
	assert_eq(debug["activity"], "work")
	assert_lt(float(debug["needs"]["hunger"]), 86.0)


func test_civilian_schedule_resumes_after_hostile_brain_returns_home() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var shopkeeper: WorldEntity = fixture["entities"].entities_by_id["northgate_shopkeeper_actor"]
	var npc_id := "npc_northgate_shopkeeper_proposal"
	shopkeeper.data["schedule_brain_id"] = "civilian_schedule"
	shopkeeper.data["brain_id"] = "hostile_basic"
	shopkeeper.data["hostility"] = "hostile"
	shopkeeper.data["hostile_to_player"] = true
	manager.update(0.1)
	assert_true(manager.get_schedule_debug(npc_id).has("interruption"))

	shopkeeper.data["brain_id"] = "civilian_schedule"
	shopkeeper.data["hostility"] = "neutral"
	shopkeeper.data["hostile_to_player"] = false
	shopkeeper.data["schedule_resume_requested"] = true
	manager.update(0.1)
	assert_false(manager.get_schedule_debug(npc_id).has("interruption"))


func test_authored_activity_tiles_rotate_during_a_long_work_block() -> void:
	var fixture := _fixture()
	var manager: CivilianScheduleManager = fixture["manager"]
	var time: TimeManager = fixture["time"]
	var destinations: Dictionary = fixture["destinations"]
	destinations["northgate_farm_field"]["activity_tiles"] = [[-3148, -3843], [-3149, -3843], [-3148, -3844]]
	destinations["northgate_farm_field"]["activity_cycle_minutes"] = 30
	manager.load_authored_data(fixture["profiles"], fixture["bindings"], destinations)
	var seen_tiles: Array = []
	var seen_actions: Array = []
	for _cycle in range(6):
		var farmer_state: Dictionary = manager.get_schedule_debug("npc_northgate_farmer_proposal")
		var tile: Array = farmer_state["destination_tile"]
		if not seen_tiles.has(tile):
			seen_tiles.append(tile)
		if not seen_actions.has(farmer_state["activity_action"]):
			seen_actions.append(farmer_state["activity_action"])
		time.advance_minutes(30)
	assert_gte(seen_tiles.size(), 2)
	assert_gte(seen_actions.size(), 2)


func _fixture() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROPOSAL_PATH))
	var bus := EventBus.new()
	add_child_autofree(bus)
	var time := TimeManager.new()
	add_child_autofree(time)
	time.setup(bus)
	var entities := EntitySet.new()
	var manager := CivilianScheduleManager.new()
	add_child_autofree(manager)
	manager.setup(bus, null, time, entities, null)
	manager.load_authored_data(parsed["profiles"], parsed["bindings"], parsed["destinations"])
	for actor_data in parsed["actors"]:
		var actor := _actor(actor_data)
		entities.entities_by_id[actor.get_entity_id()] = actor
		add_child_autofree(actor)
	manager.load_authored_data(parsed["profiles"], parsed["bindings"], parsed["destinations"])
	return {
		"bus": bus,
		"time": time,
		"entities": entities,
		"manager": manager,
		"profiles": parsed["profiles"],
		"bindings": parsed["bindings"],
		"destinations": parsed["destinations"]
	}


func _actor(data: Dictionary) -> WorldEntity:
	var actor := WorldEntity.new()
	actor.setup(data)
	return actor


func _actor_data(actor_id: String, npc_id: String, tile: Array) -> Dictionary:
	return {"id": actor_id, "npc_id": npc_id, "kind": "npc", "brain_id": "civilian_schedule", "hostility": "neutral", "world_layer": "surface", "global_tile": tile, "move_speed": 220}
