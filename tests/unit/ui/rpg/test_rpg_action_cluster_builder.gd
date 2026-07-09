extends GutTest


func test_build_creates_combat_cluster_and_wires_aim_signals() -> void:
	var root := Control.new()
	add_child_autofree(root)
	var aimed: Array[Dictionary] = []
	var held: Array[Dictionary] = []
	var context := _build_context(
		root,
		func(action_id: String, direction: Vector2) -> void:
			aimed.append({"action_id": action_id, "direction": direction}),
		func(action_id: String, direction: Vector2, delta: float) -> void:
			held.append({"action_id": action_id, "direction": direction, "delta": delta})
	)

	var nodes := RpgActionClusterBuilder.build(context)

	var cluster := nodes["cluster"] as Control
	var primary := nodes["primary"] as RpgAimJoystick
	var abilities := nodes["ability_buttons"] as Dictionary
	var utilities := nodes["utility_buttons"] as Dictionary
	var ability := abilities["ability_1"] as RpgAimJoystick
	assert_eq(cluster.name, "CombatJoystickCluster")
	assert_eq(cluster.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(abilities.size(), 3)
	assert_eq(utilities.size(), 3)
	assert_eq(primary.action_id, "attack")
	assert_eq(primary.get_meta("action_role"), "primary")
	assert_eq(primary.get_meta("action_input"), "aim_drag")
	assert_eq(ability.action_id, "ability_1")
	assert_eq(ability.center_label, "I")
	assert_eq(ability.get_meta("ability_slot"), "ability_1")
	assert_true(utilities["sneak"] is RpgIconButton)
	assert_eq((utilities["menu"] as Button).tooltip_text, "Open systems menu")

	ability.aimed.emit("ability_1", Vector2.RIGHT)
	primary.aim_held.emit("attack", Vector2.LEFT, 0.25)

	assert_eq(aimed, [{"action_id": "ability_1", "direction": Vector2.RIGHT}])
	assert_eq(held, [{"action_id": "attack", "direction": Vector2.LEFT, "delta": 0.25}])


func test_apply_layout_positions_desktop_and_compact_controls() -> void:
	var root := Control.new()
	add_child_autofree(root)
	var nodes := RpgActionClusterBuilder.build(
		_build_context(root, Callable(), Callable())
	)
	var request := RpgActionClusterBuilder.LayoutRequest.new()
	request.cluster = nodes["cluster"]
	request.primary = nodes["primary"]
	request.primary_style = Callable(self, "_style_primary")
	request.compact = false

	RpgActionClusterBuilder.apply_layout(request)

	var cluster := nodes["cluster"] as Control
	var primary := nodes["primary"] as RpgAimJoystick
	var utility_row := cluster.find_child("UtilityButtonStack", true, false) as HBoxContainer
	var ability := (nodes["ability_buttons"] as Dictionary)["ability_1"] as RpgAimJoystick
	assert_eq(cluster.custom_minimum_size, Vector2(284, 228))
	assert_eq(cluster.offset_left, -296.0)
	assert_eq(primary.position, Vector2(102, 58))
	assert_eq(primary.custom_minimum_size, Vector2(170, 170))
	assert_eq(primary.get_meta("action_shape"), "aim_joystick_primary")
	assert_true(bool(primary.get_meta("primary_styled")))
	assert_eq(utility_row.position, Vector2(96, 0))
	assert_eq(ability.position, Vector2(44, 48))
	assert_eq(ability.custom_minimum_size, Vector2(58, 58))

	request.compact = true
	RpgActionClusterBuilder.apply_layout(request)

	assert_eq(cluster.custom_minimum_size, Vector2(218, 176))
	assert_eq(cluster.offset_left, -230.0)
	assert_eq(primary.position, Vector2(78, 40))
	assert_eq(primary.custom_minimum_size, Vector2(136, 136))
	assert_eq(utility_row.position, Vector2(72, 0))
	assert_eq(ability.position, Vector2(32, 32))
	assert_eq(ability.custom_minimum_size, Vector2(46, 46))


func test_refresh_ability_buttons_sets_spell_and_empty_slot_state() -> void:
	var root := Control.new()
	add_child_autofree(root)
	var nodes := RpgActionClusterBuilder.build(
		_build_context(root, Callable(), Callable())
	)
	var buttons := nodes["ability_buttons"] as Dictionary

	RpgActionClusterBuilder.refresh_ability_buttons(
		buttons,
		{
			"ability_1":
			{
				"spell_id": "spell_fire_blast",
				"name": "Fire Blast",
				"mana_cost": 12,
				"icon": "Fl"
			},
			"ability_2": {"spell_id": "", "name": ""},
		}
	)

	var fire := buttons["ability_1"] as RpgAimJoystick
	var empty := buttons["ability_2"] as RpgAimJoystick
	assert_eq(fire.text, "Fire\n12")
	assert_eq(fire.tooltip_text, "Cast Fire Blast")
	assert_eq(fire.get_meta("spell_id"), "spell_fire_blast")
	assert_false(bool(fire.get_meta("ability_empty")))
	assert_eq(fire.center_label, "Fl")
	assert_eq(fire.footer_label, "12")
	assert_false(fire.empty_slot)
	assert_eq(empty.text, "II")
	assert_eq(empty.tooltip_text, "Empty ability slot")
	assert_eq(empty.get_meta("spell_id"), "")
	assert_true(bool(empty.get_meta("ability_empty")))
	assert_eq(empty.center_label, "II")
	assert_eq(empty.footer_label, "")
	assert_true(empty.empty_slot)


func _build_context(
	root: Control, aim_action: Callable, held_action: Callable
) -> RpgActionClusterBuilder.BuildContext:
	var context := RpgActionClusterBuilder.BuildContext.new()
	context.root = root
	context.aim_action = aim_action
	context.held_action = held_action
	return context


func _style_primary(button: Button) -> void:
	button.set_meta("primary_styled", true)
