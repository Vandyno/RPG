extends GutTest

const PoiInteraction = preload("res://scripts/main/actions/poi_interaction.gd")


class EntityStub:
	var data := {}
	var display_name := "Town Square"

	func _init(p_data: Dictionary, p_display_name := "Town Square") -> void:
		data = p_data
		display_name = p_display_name

	func get_display_name() -> String:
		return display_name


class WorldStateStub:
	var discovered: Dictionary = {}

	func discover_location(location_id: String) -> bool:
		if discovered.has(location_id):
			return false
		discovered[location_id] = true
		return true


class HudStub:
	var card_title := ""
	var card_body := ""
	var card_actions: Array[Dictionary] = []
	var card_kind := ""
	var shown_system_tab := ""

	func show_content_card(
		title: String, body: String, actions: Array[Dictionary], kind: String
	) -> void:
		card_title = title
		card_body = body
		card_actions = actions
		card_kind = kind

	func show_systems_panel(tab_id: String) -> void:
		shown_system_tab = tab_id


class EventBusStub:
	var messages: Array[String] = []

	func post_message(message: String) -> void:
		messages.append(message)


class ConditionEvaluatorStub:
	var allowed_id := "need_flag"

	func evaluate_all(conditions: Array) -> bool:
		if conditions.is_empty():
			return true
		return String(conditions[0].get("id", "")) == allowed_id


class EffectSink:
	var effects: Array[Dictionary] = []

	func apply_effect(effect: Dictionary) -> void:
		effects.append(effect)


func test_detail_and_primary_action_text_follow_poi_shape() -> void:
	var trade_entity := EntityStub.new(
		{"poi_type": "Market", "summary": "open stalls", "shop_id": "shop_maera"}
	)
	var service_entity := EntityStub.new({"system_tab": "crafting"})
	var plain_entity := EntityStub.new({"poi_type": "Shrine"})

	assert_eq(PoiInteraction.detail(trade_entity), "Market: open stalls")
	assert_eq(PoiInteraction.detail(plain_entity), "Shrine")
	assert_eq(PoiInteraction.primary_action_text(trade_entity), "Trade")
	assert_eq(PoiInteraction.primary_action_text(service_entity), "Open")
	assert_eq(PoiInteraction.primary_action_text(plain_entity), "Use")
	assert_eq(PoiInteraction.primary_action_text(null), "Use")


func test_interact_discovers_once_applies_effects_and_opens_shop_tab() -> void:
	var entity := EntityStub.new(
		{
			"location_id": "loc_market",
			"shop_id": "shop_maera",
			"effects_on_discover": [{"type": "set_flag", "flag": "visited_market"}]
		},
		"Maera's Stall"
	)
	var world_state := WorldStateStub.new()
	var hud := HudStub.new()
	var event_bus := EventBusStub.new()
	var effects := EffectSink.new()
	var active_choices := {"old": {"id": "old"}}
	var context := PoiInteraction.InteractionContext.new(
		entity,
		world_state,
		hud,
		Callable(effects, "apply_effect"),
		event_bus,
		active_choices
	)

	PoiInteraction.interact(context)
	PoiInteraction.interact(context)

	assert_eq(active_choices, {})
	assert_eq(hud.shown_system_tab, "trade")
	assert_eq(effects.effects, [{"type": "set_flag", "flag": "visited_market"}])
	assert_eq(event_bus.messages, ["Discovered Maera's Stall.", "Visited Maera's Stall."])


func test_inspect_shows_filtered_content_actions_and_records_choices() -> void:
	var entity := EntityStub.new(
		{
			"description": "Work orders are pinned here.",
			"actions":
			[
				{"id": "take_job", "label": "Take Job", "conditions": [{"id": "need_flag"}]},
				{"id": "blocked_job", "label": "Blocked", "conditions": [{"id": "missing"}]},
				{"id": "always", "label": "Always"},
				"bad"
			]
		},
		"Job Board"
	)
	var hud := HudStub.new()
	var event_bus := EventBusStub.new()
	var active_choices: Dictionary = {}
	var context := PoiInteraction.InteractionContext.new(
		entity,
		null,
		hud,
		Callable(),
		event_bus,
		active_choices,
		ConditionEvaluatorStub.new()
	)

	PoiInteraction.inspect(context)

	assert_eq(hud.card_title, "Job Board")
	assert_eq(hud.card_body, "Work orders are pinned here.")
	assert_eq(hud.card_kind, "place")
	assert_eq(hud.card_actions.size(), 2)
	assert_true(active_choices.has("take_job"))
	assert_true(active_choices.has("always"))
	assert_false(active_choices.has("blocked_job"))
	assert_eq(event_bus.messages, ["Visited Job Board."])


func test_available_actions_returns_safe_duplicates() -> void:
	var action := {"id": "take_job", "label": "Take Job", "payload": {"reward": 1}}
	var entity := EntityStub.new({"actions": [action]})
	var actions := PoiInteraction.available_actions(entity, null)

	actions[0]["payload"]["reward"] = 5

	assert_eq(action["payload"]["reward"], 1)
