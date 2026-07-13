class_name VariantFields
extends RefCounted


static func array(value: Variant) -> Array:
	return value if value is Array else []


static func dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func portal_data(entity) -> Dictionary:
	if not entity or not (entity.data is Dictionary):
		return {}
	var portal: Variant = entity.data.get("portal", {})
	return dictionary(portal)


static func entity_layer(entity) -> String:
	if not entity or not (entity.data is Dictionary):
		return "surface"
	var layer := String(entity.data.get("world_layer", "surface"))
	return "surface" if layer.is_empty() else layer


static func vector2i_from_pair(value: Variant, fallback: Vector2i) -> Vector2i:
	var pair := numeric_pair(value)
	if pair.is_empty():
		return fallback
	return Vector2i(int(pair[0]), int(pair[1]))


static func vector2_from_pair(value: Variant, fallback: Vector2) -> Vector2:
	var pair := numeric_pair(value)
	if pair.is_empty():
		return fallback
	return Vector2(float(pair[0]), float(pair[1]))


static func numeric_pair(value: Variant) -> Array:
	if not value is Array or value.size() < 2:
		return []
	if not is_number(value[0]) or not is_number(value[1]):
		return []
	return [value[0], value[1]]


static func positive_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	return positive_int(source.get(field_id, fallback), fallback)


static func positive_int(value: Variant, fallback: int) -> int:
	if not is_number(value):
		return maxi(1, fallback)
	return maxi(1, int(value))


static func non_negative_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	return non_negative_int(source.get(field_id, fallback), fallback)


static func non_negative_int(value: Variant, fallback: int) -> int:
	if not is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


static func int_value(value: Variant, fallback: int) -> int:
	return int(value) if is_number(value) else fallback


static func positive_float_field(source: Dictionary, field_id: String, fallback: float) -> float:
	return positive_float_at_least(source.get(field_id, fallback), fallback, 0.01)


static func positive_float(value: Variant, fallback: float) -> float:
	return positive_float_at_least(value, fallback, 0.01)


static func positive_float_field_at_least(
	source: Dictionary, field_id: String, fallback: float, minimum: float
) -> float:
	return positive_float_at_least(source.get(field_id, fallback), fallback, minimum)


static func positive_float_at_least(value: Variant, fallback: float, minimum: float) -> float:
	if not is_number(value):
		return maxf(minimum, fallback)
	return maxf(minimum, float(value))


static func non_negative_float(value: Variant, fallback: float) -> float:
	if not is_number(value):
		return maxf(0.0, fallback)
	return maxf(0.0, float(value))


static func is_number(value: Variant) -> bool:
	return value is int or value is float
