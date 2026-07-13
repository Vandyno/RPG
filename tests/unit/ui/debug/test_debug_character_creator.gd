extends GutTest

const DebugCharacterCreator = preload("res://scripts/ui/debug/debug_character_creator.gd")


class ContentStub:
	extends RefCounted

	var last_people_id := ""
	var last_owner_id := ""
	var last_seed := ""
	var last_options := {}

	func get_generated_people_profile(
		people_id: String, owner_id: String, seed: String, options: Dictionary
	) -> Dictionary:
		last_people_id = people_id
		last_owner_id = owner_id
		last_seed = seed
		last_options = options.duplicate(true)
		return {
			"character_id": "preview",
			"people_id": people_id,
			"appearance":
			{
				"people_id": people_id,
				"body_plan_id": "body_humanoid_average",
				"head_id": "head_human_round",
				"palette_id": "palette_human_warm_brown",
				"visual_model_id": String(options.get("variant_id", "")),
			}
		}

	func get_people_visual_model(people_id: String) -> Dictionary:
		return {
			"id": people_id,
			"variants":
			[
				{"id": "%s_default" % people_id, "display_name": "Default"},
				{"id": "%s_alt" % people_id, "display_name": "Alt"},
			]
		}

	func get_people_visual_variant(_people_id: String, variant_id: String) -> Dictionary:
		return {"id": variant_id, "display_name": "Variant %s" % variant_id}

	func get_people(people_id: String) -> Dictionary:
		return {"id": people_id, "display_name": "Display %s" % people_id}

	func get_item(item_id: String) -> Dictionary:
		return {"id": item_id, "avatar_visual": {"placeholder": item_id}}


class PlayerStub:
	extends RefCounted

	var humanoid_profile := {
		"faction_id": "faction_briarwatch",
		"state": "unconscious",
		"level": 7,
		"stats": {"might": 3},
		"derived_bonuses": {"armor": 1},
		"corpse_entity_id": "corpse_player",
	}
	var applied_profiles: Array[Dictionary] = []

	func set_humanoid_profile(profile: Dictionary) -> void:
		humanoid_profile = profile.duplicate(true)
		applied_profiles.append(humanoid_profile)


func test_setup_builds_hidden_creator_with_initial_preview_state() -> void:
	var content := ContentStub.new()
	var creator := _creator(content, PlayerStub.new())

	assert_false(creator.is_open())
	assert_eq(creator.layer, 80)
	assert_eq(creator.root.name, "DebugCharacterCreatorRoot")
	assert_eq(creator.panel.name, "DebugCharacterCreatorPanel")
	assert_eq(creator.get_current_people_id(), "people_human")
	assert_eq(creator.get_current_variant_id(), "")
	assert_eq(creator.get_current_eye_id(), "eyes_human_dark")
	assert_eq(creator.get_current_face_part_id(), "brows")
	assert_eq(creator.get_current_face_value_id(), "brows_human_straight")
	assert_eq(creator.get_current_gear_id(), "none")
	assert_eq(creator.eye_label.text, "Eyes Human Dark")
	assert_eq(creator.people_label.text, "Display people_human")
	assert_eq(creator.variant_label.text, "Seeded: debug")
	assert_eq(content.last_people_id, "people_human")
	assert_eq(content.last_owner_id, "debug_creator_preview")
	assert_eq(content.last_seed, "debug")


func test_open_toggle_refreshes_and_close_button_hides_creator() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())

	creator.set_open(true)
	assert_true(creator.is_open())
	creator.toggle_open()
	assert_false(creator.is_open())
	creator.toggle_open()
	assert_true(creator.is_open())

	var close := creator.root.find_child("CreatorCloseButton", true, false) as Button
	close.pressed.emit()
	assert_false(creator.is_open())


func test_open_character_appearance_starts_from_players_saved_appearance() -> void:
	var player := PlayerStub.new()
	player.humanoid_profile = {
		"people_id": "people_mirefolk",
		"appearance": {
			"visual_model_id": "people_mirefolk_alt",
			"eye_id": "eyes_mirefolk_narrow",
			"brow_id": "brows_mirefolk_ridge",
			"mouth_id": "mouth_mirefolk_short"
		}
	}
	var creator := _creator(ContentStub.new(), player)

	creator.open_character_appearance()

	assert_true(creator.is_open())
	assert_eq(creator.get_current_people_id(), "people_mirefolk")
	assert_eq(creator.get_current_variant_id(), "people_mirefolk_alt")
	assert_eq(creator.get_current_eye_id(), "eyes_mirefolk_narrow")
	assert_eq(creator.get_current_face_value_id(), "brows_mirefolk_ridge")
	for row in creator.advanced_rows:
		assert_false(row.visible)
	assert_eq(creator.panel.custom_minimum_size.y, 600.0)


func test_select_people_and_variant_update_labels_and_reject_unknown_ids() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())

	assert_false(creator.select_people("people_missing"))
	assert_true(creator.select_people("people_ravenfolk"))
	assert_eq(creator.get_current_people_id(), "people_ravenfolk")
	assert_eq(creator.get_current_variant_id(), "")
	assert_eq(creator.people_label.text, "Display people_ravenfolk")
	assert_false(creator.select_variant("missing_variant"))

	assert_true(creator.select_variant("people_ravenfolk_alt"))
	assert_eq(creator.get_current_variant_id(), "people_ravenfolk_alt")
	assert_eq(creator.variant_label.text, "Variant people_ravenfolk_alt")
	assert_true(creator.select_variant(""))
	assert_eq(creator.get_current_variant_id(), "")


func test_seed_and_jitter_are_forwarded_to_generated_profile_options() -> void:
	var content := ContentStub.new()
	var creator := _creator(content, PlayerStub.new())
	creator.seed_edit.text = "  custom seed  "
	creator.jitter_check.button_pressed = true

	assert_true(creator.select_variant("people_human_alt"))
	var profile := creator._current_profile()

	assert_eq(profile["people_id"], "people_human")
	assert_eq(content.last_seed, "custom seed")
	assert_eq(content.last_options["variant_id"], "people_human_alt")
	assert_true(bool(content.last_options["proportion_jitter"]))
	assert_eq(content.last_options["jitter_strength"], 0.03)


func test_apply_to_player_writes_player_ids_preserves_state_and_emits_profile() -> void:
	var player := PlayerStub.new()
	var creator := _creator(ContentStub.new(), player)
	var emitted: Array[Dictionary] = []
	creator.appearance_applied.connect(func(profile: Dictionary) -> void: emitted.append(profile))
	assert_true(creator.select_people("people_tuskfolk"))
	assert_true(creator.select_variant("people_tuskfolk_default"))

	assert_true(creator.apply_to_player())

	assert_eq(player.applied_profiles.size(), 1)
	assert_eq(player.humanoid_profile["character_id"], "char_player")
	assert_eq(player.humanoid_profile["inventory_owner_id"], "char_player")
	assert_eq(player.humanoid_profile["equipment_owner_id"], "char_player")
	assert_eq(player.humanoid_profile["spellbook_owner_id"], "char_player")
	assert_eq(player.humanoid_profile["loadout_id"], "loadout_player")
	assert_eq(player.humanoid_profile["faction_id"], "faction_briarwatch")
	assert_eq(player.humanoid_profile["state"], "unconscious")
	assert_eq(player.humanoid_profile["level"], 7)
	assert_eq(player.humanoid_profile["stats"], {"might": 3})
	assert_eq(player.humanoid_profile["derived_bonuses"], {"armor": 1})
	assert_eq(player.humanoid_profile["corpse_entity_id"], "corpse_player")
	assert_eq(creator.message_label.text, "Applied to player.")
	assert_eq(emitted.size(), 1)
	assert_eq(emitted[0]["people_id"], "people_tuskfolk")
	assert_eq(emitted[0]["appearance"]["eye_id"], "eyes_tuskfolk_dark")


func test_apply_to_player_rejects_missing_player_contract() -> void:
	var creator := _creator(ContentStub.new(), RefCounted.new())

	assert_false(creator.apply_to_player())


func test_stepper_buttons_cycle_people_variant_gear_and_facing() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())
	var next_people := creator.root.find_child("CreatorNextPeopleButton", true, false) as Button
	var next_variant := creator.root.find_child("CreatorNextVariantButton", true, false) as Button
	var next_eyes := creator.root.find_child("CreatorNextEyesButton", true, false) as Button
	var next_gear := creator.root.find_child("CreatorNextGearButton", true, false) as Button
	var next_facing := creator.root.find_child("CreatorNextFacingButton", true, false) as Button

	next_people.pressed.emit()
	assert_eq(creator.get_current_people_id(), "people_tanglekin")
	next_variant.pressed.emit()
	assert_eq(creator.get_current_variant_id(), "people_tanglekin_default")
	next_eyes.pressed.emit()
	assert_eq(creator.get_current_eye_id(), "eyes_tanglekin_dark")
	assert_eq(creator.eye_label.text, "Eyes Tanglekin Dark")
	next_gear.pressed.emit()
	assert_eq(creator.get_current_gear_id(), "apron")
	var old_facing := creator.facing_label.text
	next_facing.pressed.emit()
	assert_ne(creator.facing_label.text, old_facing)


func test_eye_stepper_updates_every_people_profile() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())
	var next_eyes := creator.root.find_child("CreatorNextEyesButton", true, false) as Button

	next_eyes.pressed.emit()
	assert_eq(creator.get_current_eye_id(), "eyes_human_soft")
	assert_eq(creator.eye_label.text, "Eyes Human Soft")
	assert_eq(creator._current_profile()["appearance"]["eye_id"], "eyes_human_soft")

	assert_true(creator.select_people("people_mirefolk"))
	assert_eq(creator.eye_label.text, "Eyes Mirefolk High")
	assert_eq(creator._current_profile()["appearance"]["eye_id"], "eyes_mirefolk_high")


func test_face_part_and_value_steppers_apply_independent_human_face_parts() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())
	var next_part := creator.root.find_child("CreatorNextFacePartButton", true, false) as Button
	var next_value := creator.root.find_child("CreatorNextFaceValueButton", true, false) as Button

	assert_eq(creator.get_current_face_part_id(), "brows")
	next_value.pressed.emit()
	assert_eq(creator.get_current_face_value_id(), "brows_human_arched")
	assert_eq(creator._current_profile()["appearance"]["brow_id"], "brows_human_arched")
	next_part.pressed.emit()
	assert_eq(creator.get_current_face_part_id(), "noses")
	assert_eq(creator.get_current_face_value_id(), "nose_human_small")


func test_body_and_style_steppers_apply_profile_overrides() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())
	var next_body_value := creator.root.find_child("CreatorNextBodyValueButton", true, false) as Button
	var next_body_part := creator.root.find_child("CreatorNextBodyPartButton", true, false) as Button
	var next_style := creator.root.find_child("CreatorNextStyleButton", true, false) as Button

	next_body_value.pressed.emit()
	assert_eq(creator._current_profile()["appearance"]["proportions"]["body_height"], 1.1)
	next_body_part.pressed.emit()
	assert_eq(creator.body_part_label.text, "Shoulders")
	next_style.pressed.emit()
	assert_eq(creator.style_label.text, "Close Crop")
	assert_eq(creator._current_profile()["appearance"]["hair_id"], "hair_close_crop")

	assert_true(creator.select_people("people_tanglekin"))
	next_style.pressed.emit()
	assert_true(
		creator._current_profile()["appearance"]["feature_ids"].has("feature_tanglekin_brow_tuft")
	)


func test_public_preview_uses_players_equipped_items() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())
	creator.open_character_appearance()
	creator.set_public_preview_equipment({"chest": "item_smith_apron"})

	assert_eq(creator._current_gear(), {"chest": "item_smith_apron"})


func test_current_gear_returns_duplicate_preset_data() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())
	var next_gear := creator.root.find_child("CreatorNextGearButton", true, false) as Button
	next_gear.pressed.emit()

	var gear := creator._current_gear()
	gear["chest"] = "changed"

	assert_eq(creator._current_gear()["chest"], "item_smith_apron")


func _creator(content: ContentStub, player) -> DebugCharacterCreator:
	var creator := DebugCharacterCreator.new()
	add_child_autofree(creator)
	creator.setup(content, player)
	return creator
