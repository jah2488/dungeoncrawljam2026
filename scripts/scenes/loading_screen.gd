extends Control

## Initial loading screen — transitions to main menu after brief delay.

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/SceneManager"):
		SceneManager.change_scene(SceneManager.MAIN_MENU)
