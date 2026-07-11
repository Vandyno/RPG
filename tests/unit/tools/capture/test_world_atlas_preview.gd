extends GutTest

const WorldAtlasPreview = preload("res://scripts/tools/world_atlas_preview.gd")


func test_atlas_to_preview_maps_bounds_and_midpoint() -> void:
	var bounds := Rect2(0, 0, 100, 200)
	var preview := Rect2(10, 20, 500, 400)

	assert_eq(WorldAtlasPreview.atlas_to_preview(Vector2.ZERO, bounds, preview), Vector2(10, 20))
	assert_eq(WorldAtlasPreview.atlas_to_preview(Vector2(50, 100), bounds, preview), Vector2(260, 220))
	assert_eq(WorldAtlasPreview.atlas_to_preview(Vector2(100, 200), bounds, preview), Vector2(510, 420))


func test_setup_keeps_atlas_and_validation_warnings_for_overlay() -> void:
	var preview := WorldAtlasPreview.new()
	var atlas := {"proposal_status": "proposal"}
	var warnings := PackedStringArray(["bad route"])

	preview.setup(atlas, warnings)

	assert_eq(preview.atlas, atlas)
	assert_eq(preview.warnings, warnings)
	preview.free()
