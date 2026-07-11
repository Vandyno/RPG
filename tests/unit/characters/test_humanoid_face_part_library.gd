extends GutTest

const HumanoidFacePartLibrary = preload(
	"res://scripts/characters/humanoid_face_part_library.gd"
)


func before_each() -> void:
	HumanoidFacePartLibrary.reset_for_tests()


func test_catalog_declares_distinct_face_defaults_for_each_people() -> void:
	assert_eq(
		HumanoidFacePartLibrary.default_id("people_human", "eyes"), "eyes_human_dark"
	)
	assert_eq(
		HumanoidFacePartLibrary.default_id("people_tuskfolk", "eyes"), "eyes_tuskfolk_dark"
	)
	assert_eq(
		HumanoidFacePartLibrary.default_id("people_ravenfolk", "eyes"), "eyes_ravenfolk_gold"
	)


func test_legacy_eye_id_resolves_to_the_selected_peoples_default() -> void:
	assert_eq(
		HumanoidFacePartLibrary.resolve_id("people_human", "eyes", "eyes_dark"),
		"eyes_human_dark"
	)
	assert_eq(
		HumanoidFacePartLibrary.resolve_id("people_tuskfolk", "eyes", "eyes_dark"),
		"eyes_tuskfolk_dark"
	)


func test_catalog_accepts_people_specific_parts_and_falls_back_from_unknown_values() -> void:
	assert_eq(
		HumanoidFacePartLibrary.resolve_id(
			"people_human", "brows", "brows_human_arched"
		),
		"brows_human_arched"
	)
	assert_eq(
		HumanoidFacePartLibrary.resolve_id("people_human", "mouths", "mouth_unknown"),
		"mouth_human_neutral"
	)
