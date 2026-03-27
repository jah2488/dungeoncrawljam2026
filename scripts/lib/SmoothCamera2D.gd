class_name SmoothCamera2D
extends Camera2D

## A smooth-follow 2D camera with dead zone, look-ahead, and optional world limits.
##
## Attach this script to a Camera2D node (or add a SmoothCamera2D node directly).
## Set the [member target] to the node you want the camera to follow.
##
## Compatible with Juice.gd screen shake — since Juice operates on the camera's
## offset property, it works automatically with this camera controller.

## The node the camera will follow. Set this in the inspector or via code.
@export var target: Node2D

## How quickly the camera catches up to the target. Higher values = snappier.
@export_range(0.1, 50.0, 0.1) var smoothing_speed: float = 5.0

## How far ahead the camera looks in the direction of movement (0.0 = none, 1.0 = full velocity).
@export_range(0.0, 2.0, 0.05) var look_ahead_factor: float = 0.3

## The camera won't move until the target exceeds this distance from the camera center (in pixels).
@export var dead_zone: Vector2 = Vector2(10.0, 10.0)

## Whether to clamp the camera position within [member limit_rect].
@export var use_limits: bool = false

## World-space rectangle the camera is clamped to when [member use_limits] is true.
@export var limit_rect: Rect2 = Rect2(-10000.0, -10000.0, 20000.0, 20000.0)

## Tracks the target's previous position to derive velocity when the target
## node doesn't expose a [code]velocity[/code] property.
var _previous_target_position: Vector2 = Vector2.ZERO

## Whether we have stored at least one previous position (avoids a frame-one pop).
var _has_previous_position: bool = false


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var target_pos: Vector2 = target.global_position

	# --- Derive target velocity ---
	var target_velocity: Vector2 = Vector2.ZERO
	if "velocity" in target:
		# Use the target's own velocity when available (e.g. CharacterBody2D).
		target_velocity = target.get("velocity") as Vector2
	elif _has_previous_position:
		# Fall back to position delta.
		target_velocity = (target_pos - _previous_target_position) / delta

	_previous_target_position = target_pos
	_has_previous_position = true

	# --- Look-ahead offset ---
	var look_ahead_offset: Vector2 = target_velocity * look_ahead_factor

	# --- Desired position ---
	var desired_position: Vector2 = target_pos + look_ahead_offset

	# --- Dead zone check ---
	var camera_to_desired: Vector2 = desired_position - global_position
	if absf(camera_to_desired.x) < dead_zone.x:
		desired_position.x = global_position.x
	if absf(camera_to_desired.y) < dead_zone.y:
		desired_position.y = global_position.y

	# --- Smooth interpolation ---
	var new_position: Vector2 = global_position.lerp(desired_position, clampf(smoothing_speed * delta, 0.0, 1.0))

	# --- Clamp to world limits ---
	if use_limits:
		var half_size: Vector2 = get_viewport_rect().size / (2.0 * zoom)
		var min_pos: Vector2 = Vector2(limit_rect.position.x + half_size.x, limit_rect.position.y + half_size.y)
		var max_pos: Vector2 = Vector2(limit_rect.end.x - half_size.x, limit_rect.end.y - half_size.y)
		new_position.x = clampf(new_position.x, min_pos.x, max_pos.x)
		new_position.y = clampf(new_position.y, min_pos.y, max_pos.y)

	global_position = new_position
