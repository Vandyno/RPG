extends GutTest

const MainContextActions = preload("res://scripts/main/actions/main_context_actions.gd")


class EventBusStub:
	var messages: Array[String] = []

	func post_message(message: String) -> void:
		messages.append(message)


class HudStub:
	var hidden := false
	var shown_system_tab := ""

	func hide_content_card() -> void:
		hidden = true

	func show_systems_panel(tab_id: String) -> void:
		shown_system_tab = tab_id


class DialoguesStub:
	var applied_choices: Array[Dictionary] = []

	func preview_dialogue(_dialogue_id: String, _speaker_name: String) -> Dictionary:
		return {
			"line_id": "line_reward",
			"text": "Done.",
			"effects": [{"type": "complete_quest", "quest_id": "quest_missing_tools"}],
			"choices":
			[
				{"id": "choice_reward", "text": "Take reward", "effects": [{"type": "add_item"}]},
				{"id": "choice_plain", "text": "Goodbye"}
			]
		}

	func apply_choice(choice: Dictionary) -> Dictionary:
		applied_choices.append(choice)
		return {"response": "Reward taken."}


class ScheduleStub:
	var reason := ""
	var rumor := ""
	var incident := false

	func dialogue_block_reason(_npc_id: String) -> String:
		return reason

	func get_local_rumor(_npc_id: String) -> String:
		return rumor

	func can_address_player_incident(_npc_id: String) -> bool:
		return incident

	func acknowledge_player_incident(_npc_id: String) -> bool:
		incident = false
		return true


class ContentStub:
	func get_npc(npc_id: String) -> Dictionary:
		match npc_id:
			"npc_trader":
				return {
					"name": "Trader",
					"shop_id": "shop_trader",
					"dialogue_id": "dialogue_trader"
				}
			"npc_other_trader":
				return {
					"name": "Other Trader",
					"shop_id": "shop_other",
					"dialogue_id": "dialogue_other"
				}
			_:
				return {}


class PlayerStub:
	var is_sneaking := false
	var global_position := Vector2.ZERO


class EntityStub:
	var data := {"npc_id": "npc_trader"}
	var kind := "npc"
	var entity_id := "npc_trader_world"

	func get_kind() -> String:
		return kind

	func get_entity_id() -> String:
		return entity_id

	func get_display_name() -> String:
		return "Trader"


class MainStub:
	var active_content_choices := {"old": true}
	var active_transfer_name := ""
	var active_transfer_owner_id := ""
	var active_transfer_source_id := ""
	var active_transfer_source_kind := ""
	var active_transfer_source_tile := Vector2i.ZERO
	var active_transfer_access_mode := ""
	var chunks = null
	var condition_evaluator = null
	var content := ContentStub.new()
	var dialogues := DialoguesStub.new()
	var entities = null
	var event_bus := EventBusStub.new()
	var hud := HudStub.new()
	var inventory = null
	var player := PlayerStub.new()
	var seeded_inventory_owner_ids := {}
	var world_state = null
	var civilian_schedules = null
	var nearby_entity := EntityStub.new()
	var refreshed := 0
	var updated_nearby := 0
	var talked_to = null
	var effect_result := true

	func apply_effect(_effect: Dictionary) -> bool:
		return effect_result

	func _get_nearby_entity():
		return nearby_entity

	func _interact_npc(entity) -> void:
		talked_to = entity

	func _refresh_hud() -> void:
		refreshed += 1

	func _update_nearby() -> void:
		updated_nearby += 1

	func _clear_active_transfer(_refresh_hud: bool = true) -> void:
		active_transfer_name = ""
		active_transfer_owner_id = ""
		active_transfer_source_id = ""
		active_transfer_source_kind = ""
		active_transfer_source_tile = Vector2i.ZERO
		active_transfer_access_mode = ""


func test_build_promotes_effectful_npc_actions_without_direct_trade() -> void:
	var main := MainStub.new()
	var ctx := MainContextActions.action_list_context(main)

	var actions := MainContextActions.build(ctx, main.nearby_entity)
	var primary := MainContextActions.preferred_primary(ctx, main.nearby_entity)
	var secondary := MainContextActions.secondary(ctx, main.nearby_entity)

	assert_eq(
		_action_ids(actions),
		["talk:dialogue_trader", "line:line_reward", "dialogue:choice_reward"]
	)
	assert_eq(primary.get("id", ""), "line:line_reward")
	assert_eq(
		_action_ids(secondary),
		["talk:dialogue_trader", "dialogue:choice_reward"]
	)


func test_sleeping_npc_does_not_offer_routine_dialogue_actions() -> void:
	var main := MainStub.new()
	var schedule := ScheduleStub.new()
	schedule.reason = "They are asleep."
	main.civilian_schedules = schedule

	var actions := MainContextActions.build(
		MainContextActions.action_list_context(main), main.nearby_entity
	)
	assert_false(_action_ids(actions).any(func(action_id): return action_id.begins_with("talk:")))
	assert_false(_action_ids(actions).any(func(action_id): return action_id.begins_with("line:")))
	assert_false(_action_ids(actions).any(func(action_id): return action_id.begins_with("dialogue:")))
	assert_true(_action_ids(actions).has("wake:npc_trader"))


func test_social_npc_offers_rumor_action_and_routes_the_news() -> void:
	var main := MainStub.new()
	var schedule := ScheduleStub.new()
	schedule.rumor = "Rumor: The field rows were tended."
	main.civilian_schedules = schedule
	var ctx := MainContextActions.handle_context(main)

	var actions := MainContextActions.build(
		MainContextActions.action_list_context(main), main.nearby_entity
	)
	assert_true(_action_ids(actions).has("rumor:npc_trader"))
	MainContextActions.handle(ctx, "rumor:npc_trader")
	assert_eq(main.event_bus.messages, ["Rumor: The field rows were tended."])


func test_wary_npc_offers_incident_action_and_routes_the_acknowledgement() -> void:
	var main := MainStub.new()
	var schedule := ScheduleStub.new()
	schedule.reason = "They are wary of you."
	schedule.incident = true
	main.civilian_schedules = schedule
	var ctx := MainContextActions.handle_context(main)

	var actions := MainContextActions.build(
		MainContextActions.action_list_context(main), main.nearby_entity
	)
	assert_true(_action_ids(actions).has("incident:npc_trader"))
	MainContextActions.handle(ctx, "incident:npc_trader")
	assert_eq(main.event_bus.messages, ["They listen, but remain guarded."])
	assert_eq(main.refreshed, 1)


func test_handle_routes_dialogue_choice_and_unknown_actions() -> void:
	var main := MainStub.new()
	var ctx := MainContextActions.handle_context(main)

	MainContextActions.handle(ctx, "dialogue:choice_reward")
	MainContextActions.handle(ctx, "unknown")

	assert_true(main.hud.hidden)
	assert_eq(main.dialogues.applied_choices[0].get("id", ""), "choice_reward")
	assert_eq(main.event_bus.messages, ["Reward taken.", "Unknown action."])
	assert_true(main.active_content_choices.is_empty())
	assert_eq(main.updated_nearby, 1)


func test_handle_reports_failed_dialogue_line_effect() -> void:
	var main := MainStub.new()
	main.effect_result = false
	var ctx := MainContextActions.handle_context(main)

	MainContextActions.handle(ctx, "line:line_reward")

	assert_eq(
		main.event_bus.messages,
		["Some dialogue effects could not be applied.", "Done."]
	)
	assert_eq(main.updated_nearby, 1)


func test_handle_routes_talk_to_nearby_npc() -> void:
	var main := MainStub.new()
	var ctx := MainContextActions.handle_context(main)

	MainContextActions.handle(ctx, "talk:dialogue_trader")

	assert_eq(main.talked_to, main.nearby_entity)


func test_trade_action_revalidates_nearby_trader_before_opening() -> void:
	var main := MainStub.new()
	var ctx := MainContextActions.handle_context(main)

	MainContextActions.handle(ctx, "trade:shop_trader")

	assert_true(main.hud.hidden)
	assert_eq(main.hud.shown_system_tab, "trade")
	assert_eq(main.event_bus.messages.back(), "Trading.")

	main.hud.hidden = false
	main.hud.shown_system_tab = ""
	var refreshed_before_stale_action := main.refreshed
	main.nearby_entity = EntityStub.new()
	main.nearby_entity.data = {"npc_id": "npc_other_trader"}

	MainContextActions.handle(ctx, "trade:shop_trader")

	assert_false(main.hud.hidden)
	assert_eq(main.hud.shown_system_tab, "")
	assert_eq(main.event_bus.messages.back(), "That action is no longer available.")
	assert_eq(main.refreshed, refreshed_before_stale_action + 1)


func _action_ids(actions: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for action in actions:
		ids.append(String(action.get("id", "")))
	return ids
