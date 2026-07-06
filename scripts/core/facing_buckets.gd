class_name FacingBuckets
extends RefCounted

const COUNT := 16
const IDS := [
	"east",
	"east_southeast",
	"southeast",
	"south_southeast",
	"south",
	"south_southwest",
	"southwest",
	"west_southwest",
	"west",
	"west_northwest",
	"northwest",
	"north_northwest",
	"north",
	"north_northeast",
	"northeast",
	"east_northeast"
]


static func snap_direction(value: Vector2, fallback: Vector2 = Vector2.DOWN) -> Vector2:
	var direction := value
	if direction.length() <= 0.01:
		direction = fallback
	if direction.length() <= 0.01:
		direction = Vector2.DOWN
	var slice := TAU / float(COUNT)
	var snapped_angle := float(bucket_index(direction)) * slice
	return Vector2(cos(snapped_angle), sin(snapped_angle)).normalized()


static func bucket_index(value: Vector2) -> int:
	var direction := value
	if direction.length() <= 0.01:
		direction = Vector2.DOWN
	var angle := fposmod(direction.normalized().angle(), TAU)
	var slice := TAU / float(COUNT)
	return int(round(angle / slice)) % COUNT


static func bucket_id(value: Vector2) -> String:
	return String(IDS[bucket_index(value)])
