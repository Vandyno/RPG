extends GutTest

const CaptureAttackAnimationSheet = preload(
	"res://scripts/tools/capture/capture_attack_animation_sheet.gd"
)


func test_capture_config_uses_defaults_and_reads_args() -> void:
	assert_eq(
		CaptureAttackAnimationSheet.capture_config([]),
		{
			"output_dir": CaptureAttackAnimationSheet.DEFAULT_OUTPUT_DIR,
			"width": CaptureAttackAnimationSheet.DEFAULT_WIDTH,
			"height": CaptureAttackAnimationSheet.DEFAULT_HEIGHT,
			"people_filter": "",
			"attack_filter": ""
		}
	)
	assert_eq(
		CaptureAttackAnimationSheet.capture_config([
			"res://reports/attacks",
			"900",
			"700",
			"people_human",
			"bow"
		]),
		{
			"output_dir": "res://reports/attacks",
			"width": 900,
			"height": 700,
			"people_filter": "people_human",
			"attack_filter": "bow"
		}
	)


func test_filtered_attacks_returns_all_specific_or_empty_match() -> void:
	var all_attacks := CaptureAttackAnimationSheet._filtered_attacks("")
	var bow_attacks := CaptureAttackAnimationSheet._filtered_attacks("bow")
	var missing_attacks := CaptureAttackAnimationSheet._filtered_attacks("missing")

	assert_eq(all_attacks.size(), 6)
	assert_eq(all_attacks[0]["id"], "punch")
	assert_eq(all_attacks[1]["id"], "hatchet")
	assert_eq(all_attacks[3]["id"], "sword_buckler")
	assert_eq(all_attacks[-1]["id"], "bow")
	assert_eq(bow_attacks, [{"id": "bow", "title": "Hunting Bow", "item_id": "item_hunting_bow"}])
	assert_true(missing_attacks.is_empty())


func test_sheet_file_name_strips_people_prefix_and_uses_attack_id() -> void:
	assert_eq(
		CaptureAttackAnimationSheet.sheet_file_name(
			"people_tanglekin",
			{"id": "polearm"}
		),
		"tanglekin_polearm_16dir_animation.png"
	)


func test_equipment_for_attack_assigns_right_hand_only_when_item_exists() -> void:
	assert_eq(CaptureAttackAnimationSheet._equipment_for_attack({"item_id": ""}), {})
	assert_eq(
		CaptureAttackAnimationSheet._equipment_for_attack({"item_id": "item_training_sword"}),
		{"right_hand": "item_training_sword"}
	)
	assert_eq(
		CaptureAttackAnimationSheet._equipment_for_attack(
			{"item_id": "item_training_sword", "offhand_item_id": "item_traveler_buckler"}
		),
		{"left_hand": "item_traveler_buckler", "right_hand": "item_training_sword"}
	)


func test_add_column_labels_creates_progress_headers() -> void:
	var page := Control.new()
	add_child_autofree(page)

	CaptureAttackAnimationSheet._add_column_labels(page, 100.0, 50.0, 20.0)

	assert_eq(page.get_child_count(), CaptureAttackAnimationSheet.PROGRESS_STEPS.size())
	assert_eq((page.get_child(0) as Label).text, "0%")
	assert_eq((page.get_child(1) as Label).text, "13%")
	assert_eq((page.get_child(4) as Label).text, "50%")
	assert_eq((page.get_child(8) as Label).text, "100%")
	assert_eq((page.get_child(2) as Control).position, Vector2(140.0, 24.0))
	assert_eq((page.get_child(2) as Control).size.x, 20.0)
