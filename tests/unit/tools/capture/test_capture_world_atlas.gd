extends GutTest

const AtlasPreview = preload("res://scripts/tools/atlas/atlas_preview.gd")
const CaptureWorldAtlas = preload("res://scripts/tools/capture/capture_world_atlas.gd")
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")


func test_capture_config_defaults_and_clamps_size() -> void:
	assert_eq(CaptureWorldAtlas.capture_config([]), {"output_path": CaptureWorldAtlas.DEFAULT_OUTPUT_PATH, "width": 1536, "height": 1024})
	assert_eq(CaptureWorldAtlas.capture_config(["res://reports/test.png", "100", "200"]), {"output_path": "res://reports/test.png", "width": 640, "height": 480})


func test_preview_maps_atlas_points_inside_canvas() -> void:
	var preview := AtlasPreview.new()
	preview.size = Vector2(1536, 1024)
	preview.setup(WorldAtlasValidator.load_atlas("res://data/world_atlas_proposal.json"))
	var origin := preview.atlas_to_preview(Vector2.ZERO)
	var far_corner := preview.atlas_to_preview(Vector2(1536, 1024))
	assert_true(origin.x >= 0.0 and origin.y >= 0.0)
	assert_true(far_corner.x <= preview.size.x and far_corner.y <= preview.size.y)
	preview.free()
