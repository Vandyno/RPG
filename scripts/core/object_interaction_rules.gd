class_name ObjectInteractionRules
extends RefCounted


static func container_detail(entity, chunk_manager, condition_evaluator) -> String:
	return access_detail(entity, chunk_manager, condition_evaluator, "Container")


static func access_detail(entity, chunk_manager, condition_evaluator, label: String) -> String:
	if _is_object_opened(chunk_manager, entity):
		return "%s: opened" % label
	if is_access_locked(entity.data, condition_evaluator):
		return "%s: locked" % label
	return "%s: closed" % label


static func access_action_text(entity, chunk_manager, condition_evaluator) -> String:
	if _is_object_opened(chunk_manager, entity):
		return "Opened"
	if is_access_locked(entity.data, condition_evaluator):
		return "Locked"
	return "Open"


static func container_locked_text(data: Dictionary, condition_evaluator) -> String:
	return access_locked_text(data, condition_evaluator)


static func access_locked_text(data: Dictionary, condition_evaluator) -> String:
	if not is_access_locked(data, condition_evaluator):
		return ""
	var text := String(data.get("locked_text", "It is locked."))
	return text if not text.is_empty() else "It is locked."


static func is_container_locked(data: Dictionary, condition_evaluator) -> bool:
	return is_access_locked(data, condition_evaluator)


static func is_access_locked(data: Dictionary, condition_evaluator) -> bool:
	var conditions: Variant = data.get("open_conditions", [])
	if not conditions is Array or conditions.is_empty():
		return false
	return not condition_evaluator or not condition_evaluator.evaluate_all(conditions)


static func _entity_layer(entity) -> String:
	if not entity or not (entity.data is Dictionary):
		return "surface"
	var layer := String(entity.data.get("world_layer", "surface"))
	return "surface" if layer.is_empty() else layer


static func _is_object_opened(chunk_manager, entity) -> bool:
	if not chunk_manager or not chunk_manager.has_method("is_object_opened"):
		return false
	var arg_count := _method_argument_count(chunk_manager, "is_object_opened")
	if arg_count >= 3:
		return bool(
			chunk_manager.is_object_opened(entity.get_entity_id(), entity.global_tile, _entity_layer(entity))
		)
	return bool(chunk_manager.is_object_opened(entity.get_entity_id(), entity.global_tile))


static func _method_argument_count(target, method_name: String) -> int:
	for method in target.get_method_list():
		if String(method.get("name", "")) != method_name:
			continue
		return method.get("args", []).size()
	return 0
