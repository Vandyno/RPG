extends GutTest


func test_post_message_emits_message_posted_signal() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var messages: Array[String] = []
	bus.message_posted.connect(func(text: String) -> void: messages.append(text))

	bus.post_message("Road clear.")

	assert_eq(messages, ["Road clear."])
