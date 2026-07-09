extends GutTest

const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")


class ContentStub:
	extends RefCounted

	func load_all() -> Array:
		return ["bad row"]

	func get_people(people_id: String) -> Dictionary:
		return {"display_name": "Name %s" % people_id}


func test_arg_helpers_read_strings_and_positive_ints_with_fallbacks() -> void:
	var args := PackedStringArray(["out", "42", "", "bad"])

	assert_eq(CaptureSheetHelper.string_arg(args, 0, "fallback"), "out")
	assert_eq(CaptureSheetHelper.string_arg(args, 2, "fallback"), "fallback")
	assert_eq(CaptureSheetHelper.string_arg(args, 9, "fallback"), "fallback")
	assert_eq(CaptureSheetHelper.positive_arg(args, 1, 7), 42)
	assert_eq(CaptureSheetHelper.positive_arg(args, 3, 7), 7)
	assert_eq(CaptureSheetHelper.positive_arg(PackedStringArray(["-4"]), 0, 7), 1)
	assert_eq(CaptureSheetHelper.positive_arg(args, 9, 7), 7)


func test_capture_config_reads_common_fields_and_named_filters() -> void:
	var args := PackedStringArray(["out", "42", "24", "people_human", "slash"])
	var config := CaptureSheetHelper.capture_config(
		args, "fallback", 10, 20, ["people_filter", "attack_filter"]
	)

	assert_eq(config["output_dir"], "out")
	assert_eq(config["width"], 42)
	assert_eq(config["height"], 24)
	assert_eq(config["people_filter"], "people_human")
	assert_eq(config["attack_filter"], "slash")
	assert_eq(CaptureSheetHelper.capture_config(PackedStringArray(), "fallback", 10, 20).size(), 3)


func test_image_capture_config_reads_size_output_and_named_fields() -> void:
	var args := PackedStringArray(["900", "500", "res://reports/custom.png", "trade"])
	var config := CaptureSheetHelper.image_capture_config(
		args, 1152, 648, "res://reports/default.png", ["tab_id"], {"tab_id": "inventory"}
	)

	assert_eq(config["width"], 900)
	assert_eq(config["height"], 500)
	assert_eq(config["output_path"], "res://reports/custom.png")
	assert_eq(config["tab_id"], "trade")

	var fallback := CaptureSheetHelper.image_capture_config(
		PackedStringArray(), 1152, 648, "res://reports/default.png", ["tab_id"], {"tab_id": "inventory"}
	)
	assert_eq(fallback["tab_id"], "inventory")


func test_filtered_people_supports_empty_exact_and_suffix_filters() -> void:
	assert_eq(CaptureSheetHelper.filtered_people("").size(), 6)
	assert_eq(CaptureSheetHelper.filtered_people("people_human"), ["people_human"])
	assert_eq(CaptureSheetHelper.filtered_people("human"), ["people_human"])
	assert_eq(CaptureSheetHelper.filtered_people("missing"), [])


func test_content_and_people_helpers_delegate_to_content_object() -> void:
	var content := ContentStub.new()

	assert_eq(CaptureSheetHelper.content_load_errors(content), ["bad row"])
	assert_eq(
		CaptureSheetHelper.people_display_name(content, "people_human"),
		"Name people_human"
	)


func test_page_and_header_helpers_create_background_and_labels() -> void:
	var page := CaptureSheetHelper.create_page(320, 180)
	add_child_autofree(page)
	CaptureSheetHelper.add_sheet_header(page, "Title", "Note", 320)

	assert_eq(page.size, Vector2(320, 180))
	assert_true(page.get_child(0) is ColorRect)
	assert_eq((page.get_child(1) as Label).text, "Title")
	assert_eq((page.get_child(2) as Label).text, "Note")


func test_add_grid_rule_label_and_direction_labels_create_expected_nodes() -> void:
	var page := Control.new()
	add_child_autofree(page)

	CaptureSheetHelper.add_grid(page, 10.0, 20.0, 30.0, 40.0, 2, 3)
	CaptureSheetHelper.add_label(page, "Title", Vector2(1, 2), Vector2(30, 12), 9, Color.WHITE)
	CaptureSheetHelper.add_direction_row_labels(page, 100.0, 20.0)

	assert_eq(page.get_child_count(), 1 + 4 + 3 + 1 + CaptureSheetHelper.DIRECTION_LABELS.size())
	var area := page.get_child(0) as ColorRect
	assert_eq(area.position, Vector2(10.0, 20.0))
	assert_eq(area.size, Vector2(60.0, 120.0))
	var title := page.get_child(8) as Label
	assert_eq(title.text, "Title")
	assert_eq(title.position, Vector2(1, 2))
	var first_direction := page.get_child(9) as Label
	assert_eq(first_direction.text, "00 E")


func test_save_png_image_writes_valid_image() -> void:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	var output_path := "user://capture_sheet_helper_test.png"

	assert_eq(CaptureSheetHelper.save_png_image(image, output_path), OK)
	assert_true(FileAccess.file_exists(output_path))
