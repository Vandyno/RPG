extends GutTest

const CaptureSettlement = preload(
	"res://scripts/tools/capture/capture_world_settlement_proposal.gd"
)
const SettlementGenerator = preload(
	"res://scripts/generation/world_settlement_generator.gd"
)
const SettlementValidator = preload(
	"res://scripts/data/world_settlement_proposal_validator.gd"
)
const AtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const AtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")


func test_capture_config_has_stable_defaults() -> void:
	assert_eq(
		CaptureSettlement.capture_config([]),
		{
			"proposal_path": CaptureSettlement.DEFAULT_PROPOSAL_PATH,
			"output_dir": CaptureSettlement.DEFAULT_OUTPUT_DIR,
			"atlas_path": CaptureSettlement.DEFAULT_ATLAS_PATH
		}
	)


func test_capture_svgs_show_layout_structures_interiors_and_review_gate() -> void:
	var atlas := AtlasValidator.load_atlas("res://data/world_atlas_proposal.json")
	var review := AtlasApprovalGate.load_review("res://data/world_atlas_review.json")
	var proposal := SettlementGenerator.generate(
		atlas, "northgate", 2701, {"atlas_review": review}
	)
	var report := SettlementValidator.build_report(proposal, atlas)
	var overview := CaptureSettlement.build_overview_svg(proposal, report, false)
	var structures := CaptureSettlement.build_overview_svg(proposal, report, true)
	var interiors := CaptureSettlement.build_interiors_svg(proposal, report)

	assert_eq(report["validation_errors"], [])
	assert_true(overview.contains('data-label="NORTHGATE SETTLEMENT PROPOSAL"'))
	assert_true(overview.contains('data-label="SETTLEMENT CONTRACT"'))
	assert_true(structures.contains('data-label="NORTHGATE STRUCTURES"'))
	assert_true(interiors.contains('data-label="NORTHGATE INTERIORS"'))
	assert_true(interiors.contains("#d8b86f"))
	assert_gt(proposal["interior_fixture_slots"].size(), 40)
	assert_true(overview.contains('data-label="VALIDATION: PASS"'))
