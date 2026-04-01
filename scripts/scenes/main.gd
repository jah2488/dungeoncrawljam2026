extends Control

var cheese = preload("res://resources/items/cheese.tres")
var fire_scale = preload("res://resources/items/fire_scale.tres")
var player_inventory: Array[Item] = [cheese, fire_scale]


func _ready() -> void:
    Events.PlayerLocation.connect(
        func(location, rot):
            var dir = "?"
            match int(rad_to_deg(rot)):
                -90, 90:
                    dir = "E"
                -180, 180:
                    dir = "S"
                -270, 270:
                    dir = "W"
                0, 360, -360:
                    dir = "N"
            %Compass.text = (str(location) + " " + dir)
    )
    Events.StartCombat.connect(func(): %CombatButtons.visible = true)
    Events.EndCombat.connect(func(): %CombatButtons.visible = false)
    Events.UpdatePlayerHP.connect(func(hp): %HealthBar.value = hp)
    Events.PlayerAcquiresItem.connect(
        func(item):
            player_inventory.append(item)
            _update_inventory()
    )
    Events.GameStarted.emit()
    for child in %InventoryContainer.get_children():
        child.pressed.connect(_on_inventory_button_pressed, CONNECT_APPEND_SOURCE_OBJECT)
    _update_inventory()


func _update_inventory() -> void:
    var idx = 0
    for item in player_inventory:
        var child: Button = %InventoryContainer.get_child(idx)
        child.disabled = false
        child.icon = item.icon
        idx += 1


func _on_inventory_button_pressed(button: Button) -> void:
    var idx = (button.name.split("Button")[1].to_int() - 1)
    var item = player_inventory[idx]
    print(item.name, item.description)
    #TODO: Actually use the item


func _physics_process(_delta):
    var player = get_tree().get_nodes_in_group("player")[0]
    if player:
        %MinimapCamera3D.position.x = player.position.x
        %MinimapCamera3D.position.z = player.position.z


func _on_turn_left_pressed() -> void:
    Events.PlayerTurned.emit(-90.0)


func _on_turn_right_pressed() -> void:
    Events.PlayerTurned.emit(90.0)


func _on_forward_pressed() -> void:
    Events.PlayerMoved.emit(0)


func _on_right_pressed() -> void:
    Events.PlayerMoved.emit(1)


func _on_back_pressed() -> void:
    Events.PlayerMoved.emit(2)


func _on_left_pressed() -> void:
    Events.PlayerMoved.emit(3)


func _on_inspect_pressed() -> void:
    Events.PlayerInspected.emit()


func _on_disarm_pressed() -> void:
    Events.PlayerDisarmed.emit()


func _on_attack_pressed() -> void:
    Events.PlayerAttacked.emit()


func _on_block_pressed() -> void:
    Events.PlayerDefended.emit()
