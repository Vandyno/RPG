extends GutTest

const RpgSystemsRowBuilder = preload(
	"res://scripts/ui/systems/rows/rpg_systems_row_builder.gd"
)


func test_rows_dispatch_to_each_system_tab_builder() -> void:
	var log: Array[String] = ["Opened journal"]

	assert_eq(
		RpgSystemsRowBuilder.rows({"inventory": "Coin"}, "inventory", log, "all")[0]["id"],
		"inventory_0"
	)
	assert_eq(
		RpgSystemsRowBuilder.rows({"spells": [{}]}, "spells", log, "all")[0]["id"],
		"spell_"
	)
	assert_eq(
		RpgSystemsRowBuilder.rows({}, "character", log, "overview")[0]["id"],
		"character_health"
	)
	assert_eq(
		RpgSystemsRowBuilder.rows({"quests": ["Find Mara"]}, "quests", log, "active")[0]["id"],
		"quest_0"
	)
	assert_eq(RpgSystemsRowBuilder.rows({}, "journal", log, "")[0]["id"], "journal_events")
	assert_eq(
		RpgSystemsRowBuilder.rows({"trade": "Peddler: open"}, "trade", log, "all")[0]["id"],
		"trade_0"
	)


func test_rows_default_unknown_tab_to_inventory_rows() -> void:
	var log: Array[String] = []
	var rows := RpgSystemsRowBuilder.rows({"inventory": "Apple x2"}, "unknown", log, "all")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "inventory_0")
	assert_eq(rows[0]["title"], "Apple")


func test_category_labels_dispatch_to_each_tab_and_unknown_default() -> void:
	assert_eq(
		RpgSystemsRowBuilder.category_labels("inventory"),
		["All", "Weapons", "Armour", "Ingredients", "Misc", "Quest"]
	)
	assert_eq(
		RpgSystemsRowBuilder.category_labels("spells"),
		["All", "Fire", "Frost", "Storm", "Restore", "Necromancy", "Utility"]
	)
	assert_eq(
		RpgSystemsRowBuilder.category_labels("character"),
		["Overview", "Training", "Gear", "Effects"]
	)
	assert_eq(RpgSystemsRowBuilder.category_labels("quests"), ["Active", "Routes", "Rewards"])
	assert_eq(
		RpgSystemsRowBuilder.category_labels("journal"),
		["Recent", "Factions", "Time", "System"]
	)
	assert_eq(RpgSystemsRowBuilder.category_labels("trade"), ["Stock", "Buy", "Sell"])
	assert_eq(RpgSystemsRowBuilder.category_labels("unknown"), ["Overview"])
