extends GutTest

const MainHudState = preload("res://scripts/main/ui/main_hud_state.gd")
const MainContextActions = preload("res://scripts/main/actions/main_context_actions.gd")


class EntityStub:
	var data := {}
	var kind := "readable"
	var id := "entity"
	var display_name := "Entity"
	var global_tile := Vector2i.ZERO

	func _init(p_kind: String, p_data: Dictionary = {}) -> void:
		kind = p_kind
		data = p_data

	func get_kind() -> String:
		return kind

	func get_entity_id() -> String:
		return id

	func get_display_name() -> String:
		return display_name


class ChunkStub:
	var opened := false

	func is_object_opened(_entity_id: String, _global_tile: Vector2i) -> bool:
		return opened


class ConditionEvaluatorStub:
	var allowed := false

	func evaluate_all(_conditions: Array) -> bool:
		return allowed


class PlayerStub:
	var is_sneaking := false


class InventoryStub:
	var owner_items := {"char_player": {"item_b": 1, "item_a": 2}}

	func get_items_for_owner(owner_id: String) -> Dictionary:
		return owner_items.get(owner_id, {})

	func get_count_for_owner(owner_id: String, item_id: String) -> int:
		return int(owner_items.get(owner_id, {}).get(item_id, 0))


class ContentStub:
	func get_item(item_id: String) -> Dictionary:
		match item_id:
			"item_a":
				return {
					"name": "Apple",
					"type": "food",
					"tags": ["fresh"],
					"value": 2,
					"weight": 0.1,
					"description": "Crisp."
				}
			"item_b":
				return {
					"name": "Blade",
					"type": "weapon",
					"equipment_slot": "right_hand",
					"value": 5
				}
		return {}


func test_context_filters_nearby_target_entries_to_dictionaries() -> void:
	var ctx := MainHudState.context(
		{"nearby_targets": [{"id": "a"}, "bad", {"id": "b"}, 12]}
	)

	assert_eq(ctx.nearby_targets, [{"id": "a"}, {"id": "b"}])


func test_primary_action_handles_stop_locked_container_and_fallbacks() -> void:
	var action_context := MainContextActions.ActionListContext.new(
		{
			"condition_evaluator": ConditionEvaluatorStub.new(),
			"content": null,
			"dialogues": null,
			"player": PlayerStub.new(),
			"world_state": null
		}
	)
	var ctx := MainHudState.context(
		{
			"auto_move_active": true,
			"chunks": ChunkStub.new(),
			"condition_evaluator": ConditionEvaluatorStub.new(),
			"context_actions_context": action_context
		}
	)

	assert_eq(MainHudState._primary_action(ctx, null, null), "Stop")

	ctx.auto_move_active = false
	var container := EntityStub.new("container", {"open_conditions": [{"flag": "key"}]})
	assert_eq(MainHudState._primary_action(ctx, container, null), "Locked")

	assert_eq(MainHudState._primary_action(ctx, EntityStub.new("readable"), null), "Read")
	assert_eq(MainHudState._primary_action(ctx, null, null), "Explore")
	assert_eq(MainHudState._primary_action(ctx, null, EntityStub.new("npc")), "Stop")


func test_system_tabs_preserve_transfer_character_and_journal_payloads() -> void:
	var tabs := MainHudState._system_tabs(
		{
			"inventory_summary": "2 items",
			"inventory_items": [{"name": "Apple"}],
			"transfer_open": true,
			"transfer_target": {"name": "Cache"},
			"transfer_target_items": [{"name": "Coin"}],
			"player_health": "8/10",
			"player_mana": "3/5",
			"equipment": "Weapon: Blade",
			"time": "Day 2, 09:00",
			"locations": "Town",
			"quests": [{"title": "Missing Tools"}]
		}
	)

	assert_true(tabs["inventory"]["transfer"]["open"])
	assert_eq(tabs["inventory"]["transfer"]["target"]["name"], "Cache")
	assert_eq(tabs["character"]["health"], "8/10")
	assert_eq(tabs["character"]["mana"], "3/5")
	assert_eq(tabs["character"]["equipment"], "Weapon: Blade")
	assert_eq(tabs["journal"]["time"], "Day 2, 09:00")
	assert_eq(tabs["journal"]["locations"], "Town")
	assert_eq(tabs["quests"]["quests"], [{"title": "Missing Tools"}])


func test_inventory_items_are_sorted_and_shaped_for_ui() -> void:
	var ctx := MainHudState.context(
		{"content": ContentStub.new(), "inventory": InventoryStub.new()}
	)

	var items := MainHudState._inventory_items_for_owner(ctx, "char_player")

	assert_eq(items.size(), 2)
	assert_eq(items[0]["item_id"], "item_a")
	assert_eq(items[0]["name"], "Apple")
	assert_eq(items[0]["count"], 2)
	assert_eq(items[0]["tags"], ["fresh"])
	assert_eq(items[1]["item_id"], "item_b")
	assert_eq(items[1]["equipment_slot"], "right_hand")
	assert_eq(MainHudState._inventory_items_for_owner(ctx, ""), [])
