extends Node

enum LOG_LEVELS { DEBUG, INFO, WARN, ERROR }
var time_format = "hh:mm:ss"
var format_string = "[{TIME}] [{LEVEL}] - {MESSAGE}"
var log_level : LOG_LEVELS = LOG_LEVELS.ERROR

func init(_log_level : LOG_LEVELS) -> void:
	log_level = _log_level

func debug(message : String) -> void:
	_log(message, LOG_LEVELS.DEBUG)

func info(message : String) -> void:
	_log(message, LOG_LEVELS.INFO)

func warn(message : String) -> void:
	_log(message, LOG_LEVELS.WARN)

func error(message : String) -> void:
	_log(message, LOG_LEVELS.ERROR)

func _log(message : String, level : LOG_LEVELS) -> void:
	if level >= log_level:
		match(level):
			LOG_LEVELS.INFO: print(_format(message, level))
			LOG_LEVELS.WARN: push_warning(_format(message, level))
			LOG_LEVELS.ERROR: push_error(_format(message, level))

func _format(message : String, level : LOG_LEVELS) -> String:
	var result = format_string
	var time = time_format
	var ts = Time.get_datetime_dict_from_system()
	time = time.replace("hh", "%02d" % [ts.hour])
	time = time.replace("mm", "%02d" % [ts.minute])
	time = time.replace("ss", "%02d" % [ts.second])
	result = result.replace("{TIME}", "%s" % time)
	result = result.replace("{LEVEL}", "%d" % level)
	result = result.replace("{MESSAGE}", "%s" % message)

	return result
