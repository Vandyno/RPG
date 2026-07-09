extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const LocationTextBuilder = preload("res://scripts/ui/text/location_text_builder.gd")


func test_location_text_builder_summarizes_discovered_locations() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var discovered := {"location_briarwatch_crossroads": true, "location_missing": true, "": true}

	assert_eq(
		LocationTextBuilder.names(discovered, content), "Briarwatch Crossroads, location_missing"
	)
	var details := LocationTextBuilder.details(discovered, content)

	assert_true(details.contains("Briarwatch Crossroads - Marches of Velcor"))
	assert_true(details.contains("west road meets the bridge"))
	assert_true(details.contains("location_missing"))
	assert_eq(LocationTextBuilder.names({}, content), "none")
	assert_eq(LocationTextBuilder.details({}, content), "none")
