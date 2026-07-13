class_name NpcPerception
extends RefCounted

const ActorRules = preload("res://scripts/core/actor_rules.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")

const DEFAULT_VISION_DISTANCE := 192.0
const DEFAULT_VISION_DEGREES := 120.0
const DEFAULT_HEARING_RADIUS := 144.0
const WALL_SOUND_MULTIPLIER := 0.4


static func can_see_entity(observer, target, world_query = null, context: Dictionary = {}) -> bool:
	if not target:
		return false
	var resolved_context := context.duplicate(true)
	if target is Object:
		var sneaking: Variant = target.get("is_sneaking")
		if sneaking is bool:
			resolved_context["target_sneaking"] = sneaking
	return can_see_position(
		observer,
		target.global_position,
		_target_layer(target),
		world_query,
		resolved_context
	)


static func can_see_position(
	observer,
	target_position: Vector2,
	target_layer: String,
	world_query = null,
	context: Dictionary = {}
) -> bool:
	if not _can_perceive(observer) or _layer(observer) != _normalized_layer(target_layer):
		return false
	var delta: Vector2 = target_position - observer.global_position
	var distance := delta.length()
	if distance <= 0.001:
		return true
	var vision_distance := VariantFields.positive_float_field(
		observer.data, "vision_distance", DEFAULT_VISION_DISTANCE
	)
	if bool(context.get("target_sneaking", false)):
		vision_distance *= clampf(float(context.get("sneak_visibility", 0.55)), 0.1, 1.0)
	var light_level := clampf(float(context.get("light_level", 1.0)), 0.0, 1.0)
	var night_vision := clampf(float(observer.data.get("night_vision", 0.0)), 0.0, 1.0)
	vision_distance *= lerpf(0.4, 1.0, maxf(light_level, night_vision))
	if distance > vision_distance:
		return false
	var facing := _facing(observer)
	if facing.length() <= 0.001:
		return false
	var vision_degrees := clampf(
		VariantFields.positive_float_field(
			observer.data, "vision_degrees", DEFAULT_VISION_DEGREES
		),
		1.0,
		360.0
	)
	var threshold := cos(deg_to_rad(vision_degrees * 0.5))
	if vision_degrees < 359.9 and facing.normalized().dot(delta.normalized()) < threshold:
		return false
	return has_line_of_sight(observer.global_position, target_position, target_layer, world_query)


static func can_hear(
	observer,
	origin: Vector2,
	event_layer: String,
	noise_radius: float,
	world_query = null,
	context: Dictionary = {}
) -> bool:
	if (
		not _can_perceive(observer)
		or noise_radius <= 0.0
		or _layer(observer) != _normalized_layer(event_layer)
	):
		return false
	var hearing_radius := VariantFields.positive_float_field(
		observer.data, "hearing_radius", DEFAULT_HEARING_RADIUS
	)
	var loudness := maxf(0.0, float(context.get("loudness", 1.0)))
	var propagated_radius := noise_radius * loudness
	if not has_line_of_sight(observer.global_position, origin, event_layer, world_query):
		propagated_radius *= WALL_SOUND_MULTIPLIER
	var effective_radius := minf(propagated_radius, hearing_radius)
	return observer.global_position.distance_to(origin) <= effective_radius


static func has_line_of_sight(
	from_position: Vector2, to_position: Vector2, layer: String, world_query = null
) -> bool:
	if not world_query or not world_query.has_method("is_walkable"):
		return true
	var start := GridMath.world_to_tile(from_position)
	var finish := GridMath.world_to_tile(to_position)
	var tiles := _line_tiles(start, finish)
	for index in range(1, maxi(1, tiles.size() - 1)):
		if not world_query.is_walkable(tiles[index], _normalized_layer(layer)):
			return false
	return true


static func _line_tiles(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var x := start.x
	var y := start.y
	var dx := absi(finish.x - start.x)
	var sx := 1 if start.x < finish.x else -1
	var dy := -absi(finish.y - start.y)
	var sy := 1 if start.y < finish.y else -1
	var error := dx + dy
	while true:
		result.append(Vector2i(x, y))
		if x == finish.x and y == finish.y:
			break
		var twice_error := error * 2
		if twice_error >= dy:
			error += dy
			x += sx
		if twice_error <= dx:
			error += dx
			y += sy
	return result


static func _can_perceive(observer) -> bool:
	return (
		observer
		and observer.data is Dictionary
		and ActorRules.is_living_actor_data(observer.data)
		and not bool(observer.data.get("incapacitated", false))
	)


static func _layer(observer) -> String:
	return _normalized_layer(String(observer.data.get("world_layer", "surface")))


static func _normalized_layer(layer: String) -> String:
	return "surface" if layer.is_empty() else layer


static func _facing(observer) -> Vector2:
	if observer.has_method("get_facing_direction"):
		return observer.get_facing_direction()
	var pair := VariantFields.numeric_pair(observer.data.get("facing_direction", []))
	if not pair.is_empty():
		var direction := Vector2(float(pair[0]), float(pair[1]))
		if direction.length() > 0.001:
			return direction.normalized()
	match String(observer.data.get("facing", "")).to_lower():
		"north":
			return Vector2.UP
		"south":
			return Vector2.DOWN
		"east":
			return Vector2.RIGHT
		"west":
			return Vector2.LEFT
	return Vector2.DOWN


static func _target_layer(target) -> String:
	if target.has_method("get_world_layer"):
		return _normalized_layer(String(target.get_world_layer()))
	var data: Variant = target.get("data")
	if data is Dictionary:
		return _normalized_layer(String(data.get("world_layer", "surface")))
	return "surface"
