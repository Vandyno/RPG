class_name TimeManager
extends Node

const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const MINUTES_PER_DAY := HOURS_PER_DAY * MINUTES_PER_HOUR
const START_DAY := 1
const START_HOUR := 8
const START_MINUTE := 0

var event_bus: EventBus
var day := START_DAY
var minute_of_day := START_HOUR * MINUTES_PER_HOUR + START_MINUTE


func setup(bus: EventBus) -> void:
	event_bus = bus
	_emit_changed()


func advance_minutes(minutes: int) -> bool:
	if minutes <= 0:
		return false
	var total_minutes := minute_of_day + minutes
	day += total_minutes / MINUTES_PER_DAY
	minute_of_day = total_minutes % MINUTES_PER_DAY
	_emit_changed()
	return true


func advance_hours(hours: int) -> bool:
	if hours <= 0:
		return false
	return advance_minutes(hours * MINUTES_PER_HOUR)


func wait_hours(hours: int) -> Dictionary:
	if not advance_hours(hours):
		return {"ok": false, "message": "Could not wait right now."}
	return {"ok": true, "message": "Waited %dh. %s." % [hours, get_summary()]}


func get_hour() -> int:
	return minute_of_day / MINUTES_PER_HOUR


func get_minute() -> int:
	return minute_of_day % MINUTES_PER_HOUR


func get_phase() -> String:
	var hour := get_hour()
	if hour >= 5 and hour < 12:
		return "Morning"
	if hour >= 12 and hour < 17:
		return "Afternoon"
	if hour >= 17 and hour < 21:
		return "Evening"
	return "Night"


func is_phase(phase: String) -> bool:
	return get_phase().to_lower() == phase.to_lower()


func is_hour_between(start_hour: int, end_hour: int) -> bool:
	var start_minute := _hour_to_minute(start_hour)
	var end_minute := _hour_to_minute(end_hour)
	if start_minute == end_minute:
		return true
	if start_minute < end_minute:
		return minute_of_day >= start_minute and minute_of_day < end_minute
	return minute_of_day >= start_minute or minute_of_day < end_minute


func get_time_label() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]


func get_summary() -> String:
	return "Day %d, %s (%s)" % [day, get_time_label(), get_phase()]


func get_details() -> String:
	var lines: Array[String] = []
	lines.append("Time: %s" % get_time_label())
	lines.append("Day: %d" % day)
	lines.append("Phase: %s" % get_phase())
	return "\n".join(lines)


func get_save_data() -> Dictionary:
	return {"day": day, "minute_of_day": minute_of_day}


func load_save_data(data: Dictionary) -> void:
	day = maxi(START_DAY, _int_field(data, "day", START_DAY))
	minute_of_day = clampi(_int_field(data, "minute_of_day", minute_of_day), 0, MINUTES_PER_DAY - 1)
	_emit_changed()


func _emit_changed() -> void:
	if event_bus:
		event_bus.time_changed.emit(day, get_hour(), get_minute(), get_phase())


func _int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return fallback
	return int(value)


func _hour_to_minute(hour: int) -> int:
	return clampi(hour, 0, HOURS_PER_DAY - 1) * MINUTES_PER_HOUR


func _is_number(value: Variant) -> bool:
	return value is int or value is float
