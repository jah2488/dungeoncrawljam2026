extends Node
## Screen shake, hitstop, and tween-based juice effects.

func shake(camera: Node, intensity: float = 5.0, duration: float = 0.2) -> void:
    if camera == null:
        return

    var is_2d: bool = camera is Camera2D
    var is_3d: bool = camera is Camera3D
    if not is_2d and not is_3d:
        return

    var original_offset_2d: Vector2 = camera.offset if is_2d else Vector2.ZERO
    var original_position_3d: Vector3 = camera.position if is_3d else Vector3.ZERO

    var tween: Tween = create_tween()
    var steps: int = int(duration / 0.03)
    for i: int in steps:
        var rand_x: float = randf_range(-intensity, intensity)
        var rand_y: float = randf_range(-intensity, intensity)
        var decay: float = 1.0 - (float(i) / steps)
        if is_2d:
            var target: Vector2 = original_offset_2d + Vector2(rand_x, rand_y) * decay
            tween.tween_property(camera, "offset", target, 0.03)
        else:
            var target: Vector3 = original_position_3d + Vector3(rand_x * decay, rand_y * decay, 0.0)
            tween.tween_property(camera, "position", target, 0.03)

    if is_2d:
        tween.tween_property(camera, "offset", original_offset_2d, 0.03)
    else:
        tween.tween_property(camera, "position", original_position_3d, 0.03)


func hitstop(duration: float = 0.05) -> void:
    get_tree().paused = true
    await get_tree().create_timer(duration, true, false, true).timeout
    get_tree().paused = false


func scale_punch(node: Node2D, punch_scale: float = 1.3, duration: float = 0.15) -> void:
    var original := node.scale
    var tween := create_tween()
    tween.tween_property(node, "scale", original * punch_scale, duration * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tween.tween_property(node, "scale", original, duration * 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)


func flash(node: SpriteBase3D, color: Color = Color.WHITE, duration: float = 0.1) -> void:
    var original_modulate := node.modulate
    node.modulate = color
    await get_tree().create_timer(duration).timeout
    node.modulate = original_modulate


func float_text(text: String, position: Vector3, parent: Node, color: Color = Color.WHITE, duration: float = 0.8) -> void:
    var label := Label3D.new()
    label.text = text
    label.modulate = color
    label.position = position
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    parent.add_child(label)

    var tween := create_tween().set_parallel(true)
    tween.tween_property(label, "position:y", position.y - 40, duration)
    tween.tween_property(label, "modulate:a", 0.0, duration)
    tween.chain().tween_callback(label.queue_free)
