extends Interactable

class_name EnemyTile

@export var text: String = ""

var in_combat := false

# Enemy Stats
var max_hp := 20
var hp := 20
var damage := 2


func _ready() -> void:
    super()
    is_passable = false
    is_enemy = true


func on_focused() -> void:
    print("[EnemyTile] ", text)
    in_combat = true


func on_unfocused() -> void:
    print("[EnemyTile] ...")
    in_combat = false


func get_options() -> Array[Dictionary]:
    return []


func on_stepped_on() -> void:
    print("[EnemyTile] (stepped on) ", text)


func take_damage(amount: int) -> void:
    hp -= amount
    if hp <= 0:
        _on_death()
    else:
        _damage_flash()


# This is where the tile receives the player's action and decides what to do in response.
func interact(choice_id: String = "") -> void:
    if hp <= 0:
        print("Can't interact with the dead")
        return
    print("[EnemyTile] (interaction) ", choice_id)
    match choice_id:
        "attack":
            print("enemy takes damage, enemy attacks player")
            Events.PlayerTakesDamage.emit(damage, self)
        "defend":
            print("enemy attacks player, but player defended")
            # Do blocks just ignore an attack?
            # Do we want blocking? SHould it be called 'evading'?
            pass


func _process(_delta: float) -> void:
    #TODO: Animate enemy when 'in_combat' is true
    pass


func _damage_flash() -> void:
    Juice.flash($Sprite3D, Color.RED)


func _on_death() -> void:
    print("[EnemyTile: " + str(Game.world_to_grid(global_position)) + "] died")
    # Maybe we don't queue-free, and instead just mark as dead and leave the tile around.
    queue_free()
