extends Interactable

class_name WallLeverTile

enum Status { ON, OFF }

var print_name: String = "[WallLeverTile]"
@export var text: String = ""

var status := Status.OFF


func _ready() -> void:
    super()
    is_passable = false
    is_enemy = false
    set_group_id()
    pick_sprite()

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
            if status == Status.OFF:
                status = Status.ON
                print("Pulled lever down... you hear something move...")
            elif status == Status.ON:
                status = Status.OFF
                print("Pushed lever up... you hear something move...")
            Groups.trigger_items_in_group(group_id)
            pick_sprite()
        _:
            print("you cannot perform this action on a wall lever")



func pick_sprite():
    if status == Status.OFF:
        $SpriteOff.show()
        $SpriteOn.hide()
    elif status == Status.ON:
        $SpriteOff.hide()
        $SpriteOn.show()
