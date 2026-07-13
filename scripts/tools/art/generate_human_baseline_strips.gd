extends SceneTree

const FRAME_SIZE := Vector2i(64, 64)
const FRAME_COUNT := 16
const OUTPUT_DIR := "res://reports/generated_human_baseline"

const OUTLINE := Color8(31, 25, 21)
const NEUTRAL := Color8(211, 202, 188)
const NEUTRAL_SHADOW := Color8(127, 112, 95)
const NEUTRAL_LIGHT := Color8(239, 228, 207)
const FACE_DARK := Color8(44, 31, 24)
const APRON := Color8(108, 70, 40)
const APRON_SHADOW := Color8(58, 39, 28)
const APRON_LIGHT := Color8(158, 111, 63)


func _initialize() -> void:
	var output_path := ProjectSettings.globalize_path(OUTPUT_DIR)
	var make_error := DirAccess.make_dir_recursive_absolute(output_path)
	if make_error != OK:
		printerr("Could not create baseline output directory: %s" % error_string(make_error))
		quit(1)
		return
	var strips := {
		"head_human_round_base.png": _generate_strip("head"),
		"face_eyes_dark.png": _generate_strip("face"),
		"body_humanoid_average_torso.png": _generate_strip("torso"),
		"body_humanoid_average_waist.png": _generate_strip("waist_hips"),
		"body_humanoid_average_left_hand.png": _generate_strip("left_hand"),
		"body_humanoid_average_right_hand.png": _generate_strip("right_hand"),
		"body_humanoid_average_left_foot.png": _generate_strip("left_foot"),
		"body_humanoid_average_right_foot.png": _generate_strip("right_foot"),
		"smith_apron_chest.png": _generate_strip("smith_apron")
	}
	for file_name in strips:
		var image: Image = strips[file_name]
		var save_error := image.save_png(output_path.path_join(String(file_name)))
		if save_error != OK:
			printerr("Could not save %s: %s" % [file_name, error_string(save_error)])
			quit(1)
			return
	print("Wrote %d baseline strips to %s" % [strips.size(), output_path])
	quit()


static func _generate_strip(part_id: String) -> Image:
	var image := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for frame_index in FRAME_COUNT:
		_draw_part(image, frame_index, part_id, _direction(frame_index))
	return image


static func _draw_part(image: Image, frame_index: int, part_id: String, direction: Vector2) -> void:
	match part_id:
		"head":
			_draw_head(image, frame_index, direction)
		"face":
			_draw_face(image, frame_index, direction)
		"torso":
			_draw_torso(image, frame_index, direction)
		"waist_hips":
			_draw_waist(image, frame_index, direction)
		"left_hand":
			_draw_hand(image, frame_index, direction, -1.0)
		"right_hand":
			_draw_hand(image, frame_index, direction, 1.0)
		"left_foot":
			_draw_foot(image, frame_index, direction, -1.0)
		"right_foot":
			_draw_foot(image, frame_index, direction, 1.0)
		"smith_apron":
			_draw_apron(image, frame_index, direction)


static func _draw_head(image: Image, frame_index: int, direction: Vector2) -> void:
	var side_amount := absf(direction.x)
	var center := Vector2(32.0 + direction.x * side_amount * 1.1, 18.0 - maxf(0.0, -direction.y))
	var radius := Vector2(lerpf(7.1, 5.8, side_amount), 8.2)
	_fill_ellipse(image, frame_index, center, radius + Vector2.ONE, OUTLINE)
	_fill_ellipse(image, frame_index, center, radius, NEUTRAL)
	_draw_line(
		image,
		frame_index,
		center + Vector2(-radius.x * 0.45, -radius.y * 0.52),
		center + Vector2(radius.x * 0.20, -radius.y * 0.62),
		NEUTRAL_LIGHT,
		1
	)
	if side_amount > 0.55:
		var ear_x := center.x - signf(direction.x) * radius.x * 0.75
		_fill_ellipse(image, frame_index, Vector2(ear_x, center.y), Vector2(1.7, 2.3), OUTLINE)
		_fill_ellipse(image, frame_index, Vector2(ear_x, center.y), Vector2(1.0, 1.6), NEUTRAL_SHADOW)


static func _draw_face(image: Image, frame_index: int, direction: Vector2) -> void:
	if direction.y < -0.35:
		return
	var side_amount := absf(direction.x)
	var center := Vector2(32.0 + direction.x * side_amount * 1.1, 18.0)
	if side_amount > 0.70:
		var side := signf(direction.x)
		_draw_line(
			image,
			frame_index,
			center + Vector2(side * 0.7, -1.8),
			center + Vector2(side * 2.2, -1.7),
			FACE_DARK,
			1
		)
		_draw_line(
			image,
			frame_index,
			center + Vector2(side * 1.0, 2.1),
			center + Vector2(side * 2.2, 2.0),
			FACE_DARK,
			1
		)
		return
	var eye_spread := lerpf(3.0, 2.0, side_amount)
	_fill_ellipse(
		image, frame_index, center + Vector2(-eye_spread, -1.7), Vector2(0.9, 0.7), FACE_DARK
	)
	_fill_ellipse(
		image, frame_index, center + Vector2(eye_spread, -1.7), Vector2(0.9, 0.7), FACE_DARK
	)
	_draw_line(
		image,
		frame_index,
		center + Vector2(-1.4, 2.2),
		center + Vector2(1.3, 2.1),
		FACE_DARK,
		1
	)


static func _draw_torso(image: Image, frame_index: int, direction: Vector2) -> void:
	var depth := absf(direction.y)
	var half_width := lerpf(5.2, 9.2, depth)
	var shift := direction.x * 1.2
	var points := PackedVector2Array(
		[
			Vector2(32.0 + shift - half_width, 23.0),
			Vector2(32.0 + shift + half_width, 23.0),
			Vector2(32.0 + shift + half_width * 0.72, 38.0),
			Vector2(32.0 + shift, 40.0),
			Vector2(32.0 + shift - half_width * 0.72, 38.0)
		]
	)
	_fill_polygon(image, frame_index, points, OUTLINE)
	var inner := _scale_polygon(points, Vector2(32.0 + shift, 31.0), 0.86)
	_fill_polygon(image, frame_index, inner, NEUTRAL)
	_draw_line(
		image,
		frame_index,
		Vector2(32.0 + shift - half_width * 0.35, 26.0),
		Vector2(32.0 + shift - half_width * 0.20, 36.0),
		NEUTRAL_LIGHT,
		1
	)
	_draw_line(
		image,
		frame_index,
		Vector2(32.0 + shift + half_width * 0.35, 26.0),
		Vector2(32.0 + shift + half_width * 0.22, 36.0),
		NEUTRAL_SHADOW,
		1
	)


static func _draw_waist(image: Image, frame_index: int, direction: Vector2) -> void:
	var depth := absf(direction.y)
	var center := Vector2(32.0 + direction.x * 0.8, 38.0)
	var radius := Vector2(lerpf(4.5, 7.4, depth), 5.0)
	_fill_ellipse(image, frame_index, center, radius + Vector2.ONE, OUTLINE)
	_fill_ellipse(image, frame_index, center, radius, NEUTRAL_SHADOW)
	_draw_line(
		image,
		frame_index,
		center + Vector2(-radius.x * 0.60, -1.8),
		center + Vector2(radius.x * 0.55, -1.8),
		NEUTRAL_LIGHT,
		1
	)


static func _draw_hand(
	image: Image, frame_index: int, direction: Vector2, side: float
) -> void:
	var anchor := Vector2(20.0, 34.0) if side < 0.0 else Vector2(44.0, 34.0)
	var lean := direction.normalized() * 0.7
	var center := anchor + lean
	_fill_ellipse(image, frame_index, center, Vector2(3.1, 3.7), OUTLINE)
	_fill_ellipse(image, frame_index, center, Vector2(2.25, 2.8), NEUTRAL)
	_draw_line(
		image,
		frame_index,
		center + Vector2(-1.1 * side, -1.2),
		center + Vector2(1.2 * side, 0.8),
		NEUTRAL_LIGHT,
		1
	)


static func _draw_foot(
	image: Image, frame_index: int, direction: Vector2, side: float
) -> void:
	var anchor := Vector2(24.0, 42.0) if side < 0.0 else Vector2(40.0, 42.0)
	var forward := direction.normalized()
	var lateral := Vector2(-forward.y, forward.x)
	var center := anchor + forward * 1.2
	var points := PackedVector2Array(
		[
			center - forward * 3.4 - lateral * 2.2,
			center - forward * 3.4 + lateral * 2.2,
			center + forward * 3.4 + lateral * 2.7,
			center + forward * 4.2,
			center + forward * 3.4 - lateral * 2.7
		]
	)
	_fill_polygon(image, frame_index, points, OUTLINE)
	_fill_polygon(image, frame_index, _scale_polygon(points, center, 0.70), NEUTRAL_SHADOW)
	_draw_line(
		image,
		frame_index,
		center - forward * 1.8 - lateral,
		center + forward * 2.5 - lateral,
		NEUTRAL_LIGHT,
		1
	)


static func _draw_apron(image: Image, frame_index: int, direction: Vector2) -> void:
	var center_x := 32.0 + direction.x
	if direction.y < -0.55:
		_draw_line(
			image,
			frame_index,
			Vector2(center_x - 5.5, 24.0),
			Vector2(center_x + 5.0, 38.0),
			APRON_SHADOW,
			2
		)
		_draw_line(
			image,
			frame_index,
			Vector2(center_x + 5.5, 24.0),
			Vector2(center_x - 5.0, 38.0),
			APRON_SHADOW,
			2
		)
		_draw_line(
			image,
			frame_index,
			Vector2(center_x - 6.0, 38.0),
			Vector2(center_x + 6.0, 38.0),
			APRON,
			2
		)
		return
	var side_amount := absf(direction.x)
	var half_width := lerpf(7.4, 3.4, side_amount)
	var side := signf(direction.x)
	var shift := side * side_amount * 1.4
	var points := PackedVector2Array(
		[
			Vector2(center_x + shift - half_width * 0.72, 24.0),
			Vector2(center_x + shift + half_width * 0.72, 24.0),
			Vector2(center_x + shift + half_width, 37.0),
			Vector2(center_x + shift + half_width * 0.62, 45.0),
			Vector2(center_x + shift - half_width * 0.62, 45.0),
			Vector2(center_x + shift - half_width, 37.0)
		]
	)
	_fill_polygon(image, frame_index, points, OUTLINE)
	_fill_polygon(
		image,
		frame_index,
		_scale_polygon(points, Vector2(center_x + shift, 34.5), 0.87),
		APRON
	)
	_draw_line(
		image,
		frame_index,
		Vector2(center_x + shift - half_width * 0.72, 36.5),
		Vector2(center_x + shift + half_width * 0.72, 36.5),
		APRON_LIGHT,
		1
	)
	_draw_line(
		image,
		frame_index,
		Vector2(center_x + shift, 38.0),
		Vector2(center_x + shift + side * 0.8, 43.0),
		APRON_SHADOW,
		1
	)


static func _fill_ellipse(
	image: Image, frame_index: int, center: Vector2, radius: Vector2, color: Color
) -> void:
	var min_x := int(floor(center.x - radius.x))
	var max_x := int(ceil(center.x + radius.x))
	var min_y := int(floor(center.y - radius.y))
	var max_y := int(ceil(center.y + radius.y))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dx := (float(x) + 0.5 - center.x) / maxf(radius.x, 0.1)
			var dy := (float(y) + 0.5 - center.y) / maxf(radius.y, 0.1)
			if dx * dx + dy * dy <= 1.0:
				_set_pixel(image, frame_index, x, y, color)


static func _fill_polygon(
	image: Image, frame_index: int, points: PackedVector2Array, color: Color
) -> void:
	var min_x := FRAME_SIZE.x
	var max_x := 0
	var min_y := FRAME_SIZE.y
	var max_y := 0
	for point in points:
		min_x = mini(min_x, int(floor(point.x)))
		max_x = maxi(max_x, int(ceil(point.x)))
		min_y = mini(min_y, int(floor(point.y)))
		max_y = maxi(max_y, int(ceil(point.y)))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if Geometry2D.is_point_in_polygon(Vector2(float(x) + 0.5, float(y) + 0.5), points):
				_set_pixel(image, frame_index, x, y, color)


static func _draw_line(
	image: Image,
	frame_index: int,
	start: Vector2,
	finish: Vector2,
	color: Color,
	width: int
) -> void:
	var distance := maxi(1, int(ceil(start.distance_to(finish) * 2.0)))
	for step in range(distance + 1):
		var point := start.lerp(finish, float(step) / float(distance))
		for offset_y in range(-width / 2, width / 2 + 1):
			for offset_x in range(-width / 2, width / 2 + 1):
				_set_pixel(
					image,
					frame_index,
					int(round(point.x)) + offset_x,
					int(round(point.y)) + offset_y,
					color
				)


static func _scale_polygon(
	points: PackedVector2Array, center: Vector2, amount: float
) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(center + (point - center) * amount)
	return result


static func _set_pixel(
	image: Image, frame_index: int, local_x: int, local_y: int, color: Color
) -> void:
	if local_x < 0 or local_x >= FRAME_SIZE.x or local_y < 0 or local_y >= FRAME_SIZE.y:
		return
	image.set_pixel(frame_index * FRAME_SIZE.x + local_x, local_y, color)


static func _direction(frame_index: int) -> Vector2:
	var angle := float(frame_index) * TAU / float(FRAME_COUNT)
	return Vector2(cos(angle), sin(angle)).normalized()
