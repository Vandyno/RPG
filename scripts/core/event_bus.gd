class_name EventBus
extends Node

signal player_tile_changed(global_tile: Vector2i, chunk_coord: Vector2i)
signal chunks_changed(loaded_chunks: Array)
signal interaction_available(entity_id: String)
signal interaction_cleared
signal message_posted(text: String)
signal world_flag_changed(flag_id: String, value: bool)
signal location_discovered(location_id: String)
signal item_count_changed(item_id: String, count: int)
signal equipment_changed(equipped_by_slot: Dictionary)
signal spell_slots_changed(assigned_by_slot: Dictionary)
signal faction_reputation_changed(faction_id: String, reputation: int)
signal progression_changed(level: int, experience: int, next_level: int, skill_points: int)
signal status_effects_changed(active_statuses: Dictionary)
signal time_changed(day: int, hour: int, minute: int, phase: String)
signal quest_changed(quest_id: String, state: Dictionary)
signal readable_read(readable_id: String)
signal combat_resolved(result: Dictionary)
signal noise_emitted(noise: Dictionary)
signal npc_perceived_event(perception: Dictionary)
signal player_crime_committed(crime: Dictionary)
signal crime_reported(report: Dictionary)
signal player_jailed(jail_state: Dictionary)
signal player_released_from_jail(release_state: Dictionary)
signal actor_state_changed(entity_id: String, npc_id: String, state: String)
signal player_health_changed(health: int, max_health: int)
signal player_mana_changed(mana: float, max_mana: float)
signal player_defeated(source: String)
signal save_completed(path: String)
signal load_completed(path: String)


func post_message(text: String) -> void:
	message_posted.emit(text)
