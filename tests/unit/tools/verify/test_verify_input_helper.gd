extends GutTest

const VerifyInputHelper = preload("res://scripts/tools/verify/verify_input_helper.gd")


class HudStub:
	extends RefCounted

	var layout_sizes: Array[Vector2] = []
	var refresh_calls := 0

	func _apply_layout_for_size(size: Vector2) -> void:
		layout_sizes.append(size)

	func refresh() -> void:
		refresh_calls += 1


class MainStub:
	extends RefCounted

	var hud := HudStub.new()
	var entities := EntitiesStub.new()


class EntitiesStub:
	extends RefCounted

	func get_entity(_entity_id: String):
		return null


func test_find_button_recurses_and_requires_visible_name_match() -> void:
	var root := VBoxContainer.new()
	add_child_autofree(root)
	var nested := HBoxContainer.new()
	var hidden := Button.new()
	hidden.name = "Target"
	hidden.visible = false
	var target := Button.new()
	target.name = "Target"
	root.add_child(hidden)
	root.add_child(nested)
	nested.add_child(target)

	assert_same(VerifyInputHelper.find_button(root, "Target"), target)
	assert_null(VerifyInputHelper.find_button(root, "Missing"))
	assert_null(VerifyInputHelper.find_button(null, "Target"))


func test_button_containing_and_action_prefix_search_visible_descendants() -> void:
	var root := VBoxContainer.new()
	add_child_autofree(root)
	var nested := HBoxContainer.new()
	var talk := Button.new()
	talk.text = "Talk Harrow"
	var action := Button.new()
	action.set_meta("action_id", "target:npc_harrow")
	root.add_child(nested)
	nested.add_child(talk)
	nested.add_child(action)

	assert_same(VerifyInputHelper.button_containing(root, "Harrow"), talk)
	assert_null(VerifyInputHelper.button_containing(root, "Maera"))
	assert_same(VerifyInputHelper.button_with_action_prefix(root, "target:"), action)
	assert_null(VerifyInputHelper.button_with_action_prefix(root, "trade:"))
	assert_null(VerifyInputHelper.button_containing(null, "Harrow"))
	assert_null(VerifyInputHelper.button_with_action_prefix(null, "target:"))


func test_settle_main_applies_layout_refresh_and_waits() -> void:
	var main := MainStub.new()

	await VerifyInputHelper.settle_main(get_tree(), main, Vector2i(640, 480))

	assert_eq(main.hud.layout_sizes, [Vector2(640, 480)])
	assert_eq(main.hud.refresh_calls, 1)


func test_world_click_entity_returns_false_when_entity_missing() -> void:
	var main := MainStub.new()

	assert_false(await VerifyInputHelper.world_click_entity(get_tree(), main, "missing"))


func test_reveal_button_scrolls_to_nested_button_without_losing_it() -> void:
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(120, 60)
	add_child_autofree(scroll)
	var stack := VBoxContainer.new()
	scroll.add_child(stack)
	for index in 8:
		var spacer := Label.new()
		spacer.text = "Spacer %d" % index
		spacer.custom_minimum_size = Vector2(120, 40)
		stack.add_child(spacer)
	var button := Button.new()
	button.name = "ClickMe"
	button.text = "Click"
	button.custom_minimum_size = Vector2(120, 40)
	stack.add_child(button)
	await get_tree().process_frame

	await VerifyInputHelper.reveal_button(get_tree(), button)

	assert_same(VerifyInputHelper.find_button(scroll, "ClickMe"), button)
