extends Interactable

class_name MerchantTile

var print_name: String = "[MerchantTile]"
@export var text: String = ""

var max_hp := 50
var hp := max_hp
var damage := 9999
var current_hit := 0
var hit_capacity := 3

var in_combat := false

func _ready() -> void:
    super()
    is_passable = false
    is_enemy = true


func on_focused() -> void:
    in_combat = true
    print(print_name + " " + text)


func on_unfocused() -> void:
    in_combat = false
    print(print_name + " ...")


func get_options() -> Array[Dictionary]:
    return []


func on_stepped_on() -> void:
    pass


func take_damage(amount: int) -> void:
    hp -= amount
    if hp <= 0:
        _on_death()
    else:
        _damage_flash()


# This is where the tile receives the player's action and decides what to do in response.
func interact(choice_id: String = "") -> void:
    print(print_name + " (interaction) ", choice_id)
    match choice_id:
        "inspect":
            print("Heard you was lookin for some cheese. Well you came to the right place")
        "attack":
            match current_hit:
                0: print("Hey quit horsin' around")
                1: print("I mean it. You better stop")
                2: print("Listen here bub... Try that 1 more time")
                hit_capacity:
                    print("Alright, that's it! Hyah")
                    Events.PlayerTakesDamage.emit(damage, self)
                _: print("O" + str(["of", "w", "uch", "h come on now"].pick_random())) # lol
            current_hit += 1
        _:
            print("you cannot perform this action on a merchant")


func _process(_delta: float) -> void:
    #TODO: Animate enemy when 'in_combat' is true
    pass


func _damage_flash() -> void:
    Juice.flash($Sprite3D, Color.RED)


func _on_death() -> void:
    print("[EnemyTile: " + str(Game.world_to_grid(global_position)) + "] died")
    # Maybe we don't queue-free, and instead just mark as dead and leave the tile around.
    queue_free()
