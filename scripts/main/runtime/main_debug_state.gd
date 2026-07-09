class_name MainDebugState
extends RefCounted

const GridMath = preload("res://scripts/core/grid_math.gd")
const MainHudState = preload("res://scripts/main/ui/main_hud_state.gd")


static func build(main) -> Dictionary:
	var state: Dictionary = main.get_hud_state()
	state.merge(
		{
			"player_world": "(%.1f, %.1f)" % [main.player.position.x, main.player.position.y],
			"player_layer": main.player.world_layer,
			"player_tile": str(main.player.global_tile),
			"player_chunk": str(GridMath.tile_to_chunk(main.player.global_tile)),
			"terrain": main.world_query.get_tile_kind(main.player.global_tile, main.player.world_layer),
			"loaded_chunk_count": main.streamer.get_loaded_chunk_keys().size(),
			"nearby_all": main.hud_queries.nearby_entities_text(
				main._ranked_nearby_entities(), main.selected_target_id
			),
			"navigation": main.entities.get_navigation_summary(main.player.global_position),
			"flags":
			(
				", ".join(main.world_state.flags.keys())
				if not main.world_state.flags.is_empty()
				else "none"
			)
		},
		true
		)
	return state
