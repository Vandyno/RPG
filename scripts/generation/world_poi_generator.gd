class_name WorldPoiGenerator
extends RefCounted

const StableHash = preload("res://scripts/core/stable_hash.gd")

const GENERATOR_VERSION := "world_poi_v1"
const DEFAULT_CATALOG_PATH := "res://data/world_poi_generation_templates.json"


static func load_catalog(path: String = DEFAULT_CATALOG_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func generate(
	atlas_region_id: String,
	template_id: String,
	seed: int,
	global_tile: Vector2i,
	options: Dictionary = {}
) -> Dictionary:
	var catalog: Dictionary = options.get("catalog", load_catalog())
	var definition: Dictionary = catalog.get("templates", {}).get(template_id, {})
	if atlas_region_id.is_empty() or definition.is_empty():
		return {}
	var size := _pair(definition.get("footprint", []))
	if size.x <= 0 or size.y <= 0:
		return {}
	var origin := global_tile - size / 2
	var base := {
		"atlas_region_id": atlas_region_id, "seed": seed,
		"generator_version": GENERATOR_VERSION
	}
	var terrain: Array[Dictionary] = []
	for index in definition.get("walkable_rects", []).size():
		var rect := _rect(definition["walkable_rects"][index])
		terrain.append(
			_with_base(
				{
					"id": "poi_terrain_%s_%02d" % [template_id, index],
					"template": "poi_walkable_%s" % template_id,
					"kind": "bridge" if template_id == "bridge" else "grass",
					"rect": {"position": [origin.x + rect.position.x, origin.y + rect.position.y], "size": [rect.size.x, rect.size.y]}
				}, base
			)
		)
	var walkable_tiles := _walkable_tiles(definition.get("walkable_rects", []), origin)
	var approaches: Array = []
	for pair in definition.get("approaches", []):
		var tile := origin + _pair(pair)
		approaches.append([tile.x, tile.y])
	var slot_counts: Dictionary = definition.get("slots", {})
	var slots: Array[Dictionary] = []
	for slot_kind in ["interaction", "service", "loot"]:
		for kind_index in int(slot_counts.get(slot_kind, 0)):
			var tile := walkable_tiles[
				StableHash.index(
					"%s:%d:%s:%d" % [template_id, seed, slot_kind, kind_index],
					walkable_tiles.size()
				)
			]
			slots.append(
				_with_base(
					{
						"id": "poi_slot_%s_%s_%02d" % [template_id, slot_kind, kind_index],
						"template": "poi_%s_slot" % slot_kind,
						"slot_kind": slot_kind,
						"global_tile": [tile.x, tile.y]
					}, base
				)
			)
	var quest_hooks: Array[Dictionary] = []
	for hook_index in int(slot_counts.get("quest_hooks", 0)):
		quest_hooks.append(
			_with_base(
				{
					"id": "poi_hook_%s_%02d" % [template_id, hook_index],
					"template": "poi_quest_hook",
					"status": "proposal_slot"
				}, base
			)
		)
	return {
		"schema_version": "1.0.0",
		"proposal_status": "proposal",
		"activation_status": "review_required",
		"id": "proposal_poi_%s_%s_seed_%d" % [atlas_region_id, template_id, seed],
		"atlas_region_id": atlas_region_id,
		"seed": seed,
		"template": template_id,
		"template_catalog_version": String(catalog.get("catalog_version", "")),
		"generator_version": GENERATOR_VERSION,
		"global_tile": [global_tile.x, global_tile.y],
		"bounds": {"position": [origin.x, origin.y], "size": [size.x, size.y]},
		"walkability": {"required": true, "approach_tiles": approaches},
		"terrain": terrain,
		"slots": slots,
		"visual_style": String(definition.get("visual_style", "")),
		"encounter_rules": {"status": "proposal", "allowed": true, "profile": String(definition.get("encounter", "local_pressure"))},
		"quest_hooks": quest_hooks,
		"review": {"canon_status": "proposal", "required_artifacts": ["overview_screenshot", "validation_report"]}
	}


static func _walkable_tiles(rects: Array, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value in rects:
		var rect := _rect(value)
		for y in rect.size.y:
			for x in rect.size.x:
				result.append(origin + rect.position + Vector2i(x, y))
	return result


static func _with_base(value: Dictionary, base: Dictionary) -> Dictionary:
	var result := value.duplicate(true)
	result.merge(base, true)
	return result


static func _rect(value: Variant) -> Rect2i:
	if not value is Dictionary:
		return Rect2i()
	return Rect2i(_pair(value.get("position", [])), _pair(value.get("size", [])))


static func _pair(value: Variant) -> Vector2i:
	if not value is Array or value.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))
