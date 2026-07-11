extends GutTest


func test_validate_accepts_minimal_valid_item_content_groups() -> void:
	var content := _valid_content()
	var errors: Array[String] = []

	ContentItemValidator.validate(content, errors)

	assert_eq(errors, [])


func test_validate_reports_malformed_items_readables_shops_statuses_and_spells() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.items = {
		"item_bad_sword":
		{
			"id": "wrong_id",
			"name": "",
			"max_stack": 0,
			"equipment_slot": "tail",
			"type": "weapon",
			"weapon_attack": "bad",
			"avatar_visual": {"avatar_slot": "head", "visual_layer_id": ""}
		}
	}
	content.readables = {"read_bad": {"id": "read_bad", "title": "", "body": ""}}
	content.shops = {"shop_bad": {"id": "shop_bad", "name": "", "stock": [{}]}}
	content.status_effects = {
		"status_bad": {"id": "status_bad", "name": "", "description": "", "attack_charges": 0}
	}
	content.spells = {"spell_bad": {"id": "spell_bad", "name": "", "mana_cost": 0}}
	var errors: Array[String] = []

	ContentItemValidator.validate(content, errors)
	var joined := "\n".join(errors)

	assert_true(joined.contains("Item item_bad_sword has mismatched id wrong_id"))
	assert_true(joined.contains("Item item_bad_sword is missing name."))
	assert_true(joined.contains("unsupported equipment_slot tail"))
	assert_true(joined.contains("weapon_attack must be a dictionary"))
	assert_true(joined.contains("avatar_slot does not match equipment_slot"))
	assert_true(joined.contains("avatar_visual is missing visual_layer_id"))
	assert_true(joined.contains("Readable read_bad is missing title."))
	assert_true(joined.contains("Shop shop_bad is missing name."))
	assert_true(joined.contains("Shop shop_bad references missing item"))
	assert_true(joined.contains("Status effect status_bad is missing name."))
	assert_true(joined.contains("Spell spell_bad is missing school."))
	assert_true(joined.contains("Spell spell_bad is missing range."))


func _valid_content() -> ContentDatabase:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.items = {
		"item_sword":
		{
			"id": "item_sword",
			"name": "Sword",
			"max_stack": 1,
			"type": "weapon",
			"equipment_slot": "right_hand",
			"weapon_attack": {"attack_interval_seconds": 0.8},
			"avatar_visual":
			{
				"avatar_slot": "right_hand",
				"visual_layer_id": "placeholder_sword",
				"accepted_placeholder": true
			}
		}
	}
	content.readables = {"read_notice": {"id": "read_notice", "title": "Notice", "body": "Read."}}
	content.shops = {
		"shop_peddler":
		{"id": "shop_peddler", "name": "Peddler", "stock": [{"item_id": "item_sword"}]}
	}
	content.status_effects = {
		"status_guard": {
			"id": "status_guard",
			"name": "Guard",
			"description": "Braced.",
			"attack_charges": 1
		}
	}
	content.spells = {
		"spell_fire": {
			"id": "spell_fire",
			"name": "Fire",
			"school": "Fire",
			"mana_cost": 1,
			"range": "6 tiles",
			"behavior": "Burns."
		}
	}
	return content
