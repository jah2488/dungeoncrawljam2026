extends Control

@onready var _sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var _sub_viewport: SubViewport = $SubViewportContainer/SubViewport


func _ready() -> void:
    if has_node("/root/Events"):
        Events.GameStarted.emit()
    Events.PlayerTurned.connect(
        func(rot):
            match int(rad_to_deg(rot)):
                -90, 90:
                    %Compass.text = "E"
                -180, 180:
                    %Compass.text = "S"
                -270, 270:
                    %Compass.text = "W"
                0, 360, -360:
                    %Compass.text = "N"
    )


func _physics_process(_delta):
    var player = get_tree().get_nodes_in_group("player")[0]
    if player:
        %MinimapCamera3D.position.x = player.position.x
        %MinimapCamera3D.position.z = player.position.z
