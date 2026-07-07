class_name HumanoidRoleAccent2D
extends RefCounted

const StableHash = preload("res://scripts/core/stable_hash.gd")
const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")

const OUTLINE := Color(0.045, 0.035, 0.025, 0.95)
const COLORS := {
	"accent_worker_apron": Color(0.38, 0.24, 0.15),
	"accent_travel_wrap": Color(0.20, 0.36, 0.30),
	"accent_scribe_sash": Color(0.70, 0.55, 0.18),
	"accent_guard_belt": Color(0.14, 0.14, 0.15),
	"accent_elder_shawl": Color(0.36, 0.32, 0.42),
	"accent_caretaker_wrap": Color(0.20, 0.44, 0.40),
	"accent_public_sash": Color(0.58, 0.25, 0.18)
}
const VARIANT_TINTS := [
	Color(0.66, 0.32, 0.18),
	Color(0.22, 0.50, 0.42),
	Color(0.76, 0.62, 0.24),
	Color(0.22, 0.36, 0.58),
	Color(0.52, 0.42, 0.32),
	Color(0.42, 0.55, 0.24),
	Color(0.58, 0.24, 0.24)
]
const TOKEN_GROUPS := [
	{
		"accent_id": "accent_worker_apron",
		"tokens":
		[
			"smith",
			"kiln",
			"mason",
			"mender",
			"worker",
			"picker",
			"gatherer",
			"granary",
			"ditch",
			"digger",
			"rigger",
			"forager",
			"brew",
			"carver",
			"basketter"
		]
	},
	{
		"accent_id": "accent_travel_wrap",
		"tokens":
		[
			"traveller",
			"courier",
			"scout",
			"runner",
			"ferryman",
			"guide",
			"peddler",
			"pilgrim"
		]
	},
	{
		"accent_id": "accent_scribe_sash",
		"tokens":
		[
			"scribe",
			"judge",
			"priest",
			"herald",
			"witness",
			"adept",
			"listener",
			"monk",
			"omen",
			"notary",
			"quill",
			"speaker"
		]
	},
	{
		"accent_id": "accent_guard_belt",
		"tokens": ["guard", "veteran", "bailiff", "shield", "warden", "gate_keeper", "windbreak"]
	},
	{
		"accent_id": "accent_elder_shawl",
		"tokens": ["elder", "aunt", "midwife", "mourner", "memory", "widow", "old_root"]
	},
	{
		"accent_id": "accent_caretaker_wrap",
		"tokens":
		[
			"healer",
			"herbalist",
			"tender",
			"handler",
			"watcher",
			"physic",
			"seed_keeper",
			"smallhand",
			"lamp_keeper"
		]
	},
	{
		"accent_id": "accent_public_sash",
		"tokens":
		[
			"performer",
			"duelist",
			"broker",
			"trader",
			"juggler",
			"boss",
			"clan",
			"usher",
			"factor",
			"voice"
		]
	}
]


static func accent_id_for_appearance(appearance: Dictionary) -> String:
	var base_clothing_id := String(appearance.get("base_clothing_id", ""))
	if not base_clothing_id.is_empty():
		return base_clothing_id
	var visual_model_id := String(appearance.get("visual_model_id", ""))
	var result := ""
	for group in TOKEN_GROUPS:
		if _contains_any_token(visual_model_id, group["tokens"]):
			result = String(group["accent_id"])
			break
	return result


static func draw(
	canvas: Node2D,
	accent_id: String,
	proportions: Dictionary,
	torso_x: float,
	appearance: Dictionary = {}
) -> void:
	if accent_id.is_empty():
		return
	var color := _accent_color(accent_id, appearance)
	var torso_width := 15.0 * HumanoidProfile.proportion_value(proportions, "torso_width")
	var shoulder_width := 18.0 * HumanoidProfile.proportion_value(proportions, "shoulder_width")
	var waist_width := 14.0 * HumanoidProfile.proportion_value(proportions, "waist_width")
	match accent_id:
		"accent_worker_apron":
			_draw_worker_apron(canvas, torso_x, torso_width, color)
		"accent_travel_wrap":
			_draw_travel_wrap(canvas, torso_x, shoulder_width, color)
		"accent_scribe_sash":
			_draw_scribe_sash(canvas, torso_x, shoulder_width, waist_width, color)
		"accent_guard_belt":
			_draw_guard_belt(canvas, torso_x, waist_width, color)
		"accent_elder_shawl":
			_draw_elder_shawl(canvas, torso_x, shoulder_width, color)
		"accent_caretaker_wrap":
			_draw_caretaker_wrap(canvas, torso_x, shoulder_width, color)
		"accent_public_sash":
			_draw_public_sash(canvas, torso_x, shoulder_width, waist_width, color)


static func _draw_worker_apron(
	canvas: Node2D, torso_x: float, torso_width: float, color: Color
) -> void:
	var points := PackedVector2Array(
		[
			Vector2(torso_x - torso_width * 0.24, -5.1),
			Vector2(torso_x + torso_width * 0.24, -5.1),
			Vector2(torso_x + torso_width * 0.32, 5.0),
			Vector2(torso_x, 7.0),
			Vector2(torso_x - torso_width * 0.32, 5.0)
		]
	)
	_draw_shape(canvas, points, color, OUTLINE, 0.75)
	canvas.draw_line(Vector2(torso_x, -4.0), Vector2(torso_x, 5.2), color.lightened(0.22), 0.7)


static func _draw_travel_wrap(
	canvas: Node2D, torso_x: float, shoulder_width: float, color: Color
) -> void:
	var left := torso_x - shoulder_width * 0.46
	var right := torso_x + shoulder_width * 0.42
	canvas.draw_line(Vector2(left, -6.5), Vector2(right, -3.7), color, 2.0)
	canvas.draw_line(
		Vector2(left + 1.0, -4.5),
		Vector2(right - 2.0, 1.6),
		color.darkened(0.08),
		1.4
	)


static func _draw_scribe_sash(
	canvas: Node2D, torso_x: float, shoulder_width: float, waist_width: float, color: Color
) -> void:
	canvas.draw_line(
		Vector2(torso_x - shoulder_width * 0.34, -6.4),
		Vector2(torso_x + waist_width * 0.30, 5.2),
		color,
		1.8
	)
	canvas.draw_circle(Vector2(torso_x + waist_width * 0.18, 3.7), 1.3, color.lightened(0.25))


static func _draw_guard_belt(
	canvas: Node2D, torso_x: float, waist_width: float, color: Color
) -> void:
	canvas.draw_line(
		Vector2(torso_x - waist_width * 0.48, 2.8),
		Vector2(torso_x + waist_width * 0.48, 2.8),
		color,
		2.0
	)
	canvas.draw_rect(Rect2(Vector2(torso_x - 1.4, 1.2), Vector2(2.8, 2.8)), color.lightened(0.30))


static func _draw_elder_shawl(
	canvas: Node2D, torso_x: float, shoulder_width: float, color: Color
) -> void:
	var points := PackedVector2Array(
		[
			Vector2(torso_x - shoulder_width * 0.47, -6.2),
			Vector2(torso_x - shoulder_width * 0.20, -2.2),
			Vector2(torso_x, -0.8),
			Vector2(torso_x + shoulder_width * 0.20, -2.2),
			Vector2(torso_x + shoulder_width * 0.47, -6.2),
			Vector2(torso_x + shoulder_width * 0.30, -7.4),
			Vector2(torso_x, -5.6),
			Vector2(torso_x - shoulder_width * 0.30, -7.4)
		]
	)
	_draw_shape(canvas, points, color, OUTLINE, 0.7)


static func _draw_caretaker_wrap(
	canvas: Node2D, torso_x: float, shoulder_width: float, color: Color
) -> void:
	canvas.draw_line(
		Vector2(torso_x - shoulder_width * 0.42, -5.2),
		Vector2(torso_x + shoulder_width * 0.30, -5.2),
		color,
		2.0
	)
	canvas.draw_line(Vector2(torso_x - 1.0, -5.0), Vector2(torso_x - 3.0, 4.8), color, 1.4)


static func _draw_public_sash(
	canvas: Node2D, torso_x: float, shoulder_width: float, waist_width: float, color: Color
) -> void:
	_draw_scribe_sash(canvas, torso_x, shoulder_width, waist_width, color)
	canvas.draw_line(
		Vector2(torso_x + shoulder_width * 0.28, -6.2),
		Vector2(torso_x + shoulder_width * 0.10, -1.0),
		color.lightened(0.15),
		1.2
	)


static func _draw_shape(
	canvas: Node2D,
	points: PackedVector2Array,
	fill: Color,
	outline: Color,
	outline_width: float
) -> void:
	canvas.draw_polygon(points, PackedColorArray([fill]))
	var outline_points := points.duplicate()
	outline_points.append(points[0])
	canvas.draw_polyline(outline_points, outline, outline_width)


static func _contains_any_token(text: String, tokens: Array) -> bool:
	for token in tokens:
		if text.contains(String(token)):
			return true
	return false


static func _accent_color(accent_id: String, appearance: Dictionary = {}) -> Color:
	var base: Color = COLORS.get(accent_id, Color(0.30, 0.25, 0.18))
	var key := String(appearance.get("visual_model_id", ""))
	if key.is_empty():
		key = String(appearance.get("palette_id", ""))
	if key.is_empty():
		return base
	var tint: Color = VARIANT_TINTS[StableHash.index(key, VARIANT_TINTS.size())]
	var blend := 0.58
	if String(appearance.get("people_id", "")) == "people_ravenfolk":
		blend = 0.30
	return base.lerp(tint, blend)

