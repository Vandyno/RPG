extends GutTest

const RpgSystemsTextBuilder = preload(
	"res://scripts/ui/systems/text/rpg_systems_text_builder.gd"
)


func test_title_and_subtitle_cover_known_tabs_and_unknown_default() -> void:
	assert_eq(RpgSystemsTextBuilder.title("inventory"), "Inventory")
	assert_eq(RpgSystemsTextBuilder.title("spells"), "Spells")
	assert_eq(RpgSystemsTextBuilder.title("character"), "Character")
	assert_eq(RpgSystemsTextBuilder.title("quests"), "Quests")
	assert_eq(RpgSystemsTextBuilder.title("journal"), "Journal")
	assert_eq(RpgSystemsTextBuilder.title("trade"), "Trade")
	assert_eq(RpgSystemsTextBuilder.title("unknown"), "Menu")
	assert_eq(RpgSystemsTextBuilder.subtitle("inventory"), "Gear, supplies, and valuables.")
	assert_eq(RpgSystemsTextBuilder.subtitle("unknown"), "Briarwatch")


func test_resource_text_summarizes_gold_mana_carry_and_time() -> void:
	assert_eq(
		RpgSystemsTextBuilder.resource_text({
			"system_tabs": {
				"inventory": {
					"summary": "Apple x2, Gold Coin x12",
					"items": [
						{"weight": 1.25, "count": 2},
						{"weight": -1.0, "count": 5},
						"bad"
					]
				},
				"journal": {"time": "Day 2, 10:00 (Morning)"}
			},
			"carry_capacity": 90.5,
			"player_mana": "8/12"
		}),
		"Gold 12     MP 8/12     Carry 2.5/90.5     D2, 10:00"
	)


func test_detail_text_covers_each_tab_and_fallbacks() -> void:
	var state := {
		"inventory_details": "Coin: old silver",
		"progression": "Level 3",
		"quest_directions": "Cache: E 2t road",
		"quests": ["Find Cache"],
		"factions": "Wardens: friendly",
		"trade": "Mara: open"
	}

	assert_eq(RpgSystemsTextBuilder.detail_text(state, "inventory"), "Coin: old silver")
	assert_eq(
		RpgSystemsTextBuilder.detail_text({}, "inventory"),
		"Select an item to see details."
	)
	assert_eq(
		RpgSystemsTextBuilder.detail_text(state, "spells"),
		"Drag known spells into Ability I, II, or III."
	)
	assert_eq(RpgSystemsTextBuilder.detail_text(state, "character"), "Level 3")
	assert_eq(
		RpgSystemsTextBuilder.detail_text(state, "quests"),
		"Find Cache\n\nCache: 2 tiles east to road"
	)
	assert_eq(RpgSystemsTextBuilder.detail_text(state, "journal"), "Wardens: friendly")
	assert_eq(RpgSystemsTextBuilder.detail_text(state, "trade"), "Mara: open")
	assert_eq(RpgSystemsTextBuilder.detail_text({}, "unknown"), "")


func test_character_text_and_rows_include_effects_when_present() -> void:
	var state := {
		"player_health": "76/100",
		"player_mana": "8/12",
		"progression": "Level 4",
		"equipment": "Weapon: Sword",
		"statuses": "Blessed"
	}

	assert_eq(
		RpgSystemsTextBuilder.character_text(state),
		"Health 76/100\nMana 8/12\nLevel 4\n\nWeapon: Sword\n\nEffects: Blessed"
	)
	var rows := RpgSystemsTextBuilder.character_rows(state)
	assert_eq(rows[0], {"title": "Vitals", "value": "Health 76/100\nMana 8/12"})
	assert_eq(rows[1], {"title": "Training", "value": "Level 4"})
	assert_eq(rows[2], {"title": "Equipment", "value": "Weapon: Sword"})
	assert_eq(rows[3], {"title": "Effects", "value": "Blessed"})


func test_character_text_and_rows_use_defaults_without_effects() -> void:
	assert_eq(
		RpgSystemsTextBuilder.character_text({}),
		(
			"Health Health unknown\nMana Mana unknown\nLevel 1\n\n"
			+ "Weapon: empty\nOffhand: empty\nBody: empty"
		)
	)
	assert_eq(RpgSystemsTextBuilder.character_rows({})[3]["value"], "None")


func test_level_and_private_helpers_cover_bad_values() -> void:
	assert_eq(RpgSystemsTextBuilder.level_from_progression("Level 12"), 12)
	assert_eq(RpgSystemsTextBuilder.level_from_progression("Level 0"), 1)
	assert_eq(RpgSystemsTextBuilder.level_from_progression("bad"), 1)
	assert_eq(RpgSystemsTextBuilder._first_non_empty(" value ", "fallback"), "value")
	assert_eq(RpgSystemsTextBuilder._first_non_empty("none", "fallback"), "fallback")
	assert_eq(RpgSystemsTextBuilder._short_time("Day 4, 08:00 (Dawn)"), "D4, 08:00")
	assert_eq(RpgSystemsTextBuilder._count_named_entry("Gold Coin x7, Apple x2", "Gold Coin"), 7)
	assert_eq(RpgSystemsTextBuilder._count_named_entry("Gold Coin xbad", "Gold Coin"), 0)
	assert_eq(RpgSystemsTextBuilder._carry_weight([{"weight": 2.0, "count": 3}]), 6.0)
	assert_eq(RpgSystemsTextBuilder._format_weight(4.0), "4")
	assert_eq(RpgSystemsTextBuilder._format_weight(4.25), "4.3")
	assert_eq(RpgSystemsTextBuilder._array_field("bad"), [])
