class_name MainSaveProviders
extends RefCounted


static func build(main) -> Dictionary:
	var providers := {
		"player": main.player,
		"world_state": main.world_state,
		"quests": main.quests,
		"inventory": main.inventory,
		"equipment": main.equipment,
		"spells": main.spells,
		"factions": main.factions,
		"progression": main.progression,
		"statuses": main.statuses,
		"time": main.time,
		"readables": main.readables,
		"combat": main.combat,
		"chunks": main.chunks,
		"entities": main.entities
	}
	var civilian_schedules = main.get("civilian_schedules")
	if civilian_schedules:
		providers["civilian_schedules"] = civilian_schedules
	var crime = main.get("crime")
	if crime:
		providers["crime"] = crime
	var companions = main.get("companions")
	if companions:
		providers["companions"] = companions
	var allegiances = main.get("allegiances")
	if allegiances:
		providers["allegiances"] = allegiances
	return providers
