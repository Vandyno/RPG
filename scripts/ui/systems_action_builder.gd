class_name SystemsActionBuilder
extends RefCounted


static func actions_for_tab(state: Dictionary, active_tab: String) -> Array:
	match active_tab:
		"character":
			return _array_field(state.get("progression_actions", []))
		"trade":
			return _array_field(state.get("trade_actions", []))
		"quests":
			return _array_field(state.get("quest_target_actions", []))
		"world":
			var actions := _array_field(state.get("time_actions", []))
			actions.append({"id": "save:game", "text": "Save Game"})
			actions.append({"id": "load:game", "text": "Load Game"})
			return actions
		_:
			return _array_field(state.get("inventory_actions", []))


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
