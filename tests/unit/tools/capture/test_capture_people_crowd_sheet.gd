extends GutTest

const CapturePeopleCrowdSheet = preload(
	"res://scripts/tools/capture/capture_people_crowd_sheet.gd"
)


func test_people_crowd_sheet_keeps_review_page_contract() -> void:
	assert_eq(CapturePeopleCrowdSheet.PEOPLE_ORDER[0], "people_human")
	assert_eq(
		CapturePeopleCrowdSheet.DIRECTIONS,
		[Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]
	)
	assert_eq(CapturePeopleCrowdSheet.LABELED_VARIANTS_PER_PAGE, 6)
	assert_eq(CapturePeopleCrowdSheet.HUNDRED_COLUMNS * CapturePeopleCrowdSheet.HUNDRED_ROWS, 100)
