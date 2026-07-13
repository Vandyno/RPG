extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const ScheduleDestinationRegistry = preload("res://scripts/core/schedule_destination_registry.gd")
const ScheduleResolver = preload("res://scripts/core/schedule_resolver.gd")


func test_northgate_schedule_bindings_and_farm_remain_review_gated() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	assert_eq(content.validate_all(), [])

	var farmer_binding := content.get_schedule_binding("binding_northgate_farmer")
	assert_eq(farmer_binding["npc_id"], "npc_northgate_farmer")
	assert_eq(farmer_binding["schedule_id"], "schedule_farmer_standard")
	assert_eq(content.get_schedule_destinations()["northgate_farm_field_runtime"]["kind"], "farm.field")
	assert_eq(content.get_npc("npc_northgate_farmer")["canon_status"], "proposal")
	assert_eq(content.get_schedule_binding("binding_northgate_shopkeeper")["service_ids"], ["service_northgate_general_shop"])
	assert_true(content.get_schedule_profile("schedule_resident_standard").has("weekend_blocks"))
	assert_eq(
		content.get_schedule_destinations()["northgate_inn_table_runtime"].get("activity_tiles", []).size(),
		4
	)
	assert_eq(
		content.get_schedule_destinations()["northgate_farm_field_runtime"].get("activity_tiles", []).size(),
		3
	)
	assert_eq(content.get_schedule_binding("binding_northgate_smith")["service_ids"], ["service_northgate_smith"])
	assert_eq(content.get_schedule_binding("binding_northgate_guard_north")["patrol_destination_id"], "northgate_guard_gate_runtime")
	assert_eq(
		content.get_schedule_destinations()["northgate_store_ledger_runtime"]["kind"],
		"store.ledger"
	)
	var manifest_quest := content.get_quest("quest_northgate_missing_manifest")
	assert_eq(
		manifest_quest["stages"]["search"]["npc_routines"][0]["npc_id"],
		"npc_northgate_storekeeper"
	)
	var registry := ScheduleDestinationRegistry.new()
	registry.load_data(content.get_schedule_destinations())
	var guard_destination := registry.resolve(
		content.get_schedule_binding("binding_northgate_guard_north"), "patrol", 1, 0
	)
	assert_eq(guard_destination["id"], "northgate_guard_gate_runtime")
	assert_eq(
		Vector2i(
			int(guard_destination["global_tile"][0]),
			int(guard_destination["global_tile"][1])
		),
		Vector2i(-3263, -3955)
	)
	var resident_one := content.get_schedule_binding("binding_northgate_resident_01")
	assert_eq(resident_one["visit_target_npc_ids"], ["npc_northgate_resident_02"])
	assert_eq(
		registry.resolve(resident_one, "visit", 6, 3)["id"],
		"northgate_south_home_runtime"
	)
	var resident_five := content.get_schedule_binding("binding_northgate_resident_05")
	var resident_five_profile := content.get_schedule_profile("schedule_resident_standard")
	var host_block := ScheduleResolver.resolve(
		resident_five_profile, 15 * 60, 6, resident_five.get("personal_overrides", [])
	)
	assert_eq(host_block["destination"], "home")
	assert_eq(host_block["action"], "host_visitors")
	assert_eq(content.get_shop("shop_northgate_smith")["worker_npc_id"], "npc_northgate_smith")
	var expected_scheduled_npcs := [
		"npc_northgate_farmer", "npc_northgate_shopkeeper", "npc_northgate_innkeeper",
		"npc_northgate_smith", "npc_northgate_apprentice", "npc_northgate_reeve",
		"npc_northgate_clerk", "npc_northgate_storekeeper", "npc_northgate_stablehand",
		"npc_northgate_guard_north", "npc_northgate_shrine_keeper",
		"npc_northgate_jail_guard",
		"npc_northgate_resident_01", "npc_northgate_resident_02",
		"npc_northgate_resident_03", "npc_northgate_resident_04",
		"npc_northgate_resident_05"
	]
	for npc_id in expected_scheduled_npcs:
		var binding := content.get_schedule_binding_for_npc(npc_id)
		assert_false(binding.is_empty(), npc_id)
		assert_false(String(binding.get("schedule_id", "")).is_empty(), npc_id)
		assert_eq(content.get_npc(npc_id).get("canon_status", ""), "proposal", npc_id)

	var farmer_actor := content.world_object_entries().filter(
		func(entry): return String(entry.get("id", "")) == "npc_northgate_farmer_world"
	)
	assert_eq(farmer_actor.size(), 1)
	assert_eq(farmer_actor[0]["canon_status"], "proposal")
