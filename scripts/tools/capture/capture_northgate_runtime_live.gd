extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")

const OUTPUT_DIR := "res://reports/northgate_live_reauthored"
const WIDTH := 1152
const HEIGHT := 648
const SURFACE_VIEWS := {
	"surface_center": Vector2i(-3260, -3940),
	"surface_north": Vector2i(-3260, -3950),
	"surface_west": Vector2i(-3275, -3940),
	"surface_east": Vector2i(-3245, -3940),
	"surface_south": Vector2i(-3260, -3925),
	"building_shrine": Vector2i(-3289, -3970),
	"building_guard": Vector2i(-3274, -3970),
	"building_hall": Vector2i(-3278, -3958),
	"building_inn": Vector2i(-3249, -3960),
	"building_stable": Vector2i(-3229, -3959),
	"building_shop": Vector2i(-3289, -3934),
	"building_store": Vector2i(-3270, -3931),
	"building_west_home": Vector2i(-3287, -3917),
	"building_south_home": Vector2i(-3270, -3914),
	"building_smith": Vector2i(-3248, -3933),
	"building_east_home": Vector2i(-3228, -3930),
	"building_southeast_home": Vector2i(-3248, -3916),
	"building_far_east_home": Vector2i(-3228, -3917)
}
const INTERIOR_IDS := [
	"structure_northgate_shrine_plot",
	"structure_northgate_guard_plot",
	"structure_northgate_hall_plot",
	"structure_northgate_inn_plot",
	"structure_northgate_stable_plot",
	"structure_northgate_shop_plot",
	"structure_northgate_store_plot",
	"structure_northgate_west_home_plot",
	"structure_northgate_south_home_plot",
	"structure_northgate_smith_plot",
	"structure_northgate_east_home_plot",
	"structure_northgate_southeast_home_plot",
	"structure_northgate_far_east_home_plot"
]
const HOME_IDS := [
	"structure_northgate_west_home_plot",
	"structure_northgate_south_home_plot",
	"structure_northgate_east_home_plot",
	"structure_northgate_southeast_home_plot",
	"structure_northgate_far_east_home_plot"
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	print("Northgate live capture: boot")
	var absolute_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	var town_render := OS.get_cmdline_user_args().has("--town")
	var capture_width := 2400 if town_render else WIDTH
	var capture_height := 1900 if town_render else HEIGHT
	root.size = Vector2i(capture_width, capture_height)
	var viewport := CaptureSheetHelper.create_viewport(root, capture_width, capture_height)
	var main := Main.new()
	viewport.add_child(main)
	await _settle()
	print("Northgate live capture: main ready")
	main.begin_new_game()
	main.debug_character_creator.apply_to_player()
	main.game_started = true
	main.start_menu.hide_menu()
	await _settle()
	if town_render:
		await _capture_complete_town(main, viewport, OUTPUT_DIR.path_join("northgate_complete_town.png"))
		quit(0)
		return
	var capture_ids := INTERIOR_IDS
	if OS.get_cmdline_user_args().has("--homes"):
		capture_ids = HOME_IDS
	elif OS.get_cmdline_user_args().has("--inn"):
		capture_ids = ["structure_northgate_inn_plot"]
	print("Northgate live capture: play ready; %d structures" % capture_ids.size())
	if OS.get_cmdline_user_args().has("--activity"):
		await _capture_activity(main, viewport)
		print("Wrote Northgate activity captures to %s" % OUTPUT_DIR)
		quit(0)
		return

	if capture_ids == INTERIOR_IDS:
		for view_id in SURFACE_VIEWS:
			main.player.set_world_layer("surface")
			main.player.set_global_tile(SURFACE_VIEWS[view_id])
			main.streamer.update_center(main.player.global_tile, main.player.world_layer)
			main._sync_camera_to_player()
			await _settle()
			await _save(viewport, OUTPUT_DIR.path_join("%s.png" % view_id))
	for structure_id in capture_ids:
		print("Northgate live capture: exterior %s" % structure_id)
		var surface_center := _surface_viewpoint(main, structure_id)
		print("Northgate live capture: viewpoint %s" % surface_center)
		main.player.set_world_layer("surface")
		main.player.set_global_tile(surface_center)
		main.streamer.update_center(main.player.global_tile, main.player.world_layer)
		main._sync_camera_to_player()
		await _settle()
		print("Northgate live capture: exterior settled")
		await _save(
			viewport,
			OUTPUT_DIR.path_join("building_%s.png" % structure_id.trim_prefix("structure_northgate_").trim_suffix("_plot"))
		)
		await _save_clean(
			main, viewport,
			OUTPUT_DIR.path_join("clean_building_%s.png" % structure_id.trim_prefix("structure_northgate_").trim_suffix("_plot"))
		)

	for structure_id in capture_ids:
		print("Northgate live capture: interior %s" % structure_id)
		main.camera.zoom = Vector2(3.0, 3.0)
		main.player.set_world_layer("interior:%s" % structure_id)
		main.player.set_global_tile(_interior_center(main, structure_id))
		main.streamer.update_center(main.player.global_tile, main.player.world_layer)
		main._sync_camera_to_player()
		await _settle()
		await _save(viewport, OUTPUT_DIR.path_join("interior_%s.png" % structure_id.trim_prefix("structure_northgate_")))
		await _save_clean(
			main, viewport,
			OUTPUT_DIR.path_join("clean_interior_%s.png" % structure_id.trim_prefix("structure_northgate_"))
		)

	print("Wrote live Northgate surface and interior captures to %s" % OUTPUT_DIR)
	quit(0)


func _capture_complete_town(main, viewport: SubViewport, output_path: String) -> void:
	var center := Vector2i(-3255, -3934)
	main.player.set_world_layer("surface")
	main.player.set_global_tile(center)
	main.streamer.active_radius = 6
	# Radius changes do not trigger a reload when the player remains in the same
	# center chunk. Force the complete-town capture to populate the wider ring.
	main.streamer.current_center_chunk = Vector2i(999999, 999999)
	main.streamer.update_center(center, "surface")
	main.camera.zoom = Vector2(1.4, 1.4)
	main.camera.global_position = GridMath.tile_to_world(center)
	main.camera.reset_smoothing()
	for _frame in range(60):
		await process_frame
	await create_timer(0.25).timeout
	main.hud.hide()
	main.player.hide()
	for entity in main.entities.get_children():
		if entity.has_method("set_action_hint"):
			entity.set_action_hint(false)
	await _save(viewport, output_path)


func _capture_activity(main, viewport: SubViewport) -> void:
	# New games begin at 08:00. Let the initial wake block resolve, then advance
	# into the resident errand block and render the actual scheduled actors.
	await _simulate_activity_frames(main, 360)
	main.time.advance_minutes(60)
	await _simulate_activity_frames(main, 720)
	_print_activity_snapshot(main, "09:00")
	await _save_activity_view(
		main, viewport, Vector2i(-3260, -3940),
		OUTPUT_DIR.path_join("activity_square_0900.png")
	)
	# At 18:00 residents choose the square or inn and the north guard begins the
	# authored patrol block.
	main.time.advance_minutes(9 * 60)
	await _simulate_activity_frames(main, 720)
	_print_activity_snapshot(main, "18:00")
	await _save_activity_view(
		main, viewport, Vector2i(-3260, -3940),
		OUTPUT_DIR.path_join("activity_square_1800.png")
	)
	await _save_activity_view(
		main, viewport, Vector2i(-3260, -3956),
		OUTPUT_DIR.path_join("activity_north_gate_1800.png")
	)


func _simulate_activity_frames(main, count: int) -> void:
	for _frame in count:
		# Capture scripts can render frames much faster than wall-clock time. Give
		# the schedule brain a fixed simulation step so cross-layer commutes finish.
		main.civilian_schedules.update(1.0 / 30.0)
		await process_frame


func _print_activity_snapshot(main, label: String) -> void:
	print("Northgate activity snapshot %s" % label)
	for binding_id in main.content.schedule_bindings:
		if not String(binding_id).begins_with("binding_northgate_"):
			continue
		var binding: Dictionary = main.content.schedule_bindings[binding_id]
		var npc_id := String(binding.get("npc_id", ""))
		var state: Dictionary = main.civilian_schedules.get_schedule_debug(npc_id)
		var actor = main.entities.get_entity("%s_world" % npc_id)
		print(
			"  %s activity=%s destination=%s target_layer=%s target=%s actor_layer=%s actor_tile=%s brain=%s"
			% [
				npc_id,
				String(state.get("activity", "missing")),
				String(state.get("destination_id", "")),
				String(state.get("destination_layer", "")),
				str(state.get("destination_tile", [])),
				String(actor.data.get("world_layer", "missing")) if actor else "missing",
				str(actor.global_tile) if actor else "missing",
				String(actor.data.get("brain_id", "missing")) if actor else "missing"
			]
		)


func _save_activity_view(
	main, viewport: SubViewport, center: Vector2i, output_path: String
) -> void:
	main.player.set_world_layer("surface")
	main.player.set_global_tile(center)
	main.streamer.update_center(center, "surface")
	main._sync_camera_to_player()
	await _settle()
	var previous_process_mode: int = main.process_mode
	main.process_mode = Node.PROCESS_MODE_DISABLED
	main.hud.hide()
	main.player.hide()
	for entity in main.entities.get_children():
		if entity.has_method("set_action_hint"):
			entity.set_action_hint(false)
	await _save(viewport, output_path)
	main.process_mode = previous_process_mode
	main.hud.show()
	main.player.show()


func _structure_center(main, structure_id: String) -> Vector2i:
	for structure in main.content.world_structure_entries():
		if String(structure.get("id", "")) != structure_id:
			continue
		var origin := Vector2i(int(structure["origin_tile"][0]), int(structure["origin_tile"][1]))
		var archetype: Dictionary = main.content.get_structure_archetype(
			String(structure.get("archetype_id", ""))
		)
		var size: Array = archetype.get("size", [1, 1])
		return origin + Vector2i(int(size[0]) / 2, int(size[1]) / 2)
	return Vector2i.ZERO


func _interior_center(main, structure_id: String) -> Vector2i:
	return _structure_center(main, "%s_interior" % structure_id)


func _surface_viewpoint(main, structure_id: String) -> Vector2i:
	var center := _structure_center(main, structure_id)
	var portal_id := "portal_%s_entry" % structure_id
	for entry in main.content.world_object_entries():
		if String(entry.get("id", "")) != portal_id:
			continue
		var tile := Vector2i(int(entry["global_tile"][0]), int(entry["global_tile"][1]))
		var delta := tile - center
		var direction := Vector2i(signi(delta.x), signi(delta.y))
		if direction == Vector2i.ZERO:
			direction = Vector2i.DOWN
		return tile + direction * 2
	return center + Vector2i.DOWN * 2


func _settle() -> void:
	for _frame in range(18):
		await process_frame
	await create_timer(0.15).timeout


func _save(viewport: SubViewport, path: String) -> void:
	# `RenderingServer.frame_post_draw` is not emitted reliably by the headless
	# compatibility renderer used for this full runtime scene. Waiting for it
	# made the Northgate audit capture hang forever. Process several rendered
	# frames and read the viewport texture directly instead.
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for _frame in range(4):
		await process_frame
	var texture := viewport.get_texture()
	var image: Image = texture.get_image() if texture != null else null
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	if image == null:
		printerr("Could not capture %s" % path)
		quit(1)
		return
	var error := CaptureSheetHelper.save_png_image(image, path)
	if error != OK:
		printerr("Could not save %s: %s" % [path, error_string(error)])
		quit(1)


func _save_clean(main, viewport: SubViewport, path: String) -> void:
	# Freeze guidance while rendering. Hiding the player and clearing hints was
	# insufficient because Main rebuilt the selected exit hint on the next frame.
	var previous_process_mode: int = main.process_mode
	main.process_mode = Node.PROCESS_MODE_DISABLED
	main.hud.hide()
	main.player.hide()
	main.selected_target_id = ""
	main.manual_target_locked = false
	var hidden_npcs: Array[Node] = []
	for entity in main.entities.get_children():
		if entity.has_method("set_action_hint"):
			entity.set_action_hint(false)
		if entity.has_method("set_highlighted"):
			entity.set_highlighted(false)
		if entity.has_method("get_kind") and entity.get_kind() == "npc":
			entity.hide()
			hidden_npcs.append(entity)
	await _save(viewport, path)
	main.process_mode = previous_process_mode
	main.hud.show()
	main.player.show()
	for npc in hidden_npcs:
		if is_instance_valid(npc):
			npc.show()
