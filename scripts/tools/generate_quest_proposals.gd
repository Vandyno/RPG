extends SceneTree

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const QuestProposalGenerator = preload("res://scripts/generation/quest_proposal_generator.gd")
const QuestProposalValidator = preload("res://scripts/data/quest_proposal_validator.gd")

const DEFAULT_SEED := "first_quest_pass"
const DEFAULT_COUNT := 5
const DEFAULT_OUTPUT_PATH := "res://reports/quest_proposals/first_quest_pass.json"


func _initialize() -> void:
	_generate.call_deferred()


func _generate() -> void:
	var config := generation_config(OS.get_cmdline_user_args())
	var content := ContentDatabase.new()
	root.add_child(content)
	var load_errors := content.load_all()
	if not load_errors.is_empty():
		for load_error in load_errors:
			printerr(load_error)
		quit(1)
		return
	var bundle := QuestProposalGenerator.generate(
		content,
		String(config["seed"]),
		int(config["count"]),
		String(config["location_id"])
	)
	var errors := QuestProposalValidator.validate(content, bundle)
	if not errors.is_empty():
		for validation_error in errors:
			printerr(validation_error)
		quit(1)
		return
	var output_path := String(config["output_path"])
	var absolute_output := ProjectSettings.globalize_path(output_path)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_output.get_base_dir())
	if make_error != OK:
		printerr("Could not create proposal directory: %s" % error_string(make_error))
		quit(1)
		return
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("Could not write quest proposals: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	file.store_string(JSON.stringify(bundle, "  ") + "\n")
	print("Wrote %d review-only quest pitches to %s" % [bundle["pitches"].size(), absolute_output])
	quit()


static func generation_config(args: PackedStringArray) -> Dictionary:
	return {
		"seed": String(args[0]) if args.size() > 0 else DEFAULT_SEED,
		"count": int(args[1]) if args.size() > 1 and String(args[1]).is_valid_int() else DEFAULT_COUNT,
		"location_id": String(args[2]) if args.size() > 2 else "",
		"output_path": String(args[3]) if args.size() > 3 else DEFAULT_OUTPUT_PATH
	}
