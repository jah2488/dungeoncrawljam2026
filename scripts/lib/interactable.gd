extends Node3D

class_name Interactable

@export var is_passable := true
@export var is_enemy := false
@export var is_triggerable := false

var group_id := ""

func _ready() -> void:
    Game.register_tile(self)
    # When subclassing, always call super() in ready function.


func on_focused() -> void:
    print("Player has approached this tile, ready to interact")


func on_unfocused() -> void:
    print("Player has moved away from this tile")


func on_stepped_on() -> void:
    print("Player has stepped on this tile")


func get_options() -> Array[Dictionary]:
    return []


func set_group_id():
    group_id = get_meta("group_id")


func interact(choice_id: String = "") -> void:
    print("Player has done interaction: ", choice_id)


func _exit_tree() -> void:
    Game.unregister_tile(self)
