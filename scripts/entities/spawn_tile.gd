extends Interactable

class_name SpawnTile

var player_packed = preload("res://entities/player.tscn")

var print_name: String = "[SpawnTile]"
@export var text: String = ""


func _ready() -> void:
    super()
    is_passable = true
    is_enemy = false
    is_triggerable = true
    set_group_id()


func on_focused() -> void:
    print(print_name + " " + text)


func on_unfocused() -> void:
    print(print_name + " ...")


func get_options() -> Array[Dictionary]:
    return []


func on_stepped_on() -> void:
    pass


# This is where the tile receives the player's action and decides what to do in response.
func interact(choice_id: String = "") -> void:
    print(print_name + " (interaction) ", choice_id)
    match choice_id:
        _:
            print("...")


func trigger() -> void:
    var existing_player_nodes = get_tree().get_nodes_in_group("player")
    if existing_player_nodes:
        var next_level = get_parent()
        var player = existing_player_nodes[0]
        player.position = global_position
        player.position.y += 0.8
        player.reparent(next_level)
    else:
        var player = player_packed.instantiate()
        player.position = position
        get_parent().add_child(player)
