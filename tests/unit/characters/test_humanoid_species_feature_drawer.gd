extends GutTest

const HumanoidSpeciesFeatureDrawer = preload(
	"res://scripts/characters/humanoid_species_feature_drawer.gd"
)


func test_feature_ids_for_layer_routes_tanglekin_back_and_front_features() -> void:
	var features: Array[String] = [
		"feature_tanglekin_tail",
		"feature_tanglekin_muzzle",
		"feature_tanglekin_ears"
	]

	assert_eq(
		HumanoidSpeciesFeatureDrawer.feature_ids_for_layer(
			features,
			HumanoidSpeciesFeatureDrawer.PEOPLE_TANGLEKIN,
			HumanoidSpeciesFeatureDrawer.LAYER_BACK
		),
		["feature_tanglekin_tail"]
	)
	assert_eq(
		HumanoidSpeciesFeatureDrawer.feature_ids_for_layer(
			features,
			HumanoidSpeciesFeatureDrawer.PEOPLE_TANGLEKIN,
			HumanoidSpeciesFeatureDrawer.LAYER_FRONT
		),
		["feature_tanglekin_muzzle", "feature_tanglekin_ears"]
	)


func test_feature_ids_for_layer_routes_ravenfolk_back_body_and_front_features() -> void:
	var features: Array[String] = [
		"feature_ravenfolk_tail_feathers",
		"feature_ravenfolk_body_feathers",
		"feature_ravenfolk_head_crest",
		"feature_ravenfolk_beak",
		"feature_ravenfolk_quill_marks",
		"feature_ravenfolk_unknown"
	]

	assert_eq(
		HumanoidSpeciesFeatureDrawer.feature_ids_for_layer(
			features,
			HumanoidSpeciesFeatureDrawer.PEOPLE_RAVENFOLK,
			HumanoidSpeciesFeatureDrawer.LAYER_BACK
		),
		["feature_ravenfolk_tail_feathers"]
	)
	assert_eq(
		HumanoidSpeciesFeatureDrawer.feature_ids_for_layer(
			features,
			HumanoidSpeciesFeatureDrawer.PEOPLE_RAVENFOLK,
			HumanoidSpeciesFeatureDrawer.LAYER_BODY
		),
		["feature_ravenfolk_body_feathers"]
	)
	assert_eq(
		HumanoidSpeciesFeatureDrawer.feature_ids_for_layer(
			features,
			HumanoidSpeciesFeatureDrawer.PEOPLE_RAVENFOLK,
			HumanoidSpeciesFeatureDrawer.LAYER_FRONT
		),
		[
			"feature_ravenfolk_head_crest",
			"feature_ravenfolk_beak",
			"feature_ravenfolk_quill_marks"
		]
	)


func test_feature_ids_for_layer_defaults_other_people_to_front_only() -> void:
	var features: Array[String] = ["feature_a", "feature_b"]

	assert_eq(
		HumanoidSpeciesFeatureDrawer.feature_ids_for_layer(
			features,
			HumanoidSpeciesFeatureDrawer.PEOPLE_TUSKFOLK,
			HumanoidSpeciesFeatureDrawer.LAYER_FRONT
		),
		features
	)
	assert_eq(
		HumanoidSpeciesFeatureDrawer.feature_ids_for_layer(
			features,
			HumanoidSpeciesFeatureDrawer.PEOPLE_TUSKFOLK,
			HumanoidSpeciesFeatureDrawer.LAYER_BACK
		),
		[]
	)


func test_draw_layer_rejects_unknown_people_and_unsupported_layers() -> void:
	assert_false(
		HumanoidSpeciesFeatureDrawer.draw_layer(
			null,
			"people_unknown",
			Color.WHITE,
			{},
			[],
			HumanoidSpeciesFeatureDrawer.LAYER_FRONT
		)
	)
	assert_false(
		HumanoidSpeciesFeatureDrawer._draw_tuskfolk_layer(
			null,
			Color.WHITE,
			{},
			[],
			HumanoidSpeciesFeatureDrawer.LAYER_BACK
		)
	)
