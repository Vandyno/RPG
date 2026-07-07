class_name StableHash
extends RefCounted


static func index(text: String, size: int) -> int:
	if size <= 0:
		return 0
	var total: int = 0
	for index_value in text.length():
		total += text.unicode_at(index_value) * (index_value + 1)
	return total % size


static func unit(text: String) -> float:
	return float(index(text, 1001)) / 1000.0
