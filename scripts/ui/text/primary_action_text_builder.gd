class_name PrimaryActionTextBuilder
extends RefCounted


static func for_kind(kind: String) -> String:
	match kind:
		"readable":
			return "Read"
		"npc":
			return "Talk"
		"pickup":
			return "Pick Up"
		"container", "door":
			return "Open"
		"rest":
			return "Rest"
		"poi":
			return "Use"
		_:
			return "Interact"
