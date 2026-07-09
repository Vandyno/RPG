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
	assert_eq(creator.get_current_gear_id(), "none")
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


func test_apply_to_player_rejects_missing_player_contract() -> void:
	var creator := _creator(ContentStub.new(), RefCounted.new())

	assert_false(creator.apply_to_player())


func test_stepper_buttons_cycle_people_variant_gear_and_facing() -> void:
	var creator := _creator(ContentStub.new(), PlayerStub.new())
	var next_people := creator.root.find_child("CreatorNextPeopleButton", true, false) as Button
	var next_variant := creator.root.find_child("CreatorNextVariantButton", true, false) as Button
	var next_gear := creator.root.find_child("CreatorNextGearButton", true, false) as Button
	var next_facing := creator.root.find_child("CreatorNextFacingButton", true, false) as Button

	next_people.pressed.emit()
	assert_eq(creator.get_current_people_id(), "people_tanglekin")
	next_variant.pressed.emit()
	assert_eq(creator.get_current_variant_id(), "people_tanglekin_default")
	next_gear.pressed.emit()
	assert_eq(creator.get_current_gear_id(), "apron")
	var old_facing := creator.facing_label.text
	next_facing.pressed.emit()
	assert_ne(creator.facing_label.text, old_facing)


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
