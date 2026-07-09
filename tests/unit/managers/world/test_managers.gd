# gdlint:disable=max-public-methods
extends GutTest

const InventoryManager = preload("res://scripts/managers/actors/inventory_manager.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const WorldStateManager = preload("res://scripts/managers/world/world_state_manager.gd")
const ReadableManager = preload("res://scripts/managers/content/readable_manager.gd")
const EquipmentManager = preload("res://scripts/managers/actors/equipment_manager.gd")
const ChunkManager = preload("res://scripts/managers/world/chunk_manager.gd")
const WorldStreamingManager = preload("res://scripts/managers/world/world_streaming_manager.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")


class ReadableContentStub:
	var readables: Dictionary = {
		"readable_known": {"id": "readable_known", "title": "Known"},
		"readable_reward":
		{
			"id": "readable_reward",
			"title": "Reward",
			"effects_on_read": [{"type": "add_item", "item_id": "item_gold_coin", "count": 1}]
		}
	}

	func get_readable(readable_id: String) -> Dictionary:
		return readables.get(readable_id, {})


func test_inventory_add_remove_and_save_load() -> void:
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.add_item("item_gold_coin", 5)
	inventory.add_item("item_gold_coin", 3)
	assert_eq(inventory.get_count("item_gold_coin"), 8)
	assert_true(inventory.remove_item("item_gold_coin", 4))
	assert_eq(inventory.get_count("item_gold_coin"), 4)
	assert_false(inventory.remove_item("item_gold_coin", 5))

	var loaded := InventoryManager.new()
	add_child_autofree(loaded)
	loaded.load_save_data(inventory.get_save_data())
	assert_eq(loaded.get_count("item_gold_coin"), 4)


func test_inventory_owner_getters_do_not_create_owner_state() -> void:
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)

	assert_eq(inventory.get_count_for_owner("char_missing", "item_gold_coin"), 0)
	assert_true(inventory.get_items_for_owner("char_missing").is_empty())
	assert_false(inventory.owner_items.has("char_missing"))

	inventory.add_item_to_owner("char_missing", "item_gold_coin", 1)
	assert_true(inventory.owner_items.has("char_missing"))


func test_inventory_respects_content_item_contract() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(null, content)

	assert_false(inventory.add_item("missing_item", 1))
	assert_true(inventory.add_item("item_old_toolbox", 1))
	assert_false(inventory.add_item("item_old_toolbox", 1))
	assert_eq(inventory.get_count("item_old_toolbox"), 1)
	assert_true(inventory.add_item("item_training_sword", 1))
	assert_true(inventory.add_item("item_training_sword", 1))
	assert_eq(inventory.get_count("item_training_sword"), 2)
	assert_true(inventory.add_item("item_gold_coin", 1200))
	assert_eq(inventory.get_count("item_gold_coin"), 999)
	assert_false(inventory.add_item("item_gold_coin", 1))

	var loaded := InventoryManager.new()
	add_child_autofree(loaded)
	loaded.setup(null, content)
	loaded.load_save_data(
		{
			"items":
			[
				{"item_id": "missing_item", "count": 5},
				{"item_id": "item_old_toolbox", "count": 7},
				{"item_id": "item_training_sword", "count": 7},
				{"item_id": "item_gold_coin", "count": 1200}
			]
		}
	)

	assert_eq(
		loaded.items, {"item_old_toolbox": 1, "item_training_sword": 7, "item_gold_coin": 999}
	)


func test_inventory_load_ignores_invalid_entries() -> void:
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)

	inventory.load_save_data(
		{
			"items":
			[
				{"item_id": "", "count": 5},
				{"item_id": "item_zero", "count": 0},
				{"item_id": "item_negative", "count": -2},
				{"item_id": "item_text", "count": "3"},
				{"item_id": "item_gold_coin", "count": 3}
			]
		}
	)

	assert_eq(inventory.items, {"item_gold_coin": 3})


func test_inventory_load_ignores_malformed_items_field() -> void:
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.add_item("item_old", 2)

	inventory.load_save_data({"items": "bad"})

	assert_eq(inventory.items, {})


func test_inventory_sanitizes_malformed_live_counts_for_queries_and_save() -> void:
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.items = {"item_gold_coin": "many", "item_old_toolbox": -2, "item_arrow": 3, "": 5}

	assert_eq(inventory.get_count("item_gold_coin"), 0)
	assert_eq(inventory.get_count("item_old_toolbox"), 0)
	assert_eq(inventory.get_count("item_arrow"), 3)
	assert_false(inventory.has_item("item_gold_coin"))

	var save_data := inventory.get_save_data()

	assert_eq(save_data, {"items": [{"item_id": "item_arrow", "count": 3}]})


func test_equipment_equip_unequip_modifiers_and_save_load() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(null, content)
	inventory.add_item("item_road_hatchet", 1)
	inventory.add_item("item_training_sword", 1)
	inventory.add_item("item_traveler_buckler", 1)
	var equipment := EquipmentManager.new()
	add_child_autofree(equipment)
	equipment.setup(null, content, inventory)

	assert_true(equipment.equip_item("item_road_hatchet"))
	assert_true(equipment.equip_item("item_training_sword"))
	assert_true(equipment.equip_item("item_traveler_buckler"))
	assert_false(equipment.equip_item("item_missing"))
	assert_false(equipment.equip_item("item_training_sword"))
	assert_eq(equipment.get_equipped_item("right_hand"), "item_training_sword")
	assert_eq(equipment.get_equipped_item("right_hand"), "item_training_sword")
	assert_eq(equipment.last_mainhand_weapon_id, "item_road_hatchet")
	assert_true(equipment.equip_last_mainhand_weapon())
	assert_eq(equipment.get_equipped_item("right_hand"), "item_road_hatchet")
	assert_eq(equipment.last_mainhand_weapon_id, "item_training_sword")
	assert_eq(equipment.get_equipped_item("left_hand"), "item_traveler_buckler")
	assert_eq(equipment.get_player_damage_bonus(), 4)
	assert_eq(equipment.guarded_counter_multiplier(0.5), 0.25)
	assert_true(equipment.get_summary().contains("Weapon: Road Hatchet"))
	var save_data := equipment.get_save_data()
	assert_true(equipment.unequip_slot("right_hand"))
	assert_eq(equipment.get_player_damage_bonus(), 0)

	var loaded := EquipmentManager.new()
	add_child_autofree(loaded)
	loaded.setup(null, content, inventory)
	loaded.load_save_data(save_data)

	assert_eq(loaded.get_equipped_item("right_hand"), "item_road_hatchet")
	assert_eq(loaded.get_equipped_item("left_hand"), "item_traveler_buckler")
	assert_eq(loaded.last_mainhand_weapon_id, "item_training_sword")

	var legacy_loaded := EquipmentManager.new()
	add_child_autofree(legacy_loaded)
	legacy_loaded.setup(null, content, inventory)
	legacy_loaded.load_save_data(
		{
			"equipped":
			{
				"weapon": "item_road_hatchet",
				"offhand": "item_traveler_buckler"
			}
		}
	)

	assert_eq(legacy_loaded.get_equipped_item("right_hand"), "item_road_hatchet")
	assert_eq(legacy_loaded.get_equipped_item("left_hand"), "item_traveler_buckler")


func test_equipment_load_ignores_invalid_missing_or_unowned_items() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(bus, content)
	inventory.add_item("item_traveler_buckler", 1)
	var equipment := EquipmentManager.new()
	add_child_autofree(equipment)
	equipment.setup(bus, content, inventory)

	equipment.load_save_data(
		{
			"equipped":
			{
				"weapon": "item_road_hatchet",
				"offhand": "item_traveler_buckler",
				"body": "item_gold_coin",
				"bad_slot": "item_traveler_buckler"
			},
			"last_mainhand_weapon": "item_road_hatchet"
		}
	)

	assert_eq(equipment.get_equipped_item("right_hand"), "")
	assert_eq(equipment.get_equipped_item("left_hand"), "item_traveler_buckler")
	assert_eq(equipment.last_mainhand_weapon_id, "")
	assert_eq(equipment.get_save_data(), {"equipped": {"left_hand": "item_traveler_buckler"}})
	inventory.remove_item("item_traveler_buckler", 1)
	assert_eq(equipment.get_equipped_item("left_hand"), "")


func test_equipment_swap_falls_back_to_carried_mainhand_weapon() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(null, content)
	inventory.add_item("item_road_hatchet", 1)
	inventory.add_item("item_training_sword", 1)
	var equipment := EquipmentManager.new()
	add_child_autofree(equipment)
	equipment.setup(null, content, inventory)

	assert_true(equipment.equip_item("item_road_hatchet"))
	assert_eq(equipment.last_mainhand_weapon_id, "")
	assert_true(equipment.equip_last_mainhand_weapon())
	assert_eq(equipment.get_equipped_item("right_hand"), "item_training_sword")
	assert_eq(equipment.last_mainhand_weapon_id, "item_road_hatchet")
	equipment.last_mainhand_weapon_id = "item_training_sword"
	assert_true(equipment.equip_last_mainhand_weapon())
	assert_eq(equipment.get_equipped_item("right_hand"), "item_road_hatchet")


func test_world_state_flags_and_save_load() -> void:
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.set_flag("flag_test", true)
	world_state.discover_location("location_test")
	assert_true(world_state.has_flag("flag_test"))

	var loaded := WorldStateManager.new()
	add_child_autofree(loaded)
	loaded.load_save_data(world_state.get_save_data())
	assert_true(loaded.has_flag("flag_test"))
	assert_true(loaded.discovered_locations.has("location_test"))


func test_world_state_discover_location_reports_only_new_locations() -> void:
	var event_bus := EventBus.new()
	add_child_autofree(event_bus)
	var discovered: Array[String] = []
	event_bus.location_discovered.connect(
		func(location_id: String) -> void: discovered.append(location_id)
	)
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.setup(event_bus)

	assert_true(world_state.discover_location("location_test"))
	assert_false(world_state.discover_location("location_test"))
	assert_false(world_state.discover_location(""))

	assert_eq(world_state.discovered_locations, {"location_test": true})
	assert_eq(discovered, ["location_test"])


func test_world_state_load_ignores_blank_flags_and_locations() -> void:
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)

	world_state.load_save_data(
		{"flags": {"": true, "flag_valid": true}, "discovered_locations": ["", "location_valid"]}
	)

	assert_eq(world_state.flags, {"flag_valid": true})
	assert_eq(world_state.discovered_locations, {"location_valid": true})


func test_world_state_load_ignores_malformed_fields() -> void:
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.set_flag("old_flag", true)
	world_state.discover_location("old_location")

	world_state.load_save_data({"flags": "bad", "discovered_locations": 12})

	assert_eq(world_state.flags, {})
	assert_eq(world_state.discovered_locations, {})

	world_state.load_save_data(
		{
			"flags":
			{
				"flag_valid": false,
				"flag_string_true": "true",
				"flag_string_false": "false",
				"flag_number": 1
			},
			"discovered_locations": ["location_valid"]
		}
	)

	assert_eq(world_state.flags, {"flag_valid": false})
	assert_eq(world_state.discovered_locations, {"location_valid": true})


func test_world_state_has_flag_requires_true_boolean() -> void:
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)

	world_state.flags = {
		"flag_true": true, "flag_false": false, "flag_string": "true", "flag_number": 1
	}

	assert_true(world_state.has_flag("flag_true"))
	assert_false(world_state.has_flag("flag_false"))
	assert_false(world_state.has_flag("flag_string"))
	assert_false(world_state.has_flag("flag_number"))


func test_readable_load_ignores_blank_and_unknown_readables() -> void:
	var readables := ReadableManager.new()
	add_child_autofree(readables)
	readables.setup(null, ReadableContentStub.new(), Callable())

	readables.load_save_data(
		{
			"read": ["", "readable_missing", "readable_known"],
			"discovered": ["readable_known", "readable_missing"]
		}
	)

	assert_eq(readables.read, {"readable_known": true})
	assert_eq(readables.discovered, {"readable_known": true})


func test_readable_load_ignores_malformed_fields() -> void:
	var readables := ReadableManager.new()
	add_child_autofree(readables)
	readables.setup(null, ReadableContentStub.new(), Callable())
	readables.read_readable("readable_known")

	readables.load_save_data({"read": "bad", "discovered": 7})

	assert_eq(readables.read, {})
	assert_eq(readables.discovered, {})


func test_readable_effects_run_only_on_first_read() -> void:
	var readables := ReadableManager.new()
	add_child_autofree(readables)
	var applied_effects: Array[Dictionary] = []
	readables.setup(
		null,
		ReadableContentStub.new(),
		func(effect: Dictionary) -> void: applied_effects.append(effect)
	)

	assert_false(readables.has_read("readable_reward"))
	assert_eq(readables.read_readable("readable_reward").get("id", ""), "readable_reward")
	assert_eq(readables.read_readable("readable_reward").get("id", ""), "readable_reward")

	assert_true(readables.has_read("readable_reward"))
	assert_eq(applied_effects.size(), 1)
	assert_eq(applied_effects[0].get("item_id", ""), "item_gold_coin")


func test_chunk_entity_removed_persists() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	chunks.mark_entity_removed("entity_test", Vector2i(3, 4))
	chunks.mark_object_opened("container_test", Vector2i(3, 4))
	assert_true(chunks.is_entity_removed("entity_test", Vector2i(3, 4)))
	assert_true(chunks.is_object_opened("container_test", Vector2i(3, 4)))

	var loaded := ChunkManager.new()
	add_child_autofree(loaded)
	loaded.load_save_data(chunks.get_save_data())
	assert_true(loaded.is_entity_removed("entity_test", Vector2i(3, 4)))
	assert_true(loaded.is_object_opened("container_test", Vector2i(3, 4)))


func test_chunk_load_ignores_invalid_removed_entities() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)

	chunks.load_save_data(
		{
			"surface:0:0":
			{
				"removed_entities": ["", "entity_test", "entity_test"],
				"modified_objects":
				{
					"": {"opened": true},
					"closed": {"opened": false},
					"bad": "open",
					"container_test": {"opened": true}
				}
			},
			"surface:1:0": {"removed_entities": "bad"},
			"surface:2:0": {"removed_entities": []},
			"broken": "not a chunk"
		}
	)

	assert_eq(
		chunks.modified_chunks,
		{
			"surface:0:0":
			{
				"removed_entities": ["entity_test"],
				"modified_objects": {"container_test": {"opened": true}}
			}
		}
	)


func test_spawn_town_uses_authored_tiles_and_walkability() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	chunks.load_world_terrain(content.get_world_terrain())

	assert_eq(chunks.get_tile_kind(Vector2i.ZERO), "road")
	assert_true(chunks.is_walkable(Vector2i.ZERO))
	assert_eq(chunks.get_tile_kind(Vector2i(0, -2)), "grass")
	assert_true(chunks.is_walkable(Vector2i(0, -2)))
	assert_eq(chunks.get_tile_kind(Vector2i(-3, -4)), "water")
	assert_false(chunks.is_walkable(Vector2i(-3, -4)))
	assert_eq(chunks.get_tile_kind(Vector2i(-3, 0)), "bridge")
	assert_true(chunks.is_walkable(Vector2i(-3, 0)))
	assert_eq(chunks.get_tile_kind(Vector2i(-12, -10)), "stone_wall")
	assert_false(chunks.is_walkable(Vector2i(-12, -10)))
	assert_eq(chunks.get_tile_kind(Vector2i(-12, -1)), "road")
	assert_true(chunks.is_walkable(Vector2i(-12, -1)))
	assert_eq(chunks.get_tile_kind(Vector2i(-12, 0)), "road")
	assert_true(chunks.is_walkable(Vector2i(-12, 0)))
	assert_eq(chunks.get_tile_kind(Vector2i(-12, 2)), "road")
	assert_true(chunks.is_walkable(Vector2i(-12, 2)))
	assert_eq(chunks.get_tile_kind(Vector2i(8, -1)), "grass")
	assert_true(chunks.is_walkable(Vector2i(8, -1)))
	assert_eq(chunks.get_tile_kind(Vector2i(6, 1)), "road")
	assert_true(chunks.is_walkable(Vector2i(6, 1)))


func test_procedural_roads_continue_outside_authored_town() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)

	assert_eq(chunks.get_tile_kind(Vector2i(20, 0)), "road")
	assert_true(chunks.is_walkable(Vector2i(20, 0)))


func test_streaming_loads_enough_chunks_for_small_tile_scale() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	var streamer := WorldStreamingManager.new()
	add_child_autofree(streamer)
	streamer.setup(null, chunks)

	streamer.update_center(Vector2i.ZERO)

	assert_eq(streamer.get_loaded_chunk_keys().size(), 25)


func test_streaming_keys_include_world_layer() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	var streamer := WorldStreamingManager.new()
	add_child_autofree(streamer)
	streamer.setup(null, chunks)

	streamer.update_center(Vector2i.ZERO, "interior:test_house")

	assert_eq(streamer.get_loaded_chunk_keys().size(), 25)
	assert_true(streamer.get_loaded_chunk_keys().has("interior:test_house:0:0"))
