extends GutTest


func test_open_seeds_loot_sets_transfer_and_updates_ui() -> void:
	var entity := FakeEntity.new(
		"object_locked_chest",
		"Locked Chest",
		"object",
		{"effects_on_open": [{"type": "add_item", "item_id": "item_gold_coin", "count": 2}]}
	)
	var main := FakeMain.new(entity)
	add_child_autofree(main)

	MainInventoryTransfer.open(MainInventoryTransfer.context(main), entity)

	assert_true(main.chunks.is_object_opened("object_locked_chest", Vector2i(1, 1)))
	assert_eq(main.active_transfer_owner_id, "loot:object_locked_chest")
	assert_eq(main.active_transfer_name, "Locked Chest")
	assert_eq(main.active_transfer_source_id, "object_locked_chest")
	assert_eq(main.active_transfer_source_kind, "object")
	assert_eq(main.active_transfer_access_mode, "object")
	assert_eq(main.inventory.count_for_owner("loot:object_locked_chest", "item_gold_coin"), 2)
	assert_eq(main.event_bus.messages, ["Opened Locked Chest."])
	assert_eq(main.hud.systems_panels, ["inventory"])
	assert_eq(main.update_nearby_calls, 1)


func test_take_item_moves_one_item_to_player_and_refreshes_owner_equipment() -> void:
	var entity := FakeEntity.new("object_chest", "Chest", "object")
	var main := FakeMain.new(entity)
	add_child_autofree(main)
	main.content.items = {"item_gold_coin": {"name": "Gold Coin"}}
	main.inventory.add_item_to_owner("loot:object_chest", "item_gold_coin", 2)
	main.active_transfer_owner_id = "loot:object_chest"
	main.active_transfer_source_id = "object_chest"
	main.active_transfer_source_kind = "object"
	main.active_transfer_source_tile = entity.global_tile
	main.active_transfer_access_mode = "object"

	MainInventoryTransfer.take_item(MainInventoryTransfer.context(main), "item_gold_coin")

	assert_eq(main.inventory.count_for_owner("loot:object_chest", "item_gold_coin"), 1)
	assert_eq(main.inventory.count_for_owner("char_player", "item_gold_coin"), 1)
	assert_eq(main.event_bus.messages, ["Took Gold Coin."])
	assert_eq(main.entities.refreshed_owner_ids, ["loot:object_chest"])
	assert_eq(main.refresh_hud_calls, 1)


func test_take_item_clears_transfer_when_source_disappears() -> void:
	var entity := FakeEntity.new("object_chest", "Chest", "object")
	var main := FakeMain.new(entity)
	add_child_autofree(main)
	main.entities.entity = null
	main.content.items = {"item_gold_coin": {"name": "Gold Coin"}}
	main.inventory.add_item_to_owner("loot:object_chest", "item_gold_coin", 1)
	main.active_transfer_owner_id = "loot:object_chest"
	main.active_transfer_source_id = "object_chest"
	main.active_transfer_source_kind = "object"
	main.active_transfer_source_tile = entity.global_tile
	main.active_transfer_access_mode = "object"

	MainInventoryTransfer.take_item(MainInventoryTransfer.context(main), "item_gold_coin")

	assert_eq(main.active_transfer_owner_id, "")
	assert_eq(main.active_transfer_source_id, "")
	assert_eq(main.inventory.count_for_owner("loot:object_chest", "item_gold_coin"), 1)
	assert_eq(main.event_bus.messages, ["Transfer source is gone."])
	assert_eq(main.refresh_hud_calls, 1)


class FakeMain:
	extends Node

	var chunks: FakeChunks
	var condition_evaluator
	var content := FakeContent.new()
	var entities: FakeEntities
	var event_bus := FakeEventBus.new()
	var hud := FakeHud.new()
	var inventory := FakeInventory.new()
	var player := Node2D.new()
	var active_content_choices := {"choice": true}
	var seeded_inventory_owner_ids := {}
	var active_transfer_owner_id := ""
	var active_transfer_name := ""
	var active_transfer_source_id := ""
	var active_transfer_source_kind := ""
	var active_transfer_source_tile := Vector2i.ZERO
	var active_transfer_access_mode := ""
	var refresh_hud_calls := 0
	var update_nearby_calls := 0
	var effect_result := false

	func _init(entity: FakeEntity) -> void:
		chunks = FakeChunks.new()
		entities = FakeEntities.new(entity)
		add_child(player)
		player.global_position = Vector2.ZERO

	func _clear_active_transfer(_refresh_hud: bool = true) -> void:
		active_transfer_owner_id = ""
		active_transfer_name = ""
		active_transfer_source_id = ""
		active_transfer_source_kind = ""
		active_transfer_source_tile = Vector2i.ZERO
		active_transfer_access_mode = ""

	func apply_effect(_effect: Dictionary) -> bool:
		return effect_result

	func _refresh_hud() -> void:
		refresh_hud_calls += 1

	func _update_nearby() -> void:
		update_nearby_calls += 1


class FakeEntity:
	extends RefCounted

	var id: String
	var display_name: String
	var kind: String
	var data: Dictionary
	var global_tile := Vector2i(1, 1)

	func _init(
		entity_id: String, entity_name: String, entity_kind: String, extra_data: Dictionary = {}
	) -> void:
		id = entity_id
		display_name = entity_name
		kind = entity_kind
		data = extra_data.duplicate(true)
		data["id"] = entity_id
		data["kind"] = entity_kind

	func get_entity_id() -> String:
		return id

	func get_display_name() -> String:
		return display_name

	func get_kind() -> String:
		return kind


class FakeChunks:
	extends RefCounted

	var opened := {}

	func is_object_opened(entity_id: String, tile: Vector2i) -> bool:
		return opened.has(_key(entity_id, tile))

	func mark_object_opened(entity_id: String, tile: Vector2i) -> void:
		opened[_key(entity_id, tile)] = true

	func _key(entity_id: String, tile: Vector2i) -> String:
		return "%s:%s,%s" % [entity_id, tile.x, tile.y]


class FakeContent:
	extends RefCounted

	var items := {}

	func get_item(item_id: String) -> Dictionary:
		return items.get(item_id, {}).duplicate(true)


class FakeEntities:
	extends RefCounted

	var entity: FakeEntity
	var refreshed_owner_ids: Array[String] = []

	func _init(source_entity: FakeEntity) -> void:
		entity = source_entity

	func get_entity(entity_id: String):
		if entity and entity.get_entity_id() == entity_id:
			return entity
		return null

	func get_interactables_world(_player_position: Vector2) -> Array:
		return [entity] if entity else []

	func refresh_equipment_for_owner(owner_id: String) -> void:
		refreshed_owner_ids.append(owner_id)


class FakeEventBus:
	extends RefCounted

	var messages: Array[String] = []

	func post_message(message: String) -> void:
		messages.append(message)


class FakeHud:
	extends RefCounted

	var systems_panels: Array[String] = []
	var content_hidden := false

	func show_systems_panel(panel_id: String) -> void:
		systems_panels.append(panel_id)

	func hide_content_card() -> void:
		content_hidden = true


class FakeInventory:
	extends RefCounted

	var owners := {}

	func add_item_to_owner(owner_id: String, item_id: String, count: int) -> bool:
		if not owners.has(owner_id):
			owners[owner_id] = {}
		owners[owner_id][item_id] = count_for_owner(owner_id, item_id) + count
		return true

	func get_items_for_owner(owner_id: String) -> Array[Dictionary]:
		var result: Array[Dictionary] = []
		for item_id in owners.get(owner_id, {}):
			result.append({"item_id": item_id, "count": owners[owner_id][item_id]})
		return result

	func has_item_for_owner(owner_id: String, item_id: String, count: int) -> bool:
		return count_for_owner(owner_id, item_id) >= count

	func can_add_item_to_owner(_owner_id: String, _item_id: String, _count: int) -> bool:
		return true

	func transfer_item(from_owner: String, to_owner: String, item_id: String, count: int) -> bool:
		if not has_item_for_owner(from_owner, item_id, count):
			return false
		owners[from_owner][item_id] -= count
		add_item_to_owner(to_owner, item_id, count)
		return true

	func count_for_owner(owner_id: String, item_id: String) -> int:
		return int(owners.get(owner_id, {}).get(item_id, 0))
