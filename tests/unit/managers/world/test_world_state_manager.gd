extends GutTest

const WorldStateManager = preload("res://scripts/managers/world/world_state_manager.gd")


class EventBusStub:
	extends Node

	signal world_flag_changed(flag_id: String, value: bool)
	signal location_discovered(location_id: String)


func test_set_flag_ignores_blank_and_emits_only_on_value_change() -> void:
	var bus := EventBusStub.new()
	add_child_autofree(bus)
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.setup(bus)
	var changes: Array[String] = []
	bus.world_flag_changed.connect(
		func(flag_id: String, value: bool) -> void: changes.append("%s:%s" % [flag_id, value])
	)

	world_state.set_flag("")
	world_state.set_flag("flag_gate_open")
	world_state.set_flag("flag_gate_open")
	world_state.set_flag("flag_gate_open", false)

	assert_eq(world_state.flags, {"flag_gate_open": false})
	assert_eq(changes, ["flag_gate_open:true", "flag_gate_open:false"])


func test_has_flag_requires_true_boolean_value() -> void:
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.flags = {
		"flag_true": true,
		"flag_false": false,
		"flag_text": "true",
	}

	assert_true(world_state.has_flag("flag_true"))
	assert_false(world_state.has_flag("flag_false"))
	assert_false(world_state.has_flag("flag_text"))
	assert_false(world_state.has_flag("missing"))


func test_discover_location_emits_only_for_new_nonblank_locations() -> void:
	var bus := EventBusStub.new()
	add_child_autofree(bus)
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.setup(bus)
	var discovered: Array[String] = []
	bus.location_discovered.connect(func(location_id: String) -> void: discovered.append(location_id))

	assert_false(world_state.discover_location(""))
	assert_true(world_state.discover_location("location_briarwatch_crossroads"))
	assert_false(world_state.discover_location("location_briarwatch_crossroads"))
	assert_eq(world_state.discovered_locations, {"location_briarwatch_crossroads": true})
	assert_eq(discovered, ["location_briarwatch_crossroads"])


func test_save_and_load_round_trips_valid_flags_and_locations() -> void:
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.set_flag("flag_a", true)
	world_state.set_flag("flag_b", false)
	world_state.discover_location("location_a")

	var loaded := WorldStateManager.new()
	add_child_autofree(loaded)
	loaded.load_save_data(world_state.get_save_data())

	assert_eq(loaded.flags, {"flag_a": true, "flag_b": false})
	assert_eq(loaded.discovered_locations, {"location_a": true})


func test_load_save_data_ignores_malformed_or_blank_values_and_clears_old_state() -> void:
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.set_flag("old", true)
	world_state.discover_location("old_location")

	world_state.load_save_data(
		{
			"flags": {"": true, "valid_true": true, "valid_false": false, "bad": "true"},
			"discovered_locations": ["", "location_valid", 12],
		}
	)

	assert_eq(world_state.flags, {"valid_true": true, "valid_false": false})
	assert_eq(world_state.discovered_locations, {"location_valid": true})

	world_state.load_save_data({"flags": "bad", "discovered_locations": 99})
	assert_eq(world_state.flags, {})
	assert_eq(world_state.discovered_locations, {})
