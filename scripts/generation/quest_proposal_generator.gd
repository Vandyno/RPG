class_name QuestProposalGenerator
extends RefCounted

const StableHash = preload("res://scripts/core/stable_hash.gd")

const SCHEMA_VERSION := "quest_proposal_bundle_v1"
const GENERATOR_VERSION := "1"
const TEMPLATES := [
	"road_notice",
	"trade_pressure",
	"missing_work",
	"paper_trail",
	"local_dispute"
]


static func generate(
	content, seed: String, count: int = 5, location_filter: String = ""
) -> Dictionary:
	if content == null:
		return {}
	var locations := _location_ids(content, location_filter)
	if locations.is_empty():
		return {}
	var pitch_count := clampi(count, 1, TEMPLATES.size())
	var pitches: Array[Dictionary] = []
	var location_start := StableHash.index(seed + "::location", locations.size())
	for index in pitch_count:
		var template_index := StableHash.index(seed + "::template::%d" % index, TEMPLATES.size())
		var template_id := String(TEMPLATES[template_index])
		var location_id := locations[(location_start + index) % locations.size()]
		pitches.append(_build_pitch(content, seed, index, template_id, location_id))
	return {
		"schema_version": SCHEMA_VERSION,
		"proposal_status": "proposal",
		"approval_status": "pending_review",
		"generator_version": GENERATOR_VERSION,
		"seed": seed,
		"runtime_import": "manual_only",
		"source_context": _source_context(content, locations),
		"pitches": pitches
	}


static func _build_pitch(
	content, seed: String, index: int, template_id: String, location_id: String
) -> Dictionary:
	var location: Dictionary = content.get_location(location_id)
	var location_name := String(location.get("name", location_id))
	var npc_id := _pick_id(content.npc_ids(), seed + "::npc::%d" % index)
	var readable_id := _pick_id(content.readable_ids(), seed + "::readable::%d" % index)
	var faction_id := _pick_id(content.faction_ids(), seed + "::faction::%d" % index)
	var npc_name := _display_name(content.get_npc(npc_id), npc_id)
	var readable_title := _display_name(content.get_readable(readable_id), readable_id)
	var faction_name := _display_name(content.get_faction(faction_id), faction_id)
	var pitch := _template_text(
		template_id, location_name, npc_name, readable_title, faction_name
	)
	var proposal_id := "proposal_quest_%s_%02d" % [template_id, index + 1]
	pitch.merge(
		{
			"id": proposal_id,
			"status": "IDEA",
			"approval_status": "unreviewed",
			"location_id": location_id,
			"required_existing_ids": {
				"locations": [location_id],
				"npcs": _optional_id_list(npc_id),
				"factions": _optional_id_list(faction_id),
				"readables": _optional_id_list(readable_id)
			},
			"implementation_gaps": _implementation_gaps(template_id),
			"source_constraints": [
				"Proposal only. It is not canon and must not be added to data/quests.json.",
				"Use only approved people, factions, locations, and named setting material.",
				"Choose real world targets, dialogue, rewards, and consequences during approval."
			]
		}
	)
	return pitch


static func _template_text(
	template_id: String,
	location_name: String,
	npc_name: String,
	readable_title: String,
	faction_name: String
) -> Dictionary:
	match template_id:
		"trade_pressure":
			return {
				"title": "A Price at %s" % location_name,
				"type": "trade pressure",
				"summary": "%s needs to know why ordinary goods no longer reach %s." % [
					npc_name, location_name
				],
				"player_hook": "Start with %s, then follow the disrupted route." % readable_title,
				"twist": "The missing goods are a symptom. The final cause stays open until review.",
				"possible_outcomes": [
					"Restore the route through a practical agreement.",
					"Expose the pressure and choose who bears its cost.",
					"Leave the route unstable and change later local dialogue."
				],
				"canon_risk": "low"
			}
		"missing_work":
			return {
				"title": "Work Left Undone at %s" % location_name,
				"type": "personal obligation",
				"summary": (
					"%s cannot finish a needed job until a small but important loss is explained."
					% npc_name
				),
				"player_hook": "Read %s and investigate the last place the work was seen." % readable_title,
				"twist": "The missing thing matters because of who relied on it, not its sale value.",
				"possible_outcomes": [
					"Return the work and strengthen a local relationship.",
					"Recover the truth but accept that the work is gone.",
					"Sell, hide, or misuse the lead and close off the easy reward."
				],
				"canon_risk": "low"
			}
		"paper_trail":
			return {
				"title": "What the Notice Omits at %s" % location_name,
				"type": "investigation",
				"summary": "A detail in %s does not match what %s remembers about %s." % [
					readable_title, npc_name, location_name
				],
				"player_hook": "Compare the written warning with the place it describes.",
				"twist": "The written account is incomplete, not automatically dishonest.",
				"possible_outcomes": [
					"Correct the record and reveal a safe route.",
					"Protect the person who left the omission.",
					"Publish the truth and create a new local problem."
				],
				"canon_risk": "medium"
			}
		"local_dispute":
			return {
				"title": "The Narrow Claim at %s" % location_name,
				"type": "local dispute",
				"summary": (
					"%s asks the player to settle a small dispute before it becomes a public quarrel."
					% npc_name
				),
				"player_hook": "Use %s as one piece of evidence, then speak to both sides." % readable_title,
				"twist": "Both sides hold a partial truth; the missing context is the real objective.",
				"possible_outcomes": [
					"Broker a compromise with a visible local consequence.",
					"Side with one claimant and change access or prices.",
					"Refuse to decide and let the dispute escalate later."
				],
				"canon_risk": "medium"
			}
		_:
			return {
				"title": "A Road Notice at %s" % location_name,
				"type": "road threat",
				"summary": "%s wants to know why %s can no longer be trusted near %s." % [
					faction_name, readable_title, location_name
				],
				"player_hook": "Read the warning, scout the route, then decide how to respond.",
				"twist": "The danger may be real, but the warning alone does not identify a culprit.",
				"possible_outcomes": [
					"Make the route safe through force or negotiation.",
					"Expose a false warning and change local trust.",
					"Leave the route dangerous for a later quest chain."
				],
				"canon_risk": "low"
			}


static func _implementation_gaps(template_id: String) -> Array[String]:
	var gaps: Array[String] = [
		"Approve the premise and final title.",
		"Choose or author objective targets in the world.",
		"Author dialogue, stages, effects, reward, and a persistent consequence.",
		"Run content validation and an in-game acceptance test before activation."
	]
	if template_id == "paper_trail" or template_id == "local_dispute":
		gaps.append("Review any historical claim or new participant against LORE.md before canonizing.")
	return gaps


static func _source_context(content, location_ids: Array[String]) -> Dictionary:
	return {
		"locations": location_ids,
		"npcs": _sorted_ids(content.npc_ids()),
		"factions": _sorted_ids(content.faction_ids()),
		"readables": _sorted_ids(content.readable_ids()),
		"existing_quest_ids": _sorted_ids(content.quest_ids())
	}


static func _location_ids(content, location_filter: String) -> Array[String]:
	if not location_filter.is_empty():
		var filtered: Array[String] = []
		if content.has_location(location_filter):
			filtered.append(location_filter)
		return filtered
	return _sorted_ids(content.location_ids())


static func _pick_id(ids: Array[String], key: String) -> String:
	var sorted_ids := _sorted_ids(ids)
	if sorted_ids.is_empty():
		return ""
	return sorted_ids[StableHash.index(key, sorted_ids.size())]


static func _sorted_ids(ids: Array[String]) -> Array[String]:
	var result := ids.duplicate()
	result.sort()
	return result


static func _display_name(entry: Dictionary, fallback: String) -> String:
	return String(entry.get("name", entry.get("title", fallback)))


static func _optional_id_list(value: String) -> Array[String]:
	var result: Array[String] = []
	if not value.is_empty():
		result.append(value)
	return result
