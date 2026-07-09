extends GutTest

const CaptureIdleDirectionSheet = preload(
	"res://scripts/tools/capture/capture_idle_direction_sheet.gd"
)


func test_capture_config_uses_defaults_and_reads_args() -> void:
	assert_eq(
		CaptureIdleDirectionSheet.capture_config([]),
		{
			"output_dir": CaptureIdleDirectionSheet.DEFAULT_OUTPUT_DIR,
			"width": CaptureIdleDirectionSheet.DEFAULT_WIDTH,
			"height": CaptureIdleDirectionSheet.DEFAULT_HEIGHT,
			"people_filter": ""
		}
	)
	assert_eq(
		CaptureIdleDirectionSheet.capture_config([
			"res://reports/idle",
			"880",
			"640",
			"people_tuskfolk"
		]),
		{
			"output_dir": "res://reports/idle",
			"width": 880,
			"height": 640,
			"people_filter": "people_tuskfolk"
		}
	)


func test_idle_loadout_contract_covers_resting_weapon_columns() -> void:
	assert_eq(CaptureIdleDirectionSheet.IDLE_LOADOUTS.size(), 4)
	assert_eq(CaptureIdleDirectionSheet.IDLE_LOADOUTS[0]["id"], "unarmed")
	assert_eq(CaptureIdleDirectionSheet.IDLE_LOADOUTS[0]["equipment"], {})
	assert_eq(CaptureIdleDirectionSheet.IDLE_LOADOUTS[1]["title"], "Sword")
	assert_eq(
		CaptureIdleDirectionSheet.IDLE_LOADOUTS[1]["equipment"],
		{"right_hand": "item_training_sword"}
	)
	assert_eq(
		CaptureIdleDirectionSheet.IDLE_LOADOUTS[-1]["equipment"],
		{"right_hand": "item_hunting_bow"}
	)


func test_sheet_file_name_strips_people_prefix() -> void:
	assert_eq(
		CaptureIdleDirectionSheet.sheet_file_name("people_ravenfolk"),
		"ravenfolk_idle_16dir.png"
	)


func test_add_column_labels_creates_loadout_headers() -> void:
	var page := Control.new()
	add_child_autofree(page)

	CaptureIdleDirectionSheet._add_column_labels(page, 80.0, 40.0, 64.0)

	assert_eq(page.get_child_count(), CaptureIdleDirectionSheet.IDLE_LOADOUTS.size())
	assert_eq((page.get_child(0) as Label).text, "Unarmed")
	assert_eq((page.get_child(1) as Label).text, "Sword")
	assert_eq((page.get_child(2) as Label).text, "Polearm")
	assert_eq((page.get_child(3) as Label).text, "Bow")
	assert_eq((page.get_child(2) as Control).position, Vector2(208.0, 14.0))
	assert_eq((page.get_child(2) as Control).size.x, 64.0)
