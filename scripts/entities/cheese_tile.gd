extends Interactable

class_name CheeseTile

var print_name: String = "[CheeseTile]"
@export var text: String = ""

var healing_amount := 5


func _ready() -> void:
    super()
    is_passable = true
    is_enemy = false
    is_triggerable = false


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
            Events.PlayerHeals.emit(healing_amount, self)
            print("Mmmm, cheese")
            queue_free()
        _:
            print("you cannot perform this action on cheese")
