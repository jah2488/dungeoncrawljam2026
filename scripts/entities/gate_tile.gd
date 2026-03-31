extends Interactable

class_name GateTile

var print_name: String = "[GateTile]"
@export var text: String = ""


func _ready() -> void:
    super()
    is_passable = false
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
        "inspect":
            print("This gate is locked...")
        _:
            print("you cannot perform this action on a wall lever")


func trigger() -> void:
    print(is_passable)
    if is_passable == true:
        is_passable = false
        $Sprite3D.show()
    else:
        is_passable = true
        $Sprite3D.hide()
