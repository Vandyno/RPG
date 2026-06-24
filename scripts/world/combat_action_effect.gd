class_name CombatActionEffect
extends Node2D

var effect_kind := "swing"
var direction := Vector2.RIGHT
var attack := {}
var ttl := 0.16
var age := 0.0


func setup(kind: String, origin: Vector2, aim: Vector2, attack_data: Dictionary) -> void:
	effect_kind = kind
	global_position = origin
	direction = aim.normalized() if aim.length() > 0.01 else Vector2.RIGHT
	attack = attack_data.duplicate(true)
	z_index = 80
	ttl = 0.10 if effect_kind == "fire_stream" else 0.22
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	if age >= ttl:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var alpha := clampf(1.0 - age / maxf(ttl, 0.01), 0.0, 1.0)
	match effect_kind:
		"fire_stream":
			_draw_fire(alpha)
		"thrust":
			_draw_thrust(alpha)
		"projectile":
			_draw_arrow(alpha)
		_:
			_draw_swing(alpha)


func _draw_fire(alpha: float) -> void:
	var range_px := float(attack.get("range_pixels", 96.0))
	var width := float(attack.get("width_pixels", 48.0))
	var side := direction.orthogonal()
	for i in range(5):
		var t0 := float(i) / 5.0
		var t1 := float(i + 1) / 5.0
		var center0 := direction * range_px * t0
		var center1 := direction * range_px * t1
		var w0 := lerpf(width * 0.10, width * 0.46, t0)
		var w1 := lerpf(width * 0.16, width * 0.58, t1)
		var heat := 1.0 - t0 * 0.45
		var outer := Color(1.0, 0.22 + 0.26 * heat, 0.03, 0.34 * alpha)
		var inner := Color(1.0, 0.78, 0.18, 0.48 * alpha)
		var outer_points := PackedVector2Array(
			[center0 - side * w0, center0 + side * w0, center1 + side * w1, center1 - side * w1]
		)
		var inner_points := PackedVector2Array(
			[
				center0 - side * w0 * 0.35,
				center0 + side * w0 * 0.35,
				center1 + side * w1 * 0.34,
				center1 - side * w1 * 0.34
			]
		)
		draw_colored_polygon(outer_points, outer)
		draw_colored_polygon(inner_points, inner)
	for i in range(7):
		var t := (float(i) + 0.5) / 7.0
		var wobble := sin((age * 30.0) + float(i) * 1.7) * width * 0.12
		var p := direction * range_px * t + side * wobble
		draw_circle(p, lerpf(5.0, 11.0, t), Color(1.0, 0.55, 0.08, 0.26 * alpha))
	draw_line(Vector2.ZERO, direction * range_px, Color(1.0, 0.92, 0.45, 0.62 * alpha), 3.0)


func _draw_swing(alpha: float) -> void:
	var range_px := float(attack.get("range_pixels", 44.0))
	var arc := deg_to_rad(float(attack.get("arc_degrees", 110.0)))
	var angle := direction.angle()
	for i in range(4):
		var radius := range_px - float(i) * 5.0
		draw_arc(
			Vector2.ZERO,
			radius,
			angle - arc * 0.5,
			angle + arc * 0.5,
			24,
			Color(0.95, 0.88, 0.68, (0.55 - float(i) * 0.10) * alpha),
			3.0
		)


func _draw_thrust(alpha: float) -> void:
	var range_px := float(attack.get("range_pixels", 74.0))
	var side := direction.orthogonal()
	draw_line(Vector2.ZERO, direction * range_px, Color(0.90, 0.84, 0.66, 0.84 * alpha), 5.0)
	draw_line(Vector2.ZERO, direction * range_px, Color(1.0, 0.96, 0.78, 0.95 * alpha), 2.0)
	var tip := direction * range_px
	draw_colored_polygon(
		PackedVector2Array(
			[tip, tip - direction * 11.0 + side * 5.0, tip - direction * 11.0 - side * 5.0]
		),
		Color(0.96, 0.96, 0.88, 0.95 * alpha)
	)


func _draw_arrow(alpha: float) -> void:
	var range_px := float(attack.get("range_pixels", 120.0))
	var side := direction.orthogonal()
	var tail := direction * 12.0
	var tip := direction * range_px
	draw_line(tail, tip, Color(0.74, 0.52, 0.28, 0.90 * alpha), 3.0)
	draw_line(tail, tip, Color(1.0, 0.92, 0.62, 0.50 * alpha), 1.0)
	draw_colored_polygon(
		PackedVector2Array(
			[tip, tip - direction * 10.0 + side * 4.0, tip - direction * 10.0 - side * 4.0]
		),
		Color(0.90, 0.90, 0.82, 0.95 * alpha)
	)
