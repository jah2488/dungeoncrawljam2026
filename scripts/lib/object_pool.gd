class_name ObjectPool
extends Node

## Generic object pool for bullets, particles, effects, etc.
## Pre-allocates instances and recycles them.
##
## Usage:
##   var pool = ObjectPool.new()
##   pool.scene = preload("res://scenes/bullet.tscn")
##   pool.pool_size = 50
##   add_child(pool)
##
##   var bullet = pool.acquire()
##   bullet.global_position = muzzle.global_position
##
##   pool.release(bullet)

@export var scene: PackedScene
@export var pool_size: int = 20
@export var auto_cull: bool = true
@export var cull_distance: float = 2000.0

var _available: Array[Node] = []
var _active: Array[Node] = []


func _ready() -> void:
	if scene == null:
		push_error("ObjectPool: No scene assigned")
		return
	for i in pool_size:
		var instance: Node = scene.instantiate()
		add_child(instance)
		instance.visible = false
		instance.set_process(false)
		instance.set_physics_process(false)
		_available.append(instance)


func _process(_delta: float) -> void:
	if auto_cull:
		_cull_distant()


func acquire() -> Node:
	var instance: Node
	if not _available.is_empty():
		instance = _available.pop_back() as Node
	else:
		if _active.is_empty():
			return null
		instance = _active.pop_front() as Node

	instance.visible = true
	instance.set_process(true)
	instance.set_physics_process(true)
	_active.append(instance)

	if instance.has_method("reset"):
		instance.call("reset")

	return instance


func release(instance: Node) -> void:
	if instance == null:
		return
	instance.visible = false
	instance.set_process(false)
	instance.set_physics_process(false)
	_active.erase(instance)
	_available.append(instance)


func release_all() -> void:
	for instance in _active.duplicate():
		release(instance)


func available_count() -> int:
	return _available.size()


func active_count() -> int:
	return _active.size()


func _cull_distant() -> void:
	var camera_2d: Camera2D = get_viewport().get_camera_2d()
	var camera_3d: Camera3D = get_viewport().get_camera_3d()
	for instance: Node in _active.duplicate():
		if instance is Node2D and camera_2d != null:
			if (instance as Node2D).global_position.distance_to(camera_2d.global_position) > cull_distance:
				release(instance)
		elif instance is Node3D and camera_3d != null:
			if (instance as Node3D).global_position.distance_to(camera_3d.global_position) > cull_distance:
				release(instance)
