extends Interactable

class_name TrapTile

var print_name: String = "[TrapTile (armed)]"
@export var text: String = ""

var triggered := false
var damage := 1
var lever_up := true
var armed := true
var difficulty := 0.5
var disarm_attempt := 0
var is_trap = true


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
    print(print_name + " (stepped on) ")
    if armed:
        Events.PlayerTriggerTrap.emit(damage, self)


# This is where the tile receives the player's action and decides what to do in response.
func interact(choice_id: String = "") -> void:
    print(print_name + " (interaction) ", choice_id)
    match choice_id:
        "disarm":
            if !armed:
                print("This trap is already disarmed")
                return

            disarm_attempt += 1
            var attempt = randf_range(0.0, 1.0)
            if attempt >= difficulty - (difficulty * disarm_attempt / 10): # difficulty lowers by 10% base difficulty every attempt
                disarm()
            else:
                print("Player fails to disarm the trap")
                Events.PlayerTriggerTrap.emit(damage, self)
        "inspect":
            if armed:
                print("Its a trap!")
            else:
                print("Its a trap! But its disarmed")
        _:
            print("you cannot perform this action on a trap")


func disarm():
    armed = false
    is_triggerable = false
    print_name = "[TrapTile (disarmed)]"
    print("Player disarms the trap")


func trigger() -> void:
    if armed == true:
        disarm()
