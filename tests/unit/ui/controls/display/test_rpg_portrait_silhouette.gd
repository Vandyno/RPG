extends GutTest

const RpgPortraitSilhouette = preload(
	"res://scripts/ui/controls/display/rpg_portrait_silhouette.gd"
)


func test_ready_ignores_pointer_input() -> void:
	var portrait := RpgPortraitSilhouette.new()
	add_child_autofree(portrait)

	assert_eq(portrait.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_set_identity_kind_updates_kind() -> void:
	var portrait := RpgPortraitSilhouette.new()
	add_child_autofree(portrait)

	portrait.set_identity_kind("readable")

	assert_eq(portrait.identity_kind, "readable")


func test_draw_returns_safely_when_size_has_no_radius() -> void:
	var portrait := RpgPortraitSilhouette.new()
	add_child_autofree(portrait)
	portrait.size = Vector2.ZERO

	portrait._draw()

	assert_eq(portrait.identity_kind, "person")


func test_portrait_draws_all_supported_identity_kinds_without_errors() -> void:
	var portrait := RpgPortraitSilhouette.new()
	add_child_autofree(portrait)
	portrait.size = Vector2(96, 96)

	for kind in ["person", "readable", "place", "response", "unknown"]:
		portrait.set_identity_kind(kind)
		await get_tree().process_frame

	assert_eq(portrait.identity_kind, "unknown")
