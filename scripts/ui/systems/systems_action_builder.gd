class_name SystemsActionBuilder
extends RefCounted

const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")


static func actions_for_tab(state: Dictionary, active_tab: String) -> Array:
	var actions := SystemsTabState.actions_for_tab(state, active_tab)
	if active_tab == "journal" or active_tab == "log":
		actions.append({"id": "save:game", "text": "Save Game"})
		actions.append({"id": "load:game", "text": "Load Game"})
	return actions
