extends GutTest

const RpgNavigationTextBuilder = preload("res://scripts/ui/text/rpg_navigation_text_builder.gd")


func test_friendly_navigation_converts_tile_routes_to_words() -> void:
	assert_eq(
		RpgNavigationTextBuilder.friendly_navigation("E 5.0t Harrow Venn"),
		"5 tiles east to Harrow Venn"
	)
	assert_eq(RpgNavigationTextBuilder.friendly_navigation("N 1t"), "1 tile north")
	assert_eq(
		RpgNavigationTextBuilder.friendly_navigation("SW 2.5t Old Cache"),
		"2.5 tiles southwest to Old Cache"
	)


func test_friendly_navigation_keeps_unknown_or_malformed_text() -> void:
	assert_eq(RpgNavigationTextBuilder.friendly_navigation("nearby"), "nearby")
	assert_eq(RpgNavigationTextBuilder.friendly_navigation("UP 3t Peak"), "UP 3t Peak")
	assert_eq(RpgNavigationTextBuilder.friendly_navigation("E five Harrow"), "E five Harrow")
	assert_eq(RpgNavigationTextBuilder.friendly_navigation("  Rest at camp  "), "Rest at camp")


func test_friendly_route_line_preserves_quest_title() -> void:
	assert_eq(
		RpgNavigationTextBuilder.friendly_route_line("The Missing Tools: E 5.0t Harrow Venn"),
		"The Missing Tools: 5 tiles east to Harrow Venn"
	)
	assert_eq(RpgNavigationTextBuilder.friendly_route_line("Notice:"), "Notice")


func test_friendly_route_lines_skips_blank_lines_and_formats_each_route() -> void:
	assert_eq(
		RpgNavigationTextBuilder.friendly_route_lines(
			"\nThe Missing Tools: E 5.0t Harrow Venn\nRoad Patrol: NW 1t\n"
		),
		"The Missing Tools: 5 tiles east to Harrow Venn\nRoad Patrol: 1 tile northwest"
	)
