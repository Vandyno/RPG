extends SceneTree

const WorldAtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")

const DEFAULT_ATLAS_PATH := "res://data/world_atlas_proposal.json"
const DEFAULT_REVIEW_PATH := "res://data/world_atlas_review.json"
const DEFAULT_REPORT_PATH := "res://reports/world_atlas/atlas_gate_report.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var config := check_config(OS.get_cmdline_user_args())
	var atlas := WorldAtlasValidator.load_atlas(config["atlas_path"])
	var review := WorldAtlasApprovalGate.load_review(config["review_path"])
	var result := WorldAtlasApprovalGate.evaluate(atlas, review)
	var report_path := String(config["report_path"])
	var absolute_path := ProjectSettings.globalize_path(report_path)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if make_error != OK:
		printerr("Could not create atlas gate report directory: %s" % error_string(make_error))
		quit(1)
		return
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		printerr("Could not write atlas gate report: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	file.store_string(JSON.stringify(result, "  ") + "\n")
	print("Atlas gate: %s (can_generate=%s)" % [result["status"], result["can_generate"]])
	for blocker in result["blockers"]:
		printerr(blocker)
	quit(0 if result["can_generate"] or not config["require_approved"] else 3)


static func check_config(args: Array) -> Dictionary:
	var positional: Array = args.filter(func(value): return String(value) != "--require-approved")
	return {
		"atlas_path": String(positional[0]) if positional.size() > 0 else DEFAULT_ATLAS_PATH,
		"review_path": String(positional[1]) if positional.size() > 1 else DEFAULT_REVIEW_PATH,
		"report_path": String(positional[2]) if positional.size() > 2 else DEFAULT_REPORT_PATH,
		"require_approved": args.has("--require-approved")
	}
