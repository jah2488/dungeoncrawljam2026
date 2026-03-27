class_name State
extends Node

## Base class for state machine states. Override methods as needed.

var state_machine: StateMachine


func _ready() -> void:
	state_machine = get_parent() as StateMachine


func enter(_data: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
