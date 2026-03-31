extends Interactable

class_name EnemyTile

@export var text: String = ""


func on_focused() -> void:
	print("[EnemyTile] ", text)


func on_unfocused() -> void:
	print("[EnemyTile] ...")


func on_stepped_on() -> void:
	print("[EnemyTile] (stepped on) ", text)


func interact(choice_id: String = "") -> void:
	print("[EnemyTile] (interact) ", text)
