class_name StateMachine
extends Node

## Generic finite state machine. Add State children to use.

@export var initial_state: State

var current_state: State


func _ready() -> void:
	await owner.ready
	if initial_state:
		transition_to(initial_state.name)
	elif get_child_count() > 0:
		transition_to(get_child(0).name)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func transition_to(state_name: String, data: Dictionary = {}) -> void:
	var new_state := get_node_or_null(NodePath(state_name)) as State
	if new_state == null:
		push_error("StateMachine: State '%s' not found" % state_name)
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter(data)
