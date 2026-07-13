extends GutTest

const WorldAtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const WorldSettlementGenerator = preload("res://scripts/generation/world_settlement_generator.gd")
const WorldSettlementProposalValidator = preload(
	"res://scripts/data/world_settlement_proposal_validator.gd"
)
const GenerateWorldSettlementProposal = preload(
	"res://scripts/tools/generate_world_settlement_proposal.gd"
)

var atlas: Dictionary
var review: Dictionary


func before_all() -> void:
	atlas = WorldAtlasValidator.load_atlas("res://data/world_atlas_proposal.json")
	review = WorldAtlasApprovalGate.load_review("res://data/world_atlas_review.json")


func test_northgate_generation_is_deterministic_and_review_only() -> void:
	var first := WorldSettlementGenerator.generate(
		atlas, "northgate", 2701, {"atlas_review": review}
	)
	var repeat := WorldSettlementGenerator.generate(
		atlas, "northgate", 2701, {"atlas_review": review}
	)
	var changed := WorldSettlementGenerator.generate(
		atlas, "northgate", 2702, {"atlas_review": review}
	)

	assert_eq(JSON.stringify(first), JSON.stringify(repeat))
	assert_ne(JSON.stringify(first["npc_role_slots"]), JSON.stringify(changed["npc_role_slots"]))
	assert_eq(first["proposal_status"], "proposal")
	assert_eq(first["activation_status"], "review_required")
	assert_eq(first["atlas_approval"]["status"], "approved")


func test_northgate_contains_complete_authored_settlement_contract() -> void:
	var proposal := WorldSettlementGenerator.generate(
		atlas, "northgate", 2701, {"atlas_review": review}
	)
	var roles: Array = proposal["plots"].map(func(plot): return plot["building_role"])
	var services: Array = proposal["service_slots"].map(func(slot): return slot["service"])

	for required_role in [
		"road_shrine", "guard_post", "town_hall", "coaching_inn", "stable",
		"general_shop", "storehouse", "smithy", "home"
	]:
		assert_true(roles.has(required_role), required_role)
	for required_service in ["inn", "general_trade", "smithing", "repair", "notices"]:
		assert_true(services.has(required_service), required_service)
	assert_eq(proposal["plots"].size(), 13)
	assert_eq(proposal["structures"].size(), 26)
	assert_eq(proposal["portals"].size(), 26)
	assert_gt(proposal["npc_role_slots"].size(), 13)
	assert_gt(proposal["quest_hook_slots"].size(), 5)
	assert_gt(proposal["interior_fixture_slots"].size(), 40)
	assert_true(
		proposal["interior_fixture_slots"].any(
			func(slot): return slot["fixture"] == "anvil" and slot["interaction_slot"]
		)
	)
	assert_eq(proposal["defenses"]["gates"].size(), 4)
	assert_gt(proposal["defenses"].get("boundary_polygon", []).size(), 8)
	var exterior_shapes: Array = proposal["structures"].filter(
		func(structure): return String(structure.get("world_layer", "")) == "surface"
	).map(
		func(structure): return proposal["structure_archetypes"][structure["archetype_id"]]["terrain_rows"]
	)
	assert_true(exterior_shapes.all(func(rows): return rows.any(func(row): return "." in row)))
	var plot_xs := {}
	var plot_ys := {}
	for plot in proposal["plots"]:
		plot_xs[plot["rect"]["position"][0]] = true
		plot_ys[plot["rect"]["position"][1]] = true
	assert_gt(plot_xs.size(), 8)
	assert_gt(plot_ys.size(), 8)
	assert_gte(proposal["streets"].size(), 6)
	assert_gte(proposal["streets"].filter(func(street): return street.has("path")).size(), 5)
	var surface_structures: Array = proposal["structures"].filter(
		func(structure): return structure["world_layer"] == "surface"
	)
	var building_paths: Array = proposal["streets"].filter(
		func(street): return street.get("kind", "") == "building_footpath"
	)
	assert_eq(building_paths.size(), surface_structures.size())
	assert_true(surface_structures.all(func(structure): return structure.has("approach_street_id")))


func test_northgate_homes_use_compact_authored_footprints_inside_larger_plots() -> void:
	var proposal := WorldSettlementGenerator.generate(
		atlas, "northgate", 2701, {"atlas_review": review}
	)
	var plots_by_structure := {}
	for plot in proposal["plots"]:
		plots_by_structure[String(plot["structure_id"])] = plot
	var homes: Array = proposal["structures"].filter(
		func(structure):
			return (
				structure.get("world_layer", "") == "surface"
				and structure.get("template", "") == "home"
			)
	)
	assert_eq(homes.size(), 5)
	for home in homes:
		var bounds: Dictionary = home["bounds"]
		var plot: Dictionary = plots_by_structure[String(home["id"])]
		var exterior_archetype: Dictionary = proposal["structure_archetypes"][home["archetype_id"]]
		assert_eq(exterior_archetype["tile_kinds"]["f"], "wood_wall", "%s must be solid" % home["id"])
		assert_eq(exterior_archetype["tile_kinds"]["d"], "wood_floor", "%s door must open" % home["id"])
		assert_lte(int(bounds["size"][0]), 7, String(home["id"]))
		assert_lte(int(bounds["size"][1]), 4, String(home["id"]))
		assert_lt(
			int(bounds["size"][0]) * int(bounds["size"][1]),
			int(plot["rect"]["size"][0]) * int(plot["rect"]["size"][1]) / 3,
			"Plot must retain meaningful yard and negative space"
		)
		var yard_zones: Array = plot.get("yard_zones", [])
		assert_gt(yard_zones.size(), 0, "%s needs an authored yard surface" % home["id"])
		for zone in yard_zones:
			assert_eq(zone.get("kind", ""), "soil")
			var zone_position: Array = zone["rect"]["position"]
			var zone_size: Array = zone["rect"]["size"]
			var plot_position: Array = plot["rect"]["position"]
			var plot_size: Array = plot["rect"]["size"]
			assert_gte(int(zone_position[0]), int(plot_position[0]))
			assert_gte(int(zone_position[1]), int(plot_position[1]))
			assert_lte(int(zone_position[0]) + int(zone_size[0]), int(plot_position[0]) + int(plot_size[0]))
			assert_lte(int(zone_position[1]) + int(zone_size[1]), int(plot_position[1]) + int(plot_size[1]))
		var interior_id := "%s_interior" % String(home["id"])
		var interior: Dictionary = proposal["structures"].filter(
			func(structure): return structure.get("id", "") == interior_id
		)[0]
		var archetype: Dictionary = proposal["structure_archetypes"][interior["archetype_id"]]
		assert_eq(archetype["size"], [10, 8])
		assert_true(String(archetype["visual_style"]).contains(String(home["interior_identity"])))


func test_northgate_public_buildings_have_authored_footprints_and_interior_zones() -> void:
	var proposal := WorldSettlementGenerator.generate(
		atlas, "northgate", 2701, {"atlas_review": review}
	)
	var plots_by_structure := {}
	for plot in proposal["plots"]:
		plots_by_structure[String(plot["structure_id"])] = plot
	var public_buildings: Array = proposal["structures"].filter(
		func(structure):
			return (
				structure.get("world_layer", "") == "surface"
				and structure.get("template", "") != "home"
			)
	)
	assert_eq(public_buildings.size(), 8)
	for building in public_buildings:
		var bounds: Dictionary = building["bounds"]
		var plot: Dictionary = plots_by_structure[String(building["id"])]
		var exterior_archetype: Dictionary = proposal["structure_archetypes"][building["archetype_id"]]
		assert_eq(exterior_archetype["tile_kinds"]["f"], "wood_wall", "%s must be solid" % building["id"])
		assert_eq(exterior_archetype["tile_kinds"]["d"], "wood_floor", "%s door must open" % building["id"])
		var footprint_area := int(bounds["size"][0]) * int(bounds["size"][1])
		var plot_area := int(plot["rect"]["size"][0]) * int(plot["rect"]["size"][1])
		assert_lt(footprint_area, plot_area / 2, "%s needs a working yard" % building["id"])
		var fixtures: Array = proposal["interior_fixture_slots"].filter(
			func(slot): return slot.get("structure_id", "") == building["id"]
		)
		assert_gte(fixtures.size(), 6, "%s needs purpose-specific furnishing" % building["id"])
		var xs: Array[int] = []
		var ys: Array[int] = []
		for fixture in fixtures:
			xs.append(int(fixture["global_tile"][0]))
			ys.append(int(fixture["global_tile"][1]))
		assert_gte(xs.max() - xs.min(), 3, "%s fixtures need horizontal zoning" % building["id"])
		assert_gte(ys.max() - ys.min(), 3, "%s fixtures need vertical zoning" % building["id"])


func test_northgate_building_entries_spawn_clear_of_the_exit_prompt() -> void:
	var proposal := WorldSettlementGenerator.generate(
		atlas, "northgate", 2701, {"atlas_review": review}
	)
	var portals_by_id := {}
	for portal in proposal["portals"]:
		portals_by_id[String(portal["id"])] = portal
	for portal in proposal["portals"]:
		if portal.get("template", "") != "structure_entry_portal":
			continue
		var exit_portal: Dictionary = portals_by_id[String(portal["reciprocal_portal_id"])]
		assert_eq(int(portal["target_tile"][0]), int(exit_portal["global_tile"][0]))
		assert_eq(int(portal["target_tile"][1]), int(exit_portal["global_tile"][1]) - 4)


func test_northgate_validates_reachability_collision_portals_and_slots_after_json_round_trip() -> void:
	var proposal := WorldSettlementGenerator.generate(
		atlas, "northgate", 2701, {"atlas_review": review}
	)
	assert_eq(
		WorldSettlementProposalValidator.validate(proposal, atlas),
		PackedStringArray()
	)
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(proposal))
	assert_eq(
		WorldSettlementProposalValidator.validate(round_trip, atlas),
		PackedStringArray(),
		"Saved and reloaded settlement must validate"
	)


func test_generator_refuses_unapproved_or_unknown_settlement() -> void:
	var pending := review.duplicate(true)
	pending["decision_status"] = "pending"
	pending["item_decisions"][0]["decision"] = "pending"
	assert_eq(
		WorldSettlementGenerator.generate(
			atlas, "northgate", 2701, {"atlas_review": pending}
		),
		{}
	)
	assert_eq(
		WorldSettlementGenerator.generate(
			atlas, "missing", 2701, {"atlas_review": review}
		),
		{}
	)


func test_settlement_cli_config_has_stable_defaults() -> void:
	assert_eq(
		GenerateWorldSettlementProposal.generation_config([]),
		{
			"settlement_id": GenerateWorldSettlementProposal.DEFAULT_SETTLEMENT_ID,
			"seed": GenerateWorldSettlementProposal.DEFAULT_SEED,
			"output_path": GenerateWorldSettlementProposal.DEFAULT_OUTPUT_PATH,
			"atlas_path": GenerateWorldSettlementProposal.DEFAULT_ATLAS_PATH,
			"review_path": GenerateWorldSettlementProposal.DEFAULT_REVIEW_PATH
		}
	)
