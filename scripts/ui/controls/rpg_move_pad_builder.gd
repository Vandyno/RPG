class_name RpgMovePadBuilder
extends RefCounted


static func build(root: Control, input_callback: Callable, knob_size: Vector2) -> Dictionary:
	var move_pad := Panel.new()
	move_pad.name = "MovePad"
	move_pad.anchor_top = 1.0
	move_pad.anchor_bottom = 1.0
	move_pad.offset_left = 18
	move_pad.offset_top = -172
	move_pad.offset_right = 184
	move_pad.offset_bottom = -12
	move_pad.mouse_filter = Control.MOUSE_FILTER_STOP
	move_pad.gui_input.connect(input_callback)
	move_pad.add_theme_stylebox_override("panel", _pad_style())
	root.add_child(move_pad)

	var outer_ring := Panel.new()
	outer_ring.name = "MovePadOuterRing"
	outer_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_ring.offset_left = 13
	outer_ring.offset_top = 10
	outer_ring.offset_right = -13
	outer_ring.offset_bottom = -10
	outer_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_ring.add_theme_stylebox_override("panel", _ring_style())
	move_pad.add_child(outer_ring)

	var inner_well := Panel.new()
	inner_well.name = "MovePadInnerWell"
	inner_well.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_well.offset_left = 47
	inner_well.offset_top = 44
	inner_well.offset_right = -47
	inner_well.offset_bottom = -44
	inner_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_well.add_theme_stylebox_override("panel", _well_style())
	move_pad.add_child(inner_well)

	var knob := ColorRect.new()
	knob.name = "MoveKnob"
	knob.color = Color(0.90, 0.76, 0.42, 0.72)
	knob.custom_minimum_size = knob_size
	knob.size = knob_size
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_pad.add_child(knob)

	return {"move_pad": move_pad, "move_knob": knob}


static func _pad_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.019, 0.016, 0.54)
	style.border_color = Color(0.78, 0.61, 0.34, 0.56)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 86
	style.corner_radius_top_right = 86
	style.corner_radius_bottom_left = 86
	style.corner_radius_bottom_right = 86
	return style


static func _ring_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.043, 0.036, 0.42)
	style.border_color = Color(0.88, 0.72, 0.43, 0.72)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 72
	style.corner_radius_top_right = 72
	style.corner_radius_bottom_left = 72
	style.corner_radius_bottom_right = 72
	return style


static func _well_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.029, 0.024, 0.80)
	style.border_color = Color(0.78, 0.61, 0.34, 0.42)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 38
	style.corner_radius_top_right = 38
	style.corner_radius_bottom_left = 38
	style.corner_radius_bottom_right = 38
	return style
