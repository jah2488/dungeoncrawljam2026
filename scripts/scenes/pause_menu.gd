extends Control

## Pause menu overlay — resume, settings, quit options.

@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_menu_button: Button = %QuitMenuButton
@onready var _quit_desktop_button: Button = %QuitDesktopButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_resume_button.pressed.connect(_on_resume)
	_settings_button.pressed.connect(_on_settings)
	_quit_menu_button.pressed.connect(_on_quit_to_menu)
	_quit_desktop_button.pressed.connect(_on_quit_to_desktop)


func _on_resume() -> void:
	_close()


func _on_settings() -> void:
	if has_node("/root/SceneManager"):
		SceneManager.push_overlay(SceneManager.SETTINGS)


func _on_quit_to_menu() -> void:
	if has_node("/root/Game"):
		Game.resume()

	if has_node("/root/SceneManager"):
		SceneManager.pop_overlay()
		SceneManager.change_scene(SceneManager.MAIN_MENU)
	else:
		queue_free()


func _on_quit_to_desktop() -> void:
	if has_node("/root/Events"):
		Events.GameQuit.emit()
	else:
		get_tree().quit()


func _close() -> void:
	if has_node("/root/Game"):
		Game.resume()

	if has_node("/root/SceneManager"):
		SceneManager.pop_overlay()
	else:
		queue_free()
