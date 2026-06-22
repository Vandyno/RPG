class_name TargetUiTextBuilder
extends RefCounted

const ButtonTextFormatter = preload("res://scripts/ui/button_text_formatter.gd")


static func action_button_text(targets: Array, compact: bool, picker_visible: bool) -> String:
	if picker_visible:
		return "Close"
	var next_target := next_target_name(targets)
	if compact and not next_target.is_empty():
		return "Next\n%s" % ButtonTextFormatter.compact_target_label(next_target)
	return "Next"


static func action_button_tooltip(targets: Array, picker_visible: bool) -> String:
	if picker_visible:
		return "Close targets"
	var next_target := next_target_name(targets)
	var suffix := "Hold for target list."
	return suffix if next_target.is_empty() else "Next target: %s. %s" % [next_target, suffix]


static func summary_label(targets: Array) -> String:
	var counts: Dictionary = {}
	var labels: Array[String] = []
	var total := 0
	for target in targets:
		if not target is Dictionary:
			continue
		if String(target.get("id", "")).is_empty():
			continue
		var label := kind_label(String(target.get("kind", "object")))
		if label.is_empty():
			label = "Object"
		if not counts.has(label):
			counts[label] = 0
			labels.append(label)
		counts[label] = int(counts[label]) + 1
		total += 1
	if total <= 0:
		return ""
	var parts: Array[String] = []
	for label in labels:
		parts.append("%s %d" % [label, int(counts[label])])
	return "%d targets: %s" % [total, ", ".join(parts)]


static func kind_label(kind: String) -> String:
	var labels := {
		"readable": "Readable",
		"npc": "NPC",
		"pickup": "Pickup",
		"container": "Container",
		"door": "Door",
		"enemy": "Enemy",
		"rest": "Rest",
		"poi": "POI"
	}
	return String(labels.get(kind, "Object"))


static func next_target_name(targets: Array) -> String:
	var valid_targets: Array[Dictionary] = []
	var selected_index := -1
	for target in targets:
		if not target is Dictionary:
			continue
		var entity_id := String(target.get("id", ""))
		if entity_id.is_empty():
			continue
		var index := valid_targets.size()
		valid_targets.append(target)
		if bool(target.get("selected", false)):
			selected_index = index
	if valid_targets.size() < 2:
		return ""
	if selected_index < 0:
		selected_index = 0
	var next_target: Dictionary = valid_targets[(selected_index + 1) % valid_targets.size()]
	return String(next_target.get("name", ""))
