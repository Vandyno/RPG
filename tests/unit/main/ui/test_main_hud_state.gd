extends GutTest

const MainHudState = preload("res://scripts/main/ui/main_hud_state.gd")


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


func test_context_uses_main_owned_primary_action_text() -> void:
	var ctx := MainHudState.context({"primary_action": "Trade"})

	assert_eq(ctx.primary_action, "Trade")


func test_system_tabs_preserve_transfer_character_and_journal_payloads() -> void:
	var tabs := MainHudState._system_tabs(
		MainHudState._inventory_tab(
			"2 items",
			[{"name": "Apple"}],
			"",
			[],
			true,
			{"name": "Cache"},
			[{"name": "Coin"}]
		),
		MainHudState._character_tab(
			"8/10",
			"3/5",
			"Level 1",
			"",
			"Weapon: Blade",
			"none",
			"",
			[]
		),
		MainHudState._trade_tab("No trader selected.", [], []),
		MainHudState._quests_tab([{"title": "Missing Tools"}], "none", []),
		MainHudState._journal_tab("Day 2, 09:00", [], "", "Town", ""),
		MainHudState._spells_tab([{"name": "Fire Blast"}], {"ability_1": {"name": "Fire Blast"}})
	)

	assert_true(tabs["inventory"]["transfer"]["open"])
	assert_eq(tabs["inventory"]["transfer"]["target"]["name"], "Cache")
	assert_eq(tabs["character"]["health"], "8/10")
	assert_eq(tabs["character"]["mana"], "3/5")
	assert_eq(tabs["character"]["equipment"], "Weapon: Blade")
	assert_eq(tabs["journal"]["time"], "Day 2, 09:00")
	assert_eq(tabs["journal"]["locations"], "Town")
	assert_eq(tabs["quests"]["quests"], [{"title": "Missing Tools"}])
	assert_eq(tabs["spells"]["spells"], [{"name": "Fire Blast"}])
	assert_eq(tabs["spells"]["spell_slots"]["ability_1"]["name"], "Fire Blast")


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
