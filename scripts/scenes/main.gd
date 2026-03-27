extends Control

@onready var _sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var _sub_viewport: SubViewport = $SubViewportContainer/SubViewport


func _ready() -> void:
	if has_node("/root/Events"):
		Events.GameStarted.emit()
