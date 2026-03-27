extends Node

## JSON save/load system with autosave, versioning, and migrations.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

var _data: Dictionary = {}
var _autosave_timer: Timer = null
var _playtime_start: float = 0.0


func _ready() -> void:
	_playtime_start = Time.get_unix_time_from_system()
	load_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
	elif what == NOTIFICATION_EXIT_TREE:
		if _autosave_timer:
			_autosave_timer.queue_free()
			_autosave_timer = null


func set_data(key: String, value: Variant) -> void:
	_data[key] = value


func get_data(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


func erase_data(key: String) -> void:
	_data.erase(key)


func save_game() -> void:
	var save_dict := {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"playtime_seconds": get_data("playtime_seconds", 0.0) + (Time.get_unix_time_from_system() - _playtime_start),
		"data": _data,
	}
	_playtime_start = Time.get_unix_time_from_system()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing")
		return
	file.store_string(JSON.stringify(save_dict, "\t"))
	file.close()

	if has_node("/root/Log"):
		Log.info("SaveManager", "Game saved")
	if has_node("/root/Events"):
		Events.SaveCompleted.emit()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading")
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("SaveManager: Failed to parse save file")
		return

	var save_dict: Dictionary = json.data
	_migrate(save_dict)
	_data = save_dict.get("data", {})
	set_data("playtime_seconds", save_dict.get("playtime_seconds", 0.0))

	if has_node("/root/Log"):
		Log.info("SaveManager", "Game loaded (v%d)" % save_dict.get("save_version", 0))
	if has_node("/root/Events"):
		Events.LoadCompleted.emit()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_data = {}


func start_autosave(interval_seconds: float = 60.0) -> void:
	if _autosave_timer:
		_autosave_timer.queue_free()
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = interval_seconds
	_autosave_timer.timeout.connect(save_game)
	add_child(_autosave_timer)
	_autosave_timer.start()


func stop_autosave() -> void:
	if _autosave_timer:
		_autosave_timer.stop()


func _migrate(save_dict: Dictionary) -> void:
	var version: int = save_dict.get("save_version", 0)
	if version < SAVE_VERSION:
		save_dict["save_version"] = SAVE_VERSION
