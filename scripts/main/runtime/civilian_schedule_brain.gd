class_name CivilianScheduleBrain
extends RefCounted

const BRAIN_ID := "civilian_schedule"


static func update(schedule_manager, delta: float) -> void:
	if schedule_manager and schedule_manager.has_method("update"):
		schedule_manager.update(delta)
