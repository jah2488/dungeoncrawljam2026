extends Interactable

class_name TextTile

@export var text: String = ""


func on_focused() -> void:
	print("[TextTile] ", text)


func on_unfocused() -> void:
	print("[TextTile] ...")


func on_stepped_on() -> void:
	print("[TextTile] (stepped on) ", text)


func interact(choice_id: String = "") -> void:
	print("[TextTile] (interact) ", text)
