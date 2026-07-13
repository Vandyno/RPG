extends GutTest

const HumanoidRoleAccent2D = preload("res://scripts/characters/humanoid_role_accent_2d.gd")


func test_accent_id_prefers_authored_base_clothing() -> void:
	var appearance := {
		"base_clothing_id": "accent_guard_belt",
		"visual_model_id": "human_scribe"
	}

	assert_eq(HumanoidRoleAccent2D.accent_id_for_appearance(appearance), "accent_guard_belt")


func test_accent_id_uses_visual_model_tokens() -> void:
	assert_eq(
		HumanoidRoleAccent2D.accent_id_for_appearance({"visual_model_id": "human_bridge_guard"}),
		"accent_guard_belt"
	)
	assert_eq(
		HumanoidRoleAccent2D.accent_id_for_appearance({"visual_model_id": "otterfolk_runner"}),
		"accent_travel_wrap"
	)
	assert_eq(
		HumanoidRoleAccent2D.accent_id_for_appearance({"visual_model_id": "tuskfolk_midwife"}),
		"accent_elder_shawl"
	)
	assert_eq(HumanoidRoleAccent2D.accent_id_for_appearance({"visual_model_id": "unknown"}), "")


func test_accent_color_uses_base_without_variant_key() -> void:
	assert_eq(
		HumanoidRoleAccent2D._accent_color("accent_worker_apron"),
		HumanoidRoleAccent2D.COLORS["accent_worker_apron"]
	)


func test_ravenfolk_variant_keeps_accent_closer_to_base_color() -> void:
	var base: Color = HumanoidRoleAccent2D.COLORS["accent_public_sash"]
	var human_color := HumanoidRoleAccent2D._accent_color(
		"accent_public_sash", {"visual_model_id": "human_voice"}
	)
	var ravenfolk_color := HumanoidRoleAccent2D._accent_color(
		"accent_public_sash",
		{"people_id": "people_ravenfolk", "visual_model_id": "human_voice"}
	)

	assert_lt(_color_delta(ravenfolk_color, base), _color_delta(human_color, base))


func _color_delta(left: Color, right: Color) -> float:
	return (
		absf(left.r - right.r)
		+ absf(left.g - right.g)
		+ absf(left.b - right.b)
		+ absf(left.a - right.a)
	)
