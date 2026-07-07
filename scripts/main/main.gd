# gdlint:disable=max-file-lines
extends Node2D
const GridMath = preload("res://scripts/core/grid_math.gd")
const ConditionEvaluatorScript = preload("res://scripts/core/condition_evaluator.gd")
const EventBusScript = preload("res://scripts/core/event_bus.gd")
const EffectRunnerScript = preload("res://scripts/core/effect_runner.gd")
const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")
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
const WorldStreamingManagerScript = preload(
	"res://scripts/managers/world/world_streaming_manager.gd"
)
const EntityManagerScript = preload("res://scripts/managers/world/entity_manager.gd")
const CombatManagerScript = preload("res://scripts/managers/actors/combat_manager.gd")
const EquipmentManagerScript = preload("res://scripts/managers/actors/equipment_manager.gd")
const PlayerControllerScript = preload("res://scripts/player/player_controller.gd")
const SaveManagerScript = preload("res://scripts/managers/persistence/save_manager.gd")
const RpgHudScript = preload("res://scripts/ui/rpg/rpg_hud.gd")
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
const MainCameraFraming = preload("res://scripts/main/runtime/main_camera_framing.gd")
const HostileActorBrain = preload("res://scripts/main/runtime/hostile_actor_brain.gd")
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
var streamer: WorldStreamingManager
var entities: EntityManager
var combat: CombatManager
var equipment: EquipmentManager
var spells: SpellManager
var player: PlayerController
var save_manager: SaveManager
var hud: RpgHud
var hud_queries: MainHudQueries
var debug_character_creator: DebugCharacterCreator
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
		event_bus.post_message("Briarwatch ready. Read, talk, trade, take jobs, save, and load.")
func _unhandled_input(event: InputEvent) -> void:
	MainInputRouter.handle_event(MainInputRouter.context(self), event)
func _process(delta: float) -> void:
	_sync_camera_to_player()
	MainInputRouter.update_auto_interaction(MainInputRouter.context(self), delta)
	HostileActorBrain.update(self, delta)
	_update_location_discoveries()
	_update_nearby()
func apply_effect(effect: Dictionary, emit_feedback: bool = true) -> bool:
	return effect_runner.apply(effect, emit_feedback)
func get_hud_state() -> Dictionary:
	return MainHudState.build(_hud_context())
func get_debug_state() -> Dictionary:
	return MainDebugState.build(self)


func _hud_context() -> MainHudState.HudContext:
	var nearby := _get_nearby_entity()
	var nearby_targets := _ranked_nearby_entities()
	return MainHudState.HudContext.new(
		{
			"active_transfer_name": active_transfer_name,
			"active_transfer_owner_id": active_transfer_owner_id,
			"auto_interact_target_id": auto_interact_target_id,
			"auto_move_active": auto_move_active,
			"chunks": chunks,
			"condition_evaluator": condition_evaluator,
			"content": content,
			"context_actions_context": _action_list_context(),
			"entities": entities,
			"equipment": equipment,
			"factions": factions,
			"hud_queries": hud_queries,
			"inventory": inventory,
			"nearby": nearby,
			"nearby_targets": hud_queries.nearby_targets_data(
				nearby_targets, selected_target_id, player.global_position
			),
			"player": player,
			"progression": progression,
			"quests": quests,
			"shop_id": hud_queries.shop_id_for_entity(nearby),
			"spells": spells,
			"statuses": statuses,
			"time": time,
			"world_state": world_state
		}
	)


func _action_list_context() -> MainContextActions.ActionListContext:
	return MainContextActions.ActionListContext.new(
		{
			"condition_evaluator": condition_evaluator,
			"content": content,
			"dialogues": dialogues,
			"player": player,
			"world_state": world_state
		}
	)
func _bootstrap() -> bool:
	event_bus = EventBusScript.new()
	event_bus.name = "EventBus"
	add_child(event_bus)
	content = _create_content_database()
	content.name = "ContentDatabase"
	add_child(content)
	var content_load_errors: Array[String] = content.load_all()
	if not content_load_errors.is_empty():
		_report_content_bootstrap_errors(
			content_load_errors, "Content failed to load. Check content file errors."
		)
		set_process(false)
		return false
	var content_validation_errors: Array[String] = content.validate_all()
	if not content_validation_errors.is_empty():
		_report_content_bootstrap_errors(
			content_validation_errors, "Content failed validation. Check content file errors."
		)
		set_process(false)
		return false
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

	effect_runner = EffectRunnerScript.new()
	effect_runner.setup(
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

	readables = ReadableManagerScript.new()
	readables.name = "ReadableManager"
	add_child(readables)
	readables.setup(event_bus, content, Callable(self, "apply_effect"))

	condition_evaluator = ConditionEvaluatorScript.new()
	condition_evaluator.setup(
		world_state, quests, inventory, readables, factions, progression, time
	)

	dialogues = DialogueManagerScript.new()
	dialogues.name = "DialogueManager"
	add_child(dialogues)
	dialogues.setup(content, condition_evaluator, effect_runner)

	chunks = ChunkManagerScript.new()
	chunks.name = "ChunkManager"
	add_child(chunks)
	chunks.load_authored_terrain(ChunkManagerScript.AUTHORED_TERRAIN_PATH)

	streamer = WorldStreamingManagerScript.new()
	streamer.name = "WorldStreamingManager"
	add_child(streamer)
	streamer.setup(event_bus, chunks)

	entities = EntityManagerScript.new()
	entities.name = "EntityManager"
	add_child(entities)
	entities.setup(event_bus, content, chunks, condition_evaluator, inventory)

	equipment = EquipmentManagerScript.new()
	equipment.name = "EquipmentManager"
	add_child(equipment)
	equipment.setup(event_bus, content, inventory)

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

	player = PlayerControllerScript.new()
	player.name = "Player"
	add_child(player)
	player.setup(event_bus, chunks, Vector2i.ZERO)
	player.set_humanoid_profile(content.get_character_profile("char_player"))
	effect_runner.set_player(player)
	event_bus.equipment_changed.connect(
		func(equipped_by_slot: Dictionary) -> void:
			player.set_equipped_items(equipped_by_slot, content)
	)

	hud_queries = MainHudQueries.new()
	hud_queries.setup(
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

	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.zoom = Vector2(2.0, 2.0)
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)

	save_manager = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	add_child(save_manager)
	save_manager.setup(event_bus, MainSaveProviders.build(self))

	hud = RpgHudScript.new()
	hud.name = "RpgHud"
	add_child(hud)
	hud.setup(event_bus, Callable(self, "get_hud_state"))
	hud.interact_pressed.connect(_handle_interact_requested)
	hud.cycle_target_pressed.connect(_handle_cycle_target_requested)
	hud.target_selected.connect(_handle_target_selected)
	hud.target_used.connect(_handle_target_used)
	hud.content_choice_selected.connect(_handle_content_choice_selected)
	hud.content_card_closed.connect(_handle_content_card_closed)
	hud.inventory_item_selected.connect(_handle_inventory_item_selected)
	hud.aim_action_released.connect(
		func(action_id: String, direction: Vector2) -> void:
			MainSystemsActions.handle_aim(MainSystemsActions.aim_context(self), action_id, direction)
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

	debug_character_creator = DebugCharacterCreatorScript.new()
	debug_character_creator.name = "DebugCharacterCreator"
	add_child(debug_character_creator)
	debug_character_creator.setup(content, player)
	debug_character_creator.appearance_applied.connect(
		func(profile: Dictionary) -> void:
			event_bus.post_message(
				"Applied %s appearance." % content.get_people(String(profile.get("people_id", ""))).get(
					"display_name", String(profile.get("people_id", ""))
				)
			)
			_refresh_hud()
	)
	event_bus.player_tile_changed.connect(_on_player_tile_changed)
	streamer.update_center(player.global_tile)
	_sync_camera_to_player()
	return true


func _create_content_database() -> ContentDatabase:
	return ContentDatabaseScript.new()


func _report_content_bootstrap_errors(errors: Array[String], summary: String) -> void:
	for error in errors:
		push_error(error)
		event_bus.post_message(error)
	event_bus.post_message(summary)


func _on_player_tile_changed(global_tile: Vector2i, _chunk_coord: Vector2i) -> void:
	streamer.update_center(global_tile)

func _sync_camera_to_player() -> void:
	if not camera or not player:
		return
	camera.global_position = MainCameraFraming.position_for_player(
		player.global_position,
		_camera_focus_position(),
		get_viewport_rect().size,
		camera.zoom
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
		var radius := _positive_float_field(
			entity.data, "discovery_radius", EntityManagerScript.DEFAULT_INTERACTION_RADIUS_PIXELS
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
				_positive_float_field(
					entry, "discovery_radius", EntityManagerScript.DEFAULT_INTERACTION_RADIUS_PIXELS
				)
			)
	return radius


func _handle_interact_requested() -> void:
	MainInputRouter.handle_interact_requested(MainInputRouter.context(self))


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
		nearby_entities, selected_target_id, target_cycle_index, player.global_position,
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
	match entity.get_kind():
		"readable":
			_interact_readable(entity)
		"pickup":
			_interact_pickup(entity)
		"container":
			_interact_container(entity)
		"body":
			_interact_container(entity)
		"door":
			_interact_container(entity)
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
			_interact_rest(entity)
		_:
			event_bus.post_message("You inspect %s." % entity.get_display_name())


func _interact_readable(entity) -> void:
	var readable_id := String(entity.data.get("readable_id", ""))
	var readable: Dictionary = readables.read_readable(readable_id)
	if readable.is_empty():
		event_bus.post_message("The writing is too weathered to read.")
		return
	var title := String(readable.get("title", "Readable"))
	var body := String(readable.get("body", ""))
	active_content_choices.clear()
	if hud:
		hud.show_content_card(title, body, [], "readable")
	event_bus.post_message("Read %s." % title)


func _interact_pickup(entity) -> void:
	var item_id := String(entity.data.get("item_id", ""))
	var count := _positive_int_field(entity.data, "count", 1)
	var pickup_effects := _array_field(entity.data.get("effects_on_pickup", []))
	if not inventory.add_item(item_id, count):
		event_bus.post_message("Could not pick up %s." % entity.get_display_name())
		return
	entities.remove_entity(entity.get_entity_id())
	var item: Dictionary = content.get_item(item_id)
	event_bus.post_message("Picked up %s." % String(item.get("name", item_id)))
	for effect in pickup_effects:
		if effect is Dictionary:
			apply_effect(effect)
	_update_nearby()


func _interact_container(entity) -> void:
	var entity_id: String = entity.get_entity_id()
	var locked_text := ObjectInteractionRules.access_locked_text(entity.data, condition_evaluator)
	if not locked_text.is_empty():
		event_bus.post_message(locked_text)
		return
	if ["container", "body"].has(entity.get_kind()):
		MainInventoryTransfer.open(MainInventoryTransfer.context(self), entity)
		return
	if chunks.is_object_opened(entity_id, entity.global_tile):
		event_bus.post_message("%s is already open." % entity.get_display_name())
		return
	var opened := false
	for effect in _array_field(entity.data.get("effects_on_open", [])):
		if effect is Dictionary and apply_effect(effect):
			opened = true
	chunks.mark_object_opened(entity_id, entity.global_tile)
	if opened:
		event_bus.post_message("Opened %s." % entity.get_display_name())
	else:
		event_bus.post_message("%s is empty." % entity.get_display_name())
	_update_nearby()


func _interact_npc(entity) -> void:
	var npc_id := String(entity.data.get("npc_id", ""))
	var npc: Dictionary = content.get_npc(npc_id)
	var result: Dictionary = dialogues.resolve_dialogue(
		String(npc.get("dialogue_id", "")), String(npc.get("name", entity.get_display_name()))
	)
	if result.is_empty():
		event_bus.post_message("%s has nothing to say." % entity.get_display_name())
		return
	_show_dialogue_line(result)
	_update_nearby()


func _handle_context_action_selected(action_id: String) -> void:
	MainContextActions.handle(MainContextActions.handle_context(self), action_id)


func _combat_hit_message(result: Dictionary, counter_damage: int) -> String:
	var message := (
		"Hit %s for %d. %d/%d HP remains. Took %d."
		% [
			result.get("name", "enemy"),
			_non_negative_int_value(result.get("damage", 0), 0),
			_non_negative_int_value(result.get("health", 0), 0),
			_positive_int_value(result.get("max_health", 1), 1),
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


func _interact_rest(entity) -> void:
	var before: int = player.health
	var heal_amount := _positive_int_field(entity.data, "heal_amount", player.max_health)
	var rest_hours := _positive_int_field(entity.data, "rest_hours", 8)
	player.heal(heal_amount)
	var time_summary := "now"
	if time:
		time.advance_hours(rest_hours)
		time_summary = time.get_summary()
	if player.health == before:
		event_bus.post_message(
			"%s is warm. You rest until %s." % [entity.get_display_name(), time_summary]
		)
		return
	event_bus.post_message(
		(
			"Rested at %s until %s. Health %d/%d."
			% [entity.get_display_name(), time_summary, player.health, player.max_health]
		)
	)


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
	MainSystemsActions.handle(MainSystemsActions.systems_context(self), action_id)


func _handle_wait_action(hours: int) -> void:
	if not time or not time.advance_hours(hours):
		event_bus.post_message("Could not wait right now.")
	else:
		event_bus.post_message("Waited %dh. %s." % [hours, time.get_summary()])
	_refresh_hud()


func _use_inventory_item(item_id: String) -> void:
	var item: Dictionary = content.get_item(item_id)
	if item.is_empty() or not inventory.has_item(item_id):
		event_bus.post_message("That item is no longer available.")
		_refresh_hud()
		return
	var applied := false
	for effect in _array_field(item.get("effects_on_use", [])):
		if effect is Dictionary and apply_effect(effect):
			applied = true
	if not applied:
		event_bus.post_message("%s has no effect right now." % String(item.get("name", item_id)))
		_refresh_hud()
		return
	if bool(item.get("consume_on_use", false)):
		inventory.remove_item(item_id, 1)
	event_bus.post_message("Used %s." % String(item.get("name", item_id)))
	_refresh_hud()


func _handle_equip_item(item_id: String) -> void:
	var item: Dictionary = content.get_item(item_id)
	if item.is_empty() or not inventory.has_item(item_id) or not equipment.equip_item(item_id):
		event_bus.post_message("Could not equip that item.")
		_refresh_hud()
		return
	event_bus.post_message("Equipped %s." % String(item.get("name", item_id)))
	_refresh_hud()


func _handle_equip_item_to_slot(item_id: String, slot_id: String) -> void:
	var item: Dictionary = content.get_item(item_id)
	if item.is_empty() or not inventory.has_item(item_id):
		event_bus.post_message("Could not equip that item there.")
		_refresh_hud()
		return
	if not equipment.equip_item_to_slot(item_id, slot_id):
		event_bus.post_message("Could not equip that item there.")
		_refresh_hud()
		return
	event_bus.post_message("Equipped %s." % String(item.get("name", item_id)))
	_refresh_hud()


func _handle_swap_mainhand_weapon() -> void:
	if not equipment.equip_last_mainhand_weapon():
		event_bus.post_message("No previous main hand weapon.")
	else:
		var item_id: String = equipment.get_equipped_item("right_hand")
		var item: Dictionary = content.get_item(item_id)
		event_bus.post_message("Equipped %s." % String(item.get("name", item_id)))
	_refresh_hud()


func _handle_unequip_slot(slot_id: String) -> void:
	var item_id: String = equipment.get_equipped_item(slot_id)
	var item: Dictionary = content.get_item(item_id)
	if item_id.is_empty() or not equipment.unequip_slot(slot_id):
		event_bus.post_message("Nothing equipped there.")
		_refresh_hud()
		return
	event_bus.post_message("Unequipped %s." % String(item.get("name", item_id)))
	_refresh_hud()


func _handle_train_stat(stat_id: String) -> void:
	var stat_label: String = progression.get_stat_label(stat_id)
	if not progression.spend_point(stat_id):
		event_bus.post_message("Could not train %s." % stat_label)
		_refresh_hud()
		return
	event_bus.post_message("Trained %s." % stat_label)
	_refresh_hud()


func _handle_buy_item(item_id: String) -> void:
	var shop_id: String = _current_shop_id()
	var item: Dictionary = content.get_item(item_id)
	var price: int = shops.buy_price(shop_id, item_id)
	if shop_id.is_empty() or item.is_empty() or not shops.buy_item(shop_id, item_id):
		event_bus.post_message("Could not buy that.")
		_refresh_hud()
		return
	var item_name: String = String(item.get("name", item_id))
	var gold_count: int = inventory.get_count("item_gold_coin")
	event_bus.post_message(
		"Bought %s. Spent %dg. Gold: %d."
		% [item_name, price, gold_count]
	)
	_update_nearby()


func _handle_sell_item(item_id: String) -> void:
	var shop_id: String = _current_shop_id()
	var item: Dictionary = content.get_item(item_id)
	var price: int = shops.sell_price(shop_id, item_id)
	if item.is_empty() or not shops.sell_item(shop_id, item_id):
		event_bus.post_message("Could not sell that.")
		_refresh_hud()
		return
	var item_name: String = String(item.get("name", item_id))
	var gold_count: int = inventory.get_count("item_gold_coin")
	event_bus.post_message(
		"Sold %s. Gained %dg. Gold: %d."
		% [item_name, price, gold_count]
	)
	_update_nearby()


func _dialogue_choices(line: Dictionary) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for choice in _array_field(line.get("choices", [])):
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


func _index_of_target_id(nearby_entities: Array, entity_id: String) -> int:
	if entity_id.is_empty():
		return -1
	for index in range(nearby_entities.size()):
		if nearby_entities[index].get_entity_id() == entity_id:
			return index
	return -1

func _array_field(value: Variant) -> Array:
	return value if value is Array else []


func _positive_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	return _positive_int_value(source.get(field_id, fallback), fallback)

func _positive_int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(1, fallback)
	return maxi(1, int(value))


func _non_negative_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	return _non_negative_int_value(source.get(field_id, fallback), fallback)


func _non_negative_int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


func _positive_float_field(source: Dictionary, field_id: String, fallback: float) -> float:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return maxf(1.0, fallback)
	return maxf(1.0, float(value))


func _refresh_hud() -> void:
	if hud:
		hud.refresh()


func _is_number(value: Variant) -> bool:
	return value is int or value is float
