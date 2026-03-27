extends Control

## Settings/options menu — volume, display, back button.

@onready var _master_slider: HSlider = %MasterSlider
@onready var _fx_slider: HSlider = %FXSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _vsync_check: CheckButton = %VSyncCheck
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_restore_display_settings()

	if has_node("/root/Audio"):
		_master_slider.value = Audio.get_bus_volume("Master")
		_fx_slider.value = Audio.get_bus_volume("FX")
		_music_slider.value = Audio.get_bus_volume("Music")

	_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_vsync_check.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED

	_master_slider.value_changed.connect(_on_master_changed)
	_fx_slider.value_changed.connect(_on_fx_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_vsync_check.toggled.connect(_on_vsync_toggled)
	_back_button.pressed.connect(_on_back)


func _on_master_changed(value: float) -> void:
	if has_node("/root/Audio"):
		Audio.set_bus_volume("Master", value)


func _on_fx_changed(value: float) -> void:
	if has_node("/root/Audio"):
		Audio.set_bus_volume("FX", value)


func _on_music_changed(value: float) -> void:
	if has_node("/root/Audio"):
		Audio.set_bus_volume("Music", value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_display_settings()


func _on_vsync_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_save_display_settings()


func _save_display_settings() -> void:
	if not has_node("/root/SaveManager"):
		return
	SaveManager.set_data("display_settings", {
		"fullscreen": DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
		"vsync": DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED,
	})


func _restore_display_settings() -> void:
	if not has_node("/root/SaveManager"):
		return
	var settings: Dictionary = SaveManager.get_data("display_settings", {})
	if settings.is_empty():
		return
	if settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if settings.get("vsync", true):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_back() -> void:
	if has_node("/root/SceneManager"):
		SceneManager.pop_overlay()
	else:
		queue_free()
