extends SceneTree

const WorldAtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const WorldSettlementGenerator = preload("res://scripts/generation/world_settlement_generator.gd")
const WorldSettlementProposalValidator = preload(
	"res://scripts/data/world_settlement_proposal_validator.gd"
)

const DEFAULT_ATLAS_PATH := "res://data/world_atlas_proposal.json"
const DEFAULT_REVIEW_PATH := "res://data/world_atlas_review.json"
const DEFAULT_SETTLEMENT_ID := "northgate"
const DEFAULT_SEED := 2701
const DEFAULT_OUTPUT_PATH := "res://data/proposals/settlement_northgate_seed_2701.json"


func _initialize() -> void:
	_generate.call_deferred()


func _generate() -> void:
	var config := generation_config(OS.get_cmdline_user_args())
	var atlas := WorldAtlasValidator.load_atlas(config["atlas_path"])
	var review := WorldAtlasApprovalGate.load_review(config["review_path"])
	var proposal := WorldSettlementGenerator.generate(
		atlas,
		config["settlement_id"],
		config["seed"],
		{"atlas_review": review}
	)
	if proposal.is_empty():
		printerr("Settlement generation blocked by invalid, unsupported, or unapproved atlas data")
		quit(3)
		return
	var errors := WorldSettlementProposalValidator.validate(proposal, atlas)
	if not errors.is_empty():
		for error in errors:
			printerr(error)
		quit(1)
		return
	var output_path := String(config["output_path"])
	var absolute_path := ProjectSettings.globalize_path(output_path)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if make_error != OK:
		printerr("Could not create settlement proposal directory: %s" % error_string(make_error))
		quit(1)
		return
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("Could not write settlement proposal: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	file.store_string(JSON.stringify(proposal, "  ") + "\n")
	print(
		"Wrote %s: %d plots, %d structures, %d NPC slots, %d services"
		% [
			absolute_path,
			proposal["plots"].size(),
			proposal["structures"].size(),
			proposal["npc_role_slots"].size(),
			proposal["service_slots"].size()
		]
	)
	quit()


static func generation_config(args: Array) -> Dictionary:
	return {
		"settlement_id": String(args[0]) if args.size() > 0 else DEFAULT_SETTLEMENT_ID,
		"seed": int(args[1]) if args.size() > 1 else DEFAULT_SEED,
		"output_path": String(args[2]) if args.size() > 2 else DEFAULT_OUTPUT_PATH,
		"atlas_path": String(args[3]) if args.size() > 3 else DEFAULT_ATLAS_PATH,
		"review_path": String(args[4]) if args.size() > 4 else DEFAULT_REVIEW_PATH
	}
