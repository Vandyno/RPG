extends GutTest

const EventBus = preload("res://scripts/core/event_bus.gd")
const RpgHud = preload("res://scripts/ui/rpg/rpg_hud.gd")
const HudClickHelper = preload("res://tests/unit/ui/helpers/hud_click_helper.gd")
const RpgContentChoiceButton = preload(
	"res://scripts/ui/controls/buttons/rpg_content_choice_button.gd"
)


func test_quick_actions_use_player_facing_icon_cards_and_route() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))
	var context_actions: Array[String] = []
	hud.context_action_selected.connect(
		func(action_id: String) -> void: context_actions.append(action_id)
	)
	hud._refresh_context_actions(
		{
			"nearby": "Harrow Venn",
			"context_actions":
			[
				{"id": "dialogue:accept", "text": "I'll find it."},
				{"id": "forge:sharpen", "text": "Sharpen Road Hatchet"},
				{"id": "trade:shop_crossroads_peddler", "text": "Trade"}
			]
		}
	)

	var dialogue := (
		_button_containing(hud.context_action_buttons, "I'll find it.") as RpgContentChoiceButton
	)
	var forge := (
		_button_containing(hud.context_action_buttons, "Sharpen Road Hatchet")
		as RpgContentChoiceButton
	)
	var trade := _button_containing(hud.context_action_buttons, "Trade") as RpgContentChoiceButton
	assert_not_null(dialogue)
	assert_not_null(forge)
	assert_not_null(trade)
	assert_eq(dialogue.choice_icon, "dialogue")
	assert_eq(forge.choice_icon, "service")
	assert_eq(trade.choice_icon, "trade")
	await HudClickHelper.click(dialogue, get_tree())
	assert_eq(context_actions, ["dialogue:accept"])


func _new_hud() -> RpgHud:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := RpgHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_sample_state"))
	return hud


func _sample_state() -> Dictionary:
	return {
		"player_health": "100/100",
		"player_health_value": 100,
		"player_max_health": 100,
		"player_mana": "100/100",
		"player_mana_value": 100,
		"player_max_mana": 100,
		"locations": "Briarwatch Crossroads",
		"progression": "Level 1 XP 0/20 Points 0",
		"inventory": "empty",
		"inventory_items": [],
		"spells": [],
		"spell_slots": {},
		"time": "Day 1, 08:00"
	}


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.visible and child.text.contains(text):
			return child
	return null
