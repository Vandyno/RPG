extends GutTest

const PoiGenerator = preload("res://scripts/generation/world_poi_generator.gd")
const PoiValidator = preload("res://scripts/data/world_poi_proposal_validator.gd")

const REQUIRED_TEMPLATES := [
	"road_camp", "shrine", "bridge", "farm", "cave", "ruin", "tower",
	"smuggler_cove", "ferry_landing"
]


func test_catalog_covers_required_poi_templates() -> void:
	var catalog: Dictionary = PoiGenerator.load_catalog()

	for template_id in REQUIRED_TEMPLATES:
		assert_true(catalog["templates"].has(template_id), template_id)


func test_every_poi_template_generates_editable_valid_proposal_contract() -> void:
	for index in REQUIRED_TEMPLATES.size():
		var proposal: Dictionary = PoiGenerator.generate(
			"region_marches_velcor", REQUIRED_TEMPLATES[index], 3100 + index,
			Vector2i(index * 100, 0)
		)

		assert_eq(PoiValidator.validate(proposal), PackedStringArray(), REQUIRED_TEMPLATES[index])
		assert_eq(proposal["proposal_status"], "proposal")
		assert_eq(proposal["activation_status"], "review_required")
		assert_false(String(proposal["visual_style"]).is_empty())
		assert_true(proposal["walkability"]["required"])
		assert_true(proposal["encounter_rules"]["allowed"])
		assert_gt(proposal["slots"].size(), 0)
		assert_gt(proposal["quest_hooks"].size(), 0)


func test_poi_generation_is_reproducible_and_seed_changes_slot_placement() -> void:
	var first: Dictionary = PoiGenerator.generate("region_marches_velcor", "farm", 8, Vector2i(10, 20))
	var repeat: Dictionary = PoiGenerator.generate("region_marches_velcor", "farm", 8, Vector2i(10, 20))
	var changed: Dictionary = PoiGenerator.generate("region_marches_velcor", "farm", 9, Vector2i(10, 20))

	assert_eq(JSON.stringify(first), JSON.stringify(repeat))
	assert_ne(JSON.stringify(first["slots"]), JSON.stringify(changed["slots"]))


func test_validator_rejects_blocked_slot_and_missing_provenance() -> void:
	var proposal: Dictionary = PoiGenerator.generate(
		"region_marches_velcor", "bridge", 4, Vector2i.ZERO
	).duplicate(true)
	proposal["slots"][0]["global_tile"] = [99, 99]
	proposal["quest_hooks"][0].erase("generator_version")
	var joined := "\n".join(PoiValidator.validate(proposal))

	assert_true(joined.contains("outside walkable layout"))
	assert_true(joined.contains("missing generator_version"))
