extends Control

@warning_ignore("unused_private_class_variable")
@onready var _sub_viewport_container: SubViewportContainer = $SubViewportContainer
@warning_ignore("unused_private_class_variable")
@onready var _sub_viewport: SubViewport = $SubViewportContainer/SubViewport


func _ready() -> void:
    if has_node("/root/Events"):
        Events.GameStarted.emit()
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
