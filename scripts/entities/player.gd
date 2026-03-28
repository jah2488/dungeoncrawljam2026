extends CharacterBody3D

const SPEED = 4.0
const JUMP_VELOCITY = 4.5

var direction: Vector3
var target_rot: float = 0
var new_position: Vector3


func _physics_process(delta: float) -> void:
    direction = Vector3.ZERO
    if not is_on_floor():
        velocity += get_gravity() * delta

        # TODO: We need a raycast in each cardinal direction
        # TODO: We need to prevent 'double dashing' through walls, have a 'is moving' var and check it before allowing another move.
    $RayCast3D.force_raycast_update()
    if not $RayCast3D.get_collider():
        if Input.is_action_just_pressed(&"move_forward"):
            direction = -transform.basis.z
    if Input.is_action_just_pressed(&"move_back"):
        direction = transform.basis.z
    if Input.is_action_just_pressed(&"move_left"):
        direction = -transform.basis.x
    if Input.is_action_just_pressed(&"move_right"):
        direction = transform.basis.x
    if Input.is_action_just_pressed(&"turn_right"):
        target_rot = target_rot + deg_to_rad(-90)
        Events.PlayerTurned.emit(target_rot)
    if Input.is_action_just_pressed(&"turn_left"):
        target_rot = target_rot + deg_to_rad(90)
        Events.PlayerTurned.emit(target_rot)

    var t = create_tween()
    new_position += direction * SPEED

    if rotation.y != target_rot:
        t.tween_property(self, "rotation:y", target_rot, 0.13).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
    t.tween_property(self, "position", new_position, 0.13).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

    move_and_slide()
