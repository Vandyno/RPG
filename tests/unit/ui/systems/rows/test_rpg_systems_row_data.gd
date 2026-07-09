extends GutTest

const RpgSystemsRowData = preload("res://scripts/ui/systems/rows/rpg_systems_row_data.gd")


func test_category_filtered_rows_passthrough_filters_and_empty_row() -> void:
	var rows: Array[Dictionary] = [
		{"id": "journal_wait", "title": "Wait", "subtitle": "Pass time", "meta": "Time"},
		{"id": "journal_save", "title": "Save Game", "subtitle": "Write", "meta": "System"}
	]

	assert_eq(RpgSystemsRowData.category_filtered_rows(rows, ""), rows)
	assert_eq(RpgSystemsRowData.category_filtered_rows(rows, "overview"), rows)
	assert_eq(RpgSystemsRowData.category_filtered_rows(rows, "time")[0]["id"], "journal_wait")
	assert_eq(
		RpgSystemsRowData.category_filtered_rows(rows, "missing")[0],
		RpgSystemsRowData.empty_category_row("missing")
	)


func test_row_matches_category_covers_special_categories() -> void:
	assert_true(RpgSystemsRowData.row_matches_category("training progression", "training"))
	assert_true(RpgSystemsRowData.row_matches_category("gear equipment", "gear"))
	assert_true(RpgSystemsRowData.row_matches_category("status effect", "effects"))
	assert_true(RpgSystemsRowData.row_matches_category("faction reputation", "factions"))
	assert_true(RpgSystemsRowData.row_matches_category("wait day", "time"))
	assert_true(RpgSystemsRowData.row_matches_category("recent log", "recent"))
	assert_true(RpgSystemsRowData.row_matches_category("save game", "system"))
	assert_true(RpgSystemsRowData.row_matches_category("alchemy table", "alchemy"))
	assert_false(RpgSystemsRowData.row_matches_category("alchemy table", "combat"))


func test_text_helpers_parse_colons_lines_and_empty_values() -> void:
	assert_eq(RpgSystemsRowData.title_before_colon("Weapon: Sword"), "Weapon")
	assert_eq(RpgSystemsRowData.title_before_colon("No colon"), "No colon")
	assert_eq(RpgSystemsRowData.text_after_colon("Weapon: Sword", "Fallback"), "Sword")
	assert_eq(RpgSystemsRowData.text_after_colon("Weapon:", "Fallback"), "Fallback")
	assert_eq(RpgSystemsRowData.text_after_colon("No colon", "Fallback"), "Fallback")
	assert_eq(RpgSystemsRowData.first_line(" first \nsecond"), "first")
	assert_eq(RpgSystemsRowData.first_line(""), "")
	assert_eq(RpgSystemsRowData.first_non_empty(" value ", "Fallback"), "value")
	assert_eq(RpgSystemsRowData.first_non_empty("", "Fallback"), "Fallback")
	assert_eq(RpgSystemsRowData.first_non_empty("none", "Fallback"), "Fallback")


func test_number_formatters_drop_unneeded_decimals() -> void:
	assert_eq(RpgSystemsRowData.format_weight(2.0), "2")
	assert_eq(RpgSystemsRowData.format_weight(2.25), "2.3")
	assert_eq(RpgSystemsRowData.format_float(3.0), "3")
	assert_eq(RpgSystemsRowData.format_float(3.75), "3.8")


func test_inventory_category_classifies_item_shapes() -> void:
	assert_eq(RpgSystemsRowData.inventory_category({"type": "weapon"}), "weapons")
	assert_eq(RpgSystemsRowData.inventory_category({"equipment_slot": "right_hand"}), "weapons")
	assert_eq(RpgSystemsRowData.inventory_category({"tags": ["weapon"]}), "weapons")
	assert_eq(RpgSystemsRowData.inventory_category({"type": "shield"}), "armour")
	assert_eq(RpgSystemsRowData.inventory_category({"equipment_slot": "chest"}), "armour")
	assert_eq(RpgSystemsRowData.inventory_category({"tags": ["armour"]}), "armour")
	assert_eq(RpgSystemsRowData.inventory_category({"type": "ingredient"}), "ingredients")
	assert_eq(RpgSystemsRowData.inventory_category({"tags": ["ingredient"]}), "ingredients")
	assert_eq(RpgSystemsRowData.inventory_category({"type": "quest_item"}), "quest")
	assert_eq(RpgSystemsRowData.inventory_category({"tags": ["quest"]}), "quest")
	assert_eq(RpgSystemsRowData.inventory_category({}), "misc")


func test_inventory_category_label_and_array_helpers() -> void:
	assert_eq(RpgSystemsRowData.inventory_category_label("weapons"), "Weapons")
	assert_eq(RpgSystemsRowData.inventory_category_label("armour"), "Armour")
	assert_eq(RpgSystemsRowData.inventory_category_label("ingredients"), "Ingredients")
	assert_eq(RpgSystemsRowData.inventory_category_label("quest"), "Quest")
	assert_eq(RpgSystemsRowData.inventory_category_label("misc"), "Misc")
	assert_eq(RpgSystemsRowData.inventory_category_label("unknown"), "Inventory")
	assert_eq(RpgSystemsRowData.lower_array(["A", "b"]), ["a", "b"])
	assert_eq(RpgSystemsRowData.lower_array("bad"), [])
	assert_eq(RpgSystemsRowData.array_field([1, 2]), [1, 2])
	assert_eq(RpgSystemsRowData.array_field("bad"), [])
