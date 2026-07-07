extends GutTest


func test_getters_return_defensive_copies_and_ids() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.items = {"item_road": {"name": "Roadside Draught", "nested": {"count": 1}}}
	content.readables = {"read_notice": {"title": "Notice"}}
	content.quests = {"quest_missing_tools": {"title": "Missing Tools"}}
	content.npcs = {"npc_harrow": {"name": "Harrow Venn"}}
	content.dialogues = {"dialogue_harrow": {"lines": []}}
	content.locations = {"loc_crossroads": {"name": "Crossroads"}}
	content.factions = {"faction_briarwatch": {"name": "Briarwatch"}}
	content.shops = {"shop_peddler": {"name": "Peddler"}}
	content.status_effects = {"status_resting": {"name": "Resting"}}
	content.spells = {"spell_fire_blast": {"name": "Fire Blast"}}

	var item := content.get_item("item_road")
	item["nested"]["count"] = 99

	assert_true(content.has_item("item_road"))
	assert_true(content.item_ids().has("item_road"))
	assert_eq(content.get_item("item_road")["nested"]["count"], 1)
	assert_eq(content.get_readable("read_notice")["title"], "Notice")
	assert_eq(content.get_quest("quest_missing_tools")["title"], "Missing Tools")
	assert_eq(content.get_npc("npc_harrow")["name"], "Harrow Venn")
	assert_eq(content.get_dialogue("dialogue_harrow")["lines"], [])
	assert_eq(content.get_location("loc_crossroads")["name"], "Crossroads")
	assert_eq(content.get_faction("faction_briarwatch")["name"], "Briarwatch")
	assert_eq(content.get_shop("shop_peddler")["name"], "Peddler")
	assert_eq(content.get_status_effect("status_resting")["name"], "Resting")
	assert_eq(content.get_spell("spell_fire_blast")["name"], "Fire Blast")
	assert_eq(content.get_item("missing"), {})


func test_world_entries_and_terrain_are_defensive_copies() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.world_objects = [{"id": "object_notice", "global_tile": [1, 2]}]
	content.world_terrain = {"chunks": {"0,0": {"tiles": []}}}

	var entries := content.world_object_entries()
	var terrain := content.get_world_terrain()
	entries[0]["id"] = "changed"
	terrain["chunks"]["0,0"]["tiles"].append("changed")

	assert_eq(content.world_object_entries()[0]["id"], "object_notice")
	assert_eq(content.get_world_terrain()["chunks"]["0,0"]["tiles"], [])


func test_people_visual_and_profile_accessors_return_copies() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.character_profiles = {"profile_harrow": {"name": "Harrow", "base": {"height": 1.0}}}
	content.people = {"people_briarwatch": {"name": "Briarwatch"}}
	content.people_visual_models = {"people_briarwatch": {"variants": []}}

	var profile := content.get_authored_character_profile("profile_harrow")
	var people := content.get_people("people_briarwatch")
	var visual := content.get_people_visual_model("people_briarwatch")
	profile["base"]["height"] = 2.0
	people["name"] = "Changed"
	visual["variants"].append("changed")

	assert_true(content.has_character_profile("profile_harrow"))
	assert_true(content.character_profile_ids().has("profile_harrow"))
	assert_eq(content.get_authored_character_profile("profile_harrow")["base"]["height"], 1.0)
	assert_true(content.has_people("people_briarwatch"))
	assert_true(content.people_ids().has("people_briarwatch"))
	assert_eq(content.get_people("people_briarwatch")["name"], "Briarwatch")
	assert_true(content.has_people_visual_model("people_briarwatch"))
	assert_true(content.people_visual_model_ids().has("people_briarwatch"))
	assert_eq(content.get_people_visual_model("people_briarwatch")["variants"], [])


func test_load_helpers_report_missing_or_wrong_json_shape() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	var dictionary_path := "user://content_database_shape_dictionary.json"
	var array_path := "user://content_database_shape_array.json"
	_write_text(dictionary_path, "[1, 2, 3]")
	_write_text(array_path, "{\"id\":\"not_array\"}")

	assert_eq(content._load_dictionary(dictionary_path), {})
	assert_eq(content._load_array(array_path), [])
	assert_eq(content._load_dictionary("user://missing_content_file.json"), {})
	assert_eq(content.load_errors.size(), 3)
	assert_true(content.load_errors[0].contains("Expected dictionary JSON"))
	assert_true(content.load_errors[1].contains("Expected array JSON"))
	assert_true(content.load_errors[2].contains("Missing content file"))


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
