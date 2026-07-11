extends GutTest

const GameStartMenu = preload("res://scripts/ui/start/game_start_menu.gd")


func test_menu_builds_new_game_and_disabled_continue_without_save() -> void:
	var menu := GameStartMenu.new()
	add_child_autofree(menu)
	menu.setup(false)

	assert_true(menu.root.visible)
	assert_not_null(menu.root.find_child("TitleNewGameButton", true, false))
	assert_true(menu.continue_button.disabled)
	assert_eq(menu.status_label.text, "No saved journey yet. Begin a new one.")


func test_menu_enables_continue_when_a_save_exists() -> void:
	var menu := GameStartMenu.new()
	add_child_autofree(menu)
	menu.setup(true)

	assert_false(menu.continue_button.disabled)
	assert_eq(menu.status_label.text, "Continue your last journey.")
	menu.hide_menu()
	assert_false(menu.root.visible)
