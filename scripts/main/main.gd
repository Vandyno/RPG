# gdlint:disable=max-file-lines
extends Node2D
const GridMath = preload("res://scripts/core/grid_math.gd")
const ConditionEvaluatorScript = preload("res://scripts/core/condition_evaluator.gd")
const EventBusScript = preload("res://scripts/core/event_bus.gd")
const EffectRunnerScript = preload("res://scripts/core/effect_runner.gd")
const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")
const ContentDatabaseScript = preload("res://scripts/data/content_database.gd")
const WorldStateManagerScript = preload("res://scripts/managers/world/world_state_manager.gd")
const InventoryManagerScript = preload("res://scripts/managers/actors/inventory_manager.gd")
const QuestManagerScript = preload("res://scripts/managers/content/quest_manager.gd")
const FactionManagerScript = preload("res://scripts/managers/content/faction_manager.gd")
const ProgressionManagerScript = preload("res://scripts/managers/actors/progression_manager.gd")
const StatusEffectManagerScript = preload("res://scripts/managers/actors/status_effect_manager.gd")
const TimeManagerScript = preload("res://scripts/managers/content/time_manager.gd")
const ShopManagerScript = preload("res://scripts/managers/content/shop_manager.gd")
const ReadableManagerScript = preload("res://scripts/managers/content/readable_manager.gd")
const DialogueManagerScript = preload("res://scripts/managers/content/dialogue_manager.gd")
const ChunkManagerScript = preload("res://scripts/managers/world/chunk_manager.gd")
const StructureManagerScript = preload("res://scripts/managers/world/structure_manager.gd")
const WorldStreamingManagerScript = preload(
	"res://scripts/managers/world/world_streaming_manager.gd"
)
const WorldQueryScript = preload("res://scripts/world/world_query.gd")
const EntityManagerScript = preload("res://scripts/managers/world/entity_manager.gd")
const CombatManagerScript = preload("res://scripts/managers/actors/combat_manager.gd")
const EquipmentManagerScript = preload("res://scripts/managers/actors/equipment_manager.gd")
const PlayerControllerScript = preload("res://scripts/player/player_controller.gd")
const SaveManagerScript = preload("res://scripts/managers/persistence/save_manager.gd")
const RpgHudScript = preload("res://scripts/ui/rpg/rpg_hud.gd")
const GameStartMenuScript = preload("res://scripts/ui/start/game_start_menu.gd")
const PrimaryActionTextBuilder = preload("res://scripts/ui/text/primary_action_text_builder.gd")
const DebugCharacterCreatorScript = preload("res://scripts/ui/debug/debug_character_creator.gd")
const InteractionTargetSelector = preload("res://scripts/main/input/interaction_target_selector.gd")
const MainInputRouter = preload("res://scripts/main/input/main_input_router.gd")
const MainHudState = preload("res://scripts/main/ui/main_hud_state.gd")
const MainHudQueries = preload("res://scripts/main/ui/main_hud_queries.gd")
const MainDebugState = preload("res://scripts/main/runtime/main_debug_state.gd")
const MainSaveProviders = preload("res://scripts/main/runtime/main_save_providers.gd")
const MainWorldGuidance = preload("res://scripts/main/ui/main_world_guidance.gd")
const MainContextActions = preload("res://scripts/main/actions/main_context_actions.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")
const MainInventoryTransfer = preload("res://scripts/main/actions/main_inventory_transfer.gd")
const MainObjectInteractions = preload("res://scripts/main/actions/main_object_interactions.gd")
const MainCameraFraming = preload("res://scripts/main/runtime/main_camera_framing.gd")
const HostileActorBrain = preload("res://scripts/main/runtime/hostile_actor_brain.gd")
const CivilianScheduleBrain = preload("res://scripts/main/runtime/civilian_schedule_brain.gd")
const CivilianScheduleManagerScript = preload("res://scripts/managers/content/civilian_schedule_manager.gd")
const NpcPerceptionManagerScript = preload("res://scripts/managers/content/npc_perception_manager.gd")
const CrimeManagerScript = preload("res://scripts/managers/content/crime_manager.gd")
const CompanionManagerScript = preload("res://scripts/managers/content/companion_manager.gd")
const PoiInteraction = preload("res://scripts/main/actions/poi_interaction.gd")
var event_bus: EventBus
var condition_evaluator: ConditionEvaluator
var effect_runner: EffectRunner
var content: ContentDatabase
var world_state: WorldStateManager
var inventory: InventoryManager
var quests: QuestManager
var factions: FactionManager
var progression: ProgressionManager
var statuses: StatusEffectManager
var time: TimeManager
var shops: ShopManager
var readables: ReadableManager
var dialogues: DialogueManager
var chunks: ChunkManager
var structures: StructureManager
var world_query: WorldQuery
var streamer: WorldStreamingManager
var entities: EntityManager
var combat: CombatManager
var equipment: EquipmentManager
var spells: SpellManager
var player: PlayerController
var save_manager: SaveManager
var civilian_schedules: CivilianScheduleManager
var npc_perception: NpcPerceptionManager
var crime: CrimeManager
var companions
var hud: RpgHud
var hud_queries: MainHudQueries
var debug_character_creator: DebugCharacterCreator
var start_menu: GameStartMenu
var game_started := false
var camera: Camera2D
var active_interaction_id := ""
var target_cycle_index := 0
var selected_target_id := ""
var manual_target_locked := false
var seeded_inventory_owner_ids: Dictionary = {}
var auto_interact_target_id := ""
var auto_interact_previous_distance := INF
var auto_interact_stuck_seconds := 0.0
var auto_move_active := false
var auto_move_destination := Vector2.ZERO
var auto_move_previous_distance := INF
var auto_move_stuck_seconds := 0.0
var auto_move_path: Array = []
var auto_move_path_index := 0
var active_content_choices: Dictionary = {}
var active_transfer_owner_id := ""
var active_transfer_name := ""
var active_transfer_source_id := ""
var active_transfer_source_kind := ""
var active_transfer_source_tile := Vector2i.ZERO
var active_transfer_access_mode := ""
var channeled_spell_damage_bank: Dictionary = {}
var channeled_spell_empty_reported: Dictionary = {}
var held_weapon_attack_elapsed: Dictionary = {}


func _ready() -> void:
	if _bootstrap():
		if _running_unit_tests():
			game_started = true
			start_menu.hide_menu()
		else:
			_show_start_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not game_started:
		return
	MainInputRouter.handle_event(MainInputRouter.context(self), event)


func _process(delta: float) -> void:
	_sync_camera_to_player()
	MainInputRouter.update_auto_interaction(MainInputRouter.context(self), delta)
	HostileActorBrain.update(HostileActorBrain.context(self), delta)
	CivilianScheduleBrain.update(civilian_schedules, delta)
	if companions:
		companions.update(delta)
	if npc_perception and hud:
		npc_perception.set_debug_visible(bool(hud.visible_debug))
	_update_location_discoveries()
	_update_nearby()


func apply_effect(effect: Dictionary, emit_feedback: bool = true) -> bool:
	return effect_runner.apply(effect, emit_feedback)


func clear_target_state() -> void:
	selected_target_id = ""
	target_cycle_index = 0
	manual_target_locked = false


func get_hud_state() -> Dictionary:
	return MainHudState.build(_hud_context())


func get_debug_state() -> Dictionary:
	return MainDebugState.build(self)


func _hud_context() -> MainHudState.HudContext:
	var nearby := _get_nearby_entity()
	var auto_target = entities.get_entity(auto_interact_target_id)
	var nearby_targets := _ranked_nearby_entities()
	var nearby_target_rows := hud_queries.nearby_targets_data(
		nearby_targets, selected_target_id, player.global_position
	)
	return MainHudState.HudContext.new(
		MainHudState.HudDataSources.new(
			content,
			entities,
			inventory,
			equipment,
			spells,
			progression,
			quests,
			statuses,
			factions,
			time,
			crime,
			npc_perception
		),
		MainHudState.HudUiServices.new(hud_queries, _action_list_context(), world_state),
		MainHudState.HudSnapshot.new(
			active_transfer_name,
			active_transfer_owner_id,
			auto_interact_target_id,
			auto_move_active,
			_current_location_name(),
			nearby,
			nearby_target_rows,
			player,
			_primary_action_text(nearby, auto_target),
			hud_queries.shop_id_for_entity(nearby)
		)
	)


func _current_location_name() -> String:
	if not player:
		return ""
	if player.world_layer == "surface" and entities:
		for entity in entities.get_entities_world(
			player.global_position, _max_location_discovery_radius(), "location"
		):
			var radius := VariantFields.positive_float_field_at_least(
				entity.data, "discovery_radius", EntityManagerScript.DEFAULT_INTERACTION_RADIUS_PIXELS, 1.0
			)
			if player.global_position.distance_to(entity.global_position) <= radius:
				return entity.get_display_name()
		return ""
	if player.world_layer.begins_with("interior:") and structures:
		var structure_id := player.world_layer.trim_prefix("interior:")
		var structure := structures.get_structure(structure_id)
		return String(structure.get("name", ""))
	return player.world_layer


func _action_list_context() -> MainContextActions.ActionListContext:
	return MainContextActions.action_list_context(self)


func _preferred_primary_context_action_for(entity) -> Dictionary:
	return MainContextActions.preferred_primary(_action_list_context(), entity)


func _handle_target_entity_intent(entity_id: String) -> void:
	MainInputRouter.target_entity(MainInputRouter.context(self), entity_id)


func _bootstrap() -> bool:
	_bootstrap_event_bus()
	if not _bootstrap_content():
		set_process(false)
		return false
	_bootstrap_core_managers()
	_bootstrap_content_services()
	_bootstrap_world_runtime()
	_bootstrap_actor_runtime()
	_bootstrap_player()
	_bootstrap_hud_queries()
	_bootstrap_camera()
	_bootstrap_save_manager()
	_bootstrap_hud()
	_bootstrap_debug_character_creator()
	_bootstrap_runtime_signals()
	_bootstrap_start_menu()
	streamer.update_center(player.global_tile, player.world_layer)
	_sync_camera_to_player()
	return true


func _bootstrap_event_bus() -> void:
	event_bus = EventBusScript.new()
	event_bus.name = "EventBus"
	add_child(event_bus)


func _bootstrap_content() -> bool:
	content = _create_content_database()
	content.name = "ContentDatabase"
	add_child(content)
	var content_load_errors: Array[String] = content.load_all()
	if not content_load_errors.is_empty():
		_report_content_bootstrap_errors(
			content_load_errors, "Content failed to load. Check content file errors."
		)
		return false
	var content_validation_errors: Array[String] = content.validate_all()
	if not content_validation_errors.is_empty():
		_report_content_bootstrap_errors(
			content_validation_errors, "Content failed validation. Check content file errors."
		)
		return false
	return true


func _bootstrap_core_managers() -> void:
	world_state = WorldStateManagerScript.new()
	world_state.name = "WorldStateManager"
	add_child(world_state)
	world_state.setup(event_bus)
	inventory = InventoryManagerScript.new()
	inventory.name = "InventoryManager"
	add_child(inventory)
	inventory.setup(event_bus, content)
	quests = QuestManagerScript.new()
	quests.name = "QuestManager"
	add_child(quests)
	quests.setup(event_bus, content)
	factions = FactionManagerScript.new()
	factions.name = "FactionManager"
	add_child(factions)
	factions.setup(event_bus, content)
	progression = ProgressionManagerScript.new()
	progression.name = "ProgressionManager"
	add_child(progression)
	progression.setup(event_bus)

	statuses = StatusEffectManagerScript.new()
	statuses.name = "StatusEffectManager"
	add_child(statuses)
	statuses.setup(event_bus, content)

	time = TimeManagerScript.new()
	time.name = "TimeManager"
	add_child(time)
	time.setup(event_bus)


func _bootstrap_content_services() -> void:
	effect_runner = EffectRunnerScript.new()
	effect_runner.setup(
		EffectRunnerScript.Dependencies.new(
			{
				"world_state": world_state,
				"quests": quests,
				"inventory": inventory,
				"content": content,
				"factions": factions,
				"progression": progression,
				"time": time,
				"statuses": statuses,
				"event_bus": event_bus
			}
		)
	)

	readables = ReadableManagerScript.new()
	readables.name = "ReadableManager"
	add_child(readables)
	readables.setup(event_bus, content, Callable(self, "apply_effect"))

	condition_evaluator = ConditionEvaluatorScript.new()
	condition_evaluator.setup(
		ConditionEvaluatorScript.Services.new(
			{
				"world_state": world_state,
				"quests": quests,
				"inventory": inventory,
				"readables": readables,
				"factions": factions,
				"progression": progression,
				"time": time
			}
		)
	)

	dialogues = DialogueManagerScript.new()
	dialogues.name = "DialogueManager"
	add_child(dialogues)
	dialogues.setup(content, condition_evaluator, effect_runner)


func _bootstrap_world_runtime() -> void:
	chunks = ChunkManagerScript.new()
	chunks.name = "ChunkManager"
	add_child(chunks)
	chunks.load_world_terrain(content.get_world_terrain())

	structures = StructureManagerScript.new()
	structures.name = "StructureManager"
	add_child(structures)
	structures.setup(content)

	world_query = WorldQueryScript.new()
	world_query.setup(chunks, structures)

	streamer = WorldStreamingManagerScript.new()
	streamer.name = "WorldStreamingManager"
	add_child(streamer)
	streamer.setup(event_bus, world_query)


func _bootstrap_actor_runtime() -> void:
	entities = EntityManagerScript.new()
	entities.name = "EntityManager"
	add_child(entities)
	entities.setup(event_bus, content, chunks, condition_evaluator, inventory)

	equipment = EquipmentManagerScript.new()
	equipment.name = "EquipmentManager"
	add_child(equipment)
	equipment.setup(event_bus, content, inventory)
	if effect_runner:
		effect_runner.set_equipment(equipment)

	spells = SpellManager.new()
	spells.name = "SpellManager"
	add_child(spells)
	spells.setup(event_bus, content)

	shops = ShopManagerScript.new()
	shops.name = "ShopManager"
	add_child(shops)
	shops.setup(event_bus, content, inventory, equipment, time)

	combat = CombatManagerScript.new()
	combat.name = "CombatManager"
	add_child(combat)
	combat.setup(event_bus, equipment, progression, statuses)

	civilian_schedules = CivilianScheduleManagerScript.new()
	civilian_schedules.name = "CivilianScheduleManager"
	add_child(civilian_schedules)
	civilian_schedules.setup(event_bus, content, time, entities, chunks, world_query, combat, quests)
	npc_perception = NpcPerceptionManagerScript.new()
	npc_perception.name = "NpcPerceptionManager"
	add_child(npc_perception)
	npc_perception.setup(event_bus, entities, world_query, time)

	crime = CrimeManagerScript.new()
	crime.name = "CrimeManager"
	add_child(crime)
	crime.setup(event_bus, entities, npc_perception, time, factions, civilian_schedules, chunks, inventory)
	companions = CompanionManagerScript.new()
	companions.name = "CompanionManager"
	add_child(companions)
	companions.setup(event_bus, entities, chunks, combat)
	shops.set_schedule_manager(civilian_schedules)
	shops.set_crime_manager(crime)


func _bootstrap_player() -> void:
	player = PlayerControllerScript.new()
	player.name = "Player"
	add_child(player)
	player.setup(event_bus, world_query, Vector2i.ZERO)
	player.set_humanoid_profile(content.get_resolved_character_profile("char_player"))
	civilian_schedules.set_player(player)
	crime.set_player(player)
	companions.set_player(player)
	event_bus.player_jailed.connect(_on_player_jailed)
	event_bus.player_released_from_jail.connect(_on_player_released_from_jail)
	effect_runner.set_player(player)
	event_bus.equipment_changed.connect(
		func(equipped_by_slot: Dictionary) -> void:
			player.set_equipped_items(equipped_by_slot, content)
	)


func _on_player_jailed(state: Dictionary) -> void:
	_transport_player_for_law(state)


func _on_player_released_from_jail(state: Dictionary) -> void:
	_transport_player_for_law(state)


func _transport_player_for_law(state: Dictionary) -> void:
	if not player:
		return
	var target_layer := String(state.get("target_layer", "surface"))
	var target_tile := VariantFields.vector2i_from_pair(
		state.get("target_tile", []), player.global_tile
	)
	player.set_world_layer(target_layer)
	player.set_global_tile(target_tile)
	world_query.set_layer(target_layer)
	streamer.update_center(target_tile, target_layer)
	clear_target_state()
	_sync_camera_to_player()
	_update_nearby()


func _bootstrap_hud_queries() -> void:
	hud_queries = MainHudQueries.new()
	hud_queries.setup(
		MainHudQueries.Dependencies.new(
			{
				"chunks": chunks,
				"combat": combat,
				"condition_evaluator": condition_evaluator,
				"content": content,
				"equipment": equipment,
				"entities": entities,
				"factions": factions,
				"inventory": inventory,
				"player": player,
				"progression": progression,
				"quests": quests,
				"shops": shops
			}
		)
	)


func _bootstrap_camera() -> void:
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(2.0, 2.0)
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)


func _bootstrap_save_manager() -> void:
	save_manager = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	add_child(save_manager)
	save_manager.setup(event_bus, MainSaveProviders.build(self))


func _bootstrap_hud() -> void:
	hud = RpgHudScript.new()
	hud.name = "RpgHud"
	add_child(hud)
	hud.setup(event_bus, Callable(self, "get_hud_state"))
	_bootstrap_hud_signals()


func _bootstrap_hud_signals() -> void:
	hud.interact_pressed.connect(_handle_interact_requested)
	hud.cycle_target_pressed.connect(_handle_cycle_target_requested)
	hud.target_selected.connect(_handle_target_selected)
	hud.target_used.connect(_handle_target_used)
	hud.content_choice_selected.connect(_handle_content_choice_selected)
	hud.content_card_closed.connect(_handle_content_card_closed)
	hud.inventory_item_selected.connect(_handle_inventory_item_selected)
	hud.aim_action_released.connect(
		func(action_id: String, direction: Vector2) -> void:
			MainSystemsActions.handle_aim(
				MainSystemsActions.aim_context(self), action_id, direction
			)
	)
	hud.aim_action_held.connect(
		func(action_id: String, direction: Vector2, delta: float) -> void:
			MainSystemsActions.handle_aim_held(
				MainSystemsActions.aim_context(self), action_id, direction, delta
			)
	)
	hud.context_action_selected.connect(_handle_context_action_selected)
	hud.save_pressed.connect(_handle_save_requested)
	hud.load_pressed.connect(_handle_load_requested)
	hud.move_vector_changed.connect(player.set_external_move_vector)
	hud.sneak_pressed.connect(_handle_sneak_pressed)
	hud.systems_panel_closed.connect(_handle_systems_panel_closed)
	hud.systems_tab_changed.connect(_handle_systems_tab_changed)


func _bootstrap_debug_character_creator() -> void:
	debug_character_creator = DebugCharacterCreatorScript.new()
	debug_character_creator.name = "DebugCharacterCreator"
	add_child(debug_character_creator)
	debug_character_creator.setup(content, player)
	debug_character_creator.appearance_applied.connect(
		func(profile: Dictionary) -> void:
			event_bus.post_message(
				(
					"Applied %s appearance."
					% content.get_people(String(profile.get("people_id", ""))).get(
						"display_name", String(profile.get("people_id", ""))
					)
				)
			)
			_refresh_hud()
	)
	debug_character_creator.creation_confirmed.connect(_on_new_character_confirmed)
	debug_character_creator.creation_cancelled.connect(_show_start_menu)


func _bootstrap_start_menu() -> void:
	start_menu = GameStartMenuScript.new()
	start_menu.name = "GameStartMenu"
	add_child(start_menu)
	start_menu.setup(FileAccess.file_exists(save_manager.save_path))
	start_menu.new_game_pressed.connect(begin_new_game)
	start_menu.continue_pressed.connect(continue_game)


func begin_new_game() -> void:
	if not debug_character_creator:
		return
	if start_menu:
		start_menu.hide_menu()
	debug_character_creator.begin_new_character()


func continue_game() -> void:
	var result := save_manager.load_game() if save_manager else null
	if result == null or not result.ok:
		if start_menu:
			start_menu.set_status(
				"Could not load that journey. Start a new one or check the save file."
			)
		return
	game_started = true
	if start_menu:
		start_menu.hide_menu()
	streamer.update_center(player.global_tile, player.world_layer)
	_sync_camera_to_player()
	event_bus.post_message("Welcome back to Briarwatch.")


func _on_new_character_confirmed(_profile: Dictionary) -> void:
	game_started = true
	streamer.update_center(player.global_tile, player.world_layer)
	_sync_camera_to_player()
	event_bus.post_message("Briarwatch awaits. Read, talk, trade, take jobs, save, and load.")


func _show_start_menu() -> void:
	game_started = false
	if start_menu:
		start_menu.show_menu(FileAccess.file_exists(save_manager.save_path))


func _running_unit_tests() -> bool:
	for argument in OS.get_cmdline_args():
		if String(argument).contains("gut_cmdln.gd"):
			return true
	return false


func _bootstrap_runtime_signals() -> void:
	event_bus.player_tile_changed.connect(_on_player_tile_changed)


func _create_content_database() -> ContentDatabase:
	return ContentDatabaseScript.new()


func _report_content_bootstrap_errors(errors: Array[String], summary: String) -> void:
	for error in errors:
		push_error(error)
		event_bus.post_message(error)
	event_bus.post_message(summary)


func _on_player_tile_changed(global_tile: Vector2i, _chunk_coord: Vector2i) -> void:
	streamer.update_center(global_tile, player.world_layer if player else "surface")


func _sync_camera_to_player() -> void:
	if not camera or not player:
		return
	camera.global_position = MainCameraFraming.position_for_player(
		player.global_position, _camera_focus_position(), get_viewport_rect().size, camera.zoom
	)
	camera.reset_smoothing()


func _camera_focus_position() -> Vector2:
	var entity = entities.get_entity(selected_target_id) if entities else null
	if not entity and entities and not String(auto_interact_target_id).is_empty():
		entity = entities.get_entity(auto_interact_target_id)
	return entity.global_position if entity else player.global_position


func _update_nearby() -> void:
	var nearby = _get_nearby_entity()
	var nearby_entities := _get_nearby_entities()
	MainWorldGuidance.sync(self, nearby_entities)
	if nearby:
		var entity_id: String = nearby.get_entity_id()
		entities.set_highlighted_entity(entity_id)
		if active_interaction_id != entity_id:
			active_interaction_id = entity_id
			event_bus.interaction_available.emit(entity_id)
	else:
		entities.set_highlighted_entity("")
		if not active_interaction_id.is_empty():
			active_interaction_id = ""
			event_bus.interaction_cleared.emit()
	_refresh_hud()


func _update_location_discoveries() -> void:
	for entity in entities.get_entities_world(
		player.global_position, _max_location_discovery_radius(), "location"
	):
		var location_id := String(entity.data.get("location_id", ""))
		var radius := VariantFields.positive_float_field_at_least(
			entity.data, "discovery_radius", EntityManagerScript.DEFAULT_INTERACTION_RADIUS_PIXELS, 1.0
		)
		if player.global_position.distance_to(entity.global_position) > radius:
			continue
		if world_state.discover_location(location_id):
			event_bus.post_message("Discovered %s." % entity.get_display_name())


func _max_location_discovery_radius() -> float:
	var radius := EntityManagerScript.DEFAULT_INTERACTION_RADIUS_PIXELS
	for entry in content.world_object_entries():
		if String(entry.get("kind", "")) == "location":
			radius = maxf(
				radius,
				VariantFields.positive_float_field_at_least(
					entry, "discovery_radius", EntityManagerScript.DEFAULT_INTERACTION_RADIUS_PIXELS, 1.0
				)
			)
	return radius


func _handle_interact_requested() -> void:
	if not String(auto_interact_target_id).is_empty():
		MainInputRouter.cancel_auto_interaction(MainInputRouter.context(self))
		return
	if auto_move_active:
		MainInputRouter.cancel_auto_move(MainInputRouter.context(self))
		return
	if hud and hud.is_target_picker_visible():
		hud.hide_target_picker()
	elif _close_open_overlay_panel():
		return
	var nearby = _get_nearby_entity()
	var preferred := _preferred_primary_context_action_for(nearby)
	if not preferred.is_empty():
		_handle_context_action_selected(String(preferred.get("id", "")))
		return
	_interact()


func _handle_sneak_pressed() -> void:
	var sneaking: bool = player.toggle_sneaking()
	event_bus.post_message("Sneaking." if sneaking else "Standing.")
	_refresh_hud()


func _handle_systems_panel_closed() -> void:
	_clear_active_transfer(false)


func _handle_systems_tab_changed(tab_id: String) -> void:
	if tab_id != "inventory":
		_clear_active_transfer(false)


func _handle_cycle_target_requested() -> void:
	if hud and hud.is_content_card_visible():
		hud.hide_content_card()
	if hud and (hud.is_systems_panel_visible() or hud.is_target_picker_visible()):
		if _close_open_overlay_panel():
			return
	elif _close_open_overlay_panel():
		return
	var nearby_entities := _get_nearby_entities()
	if nearby_entities.size() < 2:
		event_bus.post_message("No alternate target nearby.")
		return
	selected_target_id = InteractionTargetSelector.next_id(
		nearby_entities,
		selected_target_id,
		target_cycle_index,
		player.global_position,
		player.get_facing_direction()
	)
	target_cycle_index = _index_of_target_id(nearby_entities, selected_target_id)
	manual_target_locked = true
	var entity = _get_nearby_entity()
	if entity:
		event_bus.post_message("Targeting %s." % entity.get_display_name())
	_update_nearby()


func _handle_target_selected(entity_id: String) -> void:
	_select_nearby_target(entity_id, true)


func _handle_target_used(entity_id: String) -> void:
	if _select_nearby_target(entity_id, false):
		_handle_interact_requested()


func _select_nearby_target(entity_id: String, post_targeting_message: bool) -> bool:
	var nearby_entities := _get_nearby_entities()
	var selected_index := _index_of_target_id(nearby_entities, entity_id)
	if selected_index < 0:
		if hud:
			hud.hide_target_picker()
		event_bus.post_message("Target is no longer nearby.")
		manual_target_locked = false
		_update_nearby()
		return false
	target_cycle_index = selected_index
	selected_target_id = entity_id
	manual_target_locked = true
	var entity = nearby_entities[selected_index]
	if hud:
		hud.hide_target_picker()
	if post_targeting_message:
		event_bus.post_message("Targeting %s." % entity.get_display_name())
	_update_nearby()
	return true


func _handle_save_requested() -> void:
	_close_open_overlay_panel(false)
	save_manager.save_game()


func _handle_load_requested() -> void:
	_close_open_overlay_panel(false)
	save_manager.load_game()


func toggle_debug_character_creator() -> void:
	if not debug_character_creator:
		return
	if not debug_character_creator.is_open():
		_close_open_overlay_panel(false)
	debug_character_creator.toggle_open()


func open_character_appearance() -> void:
	if not debug_character_creator:
		return
	_close_open_overlay_panel(false)
	if equipment:
		debug_character_creator.set_public_preview_equipment(equipment.equipped_by_slot)
	debug_character_creator.open_character_appearance()


func _close_open_overlay_panel(consume_action: bool = true) -> bool:
	if not hud:
		return false
	var closed := false
	if debug_character_creator and debug_character_creator.is_open():
		debug_character_creator.set_open(false)
		closed = true
	if hud.is_content_card_visible():
		hud.hide_content_card()
		active_content_choices.clear()
		closed = true
	if hud.is_systems_panel_visible():
		hud.hide_systems_panel()
		_clear_active_transfer(false)
		closed = true
	if hud.is_target_picker_visible():
		hud.hide_target_picker()
		closed = true
	return closed and consume_action


func _clear_active_transfer(refresh_hud: bool = true) -> void:
	if (
		active_transfer_owner_id.is_empty()
		and active_transfer_name.is_empty()
		and active_transfer_source_id.is_empty()
		and active_transfer_source_kind.is_empty()
		and active_transfer_access_mode.is_empty()
	):
		return
	active_transfer_owner_id = ""
	active_transfer_name = ""
	active_transfer_source_id = ""
	active_transfer_source_kind = ""
	active_transfer_source_tile = Vector2i.ZERO
	active_transfer_access_mode = ""
	if refresh_hud:
		_refresh_hud()


func _interact() -> void:
	var entity = _get_nearby_entity()
	if not entity:
		event_bus.post_message("Nothing nearby to interact with.")
		return
	_interact_entity(entity)


func _interact_entity(entity: WorldEntity) -> void:
	if not entity:
		event_bus.post_message("Nothing nearby to interact with.")
		return
	if ActorRules.is_dead_actor_data(entity.data):
		MainObjectInteractions.interact_container(MainObjectInteractions.context(self), entity)
		return
	match entity.get_kind():
		"readable":
			MainObjectInteractions.interact_readable(MainObjectInteractions.context(self), entity)
		"pickup":
			MainObjectInteractions.interact_pickup(MainObjectInteractions.context(self), entity)
		"container":
			MainObjectInteractions.interact_container(MainObjectInteractions.context(self), entity)
		"body":
			MainObjectInteractions.interact_container(MainObjectInteractions.context(self), entity)
		"door":
			MainObjectInteractions.interact_container(MainObjectInteractions.context(self), entity)
		"poi":
			PoiInteraction.interact(
				PoiInteraction.InteractionContext.new(
					entity,
					world_state,
					hud,
					Callable(self, "apply_effect"),
					event_bus,
					active_content_choices,
					condition_evaluator
				)
			)
		"npc":
			_interact_npc(entity)
		"rest":
			MainObjectInteractions.interact_rest(MainObjectInteractions.context(self), entity)
		_:
			event_bus.post_message("You inspect %s." % entity.get_display_name())


func _interact_npc(entity: WorldEntity) -> void:
	var npc_id := String(entity.data.get("npc_id", ""))
	if civilian_schedules:
		var blocked_reason := civilian_schedules.dialogue_block_reason(npc_id)
		if not blocked_reason.is_empty():
			event_bus.post_message(blocked_reason)
			_refresh_hud()
			return
	var npc: Dictionary = content.get_npc(npc_id)
	var result: Dictionary = dialogues.resolve_dialogue(
		String(npc.get("dialogue_id", "")), String(npc.get("name", entity.get_display_name()))
	)
	if result.is_empty():
		event_bus.post_message("%s has nothing to say." % entity.get_display_name())
		return
	_show_dialogue_line(result)
	if bool(result.get("effects_failed", false)):
		event_bus.post_message("Some dialogue effects could not be applied.")
	_update_nearby()


func _interact_portal(entity: WorldEntity) -> void:
	MainObjectInteractions.interact_portal(MainObjectInteractions.context(self), entity)


func _handle_context_action_selected(action_id: String) -> void:
	MainContextActions.handle(MainContextActions.handle_context(self), action_id)


func _combat_hit_message(result: Dictionary, counter_damage: int) -> String:
	var message := (
		"Hit %s for %d. %d/%d HP remains. Took %d."
		% [
			result.get("name", "enemy"),
			VariantFields.non_negative_int(result.get("damage", 0), 0),
			VariantFields.non_negative_int(result.get("health", 0), 0),
			VariantFields.positive_int(result.get("max_health", 1), 1),
			counter_damage
		]
	)
	if bool(result.get("guarded", false)):
		message += " Guard reduced the counter."
	return message


func _handle_player_defeated(source_name: String) -> void:
	event_bus.player_defeated.emit(source_name)
	player.set_global_tile(Vector2i.ZERO)
	player.heal(player.max_health)
	target_cycle_index = 0
	selected_target_id = ""
	manual_target_locked = false
	event_bus.post_message("You fall to %s, then recover at the bridge campfire." % source_name)


func _show_dialogue_line(line: Dictionary) -> void:
	var speaker := String(line.get("speaker", "Speaker"))
	var text := String(line.get("text", ""))
	var choices := _dialogue_choices(line)
	active_content_choices.clear()
	for choice in choices:
		active_content_choices[String(choice.get("id", ""))] = choice
	if hud:
		hud.show_content_card(speaker, text, choices, "dialogue")
	event_bus.post_message("%s: %s" % [speaker, text])


func _handle_content_choice_selected(choice_id: String) -> void:
	if not active_content_choices.has(choice_id):
		event_bus.post_message("That choice is no longer available.")
		if hud:
			hud.hide_content_card()
		active_content_choices.clear()
		return
	var choice: Dictionary = active_content_choices[choice_id]
	active_content_choices.clear()
	var result: Dictionary = dialogues.apply_choice(choice)
	if bool(result.get("effects_failed", false)):
		event_bus.post_message("Some dialogue effects could not be applied.")
	var open_shop_id := String(result.get("open_shop_id", ""))
	if not open_shop_id.is_empty():
		if hud:
			hud.hide_content_card()
			hud.show_systems_panel("trade")
		event_bus.post_message("Trading.")
		_update_nearby()
		return
	var response := String(result.get("response", ""))
	if response.is_empty():
		if hud:
			hud.hide_content_card()
	else:
		if hud:
			hud.show_content_card(String(result.get("text", "Choice")), response, [], "response")
		event_bus.post_message(response)
	_update_nearby()


func _handle_content_card_closed() -> void:
	active_content_choices.clear()


func _handle_inventory_item_selected(item_id: String) -> void:
	_handle_systems_action_selected(item_id)


func _handle_systems_action_selected(action_id: String) -> void:
	var result := MainSystemsActions.handle(MainSystemsActions.systems_context(self), action_id)
	_handle_systems_action_result(result)


func _handle_systems_action_result(result: Dictionary) -> void:
	match String(result.get("intent", "")):
		"target_entity":
			_handle_target_entity_intent(String(result.get("entity_id", "")))


func _dialogue_choices(line: Dictionary) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for choice in VariantFields.array(line.get("choices", [])):
		if choice is Dictionary:
			choices.append(choice)
	return choices


func _get_nearby_entity() -> WorldEntity:
	var nearby_entities := _get_nearby_entities()
	var facing: Vector2 = (
		player.get_facing_direction()
		if player and player.has_method("get_facing_direction")
		else Vector2.ZERO
	)
	var selection := InteractionTargetSelector.select(
		nearby_entities, selected_target_id, manual_target_locked, player.global_position, facing
	)
	target_cycle_index = int(selection.get("index", 0))
	selected_target_id = String(selection.get("id", ""))
	manual_target_locked = bool(selection.get("manual", false))
	return selection.get("entity") as WorldEntity


func _get_nearby_entities() -> Array:
	return entities.get_interactables_world(player.global_position)


func _ranked_nearby_entities() -> Array:
	return InteractionTargetSelector.ranked_targets(
		_get_nearby_entities(), player.global_position, player.get_facing_direction()
	)


func _current_shop_id() -> String:
	return _shop_id_for_entity(_get_nearby_entity())


func _shop_id_for_entity(entity: WorldEntity) -> String:
	return hud_queries.shop_id_for_entity(entity)


func _primary_action_text(nearby, auto_target) -> String:
	if auto_move_active or auto_target:
		return "Stop"
	if nearby and ActorRules.is_dead_actor_data(nearby.data):
		return "Loot"
	var preferred := _preferred_primary_context_action_for(nearby)
	if not preferred.is_empty():
		return String(preferred.get("text", "Interact"))
	if nearby and ["container", "door"].has(nearby.get_kind()):
		return ObjectInteractionRules.access_action_text(nearby, chunks, condition_evaluator)
	if nearby and nearby.get_kind() == "poi":
		return PoiInteraction.primary_action_text(nearby)
	return PrimaryActionTextBuilder.for_kind(nearby.get_kind()) if nearby else "Explore"


func _index_of_target_id(nearby_entities: Array, entity_id: String) -> int:
	if entity_id.is_empty():
		return -1
	for index in range(nearby_entities.size()):
		if nearby_entities[index].get_entity_id() == entity_id:
			return index
	return -1


func _refresh_hud() -> void:
	if hud:
		hud.refresh()
