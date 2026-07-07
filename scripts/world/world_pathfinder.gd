class_name WorldPathfinder
extends RefCounted

const GridMath = preload("res://scripts/core/grid_math.gd")

const MAX_SEARCH_RADIUS := 28


static func path_to(query: Dictionary, from_world: Vector2, to_world: Vector2) -> Array[Vector2]:
	if not _can_stand_at(query, to_world):
		return []
	var start_tile := GridMath.world_to_tile(from_world)
	var goal_tile := GridMath.world_to_tile(to_world)
	if start_tile == goal_tile:
		return [to_world]
	var tiles := _tile_path(query, start_tile, goal_tile)
	if tiles.is_empty():
		return []
	var points: Array[Vector2] = []
	for index in range(1, tiles.size()):
		points.append(_tile_center(tiles[index]))
	if points.is_empty() or points[points.size() - 1].distance_to(to_world) > 1.0:
		points.append(to_world)
	return _simplified_points(query, from_world, points)


static func approach_path_to(
	query: Dictionary, from_world: Vector2, target_world: Vector2, stop_distance: float
) -> Array[Vector2]:
	if stop_distance <= 0.0:
		return []
	if from_world.distance_to(target_world) <= stop_distance:
		return [from_world]
	for candidate in _approach_candidates(query, from_world, target_world, stop_distance):
		var path := path_to(query, from_world, candidate)
		if not path.is_empty():
			return path
	return []


static func _approach_candidates(
	query: Dictionary, from_world: Vector2, target_world: Vector2, stop_distance: float
) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	var target_tile := GridMath.world_to_tile(target_world)
	var tile_radius := int(ceil(stop_distance / float(GridMath.TILE_SIZE))) + 2
	for y in range(target_tile.y - tile_radius, target_tile.y + tile_radius + 1):
		for x in range(target_tile.x - tile_radius, target_tile.x + tile_radius + 1):
			var point := _tile_center(Vector2i(x, y))
			if point.distance_to(target_world) > stop_distance:
				continue
			if _can_stand_at(query, point):
				candidates.append(point)
	if _can_stand_at(query, target_world):
		candidates.append(target_world)
	candidates.sort_custom(
		func(a: Vector2, b: Vector2) -> bool:
			var score_a := from_world.distance_squared_to(a)
			var score_b := from_world.distance_squared_to(b)
			if not is_equal_approx(score_a, score_b):
				return score_a < score_b
			return a.distance_squared_to(target_world) < b.distance_squared_to(target_world)
	)
	return candidates


static func _tile_path(
	query: Dictionary, start_tile: Vector2i, goal_tile: Vector2i
) -> Array[Vector2i]:
	var frontier: Array[Vector2i] = [start_tile]
	var came_from: Dictionary = {_tile_key(start_tile): start_tile}
	var min_x := mini(start_tile.x, goal_tile.x) - MAX_SEARCH_RADIUS
	var max_x := maxi(start_tile.x, goal_tile.x) + MAX_SEARCH_RADIUS
	var min_y := mini(start_tile.y, goal_tile.y) - MAX_SEARCH_RADIUS
	var max_y := maxi(start_tile.y, goal_tile.y) + MAX_SEARCH_RADIUS
	var read_index := 0
	while read_index < frontier.size():
		var current := frontier[read_index]
		read_index += 1
		if current == goal_tile:
			return _reconstruct_path(came_from, start_tile, goal_tile)
		for neighbor in _neighbors(current):
			if neighbor.x < min_x or neighbor.x > max_x or neighbor.y < min_y or neighbor.y > max_y:
				continue
			var key := _tile_key(neighbor)
			if came_from.has(key):
				continue
			if not _can_stand_at(query, _tile_center(neighbor)):
				continue
			came_from[key] = current
			frontier.append(neighbor)
	return []


static func _reconstruct_path(
	came_from: Dictionary, start_tile: Vector2i, goal_tile: Vector2i
) -> Array[Vector2i]:
	var path: Array[Vector2i] = [goal_tile]
	var current := goal_tile
	while current != start_tile:
		current = came_from[_tile_key(current)]
		path.push_front(current)
	return path


static func _simplified_points(
	query: Dictionary, from_world: Vector2, points: Array[Vector2]
) -> Array[Vector2]:
	var simplified: Array[Vector2] = []
	var anchor := from_world
	var index := 0
	while index < points.size():
		var farthest := index
		for candidate in range(points.size() - 1, index - 1, -1):
			if _has_clear_segment(query, anchor, points[candidate]):
				farthest = candidate
				break
		simplified.append(points[farthest])
		anchor = points[farthest]
		index = farthest + 1
	return simplified


static func _has_clear_segment(query: Dictionary, start: Vector2, end: Vector2) -> bool:
	var delta := end - start
	var distance := delta.length()
	if distance <= 1.0:
		return true
	var direction := delta / distance
	var step := maxf(4.0, float(GridMath.TILE_SIZE) * 0.5)
	var traveled := step
	while traveled < distance:
		if not _can_stand_at(query, start + direction * traveled):
			return false
		traveled += step
	return _can_stand_at(query, end)


static func _can_stand_at(query: Dictionary, world_position: Vector2) -> bool:
	var can_stand_at: Callable = query.get("can_stand_at", Callable())
	return can_stand_at.is_valid() and bool(can_stand_at.call(world_position))


static func _neighbors(tile: Vector2i) -> Array[Vector2i]:
	return [
		tile + Vector2i(1, 0), tile + Vector2i(-1, 0), tile + Vector2i(0, 1), tile + Vector2i(0, -1)
	]


static func _tile_center(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5


static func _tile_key(tile: Vector2i) -> String:
	return "%d:%d" % [tile.x, tile.y]
