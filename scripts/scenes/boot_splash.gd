extends Control

## Boot splash screen — fades in, holds, fades out, then transitions to the next scene.


func _ready() -> void:
	modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_on_splash_finished)


func _on_splash_finished() -> void:
	if has_node("/root/SceneManager"):
		SceneManager.change_scene(SceneManager.MAIN_MENU)
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
