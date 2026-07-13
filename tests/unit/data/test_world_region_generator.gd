extends GutTest

const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const WorldAtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")
const WorldRegionGenerator = preload("res://scripts/generation/world_region_generator.gd")
const WorldRegionProposalValidator = preload("res://scripts/data/world_region_proposal_validator.gd")
const WorldPoiProposalValidator = preload("res://scripts/data/world_poi_proposal_validator.gd")
const GenerateWorldRegionProposal = preload("res://scripts/tools/generate_world_region_proposal.gd")

var atlas: Dictionary


func before_all() -> void:
	atlas = WorldAtlasValidator.load_atlas("res://data/world_atlas_proposal.json")


func approved_review_fixture() -> Dictionary:
	var review := WorldAtlasApprovalGate.load_review("res://data/world_atlas_review.json").duplicate(true)
	review["decision_status"] = "approved"
	review["reviewed_by"] = "test_fixture"
	review["reviewed_at_utc"] = "2026-01-01T00:00:00Z"
	for item in review["item_decisions"]:
		item["decision"] = "approved"
	return review


func test_region_generation_is_reproducible_and_seed_changes_output() -> void:
	var options := {"atlas_review": approved_review_fixture()}
	var first := WorldRegionGenerator.generate(atlas, "region_marches_velcor", 1701, options)
	var repeat := WorldRegionGenerator.generate(atlas, "region_marches_velcor", 1701, options)
	var changed := WorldRegionGenerator.generate(atlas, "region_marches_velcor", 1702, options)

	assert_eq(JSON.stringify(first), JSON.stringify(repeat))
	assert_ne(JSON.stringify(first["terrain_cells"]), JSON.stringify(changed["terrain_cells"]))
	assert_ne(JSON.stringify(first["pois"]), JSON.stringify(changed["pois"]))
	var cells_by_position := {}
	for cell in first["terrain_cells"]:
		var position: Array = cell["chunk_rect"]["position"]
		cells_by_position["%d:%d" % [position[0], position[1]]] = cell["biome"]
	var matching_neighbors := 0
	var neighbor_pairs := 0
	for cell in first["terrain_cells"]:
		var position: Array = cell["chunk_rect"]["position"]
		for offset in [[8, 0], [0, 8]]:
			var neighbor_key := "%d:%d" % [position[0] + offset[0], position[1] + offset[1]]
			if not cells_by_position.has(neighbor_key):
				continue
			neighbor_pairs += 1
			if cells_by_position[neighbor_key] == cell["biome"]:
				matching_neighbors += 1
	assert_gt(float(matching_neighbors) / float(neighbor_pairs), 0.55)


func test_region_proposal_preserves_atlas_constraints_and_provenance() -> void:
	var proposal := WorldRegionGenerator.generate(
		atlas, "region_marches_velcor", 1701, {"atlas_review": approved_review_fixture()}
	)
	var fixed: Dictionary = proposal["fixed_constraints"]
	var feature_ids: Array = fixed["terrain_features"].map(func(entry): return entry["source_atlas_id"])
	var route_ids: Array = fixed["routes"].map(func(entry): return entry["source_atlas_id"])
	var settlement_ids: Array = fixed["settlements"].map(func(entry): return entry["source_atlas_id"])

	assert_true(feature_ids.has("river_veyn"))
	assert_true(route_ids.has("road_cairnwall_dunmere"))
	assert_true(settlement_ids.has("cairnwall"))
	assert_true(settlement_ids.has("dunmere"))
	assert_true(fixed["terrain_features"].all(func(entry): return entry["preserve"]))
	for collection_name in ["terrain_cells", "minor_routes", "pois"]:
		assert_true(proposal[collection_name].all(func(entry): return entry["atlas_region_id"] == "region_marches_velcor"))
		assert_true(proposal[collection_name].all(func(entry): return entry["seed"] == 1701))
		assert_true(proposal[collection_name].all(func(entry): return entry["generator_version"] == WorldRegionGenerator.GENERATOR_VERSION))
	var polygon := PackedVector2Array(
		proposal["region_polygon_global_tiles"].map(
			func(pair): return Vector2(float(pair[0]), float(pair[1]))
		)
	)
	assert_true(
		proposal["pois"].all(
			func(poi): return Geometry2D.is_point_in_polygon(
				Vector2(float(poi["global_tile"][0]), float(poi["global_tile"][1])), polygon
			)
		)
	)
	var protected_points: Array[Vector2] = []
	for collection_name in ["settlements", "landmarks"]:
		for entry in fixed[collection_name]:
			if entry.has("global_tile"):
				protected_points.append(Vector2(entry["global_tile"][0], entry["global_tile"][1]))
	for poi in proposal["pois"]:
		var poi_point := Vector2(poi["global_tile"][0], poi["global_tile"][1])
		for protected in protected_points:
			if not bool(poi.get("required_site", false)):
				assert_gte(poi_point.distance_to(protected), 384.0)
	for route in proposal["minor_routes"]:
		for index in range(route["path"].size() - 1):
			assert_false(
				WorldRegionGenerator._segment_crosses_water(
					Vector2(route["path"][index][0], route["path"][index][1]),
					Vector2(route["path"][index + 1][0], route["path"][index + 1][1]),
					fixed["terrain_features"]
				)
			)


func test_generated_proposal_validates_and_stays_review_gated() -> void:
	var proposal := WorldRegionGenerator.generate(
		atlas, "region_marches_velcor", 1701, {"atlas_review": approved_review_fixture()}
	)

	assert_eq(WorldRegionProposalValidator.validate(proposal), PackedStringArray())
	assert_eq(proposal["proposal_status"], "proposal")
	assert_eq(proposal["activation_status"], "review_required")
	assert_gt(proposal["terrain_cells"].size(), 1000)
	assert_gt(proposal["minor_routes"].size(), 0)
	assert_gte(proposal["pois"].size(), 100)
	var northgate_farms: Array = proposal["pois"].filter(
		func(poi): return poi.get("id", "") == "poi_northgate_working_farm"
	)
	assert_eq(northgate_farms.size(), 1)
	assert_eq(northgate_farms[0]["source_settlement_id"], "northgate")
	assert_true(northgate_farms[0]["required_site"])
	assert_eq(
		WorldPoiProposalValidator.validate(northgate_farms[0]["site_layout"]),
		PackedStringArray()
	)
	assert_true(proposal["pois"].all(func(poi): return poi.has("placement_context")))
	assert_true(proposal["terrain_cells"].all(func(cell): return cell.has("generation_context")))
	assert_false(
		proposal["terrain_cells"].any(func(cell): return cell["biome"] == "hills"),
		"The central Marches should remain flat"
	)
	assert_true(proposal["pois"].all(func(poi): return poi.has("walkability") and poi.has("slots") and poi.has("quest_hooks")))
	assert_eq(proposal["atlas_approval"]["status"], "approved")
	assert_true(proposal["terrain_palette"].has("red_loam_field"))
	assert_true(
		proposal["terrain_cells"].any(
			func(cell): return cell["recommended_default_kind"] in [
				"red_loam_field", "fallow_field", "orchard_edge"
			]
		)
	)
	var round_tripped: Dictionary = JSON.parse_string(JSON.stringify(proposal))
	assert_eq(
		WorldRegionProposalValidator.validate(round_tripped),
		PackedStringArray(),
		"Saved and reloaded proposal must validate"
	)


func test_generator_rejects_missing_region_and_invalid_atlas() -> void:
	var options := {"atlas_review": approved_review_fixture()}
	assert_eq(WorldRegionGenerator.generate(atlas, "missing_region", 1, options), {})
	assert_eq(WorldRegionGenerator.generate({}, "region_marches_velcor", 1), {})


func test_cli_config_has_stable_defaults_and_reads_args() -> void:
	assert_eq(
		GenerateWorldRegionProposal.generation_config([]),
		{
			"region_id": GenerateWorldRegionProposal.DEFAULT_REGION_ID,
			"seed": GenerateWorldRegionProposal.DEFAULT_SEED,
			"output_path": GenerateWorldRegionProposal.DEFAULT_OUTPUT_PATH,
			"atlas_path": GenerateWorldRegionProposal.DEFAULT_ATLAS_PATH,
			"review_path": GenerateWorldRegionProposal.DEFAULT_REVIEW_PATH
		}
	)
	assert_eq(
		GenerateWorldRegionProposal.generation_config(["region_mireveil", "42", "out.json", "atlas.json", "review.json"]),
		{"region_id": "region_mireveil", "seed": 42, "output_path": "out.json", "atlas_path": "atlas.json", "review_path": "review.json"}
	)


func test_generator_refuses_unapproved_atlas_review() -> void:
	var review := WorldAtlasApprovalGate.load_review("res://data/world_atlas_review.json")
	review["decision_status"] = "pending"
	review["item_decisions"][0]["decision"] = "pending"
	assert_eq(
		WorldRegionGenerator.generate(
			atlas, "region_marches_velcor", 1701, {"atlas_review": review}
		),
		{}
	)
