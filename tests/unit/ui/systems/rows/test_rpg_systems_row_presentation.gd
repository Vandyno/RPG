extends GutTest

const RpgSystemsRowPresentation = preload(
	"res://scripts/ui/systems/rows/rpg_systems_row_presentation.gd"
)


func test_clear_non_button_children_keeps_buttons_and_frees_other_nodes() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)
	var label := Label.new()
	var button := Button.new()
	var panel := PanelContainer.new()
	container.add_child(label)
	container.add_child(button)
	container.add_child(panel)

	RpgSystemsRowPresentation.clear_non_button_children(container)

	assert_eq(container.get_child_count(), 1)
	assert_same(container.get_child(0), button)


func test_tab_label_width_uses_compact_fallback_or_known_widths() -> void:
	assert_eq(RpgSystemsRowPresentation.tab_label_width("Weapons", 44.0, true), 44.0)
	assert_eq(RpgSystemsRowPresentation.tab_label_width("Weapons", 44.0, false), 72.0)
	assert_eq(RpgSystemsRowPresentation.tab_label_width("Ingredients", 44.0, false), 88.0)
	assert_eq(RpgSystemsRowPresentation.tab_label_width("Unknown", 44.0, false), 44.0)


func test_button_text_combines_title_subtitle_and_meta() -> void:
	assert_eq(RpgSystemsRowPresentation.button_text({}), "Entry")
	assert_eq(RpgSystemsRowPresentation.button_text({"title": "Coin"}), "Coin")
	assert_eq(
		RpgSystemsRowPresentation.button_text({"title": "Coin", "meta": "Inventory"}),
		"Coin\nInventory"
	)
	assert_eq(
		RpgSystemsRowPresentation.button_text({"title": "Coin", "subtitle": "Count 2"}),
		"Coin\nCount 2"
	)
	assert_eq(
		RpgSystemsRowPresentation.button_text({
			"title": "Coin",
			"subtitle": "Count 2",
			"meta": "Inventory"
		}),
		"Coin\nInventory - Count 2"
	)


func test_selected_row_and_has_id_use_row_ids_with_safe_defaults() -> void:
	var rows: Array[Dictionary] = [
		{"id": "first", "title": "First"},
		{"id": "second", "title": "Second"}
	]

	assert_eq(RpgSystemsRowPresentation.selected_row(rows, "second")["title"], "Second")
	assert_eq(RpgSystemsRowPresentation.selected_row(rows, "missing")["title"], "First")
	assert_eq(RpgSystemsRowPresentation.selected_row([], "missing"), {})
	assert_true(RpgSystemsRowPresentation.has_id(rows, "first"))
	assert_false(RpgSystemsRowPresentation.has_id(rows, ""))
	assert_false(RpgSystemsRowPresentation.has_id(rows, "missing"))


func test_hidden_text_joins_titles_and_non_empty_subtitles() -> void:
	assert_eq(
		RpgSystemsRowPresentation.hidden_text([
			{"title": "Vitals", "subtitle": "Health 10"},
			{"title": "Equipment", "subtitle": ""}
		]),
		"Vitals\nHealth 10\nEquipment"
	)
