extends GutTest

const RegionCapture = preload("res://scripts/tools/capture/capture_world_region_proposal.gd")
const RegionGenerator = preload("res://scripts/generation/world_region_generator.gd")
const RegionValidator = preload("res://scripts/data/world_region_proposal_validator.gd")
const AtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const AtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")


func test_capture_config_has_stable_defaults_and_reads_args() -> void:
	assert_eq(
		RegionCapture.capture_config([]),
		{
			"proposal_path": RegionCapture.DEFAULT_PROPOSAL_PATH,
			"output_path": RegionCapture.DEFAULT_OUTPUT_PATH,
			"report_path": RegionCapture.DEFAULT_REPORT_PATH
		}
	)
	assert_eq(
		RegionCapture.capture_config(["proposal.json", "overview.png", "report.json"]),
		{"proposal_path": "proposal.json", "output_path": "overview.png", "report_path": "report.json"}
	)


func test_svg_contains_terrain_constraints_generated_content_and_review_gate() -> void:
	var atlas := AtlasValidator.load_atlas("res://data/world_atlas_proposal.json")
	var review := AtlasApprovalGate.load_review("res://data/world_atlas_review.json").duplicate(true)
	review["decision_status"] = "approved"
	review["reviewed_by"] = "test_fixture"
	review["reviewed_at_utc"] = "2026-01-01T00:00:00Z"
	for item in review["item_decisions"]:
		item["decision"] = "approved"
	var proposal := RegionGenerator.generate(
		atlas, "region_marches_velcor", 1701,
		{"poi_count": 8, "atlas_review": review}
	)
	var report := RegionValidator.build_report(proposal)
	var svg := RegionCapture.build_svg(proposal, report)

	assert_eq(report["validation_errors"], [], JSON.stringify(report))
	assert_true(svg.contains("data-label=\"REGION PROPOSAL\""))
	assert_true(svg.contains("data-label=\"Cairnwall\""))
	assert_true(svg.contains("#55add1"))
	assert_true(svg.contains("stroke-dasharray=\"5 3\""))
	assert_true(svg.contains("clip-path=\"url(#region-clip)\""))
	assert_true(svg.contains("region marches velcor"))
	assert_true(svg.contains("data-label=\"VALIDATION: PASS\""))
	assert_true(svg.contains("data-label=\"ACTIVATION: REVIEW REQUIRED\""))
