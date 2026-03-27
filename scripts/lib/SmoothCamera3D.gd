class_name SmoothCamera3D
extends Camera3D

## A smooth-follow 3D camera that tracks a target node with a configurable offset.
##
## Attach this script to a Camera3D node (or add a SmoothCamera3D node directly).
## Set the [member target] to the node you want the camera to follow.
##
## Compatible with Juice.gd screen shake — since Juice operates on the camera's
## position property, it works automatically with this camera controller.

## The node the camera will follow. Set this in the inspector or via code.
@export var target: Node3D

## Offset from the target's position where the camera sits (in world space).
## Default places the camera slightly above and behind the target.
@export var offset: Vector3 = Vector3(0.0, 5.0, 8.0)

## How quickly the camera catches up to the target. Higher values = snappier.
@export_range(0.1, 50.0, 0.1) var smoothing_speed: float = 5.0

## Whether the camera should rotate to look at the target each frame.
@export var look_at_target: bool = true

## Offset added to the target's position when using look_at (e.g., look at chest height).
@export var look_at_offset: Vector3 = Vector3(0.0, 1.0, 0.0)


func _physics_process(delta: float) -> void:
	if target == null:
		return

	# --- Desired position ---
	var desired_position: Vector3 = target.global_position + offset

	# --- Smooth interpolation ---
	global_position = global_position.lerp(desired_position, clampf(smoothing_speed * delta, 0.0, 1.0))

	# --- Look at target ---
	if look_at_target:
		var look_target: Vector3 = target.global_position + look_at_offset
		look_at(look_target)
