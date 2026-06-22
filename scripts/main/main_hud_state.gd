class_name MainHudState
extends RefCounted

const MainDebugState = preload("res://scripts/main/main_debug_state.gd")


static func build(main) -> Dictionary:
	return MainDebugState.build(main)
