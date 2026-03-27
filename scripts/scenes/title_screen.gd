extends Control


func _ready() -> void:
	%PlayButton.pressed.connect(_on_play)
	%SettingsButton.pressed.connect(_on_settings)
	%TestGymButton.pressed.connect(_on_test_gym)
	%QuitButton.pressed.connect(_on_quit)


func _on_play() -> void:
	if has_node("/root/SceneManager"):
		SceneManager.change_scene("res://scenes/main.tscn")


func _on_settings() -> void:
	if has_node("/root/SceneManager"):
		SceneManager.push_overlay(SceneManager.SETTINGS)


func _on_test_gym() -> void:
	if has_node("/root/SceneManager"):
		SceneManager.change_scene(SceneManager.TEST_SCENE)


func _on_quit() -> void:
	if has_node("/root/Events"):
		Events.GameQuit.emit()
	else:
		get_tree().quit()
