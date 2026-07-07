extends GutTest

const EventBus = preload("res://scripts/core/event_bus.gd")
const ReadableManager = preload("res://scripts/managers/content/readable_manager.gd")


class ContentStub:
	var readables := {
		"readable_notice":
		{
			"id": "readable_notice",
			"title": "Notice",
			"effects_on_read": [{"type": "set_flag", "flag": "read_notice"}]
		},
		"readable_plain": {"id": "readable_plain", "title": "Plain"}
	}

	func get_readable(readable_id: String) -> Dictionary:
		return readables.get(readable_id, {})


class EffectSink:
	var effects: Array[Dictionary] = []

	func apply(effect: Dictionary) -> void:
		effects.append(effect)


func test_readable_manager_reads_known_entries_once_and_emits_signal() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := ContentStub.new()
	var effects := EffectSink.new()
	var manager := ReadableManager.new()
	add_child_autofree(manager)
	var emitted: Array[String] = []
	bus.readable_read.connect(func(readable_id: String) -> void: emitted.append(readable_id))
	manager.setup(bus, content, Callable(effects, "apply"))

	var first := manager.read_readable("readable_notice")
	var second := manager.read_readable("readable_notice")

	assert_eq(first["id"], "readable_notice")
	assert_eq(second["id"], "readable_notice")
	assert_true(manager.has_read("readable_notice"))
	assert_eq(manager.read, {"readable_notice": true})
	assert_eq(manager.discovered, {"readable_notice": true})
	assert_eq(effects.effects, [{"type": "set_flag", "flag": "read_notice"}])
	assert_eq(emitted, ["readable_notice", "readable_notice"])


func test_readable_manager_ignores_unknown_reads_and_sanitizes_save_data() -> void:
	var manager := ReadableManager.new()
	add_child_autofree(manager)
	manager.setup(null, ContentStub.new(), Callable())

	assert_eq(manager.read_readable("missing"), {})

	manager.load_save_data(
		{
			"read": ["", "missing", "readable_notice"],
			"discovered": ["readable_plain", "missing"]
		}
	)

	assert_eq(manager.read, {"readable_notice": true})
	assert_eq(manager.discovered, {"readable_plain": true})
	assert_eq(manager.get_save_data(), {"read": ["readable_notice"], "discovered": ["readable_plain"]})


func test_readable_manager_rejects_malformed_save_fields() -> void:
	var manager := ReadableManager.new()
	add_child_autofree(manager)
	manager.setup(null, ContentStub.new(), Callable())
	manager.read_readable("readable_plain")

	manager.load_save_data({"read": "bad", "discovered": 12})

	assert_eq(manager.read, {})
	assert_eq(manager.discovered, {})
