class_name ActorWeaponAttackAction
extends Node2D

const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")

const DEFAULT_SWING_DURATION := 0.22
const DEFAULT_THRUST_DURATION := 0.18
const DEFAULT_PROJECTILE_DURATION := 0.16
const DEFAULT_PUNCH_DURATION := 0.16
const DEFAULT_HIT_START := 0.08
const DEFAULT_HIT_END := 0.18
const MIN_DIRECTION_LENGTH := 0.01
const PROJECTILE_RELEASE_PROGRESS := 0.30
const PROJECTILE_BOW_OFFSET := 6.0
const PROJECTILE_ARROW_LENGTH := 16.0
const MELEE_ANCHOR_ID := "weapon_hand"
const BOW_ANCHOR_ID := "bow_hand"

var source_actor
var source_origin := Vector2.ZERO
var direction := Vector2.RIGHT
var attack := {}
var damage := 1
var source_name := "Attack"
var age := 0.0
var duration := DEFAULT_SWING_DURATION
var hit_start := DEFAULT_HIT_START
var hit_end := DEFAULT_HIT_END
var targets_provider := Callable()
var hit_callback := Callable()
var miss_callback := Callable()
var hit_target_keys: Dictionary = {}
var hit_any := false
var miss_reported := false
var immediate_resolved := false


func setup(config: Dictionary) -> void:
	source_actor = config.get("source_actor")
	attack = _dictionary_field(config.get("attack", {})).duplicate(true)
	damage = maxi(1, int(config.get("damage", attack.get("damage", 1))))
	source_name = String(
		config.get("source_name", attack.get("item_name", attack.get("name", "Attack")))
	)
	direction = _safe_direction(config.get("direction", Vector2.RIGHT))
	targets_provider = config.get("targets_provider", Callable())
	hit_callback = config.get("hit_callback", Callable())
	miss_callback = config.get("miss_callback", Callable())
	duration = _attack_duration(attack)
	hit_start = clampf(float(attack.get("hit_start_seconds", duration * 0.20)), 0.0, duration)
	hit_end = clampf(float(attack.get("hit_end_seconds", duration * 0.78)), hit_start, duration)
	z_index = int(config.get("z_index", 86))
	visible = _is_projectile_attack()
	_set_source_attack_pose(0.0)
	_update_origin()
	if bool(config.get("resolve_immediately", true)):
		_apply_sweep(0.0, 1.0)
		_report_miss_if_needed()
		immediate_resolved = true
	queue_redraw()


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var old_age := age
	age += delta
	_set_source_attack_pose(_visual_progress())
	_update_origin()
	if not immediate_resolved:
		_apply_active_window(old_age, age)
	if age >= duration:
		_report_miss_if_needed()
		_clear_source_attack_pose()
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	if _is_projectile_attack():
		_draw_projectile_arrow()


func _exit_tree() -> void:
	_clear_source_attack_pose()


func _apply_active_window(from_age: float, to_age: float) -> void:
	if to_age < hit_start or from_age > hit_end:
		return
	var active_from := clampf(maxf(from_age, hit_start), hit_start, hit_end)
	var active_to := clampf(minf(to_age, hit_end), hit_start, hit_end)
	var span := maxf(0.01, hit_end - hit_start)
	_apply_sweep((active_from - hit_start) / span, (active_to - hit_start) / span)


func _apply_sweep(progress_from: float, progress_to: float) -> void:
	if not targets_provider.is_valid() or not hit_callback.is_valid():
		return
	var candidates_value: Variant = targets_provider.call()
	if not candidates_value is Array:
		return
	var sweep_query := {
		"origin": global_position,
		"direction": direction,
		"attack": attack,
		"progress_from": progress_from,
		"progress_to": progress_to
	}
	for target in candidates_value:
		if not _is_valid_target(target):
			continue
		var key := _target_key(target)
		if hit_target_keys.has(key):
			continue
		if not DirectionalAttack.weapon_sweep_contains_point(target.global_position, sweep_query):
			continue
		hit_target_keys[key] = true
		hit_any = true
		hit_callback.call(target, damage, source_name)


func _report_miss_if_needed() -> void:
	if hit_any or miss_reported or not miss_callback.is_valid():
		return
	miss_reported = true
	miss_callback.call(source_name, attack, direction)


func _visual_progress() -> float:
	return clampf(age / maxf(duration, 0.01), 0.0, 1.0)


func _update_origin() -> void:
	source_origin = Vector2.ZERO
	if source_actor and source_actor is Node2D:
		source_origin = source_actor.global_position
	if _is_projectile_attack():
		var bow_origin := _hand_world_position(BOW_ANCHOR_ID, source_origin)
		global_position = bow_origin + direction * PROJECTILE_BOW_OFFSET
	else:
		global_position = _hand_world_position(MELEE_ANCHOR_ID, source_origin)


func _draw_projectile_arrow() -> void:
	var flight_progress := clampf(
		(_visual_progress() - PROJECTILE_RELEASE_PROGRESS) / (1.0 - PROJECTILE_RELEASE_PROGRESS),
		0.0,
		1.0
	)
	if flight_progress <= 0.0:
		return
	var range_px := float(attack.get("range_pixels", 120.0))
	var side := direction.orthogonal()
	var tip_distance := lerpf(4.0, range_px, flight_progress)
	var tail_distance := maxf(0.0, tip_distance - PROJECTILE_ARROW_LENGTH)
	var tip := direction * tip_distance
	var tail := direction * tail_distance
	var head_base := tip - direction * 4.2
	draw_line(tail, tip, Color(0.74, 0.52, 0.28, 0.92), 2.2)
	draw_line(tail, tip, Color(1.0, 0.90, 0.62, 0.40), 0.8)
	draw_colored_polygon(
		PackedVector2Array([tip, head_base + side * 2.0, head_base - side * 2.0]),
		Color(0.86, 0.86, 0.78, 0.96)
	)
	draw_line(tail, tail - direction * 3.0 + side * 2.0, Color(0.70, 0.62, 0.45, 0.80), 1.0)
	draw_line(tail, tail - direction * 3.0 - side * 2.0, Color(0.70, 0.62, 0.45, 0.80), 1.0)


func _attack_duration(attack_data: Dictionary) -> float:
	match String(attack_data.get("shape", "swing")):
		"punch":
			return maxf(
				0.05, float(attack_data.get("action_duration_seconds", DEFAULT_PUNCH_DURATION))
			)
		"thrust":
			return maxf(
				0.05, float(attack_data.get("action_duration_seconds", DEFAULT_THRUST_DURATION))
			)
		"projectile":
			return maxf(
				0.05, float(attack_data.get("action_duration_seconds", DEFAULT_PROJECTILE_DURATION))
			)
		_:
			return maxf(
				0.05, float(attack_data.get("action_duration_seconds", DEFAULT_SWING_DURATION))
			)


func _is_projectile_attack() -> bool:
	return String(attack.get("shape", "")) == "projectile"


func _safe_direction(value: Variant) -> Vector2:
	if value is Vector2 and value.length() > MIN_DIRECTION_LENGTH:
		return value.normalized()
	return Vector2.RIGHT


func _set_source_attack_pose(progress: float) -> void:
	if source_actor and source_actor.has_method("set_attack_pose"):
		source_actor.set_attack_pose(attack, direction, progress)
		return
	var avatar = _source_avatar()
	if avatar and avatar.has_method("set_attack_pose"):
		avatar.set_attack_pose(attack, direction, progress)


func _clear_source_attack_pose() -> void:
	if source_actor and source_actor.has_method("clear_attack_pose"):
		source_actor.clear_attack_pose()
		return
	var avatar = _source_avatar()
	if avatar and avatar.has_method("clear_attack_pose"):
		avatar.clear_attack_pose()


func _is_valid_target(target) -> bool:
	return target and target.get("global_position") is Vector2 and target != source_actor


func _hand_world_position(hand_id: String, fallback: Vector2) -> Vector2:
	var anchor_owner = _source_anchor_owner()
	if not anchor_owner:
		return fallback
	var anchors: Dictionary = anchor_owner.get_body_part_anchors()
	var local_anchor: Variant = anchors.get(
		hand_id, anchors.get(_fallback_anchor_id(hand_id), Vector2.ZERO)
	)
	if not local_anchor is Vector2:
		return fallback
	return fallback + local_anchor


func _fallback_anchor_id(anchor_id: String) -> String:
	match anchor_id:
		MELEE_ANCHOR_ID, "draw_hand":
			return "right_hand"
		BOW_ANCHOR_ID, "off_hand":
			return "left_hand"
		_:
			return ""


func _source_anchor_owner():
	if source_actor and source_actor.has_method("get_body_part_anchors"):
		return source_actor
	return _source_avatar()


func _source_avatar():
	if not source_actor:
		return null
	var avatar: Variant = source_actor.get("humanoid_avatar") if source_actor is Object else null
	if avatar and avatar.has_method("get_body_part_anchors"):
		return avatar
	return null


func _target_key(target) -> String:
	if target and target.has_method("get_entity_id"):
		return String(target.get_entity_id())
	if target is Object:
		return str(target.get_instance_id())
	return str(target)


func _dictionary_field(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}
