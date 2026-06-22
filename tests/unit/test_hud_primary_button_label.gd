extends GutTest

const DebugHud = preload("res://scripts/ui/debug_hud.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const ButtonTextFormatter = preload("res://scripts/ui/button_text_formatter.gd")


func test_primary_action_button_wraps_long_action_text() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_long_action_state"))

	assert_eq(hud.primary_action_button.text, "Sharpen Road\nHatchet (2g)")
	assert_eq(hud.primary_action_button.tooltip_text, "Sharpen Road Hatchet (2g)")
	assert_true(hud.prompt_label.text.begins_with("Sharpen Road Hatchet (2g)\nHarrow's Forge"))


func test_compact_primary_action_button_names_target_for_short_actions() -> void:
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Rest", "Roadside Campfire"),
		"Rest\nCampfire"
	)
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Open", "Sealed Strongbox"),
		"Open\nStrongbox"
	)
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Sharpen Road Hatchet (2g)", "Forge"),
		"Sharpen Road\nHatchet (2g)"
	)
	assert_eq(ButtonTextFormatter.compact_primary_action_label("Stop", "Harrow Venn"), "Stop")


func _long_action_state() -> Dictionary:
	return {
		"player_health_value": 100,
		"player_max_health": 100,
		"player_health": "100/100",
		"player_tile": "(0, 0)",
		"terrain": "road",
		"time": "Day 1, 08:00",
		"nearby": "Harrow's Forge",
		"primary_action": "Sharpen Road Hatchet (2g)",
		"target_detail": "Forge: repair and craft hook"
	}
