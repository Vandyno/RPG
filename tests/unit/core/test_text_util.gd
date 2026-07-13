extends GutTest

const TextUtil = preload("res://scripts/core/text_util.gd")


func test_ellipsized_respects_character_limits() -> void:
	assert_eq(TextUtil.ellipsized("Talk", 22), "Talk")
	assert_eq(TextUtil.ellipsized("abcdef", 0), "")
	assert_eq(TextUtil.ellipsized("abcdef", 1), "a")
	assert_eq(TextUtil.ellipsized("abcdef", 3), "abc")
	assert_eq(TextUtil.ellipsized("abcdef", 5), "ab...")
