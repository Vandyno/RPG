extends SceneTree

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")

const DEFAULT_OUTPUT_DIR := "res://reports/people_iterations_v7"
const DEFAULT_WIDTH := 1152
const DEFAULT_HEIGHT := 648
const PEOPLE_ORDER := [
	"people_human",
	"people_tanglekin",
	"people_tuskfolk",
	"people_mirefolk",
	"people_ravenfolk",
	"people_rootborn"
]
const ROUND_DEFS := [
	{
		"title": "Round 01 - Baseline Role Accents",
		"variant_index": 0,
		"direction": Vector2.DOWN,
		"note": "First reusable archetype for each people."
	},
	{
		"title": "Round 02 - Service Role Accents",
		"variant_index": 1,
		"direction": Vector2.DOWN,
		"note": "Second archetype: work, guard, or civic service read."
	},
	{
		"title": "Round 03 - Social Archetypes",
		"variant_index": 2,
		"direction": Vector2.DOWN,
		"note": "Third archetype: softer, trader, scout, or social role."
	},
	{
		"title": "Round 04 - Edge Archetypes",
		"variant_index": 3,
		"direction": Vector2.DOWN,
		"note": "Fourth archetype: strongest original shape spread."
	},
	{
		"title": "Round 05 - Breadth Archetypes",
		"variant_index": 4,
		"direction": Vector2.DOWN,
		"note": "Fifth archetype adds everyday role breadth."
	},
	{
		"title": "Round 06 - Civilian Archetypes",
		"variant_index": 5,
		"direction": Vector2.DOWN,
		"note": "Sixth archetype broadens non-combat civilian silhouettes."
	},
	{
		"title": "Round 07 - Candidate v7 Accents",
		"variant_index": 6,
		"direction": Vector2.DOWN,
		"note": "Seventh archetype proves the model set can scale past hero designs."
	},
	{
		"title": "Round 08 - Full Breadth Proof",
		"variant_index": 7,
		"direction": Vector2.DOWN,
		"note": "Eighth archetype completes the current reusable spread for each people."
	}
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var output_dir := String(config["output_dir"])
	var width := int(config["width"])
	var height := int(config["height"])
	root.size = Vector2i(width, height)

	var content := ContentDatabase.new()
	root.add_child(content)
	if not CaptureSheetHelper.ensure_content_loaded(self, content, "People visual model capture"):
		return

	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if make_error != OK:
		printerr("Could not create people visual output dir: %s" % error_string(make_error))
		quit(1)
		return

	for round_index in ROUND_DEFS.size():
		var page := _build_round(content, ROUND_DEFS[round_index], width, height)
		root.add_child(page)
		await process_frame
		await process_frame

		var image := root.get_texture().get_image()
		var output_path := round_output_path(output_dir, round_index)
		var error := image.save_png(output_path)
		root.remove_child(page)
		page.queue_free()
		await process_frame
		if error != OK:
			printerr("Could not save people visual capture: %s" % error_string(error))
			quit(1)
			return

	quit()


static func capture_config(args: Array) -> Dictionary:
	return {
		"output_dir": CaptureSheetHelper.string_arg(args, 0, DEFAULT_OUTPUT_DIR),
		"width": CaptureSheetHelper.positive_arg(args, 1, DEFAULT_WIDTH),
		"height": CaptureSheetHelper.positive_arg(args, 2, DEFAULT_HEIGHT)
	}


static func round_output_path(output_dir: String, round_index: int) -> String:
	return output_dir.path_join("round_%02d.png" % [round_index + 1])


func _build_round(content: ContentDatabase, round: Dictionary, width: int, height: int) -> Control:
	var page := Control.new()
	page.size = Vector2(width, height)

	var bg := ColorRect.new()
	bg.color = Color(0.92, 0.90, 0.86)
	bg.size = page.size
	page.add_child(bg)

	CaptureSheetHelper.add_label(
		page,
		String(round["title"]),
		Vector2(44, 28),
		Vector2(800, 36),
		24,
		Color(0.08, 0.07, 0.06)
	)
	CaptureSheetHelper.add_label(
		page,
		String(round["note"]),
		Vector2(48, 68),
		Vector2(1000, 24),
		12,
		Color(0.28, 0.25, 0.22)
	)
	CaptureSheetHelper.add_label(
		page,
		"Godot capture from live ContentDatabase + HumanoidAvatar2D with role accents.",
		Vector2(48, 94),
		Vector2(1000, 22),
		10,
		Color(0.35, 0.31, 0.28)
	)

	for index in PEOPLE_ORDER.size():
		var people_id := String(PEOPLE_ORDER[index])
		var card_position := Vector2(38 + (index % 3) * 368, 118 + int(index / 3) * 250)
		_add_card(
			page,
			content,
			people_id,
			int(round["variant_index"]),
			round["direction"],
			card_position
		)

	return page


func _add_card(
	page: Control,
	content: ContentDatabase,
	people_id: String,
	variant_index: int,
	direction: Vector2,
	position: Vector2
) -> void:
	var definition := content.get_people(people_id)
	var model := content.get_people_visual_model(people_id)
	var variants: Array = model.get("variants", [])
	var variant := chosen_variant(variants, variant_index)
	if variant.is_empty():
		return
	var profile := content.get_people_visual_variant_profile(
		people_id, String(variant.get("id", "")), "preview_%s" % people_id
	)
	var appearance: Dictionary = profile.get("appearance", {})
	var proportions: Dictionary = appearance.get("proportions", {})

	var card := ColorRect.new()
	card.position = position
	card.size = Vector2(336, 220)
	card.color = Color(0.99, 0.98, 0.94)
	page.add_child(card)

	CaptureSheetHelper.add_label(
		page,
		String(definition.get("display_name", people_id)),
		position + Vector2(16, 14),
		Vector2(300, 28),
		18,
		Color(0.08, 0.07, 0.06)
	)
	CaptureSheetHelper.add_label(
		page,
		"%s / %s" % [String(variant.get("id", "")), String(variant.get("palette_id", ""))],
		position + Vector2(16, 45),
		Vector2(305, 18),
		7,
		Color(0.28, 0.22, 0.18)
	)

	var avatar := HumanoidAvatar2D.new()
	avatar.position = position + Vector2(78, 160)
	avatar.scale = Vector2(3.05, 3.05)
	avatar.setup(profile)
	avatar.set_facing_direction(direction)
	page.add_child(avatar)

	var prop_text := "h %.2f sh %.2f tor %.2f waist %.2f head %.2f" % [
		float(proportions.get("body_height", 1.0)),
		float(proportions.get("shoulder_width", 1.0)),
		float(proportions.get("torso_width", 1.0)),
		float(proportions.get("waist_width", 1.0)),
		float(proportions.get("head_size", 1.0))
	]
	CaptureSheetHelper.add_label(
		page,
		prop_text,
		position + Vector2(142, 78),
		Vector2(178, 18),
		6,
		Color(0.08, 0.07, 0.06)
	)
	CaptureSheetHelper.add_label(
		page,
		"Variant: %s" % String(variant.get("display_name", "")),
		position + Vector2(142, 101),
		Vector2(178, 18),
		8,
		Color(0.10, 0.08, 0.06)
	)
	CaptureSheetHelper.add_label(
		page,
		"Features:",
		position + Vector2(142, 126),
		Vector2(178, 16),
		7,
		Color(0.30, 0.26, 0.22)
	)
	var features_label := feature_text(variant.get("feature_ids", []))
	CaptureSheetHelper.add_label(
		page,
		features_label,
		position + Vector2(142, 144),
		Vector2(178, 44),
		6,
		Color(0.08, 0.07, 0.06)
	)

	var notes: Array = definition.get("visual_notes", [])
	if not notes.is_empty():
		CaptureSheetHelper.add_label(
			page,
			String(notes[0]),
			position + Vector2(16, 194),
			Vector2(302, 18),
			6,
			Color(0.26, 0.23, 0.20)
		)


static func chosen_variant(variants: Array, variant_index: int) -> Dictionary:
	if variants.is_empty():
		return {}
	var value: Variant = variants[clampi(variant_index, 0, variants.size() - 1)]
	return value if value is Dictionary else {}


static func feature_text(value: Variant) -> String:
	if not value is Array or value.is_empty():
		return "none"
	var parts: Array[String] = []
	for entry in value:
		parts.append(str(entry))
	return ", ".join(parts)
