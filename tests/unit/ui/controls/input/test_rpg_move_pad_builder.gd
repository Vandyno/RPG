extends GutTest

const RpgMovePadBuilder = preload("res://scripts/ui/controls/input/rpg_move_pad_builder.gd")


func test_build_returns_empty_without_context_or_root() -> void:
	assert_true(RpgMovePadBuilder.build(null).is_empty())
	var context := RpgMovePadBuilder.BuildContext.new()
	assert_true(RpgMovePadBuilder.build(context).is_empty())


func test_build_creates_anchored_joystick_panel_and_knob() -> void:
	var root := Control.new()
	add_child_autofree(root)
	var events: Array[String] = []
	var context := RpgMovePadBuilder.BuildContext.new()
	context.root = root
	context.input_callback = func(_event: InputEvent) -> void: events.append("input")
	context.knob_size = Vector2(28, 30)

	var nodes := RpgMovePadBuilder.build(context)

	var move_pad := nodes["move_pad"] as Panel
	var knob := nodes["move_knob"] as ColorRect
	assert_same(root.get_child(0), move_pad)
	assert_eq(move_pad.name, "MovePad")
	assert_eq(move_pad.anchor_top, 1.0)
	assert_eq(move_pad.anchor_bottom, 1.0)
	assert_eq(move_pad.offset_left, 18.0)
	assert_eq(move_pad.offset_top, -172.0)
	assert_eq(move_pad.offset_right, 184.0)
	assert_eq(move_pad.offset_bottom, -12.0)
	assert_eq(move_pad.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_not_null(move_pad.get_node("MovePadOuterRing"))
	assert_not_null(move_pad.get_node("MovePadInnerWell"))
	assert_same(move_pad.get_node("MoveKnob"), knob)
	assert_eq(knob.custom_minimum_size, Vector2(28, 30))
	assert_eq(knob.size, Vector2(28, 30))
	assert_eq(knob.mouse_filter, Control.MOUSE_FILTER_IGNORE)

	move_pad.gui_input.emit(InputEventMouseMotion.new())
	assert_eq(events, ["input"])


func test_build_sets_visual_layers_to_ignore_pointer_input() -> void:
	var root := Control.new()
	add_child_autofree(root)
	var context := RpgMovePadBuilder.BuildContext.new()
	context.root = root
	context.input_callback = func(_event: InputEvent) -> void: pass
	context.knob_size = Vector2(24, 24)

	var nodes := RpgMovePadBuilder.build(context)
	var move_pad := nodes["move_pad"] as Panel
	var outer_ring := move_pad.get_node("MovePadOuterRing") as Panel
	var inner_well := move_pad.get_node("MovePadInnerWell") as Panel

	assert_eq(outer_ring.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(inner_well.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_true(outer_ring.has_theme_stylebox_override("panel"))
	assert_true(inner_well.has_theme_stylebox_override("panel"))
	assert_true(move_pad.has_theme_stylebox_override("panel"))


func test_style_helpers_return_rounded_flat_styleboxes() -> void:
	var pad := RpgMovePadBuilder._pad_style()
	var ring := RpgMovePadBuilder._ring_style()
	var well := RpgMovePadBuilder._well_style()

	assert_eq(pad.get_border_width(SIDE_LEFT), 2)
	assert_eq(ring.get_border_width(SIDE_LEFT), 2)
	assert_eq(well.get_border_width(SIDE_LEFT), 1)
	assert_eq(pad.corner_radius_top_left, 86)
	assert_eq(ring.corner_radius_top_left, 72)
	assert_eq(well.corner_radius_top_left, 38)
