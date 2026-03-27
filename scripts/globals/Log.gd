extends Node

## Configuration
var enable_file_logging: bool = false
var log_file_path: String = "user://game.log"
var log_levels_enabled: Dictionary = {"DEBUG": true, "INFO": true, "WARN": true, "ERROR": true}

## Internal state
var _log_file: FileAccess = null
var _session_start_time: int = 0

enum LogLevel { DEBUG, INFO, WARN, ERROR }


func _ready() -> void:
	_session_start_time = Time.get_ticks_msec()
	if enable_file_logging:
		_open_log_file()


func _exit_tree() -> void:
	_close_log_file()


## Public logging methods
func debug(system: String, message: String) -> void:
	_log(LogLevel.DEBUG, system, message)


func info(system: String, message: String) -> void:
	_log(LogLevel.INFO, system, message)


func warn(system: String, message: String) -> void:
	_log(LogLevel.WARN, system, message)


func error(system: String, message: String) -> void:
	_log(LogLevel.ERROR, system, message)


## Configuration methods
func set_file_logging(enabled: bool) -> void:
	enable_file_logging = enabled
	if enabled and _log_file == null:
		_open_log_file()
	elif not enabled and _log_file != null:
		_close_log_file()


func set_log_level_enabled(level: String, enabled: bool) -> void:
	if level in log_levels_enabled:
		log_levels_enabled[level] = enabled


func set_log_file_path(path: String) -> void:
	var was_logging: bool = enable_file_logging and _log_file != null
	if was_logging:
		_close_log_file()

	log_file_path = path

	if was_logging:
		_open_log_file()


func clear_log_file() -> void:
	if _log_file != null:
		_close_log_file()

	if FileAccess.file_exists(log_file_path):
		DirAccess.remove_absolute(log_file_path)

	if enable_file_logging:
		_open_log_file()


## Internal methods
func _log(level: LogLevel, system: String, message: String) -> void:
	var level_name: String = LogLevel.keys()[level]

	# Check if this log level is enabled
	if not log_levels_enabled.get(level_name, true):
		return

	var frame_no: int = Engine.get_frames_drawn()
	var formatted_message: String = _format_message(frame_no, system, level_name, message)

	# Print to console
	match level:
		LogLevel.ERROR:
			push_error(formatted_message)
		LogLevel.WARN:
			push_warning(formatted_message)
		_:
			print(formatted_message)

	# Write to file if enabled
	if enable_file_logging and _log_file != null:
		_write_to_file(formatted_message)


func _format_message(frame_no: int, system: String, level: String, message: String) -> String:
	return "[%d][%s][%s] %s" % [frame_no, system, level, message]


func _open_log_file() -> void:
	_log_file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if _log_file == null:
		push_error("Failed to open log file at: " + log_file_path)
		return

	# Write session header
	var timestamp: String = Time.get_datetime_string_from_system()
	_log_file.store_line("=== Log Session Started: %s ===" % timestamp)
	_log_file.flush()


func _close_log_file() -> void:
	if _log_file != null:
		var timestamp: String = Time.get_datetime_string_from_system()
		_log_file.store_line("=== Log Session Ended: %s ===" % timestamp)
		_log_file.close()
		_log_file = null


func _write_to_file(message: String) -> void:
	if _log_file != null:
		var timestamp: String = Time.get_datetime_string_from_system()
		_log_file.store_line("[%s] %s" % [timestamp, message])
		_log_file.flush()
