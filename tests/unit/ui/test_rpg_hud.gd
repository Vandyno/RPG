# gdlint:disable=max-file-lines
extends GutTest
const EventBus = preload("res://scripts/core/event_bus.gd")
const Main = preload("res://scripts/main/main.gd")
const RpgHud = preload("res://scripts/ui/rpg/rpg_hud.gd")
const RpgEquipmentSlot = preload("res://scripts/ui/controls/slots/rpg_equipment_slot.gd")
const RpgInventoryItemButton = preload(
	"res://scripts/ui/controls/buttons/rpg_inventory_item_button.gd"
)
const RpgAimJoystick = preload("res://scripts/ui/controls/input/rpg_aim_joystick.gd")
const RpgSpellSlot = preload("res://scripts/ui/controls/slots/rpg_spell_slot.gd")

var _hud_state_override := {}

func test_main_uses_player_facing_rpg_hud() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_eq(main.hud.name, "RpgHud")
	assert_true(main.hud is RpgHud)
	assert_eq(main.get_hud_state()["primary_action"], main.get_debug_state()["primary_action"])
	assert_true(main.get_hud_state()["inventory_items"] is Array)
	var system_tabs: Dictionary = main.get_hud_state()["system_tabs"]
	assert_true(system_tabs["inventory"]["items"] is Array)
	assert_true(system_tabs["inventory"]["actions"] is Array)
	assert_true(system_tabs["character"].has("progression"))
	assert_true(system_tabs["quests"].has("directions"))
	assert_true(main.inventory.add_item("item_road_hatchet"))
	var hud_items: Array = main.get_hud_state()["inventory_items"]
	assert_gt(hud_items.size(), 0)
	assert_true(hud_items[0].has("weight"))
	assert_true(hud_items[0].has("value"))
	assert_false(main.get_hud_state().has("player_world"))
	assert_true(main.get_debug_state().has("player_world"))
	assert_true(main.hud.get_state.get_method() == "get_hud_state")
	var inventory_actions: Array = main.get_hud_state()["system_tabs"]["inventory"]["actions"]
	var hatchet_action_has_item_id := false
	for action in inventory_actions:
		if (
			action is Dictionary
			and String(action.get("id", "")) == "equip:item_road_hatchet"
			and String(action.get("item_id", "")) == "item_road_hatchet"
		):
			hatchet_action_has_item_id = true
	assert_true(hatchet_action_has_item_id)

func test_rpg_hud_adds_mockup_style_navigation_without_debug_prompt() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	assert_false(hud.prompt_panel.visible)
	assert_true(hud.location_banner_panel.visible)
	assert_eq(hud.location_banner_label.text, "Briarwatch")
	assert_true(hud.top_nav_panel.visible)
	assert_eq(
		_button_texts(hud.top_nav_buttons),
		["Quests", "Journal", "Menu"]
	)
	assert_true(hud.status_label.text.contains("Adventurer"))
	assert_true(hud.status_label.text.contains("Level 2"))
	assert_false(hud.status_label.text.contains("Quest:"))
	assert_false(hud.status_label.text.contains("Briarwatch  Day"))
	assert_false(hud.debug_panel.visible)
	hud.toggle_debug()
	assert_false(hud.debug_panel.visible)

	var screen := Rect2(Vector2.ZERO, Vector2(1152, 648))
	var status_rect := _top_left_rect(hud.status_panel)
	var banner_rect := _center_top_rect(hud.location_banner_panel, Vector2(1152, 648))
	var nav_rect := _right_rect(hud.top_nav_panel, Vector2(1152, 648))
	var message_rect := _bottom_left_rect(hud.message_panel, Vector2(1152, 648))

	assert_true(_rect_inside(status_rect, screen), "Status panel should stay on screen.")
	assert_true(_rect_inside(banner_rect, screen), "Location banner should stay on screen.")
	assert_true(_rect_inside(nav_rect, screen), "Top nav should stay on screen.")
	assert_false(status_rect.intersects(banner_rect), "Status should not cover location.")
	assert_false(banner_rect.intersects(nav_rect), "Location should not cover nav.")
	assert_false(nav_rect.intersects(message_rect), "Top nav should not cover messages.")

func test_rpg_hud_top_nav_controls_real_systems_panel() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	_press_nav(hud, "Quests")
	assert_true(hud.is_systems_panel_visible())
	assert_eq(hud.get_systems_tab(), "quests")

	_press_nav(hud, "Journal")
	assert_true(hud.is_systems_panel_visible())
	assert_eq(hud.get_systems_tab(), "journal")

	hud.hide_systems_panel()
	_press_nav(hud, "Menu")
	assert_true(hud.is_systems_panel_visible())

func test_rpg_systems_menu_has_spells_between_inventory_and_character() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("spells")

	assert_eq(hud.get_systems_tab(), "spells")
	assert_eq(
		_button_texts(hud.systems_nav),
		["Inventory", "Spells", "Character", "Quests", "Journal", "Trade"]
	)
	assert_eq(hud.systems_subtitle_label.text, "Spells - Known magic and assigned abilities.")
	assert_eq(hud.systems_detail_title_label.text, "Spell Details")
	assert_true(hud.systems_spell_slot_panel.visible)
	assert_false(hud.systems_detail_equipment_panel.visible)
	assert_eq(
		(hud.systems_spell_slot_panel.find_child("SystemsSpellSlotTitle", true, false) as Label).text,
		"Ability Slots"
	)
	var fire := _button_containing(hud.systems_item_list, "Fire Blast")
	assert_not_null(fire)
	assert_true(fire.text.contains("Fire school"))
	assert_true(hud.systems_detail_label.text.contains("Mana cost/drain: 8 per second"))
	assert_true(hud.systems_detail_label.text.contains("Range: 6 tiles"))
	assert_true(hud.systems_detail_label.text.contains("flamethrower"))
	assert_true(hud.systems_detail_label.text.contains("Assigned slot:"))

func test_rpg_spell_drag_drop_assigns_ability_slot_and_updates_hud_buttons() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("spells")
	var emitted: Array[String] = []
	hud.inventory_item_selected.connect(func(action_id: String) -> void: emitted.append(action_id))

	var fire := _button_containing(hud.systems_item_list, "Fire Blast") as RpgInventoryItemButton
	var slot := hud.systems_spell_slot_buttons["ability_1"] as RpgSpellSlot
	assert_not_null(fire)
	assert_not_null(slot)
	var drag: Variant = fire._get_drag_data(Vector2.ZERO)
	assert_true(slot._can_drop_data(Vector2.ZERO, drag))
	slot._drop_data(Vector2.ZERO, drag)
	assert_eq(emitted, ["assign_spell:spell_fire_blast:ability_1"])
	emitted.clear()
	var slot_2 := hud.systems_spell_slot_buttons["ability_2"] as RpgSpellSlot
	assert_not_null(slot_2)
	slot_2.pressed.emit()
	assert_eq(emitted, ["assign_spell:spell_fire_blast:ability_2"])

	hud.refresh()
	var ability := hud.ability_slot_buttons["ability_1"] as Button
	assert_true(ability.text.contains("Fire"))
	assert_true(ability.text.contains("5"))
	assert_true(ability.tooltip_text.contains("Fire Blast"))
	assert_true((hud.ability_slot_buttons["ability_2"] as Button).text.contains("II"))
	assert_false((hud.ability_slot_buttons["ability_2"] as Button).text.contains("Empty"))
	assert_true((hud.ability_slot_buttons["ability_2"] as Button).tooltip_text.contains("Empty"))
func test_rpg_hud_disables_player_facing_target_picker() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))

	var used_targets: Array[String] = []
	var sneak_events := []
	hud.target_used.connect(func(entity_id: String) -> void: used_targets.append(entity_id))
	hud.sneak_pressed.connect(func() -> void: sneak_events.append("sneak"))
	hud.toggle_target_picker()

	assert_false(hud.is_target_picker_visible())
	assert_null(hud.target_panel)
	assert_eq(used_targets, [])
	assert_true(hud.action_buttons.visible)
	assert_true(hud.move_pad.visible)

	assert_eq(hud.target_action_button.text, "Sneak")
	hud.target_action_button.pressed.emit()
	assert_eq(sneak_events, ["sneak"])
	assert_false(hud.is_target_picker_visible())
	assert_true(hud.action_buttons.visible)
	assert_true(hud.move_pad.visible)

func test_rpg_move_pad_is_joystick_style_and_routes_touch_vector() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))

	assert_not_null(hud.move_pad.get_node("MovePadOuterRing"))
	assert_not_null(hud.move_pad.get_node("MovePadInnerWell"))
	assert_not_null(hud.move_pad.get_node("MoveKnob"))
	for child in hud.move_pad.get_children():
		assert_false(child is Button, "RPG movement pad should not expose debug D-pad buttons.")

	var vectors: Array[Vector2] = []
	hud.move_vector_changed.connect(func(direction: Vector2) -> void: vectors.append(direction))
	var press := InputEventMouseButton.new()
	press.pressed = true
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = Vector2(128, 128)
	hud._on_move_pad_gui_input(press)
	assert_eq(hud.get_touch_move_vector(), Vector2(1, 1).normalized())
	assert_eq(vectors[0], Vector2(1, 1).normalized())

	var release := InputEventMouseButton.new()
	release.pressed = false
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(128, 128)
	hud._on_move_pad_gui_input(release)
	assert_eq(hud.get_touch_move_vector(), Vector2.ZERO)
	assert_eq(vectors[-1], Vector2.ZERO)


func test_rpg_action_cluster_uses_player_facing_commands_and_routes_actions() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	assert_eq(_button_texts(hud.action_buttons), ["Attack"])
	assert_eq(hud.action_buttons.offset_right, -12.0)
	assert_eq(hud.action_buttons.offset_bottom, -12.0)
	assert_eq(hud.primary_action_button.get_meta("action_role"), "primary")
	assert_eq(hud.primary_action_button.get_meta("action_shape"), "aim_joystick_primary")
	assert_eq(hud.primary_action_button.get_meta("action_kind"), "attack")
	assert_true(hud.primary_action_button is RpgAimJoystick)
	var ability := hud.ability_slot_buttons["ability_1"] as RpgAimJoystick
	assert_not_null(ability)
	assert_eq(ability.get_meta("action_kind"), "ability_1")
	assert_eq(ability.get_meta("action_shape"), "aim_joystick_ability")
	assert_gt(
		hud.primary_action_button.custom_minimum_size.x,
		ability.custom_minimum_size.x
	)
	assert_gt(
		hud.primary_action_button.custom_minimum_size.y,
		ability.custom_minimum_size.y
	)
	assert_gt(hud.primary_action_button.position.x, ability.position.x)

	var interact_events := []
	var cycle_events := []
	var sneak_events := []
	hud.interact_pressed.connect(func() -> void: interact_events.append("interact"))
	hud.cycle_target_pressed.connect(func() -> void: cycle_events.append("cycle"))
	hud.sneak_pressed.connect(func() -> void: sneak_events.append("sneak"))
	var aim_events: Array[Dictionary] = []
	var utility_events: Array[String] = []
	hud.inventory_item_selected.connect(
		func(action_id: String) -> void: utility_events.append(action_id)
	)
	hud.aim_action_released.connect(
		func(action_id: String, direction: Vector2) -> void:
			aim_events.append({"action_id": action_id, "direction": direction})
	)

	var utility_stack := hud.action_buttons.find_child("UtilityButtonStack", true, false)
	var ability_stack := hud.action_buttons.find_child("AbilityButtonStack", true, false)
	assert_not_null(utility_stack)
	assert_not_null(ability_stack)
	assert_eq(hud.action_buttons.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(ability_stack.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	var weapon_swap := utility_stack.find_child("WeaponSwapButton", true, false) as Button
	var sneak := utility_stack.find_child("SneakButton", true, false) as Button
	var menu := utility_stack.find_child("MenuButton", true, false) as Button
	assert_not_null(weapon_swap)
	assert_not_null(sneak)
	assert_null(utility_stack.find_child("InventoryButton", true, false))
	assert_null(utility_stack.find_child("TargetButton", true, false))
	assert_eq(hud.target_action_button, sneak)

	weapon_swap.pressed.emit()
	assert_eq(utility_events, ["swap_mainhand:weapon"])
	assert_false(hud.is_systems_panel_visible())
	menu.pressed.emit()
	assert_true(hud.is_systems_panel_visible())

	hud.hide_systems_panel()
	var attack := hud.primary_action_button as RpgAimJoystick
	attack._start_aim(Vector2.ZERO)
	attack._finish_aim(Vector2(32, 0))
	assert_eq(aim_events[0]["action_id"], "attack")
	assert_eq(aim_events[0]["direction"], Vector2.RIGHT)
	assert_eq(interact_events, [])

	sneak.pressed.emit()
	assert_eq(sneak_events, ["sneak"])
	assert_eq(cycle_events, [])
	assert_false(hud.is_target_picker_visible())
	ability._start_aim(Vector2.ZERO)
	ability._finish_aim(Vector2(0, -32))
	assert_eq(aim_events[1]["action_id"], "ability_1")
	assert_eq(aim_events[1]["direction"], Vector2.UP)

	var touch_press := InputEventScreenTouch.new()
	touch_press.index = 0
	touch_press.pressed = true
	touch_press.position = Vector2.ZERO
	ability._gui_input(touch_press)
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 0
	touch_drag.position = Vector2(0, 32)
	ability._gui_input(touch_drag)
	var touch_release := InputEventScreenTouch.new()
	touch_release.index = 0
	touch_release.pressed = false
	touch_release.position = Vector2(0, 32)
	ability._gui_input(touch_release)
	assert_eq(aim_events[2]["action_id"], "ability_1")
	assert_eq(aim_events[2]["direction"], Vector2.DOWN)


func test_rpg_quick_actions_use_player_facing_strip_and_route_actions() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))

	var context_actions: Array[String] = []
	hud.context_action_selected.connect(
		func(action_id: String) -> void: context_actions.append(action_id)
	)

	hud._refresh_context_actions(
		{
			"nearby": "Harrow Venn",
			"context_actions":
			[
				{"id": "dialogue:accept", "text": "I'll find it."},
				{"id": "forge:sharpen", "text": "Sharpen Road Hatchet"},
				{"id": "trade:shop_crossroads_peddler", "text": "Trade"}
			]
		}
	)
	assert_true(hud.context_action_panel.visible)
	assert_eq(
		(hud.context_action_panel.find_child("QuickActionTitle", true, false) as Label).text,
		"Harrow Venn"
	)
	var screen := Rect2(Vector2.ZERO, Vector2(640, 360))
	var quick_rect := _anchored_rect(hud.context_action_panel, Vector2(640, 360))
	assert_true(_rect_inside(quick_rect, screen))
	for action_rect in _visible_button_rects(hud.action_buttons):
		assert_false(quick_rect.intersects(action_rect))
	assert_false(quick_rect.intersects(_anchored_rect(hud.move_pad, Vector2(640, 360))))
	assert_false(quick_rect.intersects(_anchored_rect(hud.message_panel, Vector2(640, 360))))
	var accept := _button_containing(hud.context_action_buttons, "I'll find it.")
	assert_not_null(accept)
	assert_true(accept.text.contains("Dialogue"))
	assert_gte(accept.custom_minimum_size.x, 104.0)
	assert_gte(accept.custom_minimum_size.y, 44.0)
	accept.pressed.emit()
	assert_eq(context_actions, ["dialogue:accept"])

	hud._refresh_context_actions({"combat_actions": [{"id": "guard", "text": "Guard"}]})
	assert_false(hud.context_action_panel.visible)
	assert_null(_button_containing(hud.context_action_buttons, "Guard"))

func test_rpg_content_panel_uses_bottom_dialogue_structure_and_routes_choices() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	var selected_choices: Array[String] = []
	hud.content_choice_selected.connect(
		func(choice_id: String) -> void: selected_choices.append(choice_id)
	)
	hud.show_content_card(
		"Harrow Venn",
		"Evening. You look like someone who gets their hands dirty.",
		[
			{
				"id": "ask_tools",
				"text": "Ask about tools",
				"response": "Harrow needs the old toolbox from the west road."
			},
			{
				"id": "accept_tools",
				"text": "I'll find it.",
				"effects": [{"type": "start_quest", "quest_id": "quest_missing_tools"}]
			},
			{"id": "leave", "text": "Leave"}
		],
		"dialogue"
	)

	assert_true(hud.is_content_card_visible())
	assert_eq(hud.content_kind_label.text, "Dialogue")
	assert_eq(hud.content_title_label.text, "Harrow Venn")
	assert_true(hud.content_body_label.text.contains("hands dirty"))
	assert_eq(hud.content_scroll.get_child(0), hud.content_body_label)
	assert_true(hud.content_identity_panel.visible)
	assert_true(hud.content_portrait_panel.visible)
	assert_eq(hud.content_portrait_label.text, "")
	assert_true(hud.content_preview_panel.visible)
	var preview_title := hud.content_preview_panel.find_child(
		"ContentPreviewTitle", true, false
	) as Label
	var preview_rewards := hud.content_preview_panel.find_child(
		"ContentPreviewRewards", true, false
	) as Label
	assert_not_null(preview_title)
	assert_not_null(preview_rewards)
	assert_eq(preview_title.text, "Quest: Missing Tools")
	assert_true(hud.content_preview_label.text.contains("I'll find it."))
	assert_true(preview_rewards.text.contains("Starts quest"))
	assert_false(hud.move_pad.visible)
	assert_false(hud.action_buttons.visible)
	assert_false(hud.message_panel.visible)
	var ask_button := _button_containing(hud.content_choice_list, "Ask about tools")
	assert_not_null(ask_button)
	assert_true(ask_button.text.contains("Learn more before acting."))
	var accept_button := _button_containing(hud.content_choice_list, "I'll find it.")
	assert_not_null(accept_button)
	assert_true(accept_button.text.contains("Starts quest"))
	assert_true((accept_button as Button).text.contains("\n"))

	ask_button.pressed.emit()
	assert_eq(selected_choices, ["ask_tools"])

	var close_events: Array[String] = []
	hud.content_card_closed.connect(func() -> void: close_events.append("closed"))
	var close_button := hud.content_panel.find_child("ContentCloseButton", true, false) as Button
	assert_not_null(close_button)
	assert_eq(close_button.text, "Leave")
	assert_false(close_button.visible)
	var leave_button := _button_containing(hud.content_choice_list, "Leave")
	assert_not_null(leave_button)
	leave_button.pressed.emit()
	assert_false(hud.is_content_card_visible())
	assert_true(hud.move_pad.visible)
	assert_true(hud.action_buttons.visible)
	assert_eq(close_events, ["closed"])


func test_rpg_content_panel_uses_readable_mode_without_empty_choice_lane() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	hud.show_content_card(
		"Road Notice",
		"Boundary stones are not to be moved.",
		[],
		"readable"
	)

	assert_true(hud.is_content_card_visible())
	assert_eq(hud.content_kind_label.text, "Readable")
	assert_eq(hud.content_portrait_label.text, "")
	assert_false(hud.content_choice_panel.visible)
	var close_button := hud.content_panel.find_child("ContentCloseButton", true, false) as Button
	assert_not_null(close_button)
	assert_eq(close_button.text, "Close")
	assert_eq(close_button.tooltip_text, "Close panel")
	assert_eq(close_button.get_parent(), hud.content_portrait_panel.get_parent())
	assert_false(hud.content_preview_panel.visible)
	assert_false(hud.content_right_stack.visible)


func test_rpg_systems_menu_uses_full_screen_player_facing_structure() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	var screen := Rect2(Vector2.ZERO, Vector2(1152, 648))
	var menu_rect := _anchored_rect(hud.systems_panel, Vector2(1152, 648))
	assert_true(hud.is_systems_panel_visible())
	assert_true(_rect_inside(menu_rect, screen), "Systems menu should stay on screen.")
	assert_gt(hud.systems_panel.z_index, hud.top_nav_panel.z_index)
	assert_gt(hud.systems_panel.z_index, hud.action_buttons.z_index)
	assert_gte(menu_rect.size.x, 1100.0)
	assert_gte(menu_rect.size.y, 600.0)
	assert_eq(hud.systems_title_label.text, "Briarwatch")
	assert_true(hud.systems_subtitle_label.text.contains("Inventory"))
	assert_true(hud.systems_subtitle_label.text.contains("Gear"))
	assert_true(hud.systems_resources_label.text.contains("D1, 16:00"))
	assert_true(hud.systems_resources_label.text.contains("Gold"))
	assert_true(hud.systems_resources_label.text.contains("Carry"))
	assert_eq(_button_texts(hud.systems_nav), [
		"Inventory", "Spells", "Character", "Quests", "Journal", "Trade"
	])
	assert_false(hud.systems_body_label.visible)
	assert_eq(
		_button_texts(hud.systems_category_row),
		["All", "Weapons", "Armour", "Ingredients", "Misc", "Quest"]
	)
	var toolbox_row := _button_containing(hud.systems_item_list, "Old Toolbox")
	assert_not_null(toolbox_row)
	assert_true(toolbox_row is RpgInventoryItemButton)
	assert_false(toolbox_row.text.begins_with("Q  "))
	assert_eq(toolbox_row.get_meta("item_id"), "item_old_toolbox")
	assert_true(toolbox_row.text.contains("Count 1"))
	assert_true(toolbox_row.text.contains("5 wt"))
	assert_true(hud.systems_body_label.text.contains("Old Toolbox x1"))
	assert_true(hud.systems_detail_label.text.contains("Weight: 5"))
	assert_true(hud.systems_detail_label.text.contains("A heavy wooden toolbox"))
	assert_false(hud.systems_detail_equipment_panel.visible)
	assert_true(hud.systems_character_panel.visible)
	assert_not_null(_button_containing(hud.systems_character_panel, "Road Hatchet"))
	assert_not_null(_button_containing(hud.systems_character_panel, "Empty"))
	var hatchet_row := _button_containing(hud.systems_item_list, "Road Hatchet")
	assert_not_null(hatchet_row)
	assert_false(hatchet_row.text.begins_with("W  "))
	assert_true(hatchet_row.text.contains("1.6 wt"))
	assert_true(hatchet_row.text.contains("18g"))
	assert_not_null(_button_containing(hud.systems_character_panel, "Vitals"))
	assert_not_null(_button_containing(hud.systems_character_panel, "Training"))
	var equipment_row := _button_containing(hud.systems_character_panel, "Equipment")
	assert_not_null(equipment_row)
	assert_true(equipment_row.text.contains("Weapon: Road Hatchet"))
	assert_not_null(_button_containing(hud.systems_action_list, "Use Roadside Draught"))

	_press_category(hud, "Weapons")
	var weapon_hatchet_row := _button_containing(hud.systems_item_list, "Road Hatchet")
	assert_not_null(weapon_hatchet_row)
	assert_eq(weapon_hatchet_row.get_meta("item_id"), "item_road_hatchet")
	assert_eq(weapon_hatchet_row.get_meta("equipment_slot"), "right_hand")
	assert_null(_button_containing(hud.systems_item_list, "Old Toolbox"))
	_press_category(hud, "Armour")
	assert_not_null(_button_containing(hud.systems_item_list, "Traveler Buckler"))
	_press_category(hud, "Ingredients")
	assert_not_null(_button_containing(hud.systems_item_list, "River Mint"))
	_press_category(hud, "Misc")
	assert_not_null(_button_containing(hud.systems_item_list, "Roadside Draught"))
	_press_category(hud, "Quest")
	assert_not_null(_button_containing(hud.systems_item_list, "Old Toolbox"))
	assert_null(_button_containing(hud.systems_item_list, "Road Hatchet"))

	hud.set_systems_tab("quests")
	assert_eq(hud.systems_title_label.text, "Briarwatch")
	assert_true(hud.systems_subtitle_label.text.contains("Quests"))
	assert_eq(hud.systems_detail_title_label.text, "Quest Details")
	assert_eq(_button_texts(hud.systems_category_row), ["Active", "Routes", "Rewards"])
	assert_not_null(_button_containing(hud.systems_item_list, "The Missing Tools"))
	assert_true(hud.systems_detail_label.text.contains("The Missing Tools"))
	assert_not_null(_button_containing(hud.systems_action_list, "Target Harrow Venn"))

	hud.set_systems_tab("map")
	assert_eq(hud.get_systems_tab(), "journal")
	assert_false(hud.systems_tab_buttons.has("map"))

	hud.set_systems_tab("journal")
	assert_eq(hud.systems_title_label.text, "Briarwatch")
	assert_true(hud.systems_subtitle_label.text.contains("Journal"))
	assert_eq(hud.systems_detail_title_label.text, "Journal Details")
	assert_eq(_button_texts(hud.systems_category_row), ["Recent", "Factions", "Time", "System"])
	assert_not_null(_button_containing(hud.systems_item_list, "Recent Events"))
	assert_not_null(_button_containing(hud.systems_action_list, "Wait 1h"))
	assert_not_null(_button_containing(hud.systems_action_list, "Save Game"))
	var time_summary := hud.systems_item_list.find_child("SystemsRow_JournalTime", false, false)
	assert_true(time_summary == null or not time_summary.visible)
	_press_category(hud, "Factions")
	assert_not_null(_button_containing(hud.systems_item_list, "Reputation"))
	_press_category(hud, "Time")
	assert_not_null(_button_containing(hud.systems_item_list, "Wait 1h"))
	_press_category(hud, "System")
	assert_not_null(_button_containing(hud.systems_action_list, "Save Game"))
	assert_not_null(_button_containing(hud.systems_action_list, "Load Game"))

	hud.set_systems_tab("trade")
	assert_eq(_button_texts(hud.systems_category_row), ["Stock", "Buy", "Sell"])
	assert_null(hud.systems_item_list.find_child("SystemsRow_TradeMerchant", false, false))
	var draught_row := _button_containing(hud.systems_item_list, "Roadside Draught")
	assert_not_null(draught_row)
	assert_true(draught_row.text.contains("Buy Roadside Draught"))
	assert_true(draught_row.text.contains("Crossroads Peddler"))
	assert_eq(draught_row.get_meta("action_id"), "buy:item_roadside_draught")
	assert_true(draught_row.text.contains("8g"))
	assert_false(draught_row.text.contains("Trade\nTrade"))
	assert_null(_button_containing(hud.systems_item_list, "Nothing to Sell"))
	assert_true(hud.systems_detail_label.text.contains("Buy offer"))
	assert_true(hud.systems_detail_label.text.contains("Tap this row to buy."))
	_press_category(hud, "Sell")
	assert_not_null(_button_containing(hud.systems_item_list, "Nothing to Sell"))
	assert_false(hud.systems_detail_equipment_panel.visible)

	hud.set_systems_tab("character")
	assert_true(hud.systems_character_panel.visible)
	assert_false(hud.systems_detail_equipment_panel.visible)
	var training_row := _button_containing(hud.systems_item_list, "Training")
	assert_not_null(training_row)
	assert_not_null(_button_containing(hud.systems_item_list, "Vitals"))
	assert_true(hud.systems_detail_label.text.contains("Current Health"))
	assert_false(training_row.text.contains("Training    Progression"))
	assert_true(training_row.text.contains("Progression - "))
	_press_category(hud, "Gear")
	assert_null(_button_containing(hud.systems_item_list, "Training"))
	assert_not_null(_button_containing(hud.systems_item_list, "Equipment"))
	assert_true(hud.systems_detail_label.text.contains("Drag gear onto body slots"))


func test_empty_inventory_and_quests_do_not_create_fake_rows() -> void:
	var state := _sample_state()
	state["inventory"] = "empty"
	state["inventory_items"] = []
	state["inventory_details"] = ""
	state["inventory_actions"] = []
	state["quests"] = []
	state["quest_target_actions"] = []
	state["quest_directions"] = "none"
	var hud := _new_hud(state)
	hud._apply_layout_for_size(Vector2(1152, 648))

	hud.show_systems_panel("inventory")
	assert_null(_button_containing(hud.systems_item_list, "Pack Empty"))
	assert_null(_button_containing(hud.systems_item_list, "No Inventory"))
	assert_true(hud.systems_detail_label.text.contains("Select an item"))

	hud.set_systems_tab("quests")
	assert_null(_button_containing(hud.systems_item_list, "No Active Quests"))
	assert_true(hud.systems_detail_label.text.contains("No active quests"))


func test_inventory_rows_do_not_invent_missing_item_actions() -> void:
	var state := _sample_state()
	state["inventory_actions"] = [
		{
			"id": "use:item_roadside_draught",
			"item_id": "item_roadside_draught",
			"text": "Use Roadside Draught"
		}
	]
	var hud := _new_hud(state)
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	var emitted: Array[String] = []
	hud.inventory_item_selected.connect(func(action_id: String) -> void: emitted.append(action_id))
	var hatchet_row := _button_containing(hud.systems_item_list, "Road Hatchet")
	assert_not_null(hatchet_row)
	assert_eq(String(hatchet_row.get_meta("action_id", "")), "")
	hatchet_row.pressed.emit()
	assert_true(emitted.is_empty())


func test_transfer_rows_emit_after_completed_click() -> void:
	var state := _sample_state()
	state["transfer_open"] = true
	state["transfer_target"] = {"owner_id": "char_harrow_venn", "name": "Harrow Venn"}
	state["transfer_player_items"] = []
	state["transfer_target_items"] = [
		{
			"item_id": "item_gold_coin",
			"name": "Gold Coin",
			"count": 1,
			"type": "currency",
			"tags": [],
			"value": 1,
			"weight": 0.0
		}
	]
	var hud := _new_hud(state)
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	var emitted: Array[String] = []
	hud.inventory_item_selected.connect(func(action_id: String) -> void: emitted.append(action_id))
	var take_gold := hud.systems_item_list.find_child(
		"TransferTake_ItemGoldCoin", true, false
	) as Button
	assert_not_null(take_gold)

	take_gold.button_down.emit()
	await get_tree().process_frame
	assert_true(emitted.is_empty())

	take_gold.pressed.emit()
	await get_tree().process_frame
	assert_eq(emitted, ["take:item_gold_coin"])


func test_rpg_systems_menu_shows_right_character_pane_on_wide_desktop() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1920, 1080))
	hud.show_systems_panel("inventory")

	assert_true(hud.systems_character_panel.visible)
	assert_false(hud.systems_detail_equipment_panel.visible)
	var right_hand := hud.systems_character_panel.find_child(
		"EquipmentSlot_RightHand", true, false
	) as RpgEquipmentSlot
	assert_not_null(right_hand)
	assert_true(right_hand.text.contains("Road Hatchet"))


func test_rpg_equipment_slots_accept_dropped_items_and_route_equip_action() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	var emitted: Array[String] = []
	hud.inventory_item_selected.connect(func(action_id: String) -> void: emitted.append(action_id))
	var right_hand := hud.systems_character_panel.find_child(
		"EquipmentSlot_RightHand", true, false
	) as RpgEquipmentSlot
	var left_hand := hud.systems_character_panel.find_child(
		"EquipmentSlot_LeftHand", true, false
	) as RpgEquipmentSlot
	assert_not_null(right_hand)
	assert_not_null(left_hand)
	var hatchet_drag := {
		"type": "inventory_item",
		"item_id": "item_road_hatchet",
		"equipment_slot": "right_hand"
	}

	assert_true(right_hand._can_drop_data(Vector2.ZERO, hatchet_drag))
	assert_false(left_hand._can_drop_data(Vector2.ZERO, hatchet_drag))
	right_hand._drop_data(Vector2.ZERO, hatchet_drag)
	assert_eq(emitted, ["equip_slot:item_road_hatchet:right_hand"])


func test_rpg_systems_menu_keeps_same_structure_on_compact_landscape() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))
	hud.show_systems_panel("inventory")

	var screen := Rect2(Vector2.ZERO, Vector2(640, 360))
	var menu_rect := _anchored_rect(hud.systems_panel, Vector2(640, 360))
	assert_true(_rect_inside(menu_rect, screen), "Compact systems menu should stay on screen.")
	assert_gte(menu_rect.size.x, 600.0)
	assert_true(hud.systems_detail_panel.visible)
	assert_false(hud.systems_character_panel.visible)
	assert_true(hud.systems_left_panel.visible)
	assert_true(hud.systems_center_panel.visible)
	assert_true(hud.systems_category_row.visible)
	assert_true(hud.systems_category_row is HFlowContainer)
	assert_true(hud.systems_item_list.visible)
	assert_lte(hud.systems_left_panel.custom_minimum_size.x, 112.0)
	assert_gte(hud.systems_detail_panel.custom_minimum_size.x, 184.0)
	assert_eq((hud.systems_tab_buttons["inventory"] as Button).custom_minimum_size, Vector2(92, 38))
	var compact_neck := _button_containing(hud.systems_detail_panel, "Neck")
	var compact_right := _button_containing(hud.systems_detail_panel, "R Hand")
	assert_not_null(compact_neck)
	assert_not_null(compact_right)
	assert_gte(hud.systems_detail_equipment_panel.custom_minimum_size.y, 156.0)
	assert_eq(hud.systems_detail_label.size_flags_vertical, Control.SIZE_SHRINK_BEGIN)
	assert_true((compact_neck as Button).text.contains("Empty"))
	assert_true((compact_right as Button).text.contains("Road Hatchet"))
	assert_gte((compact_right as Button).custom_minimum_size.x, 72.0)
	assert_gte((compact_right as Button).custom_minimum_size.y, 52.0)


func test_rpg_hud_keeps_same_chrome_on_compact_landscape() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))
	hud.show_content_card(
		"Road Notice",
		"Boundary stones are not to be moved.",
		[
			{"id": "accept", "text": "Accept"},
			{"id": "inspect", "text": "Inspect notice"},
			{"id": "note", "text": "Make note"},
			{"id": "close", "text": "Close"}
		],
		"readable"
	)

	assert_false(hud.prompt_panel.visible)
	assert_true(hud.location_banner_panel.visible)
	assert_true(hud.top_nav_panel.visible)
	assert_false(hud.message_panel.visible)
	assert_true(hud.status_label.text.contains("Lv 2  XP 10/40"))
	assert_false(hud.status_label.text.contains("Points"))
	assert_false(hud.status_label.text.contains("Quest:"))

	var screen := Rect2(Vector2.ZERO, Vector2(640, 360))
	var status_rect := _top_left_rect(hud.status_panel)
	var message_rect := _anchored_rect(hud.message_panel, Vector2(640, 360))
	var action_rect := _anchored_rect(hud.action_buttons, Vector2(640, 360))
	var move_rect := _anchored_rect(hud.move_pad, Vector2(640, 360))
	var content_rect := _anchored_rect(hud.content_panel, Vector2(640, 360))
	assert_true(_rect_inside(status_rect, screen), "Compact status should stay on screen.")
	assert_true(_rect_inside(message_rect, screen), "Compact messages should stay on screen.")
	assert_true(_rect_inside(action_rect, screen), "Compact actions should stay on screen.")
	assert_true(_rect_inside(content_rect, screen), "Compact content should stay on screen.")
	assert_gte(content_rect.size.y, 320.0)
	assert_false(status_rect.intersects(message_rect), "Compact top panels should not overlap.")
	assert_false(action_rect.intersects(move_rect), "Actions should not cover movement.")
	assert_true(content_rect.intersects(action_rect), "Content should own the bottom action lane.")
	assert_false(hud.action_buttons.visible)
	assert_false(hud.move_pad.visible)
	assert_true(hud.content_identity_panel.visible)
	assert_true(hud.content_portrait_panel.visible)
	assert_true(hud.content_preview_panel.visible)
	assert_true(hud.content_preview_label.visible)
	assert_false(hud.content_preview_reward_label.visible)
	assert_true(hud.content_preview_label.text.contains("Choose this response."))
	assert_false(hud.content_preview_title_label.text.is_empty())
	assert_gte(hud.content_identity_panel.custom_minimum_size.x, 108.0)
	assert_gte(hud.content_right_stack.custom_minimum_size.x, 190.0)
	assert_lte(hud.content_body_label.get_theme_font_size("font_size"), 16)
	assert_lte(hud.content_preview_label.get_theme_font_size("font_size"), 10)
	var accept_button := _button_containing(hud.content_choice_list, "Accept") as Button
	assert_not_null(accept_button)
	assert_gte(accept_button.custom_minimum_size.y, 48.0)
	assert_gte(accept_button.get_theme_font_size("font_size"), 12)


func _new_hud(state_override: Dictionary = {}) -> RpgHud:
	_hud_state_override = state_override
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := RpgHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_hud_state"))
	return hud


func _hud_state() -> Dictionary:
	return _hud_state_override if not _hud_state_override.is_empty() else _sample_state()


func _sample_state() -> Dictionary:
	return {
		"player_health": "76/100",
		"player_health_value": 76,
		"player_max_health": 100,
		"player_mana": "100/100",
		"player_mana_value": 100,
		"player_max_mana": 100,
		"terrain": "grass",
		"nearby": "Harrow Venn",
		"target_kind": "npc",
		"primary_action": "Talk",
		"locations": "Briarwatch Crossroads",
		"quests": ["The Missing Tools: Return the toolbox to Harrow Venn."],
		"inventory":
		(
			"Old Toolbox x1, Road Hatchet x1, Traveler Buckler x1, "
			+ "River Mint x2, Roadside Draught x1"
		),
		"inventory_items":
		[
			{
				"item_id": "item_old_toolbox",
				"name": "Old Toolbox",
				"count": 1,
				"type": "quest_item",
				"tags": ["quest"],
				"value": 0,
				"weight": 5.0,
				"description": "A heavy wooden toolbox."
			},
			{
				"item_id": "item_road_hatchet",
				"name": "Road Hatchet",
				"count": 1,
				"type": "weapon",
				"tags": ["weapon"],
				"equipment_slot": "right_hand",
				"value": 18,
				"weight": 1.6,
				"description": "A short iron hatchet."
			},
			{
				"item_id": "item_traveler_buckler",
				"name": "Traveler Buckler",
				"count": 1,
				"type": "shield",
				"tags": ["shield"],
				"equipment_slot": "left_hand",
				"value": 16,
				"weight": 2.5,
				"description": "A scarred round shield."
			},
			{
				"item_id": "item_river_mint",
				"name": "River Mint",
				"count": 2,
				"type": "ingredient",
				"tags": ["ingredient"],
				"value": 2,
				"weight": 0.1,
				"description": "Bright mint used in roadside tonics."
			},
			{
				"item_id": "item_roadside_draught",
				"name": "Roadside Draught",
				"count": 1,
				"type": "consumable",
				"tags": ["consumable"],
				"value": 12,
				"weight": 0.3,
				"description": "A bitter green tonic."
			}
		],
		"inventory_details":
		(
			"Old Toolbox x1: A heavy wooden toolbox.\n"
			+ "Road Hatchet x1: A short iron hatchet.\n"
			+ "Traveler Buckler x1: A scarred round shield.\n"
			+ "River Mint x2: Bright mint used in roadside tonics.\n"
			+ "Roadside Draught x1: A bitter green tonic."
		),
		"inventory_actions":
		[
			{
				"id": "use:item_roadside_draught",
				"item_id": "item_roadside_draught",
				"text": "Use Roadside Draught"
			},
			{
				"id": "equip:item_road_hatchet",
				"item_id": "item_road_hatchet",
				"text": "Equip Road Hatchet"
			}
		],
		"equipment": "Weapon: Road Hatchet\nOffhand: empty\nBody: empty",
		"equipment_slots":
		{
			"head": {"label": "Head", "item_id": "", "item_name": ""},
			"left_hand": {"label": "Left Hand", "item_id": "", "item_name": ""},
			"right_hand":
			{
				"label": "Right Hand",
				"item_id": "item_road_hatchet",
				"item_name": "Road Hatchet"
			},
			"chest": {"label": "Chest", "item_id": "", "item_name": ""},
			"legs": {"label": "Legs", "item_id": "", "item_name": ""},
			"gloves": {"label": "Gloves", "item_id": "", "item_name": ""},
			"boots": {"label": "Boots", "item_id": "", "item_name": ""},
			"back": {"label": "Back", "item_id": "", "item_name": ""},
			"necklace": {"label": "Necklace", "item_id": "", "item_name": ""},
			"ring_1": {"label": "Ring 1", "item_id": "", "item_name": ""},
			"ring_2": {"label": "Ring 2", "item_id": "", "item_name": ""}
		},
		"spells":
		[
			{
				"spell_id": "spell_fire_blast",
				"name": "Fire Blast",
				"school": "Fire",
				"icon": "F",
				"mana_cost": 5,
				"mana_drain_per_second": 8,
				"range": "6 tiles",
				"behavior": "Channels a short flamethrower in the aimed direction while held.",
				"assigned_slot": "ability_1",
				"assigned_label": "Ability I"
			}
		],
		"spell_slots":
		{
			"ability_1":
			{
				"slot": "ability_1",
				"slot_label": "Ability I",
				"spell_id": "spell_fire_blast",
				"name": "Fire Blast",
				"mana_cost": 5,
				"mana_drain_per_second": 8
			},
			"ability_2": {"slot": "ability_2", "slot_label": "Ability II", "spell_id": ""},
			"ability_3": {"slot": "ability_3", "slot_label": "Ability III", "spell_id": ""}
		},
		"factions": "Marches of Velcor +5",
		"progression": "Level 2  XP 10/40  Points 1",
		"progression_details": "Level: 2\nXP: 10/40\nUnspent points: 1",
		"time_actions": [{"id": "wait:1", "text": "Wait 1h"}],
		"time": "Day 1, 16:00 (Afternoon)",
		"trade":
		(
			"Crossroads Peddler\n"
			+ "Hours: 08:00-18:00\n"
			+ "Gold: 25\n\n"
			+ "Stock:\n"
			+ "- Roadside Draught: 8g\n"
			+ "- Traveler Buckler: 18g\n\n"
			+ "Sell: none"
		),
		"trade_actions": [{"id": "buy:item_roadside_draught", "text": "Buy Roadside Draught (8g)"}],
		"location_details": "Briarwatch Crossroads - Marches of Velcor",
		"nearby_targets":
		[
			{
				"id": "npc_harrow_venn_world",
				"name": "Harrow Venn",
				"kind": "npc",
				"detail": "Blacksmith, quest giver",
				"navigation": "Near Road Notice",
				"selected": true
			},
			{
				"id": "readable_road_notice",
				"name": "Road Notice",
				"kind": "readable",
				"detail": "Readable notice board",
				"navigation": "East of the bridge"
			}
		],
		"quest_directions": "The Missing Tools: E 5.0t Harrow Venn",
		"quest_target_actions": [{"id": "target:npc_harrow_venn_world", "text": "Target Harrow Venn"}]
	}


func _button_texts(parent: Node) -> Array:
	var texts := []
	for child in parent.get_children():
		if child is Button and child.visible:
			texts.append(child.text)
	return texts


func _press_nav(hud: RpgHud, text: String) -> void:
	var button := _button_containing(hud.top_nav_buttons, text)
	assert_not_null(button)
	button.pressed.emit()


func _press_category(hud: RpgHud, text: String) -> void:
	var button := _button_containing(hud.systems_category_row, text)
	assert_not_null(button)
	button.pressed.emit()


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.visible and child.text.contains(text):
			return child
		var nested := _button_containing(child, text)
		if nested != null:
			return nested
	return null

func _visible_button_rects(parent: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child in parent.get_children():
		if child is Button and child.visible:
			rects.append((child as Button).get_global_rect())
		rects.append_array(_visible_button_rects(child))
	return rects


func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)


func _top_left_rect(panel: Control) -> Rect2:
	return Rect2(
		Vector2(panel.offset_left, panel.offset_top),
		Vector2(panel.offset_right - panel.offset_left, panel.offset_bottom - panel.offset_top)
	)


func _center_top_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var center_x := viewport_size.x * 0.5
	return Rect2(
		Vector2(center_x + panel.offset_left, panel.offset_top),
		Vector2(panel.offset_right - panel.offset_left, panel.offset_bottom - panel.offset_top)
	)


func _right_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var left := viewport_size.x + panel.offset_left
	var right := viewport_size.x + panel.offset_right
	return Rect2(
		Vector2(left, panel.offset_top),
		Vector2(right - left, panel.offset_bottom - panel.offset_top)
	)


func _bottom_left_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var top := viewport_size.y + panel.offset_top
	var bottom := viewport_size.y + panel.offset_bottom
	return Rect2(
		Vector2(panel.offset_left, top),
		Vector2(panel.offset_right - panel.offset_left, bottom - top)
	)


func _anchored_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var left := panel.anchor_left * viewport_size.x + panel.offset_left
	var right := panel.anchor_right * viewport_size.x + panel.offset_right
	var top := panel.anchor_top * viewport_size.y + panel.offset_top
	var bottom := panel.anchor_bottom * viewport_size.y + panel.offset_bottom
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))
