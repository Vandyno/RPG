extends GutTest

const CaptureWorldAtlasPreview = preload(
	"res://scripts/tools/capture/capture_world_atlas_preview.gd"
)
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")


func test_capture_config_has_one_supported_preview_and_report_contract() -> void:
	assert_eq(
		CaptureWorldAtlasPreview.capture_config([]),
		{
			"atlas_path": CaptureWorldAtlasPreview.DEFAULT_ATLAS_PATH,
			"output_path": CaptureWorldAtlasPreview.DEFAULT_OUTPUT_PATH,
			"report_path": CaptureWorldAtlasPreview.DEFAULT_REPORT_PATH
		}
	)
	assert_eq(
		CaptureWorldAtlasPreview.capture_config(["a.json", "preview.png", "report.json"]),
		{"atlas_path": "a.json", "output_path": "preview.png", "report_path": "report.json"}
	)


func test_svg_contains_scale_validation_review_and_map_layers() -> void:
	var atlas := WorldAtlasValidator.load_atlas("res://data/world_atlas_proposal.json")
	var report := WorldAtlasValidator.build_report(atlas)
	var svg := CaptureWorldAtlasPreview.build_svg(atlas, report)

	assert_true(svg.contains("VELCOR WORLD ATLAS"))
	assert_true(svg.contains("30,720 x 20,480 global tiles"))
	assert_true(svg.contains("VALIDATION: PASS"))
	assert_true(svg.contains("APPROVAL: PENDING"))
	assert_true(svg.contains("Briarwatch"))
	assert_true(svg.contains("The Elderweald"))
	assert_true(svg.contains("Cult pressure zone"))


func test_svg_escapes_authored_labels() -> void:
	assert_eq(
		CaptureWorldAtlasPreview._xml_escape('A & B <C> "D"'),
		"A &amp; B &lt;C&gt; &quot;D&quot;"
	)
