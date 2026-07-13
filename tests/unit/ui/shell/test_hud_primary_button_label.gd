extends GutTest

const LegacyHudShell = preload("res://tests/fixtures/ui/legacy_hud_shell.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const ButtonTextFormatter = preload("res://scripts/ui/text/button_text_formatter.gd")


func test_primary_action_button_wraps_long_action_text() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := LegacyHudShell.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_long_action_state"))

	assert_eq(hud.primary_action_button.text, "Examine Long\nWarden Notice")
	assert_eq(hud.primary_action_button.tooltip_text, "Examine Long Warden Notice")
	assert_true(hud.prompt_label.text.begins_with("Examine Long Warden Notice\nNotice Board"))


func test_compact_primary_action_button_names_target_for_short_actions() -> void:
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Rest", "Bridge Campfire"),
		"Rest\nCampfire"
	)
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Open", "Warden's Strongbox"),
		"Open\nStrongbox"
	)
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Examine Long Warden Notice", "Notice Board"),
		"Examine Long\nWarden Notice"
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
		"nearby": "Notice Board",
		"primary_action": "Examine Long Warden Notice",
		"target_detail": "Readable: Town notice"
	}
