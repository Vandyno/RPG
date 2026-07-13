extends SceneTree

const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const WorldAtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")
const WorldRegionGenerator = preload("res://scripts/generation/world_region_generator.gd")
const WorldRegionProposalValidator = preload("res://scripts/data/world_region_proposal_validator.gd")

const DEFAULT_ATLAS_PATH := "res://data/world_atlas_proposal.json"
const DEFAULT_REGION_ID := "region_marches_velcor"
const DEFAULT_SEED := 1701
const DEFAULT_OUTPUT_PATH := "res://data/proposals/region_marches_velcor_seed_1701.json"
const DEFAULT_REVIEW_PATH := "res://data/world_atlas_review.json"


func _initialize() -> void:
	_generate.call_deferred()


func _generate() -> void:
	var config := generation_config(OS.get_cmdline_user_args())
	var atlas := WorldAtlasValidator.load_atlas(config["atlas_path"])
	var atlas_review := WorldAtlasApprovalGate.load_review(config["review_path"])
	var proposal := WorldRegionGenerator.generate(
		atlas, config["region_id"], config["seed"], {"atlas_review": atlas_review}
	)
	if proposal.is_empty():
		printerr("Region generation blocked by invalid or unapproved atlas data")
		quit(3)
		return
	var errors := WorldRegionProposalValidator.validate(proposal)
	if not errors.is_empty():
		for error in errors:
			printerr(error)
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
		printerr("Could not write region proposal: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	file.store_string(JSON.stringify(proposal, "  ") + "\n")
	print(
		"Wrote %s: %d terrain cells, %d minor routes, %d POIs"
		% [absolute_output, proposal["terrain_cells"].size(), proposal["minor_routes"].size(), proposal["pois"].size()]
	)
	quit()


static func generation_config(args: Array) -> Dictionary:
	return {
		"region_id": String(args[0]) if args.size() > 0 else DEFAULT_REGION_ID,
		"seed": int(args[1]) if args.size() > 1 else DEFAULT_SEED,
		"output_path": String(args[2]) if args.size() > 2 else DEFAULT_OUTPUT_PATH,
		"atlas_path": String(args[3]) if args.size() > 3 else DEFAULT_ATLAS_PATH,
		"review_path": String(args[4]) if args.size() > 4 else DEFAULT_REVIEW_PATH
	}
