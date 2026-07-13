extends GutTest

const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const ATLAS_PATH := "res://data/world_atlas_proposal.json"


func test_proposal_atlas_loads_and_validates() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var errors := WorldAtlasValidator.validate(atlas)

	assert_false(atlas.is_empty())
	assert_eq(errors, PackedStringArray())


func test_atlas_scale_produces_roughly_half_hour_world() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var west := WorldAtlasValidator.atlas_to_global_tile(atlas, Vector2(245, 500))
	var east := WorldAtlasValidator.atlas_to_global_tile(atlas, Vector2(1510, 500))

	assert_eq(east.x - west.x, 25300)
	assert_true(float(east.x - west.x) / 13.75 / 60.0 >= 30.0)


func test_report_separates_validation_from_pending_canon_review() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var report := WorldAtlasValidator.build_report(atlas)

	assert_eq(report["validation_status"], "pass")
	assert_eq(report["approval_status"], "pending_review")
	assert_almost_eq(float(report["world_scale"]["baseline_crossing_minutes"]), 30.7, 0.01)
	assert_eq(report["counts"]["regions"], 11)
	assert_true(report["review_items"].any(func(item): return item["id"] == "last_perch"))
	assert_true(report["review_items"].any(func(item): return item["id"] == "saltspring"))
	assert_true(atlas["authoring_policy"]["may_add_tile_kinds"])
	assert_eq(atlas["authoring_policy"]["terrain_palette"], "extensible")


func test_validator_reports_duplicate_invalid_geometry_and_missing_required_place() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH).duplicate(true)
	atlas["regions"].append(atlas["regions"][0].duplicate(true))
	atlas["regions"][0]["polygon"] = [[0, 0], [2, 2], [0, 2], [2, 0]]
	atlas["required_named_location_ids"].append("missing_place")
	var joined := "\n".join(WorldAtlasValidator.validate(atlas))

	assert_true(joined.contains("Duplicate atlas id region_elderweald"))
	assert_true(joined.contains("region region_elderweald has zero area"))
	assert_true(joined.contains("region region_elderweald self-intersects"))
	assert_true(joined.contains("Missing required named location missing_place"))


func test_validator_reports_settlement_region_route_and_water_contradictions() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH).duplicate(true)
	atlas["settlements"][0]["anchor"] = [1150, 450]
	atlas["routes"][0]["endpoint_refs"][1] = "missing_anchor"
	atlas["routes"][1]["path"][1] = [1150, 450]
	var joined := "\n".join(WorldAtlasValidator.validate(atlas))

	assert_true(joined.contains("Settlement briarwatch is outside intended region region_elderweald"))
	assert_true(joined.contains("Settlement briarwatch contradicts water exclusion"))
	assert_true(joined.contains("Route road_briarwatch_northgate endpoint references missing anchor missing_anchor"))
	assert_true(joined.contains("Land route road_northgate_stonebridge contradicts water exclusion"))
