class_name MainSaveProviders
extends RefCounted


static func build(main) -> Dictionary:
	return {
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
