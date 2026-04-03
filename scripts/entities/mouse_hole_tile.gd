extends Interactable

class_name DoorTile

var print_name: String = "[DoorTile]"
@export var text: String = ""


func _ready() -> void:
    super()
    is_passable = false
    is_enemy = false
    is_triggerable = false
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
            if group_id:
                Groups.trigger_items_in_group(group_id, self)
                print("It's a mouse hole... You feel a desire to go in...")
            else:
                print("This is your home. You must venture forth.")
        _:
            print("you cannot perform this action on a mouse hole")
