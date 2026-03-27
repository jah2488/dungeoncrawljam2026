extends CharacterBody3D

const SPEED = 4.0
const JUMP_VELOCITY = 4.5

var direction: Vector3


func _physics_process(delta: float) -> void:
    direction = Vector3.ZERO
    if not is_on_floor():
        velocity += get_gravity() * delta

    if Input.is_action_just_pressed(&"move_forward"):
        direction = -transform.basis.z
    if Input.is_action_just_pressed(&"move_back"):
        direction = transform.basis.z
    if Input.is_action_just_pressed(&"move_left"):
        direction = -transform.basis.x
    if Input.is_action_just_pressed(&"move_right"):
        direction = transform.basis.x
    if Input.is_action_just_pressed(&"turn_right"):
        transform.basis = transform.basis.rotated(Vector3.UP, deg_to_rad(-90))
    if Input.is_action_just_pressed(&"turn_left"):
        transform.basis = transform.basis.rotated(Vector3.UP, deg_to_rad(90))

    position += direction * SPEED

    move_and_slide()
