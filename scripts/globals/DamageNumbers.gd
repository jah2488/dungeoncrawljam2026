extends Node

## Autoload that spawns floating number popups.
## Converts world position to screen space at spawn time, then animates
## in screen space so numbers don't follow camera movement.
##
## Usage:
##   DamageNumbers.spawn_damage(enemy.global_position, 42)
##   DamageNumbers.spawn_heal(player.global_position, 15)
##   DamageNumbers.spawn_xp(player.global_position, 100)

var _canvas_layer: CanvasLayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 105
	_canvas_layer.process_mode = PROCESS_MODE_ALWAYS
	add_child(_canvas_layer)


## Spawn a floating label. `world_position` is in world coordinates and
## gets converted to screen space automatically.
func spawn(world_position: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var screen_pos: Vector2 = _world_to_screen(world_position)

	var label: Label = Label.new()
	label.text = text
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.process_mode = PROCESS_MODE_ALWAYS
	label.add_theme_font_size_override("font_size", 18)
	_canvas_layer.add_child(label)

	# Center the label on the spawn position.
	label.position = screen_pos - Vector2(label.size.x * 0.5, label.size.y * 0.5)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE

	var drift_x: float = randf_range(-20.0, 20.0)
	var target_position: Vector2 = label.position + Vector2(drift_x, -50.0)
	var duration: float = 0.8

	# Float up and fade out.
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position", target_position, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Punch scale: grow to 1.5x over first 30%, then ease back to 0.8x.
	var punch_up_time: float = duration * 0.3
	var punch_down_time: float = duration * 0.7
	var scale_tween: Tween = create_tween()
	scale_tween.tween_property(label, "scale", Vector2(1.5, 1.5), punch_up_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_tween.tween_property(label, "scale", Vector2(0.8, 0.8), punch_down_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Clean up after animation finishes.
	tween.chain().tween_callback(label.queue_free)


func spawn_damage(world_position: Vector2, amount: int) -> void:
	spawn(world_position, str(amount), Color.RED)


func spawn_heal(world_position: Vector2, amount: int) -> void:
	spawn(world_position, "+" + str(amount), Color.GREEN)


func spawn_xp(world_position: Vector2, amount: int) -> void:
	spawn(world_position, "+" + str(amount) + " XP", Color.YELLOW)


func _world_to_screen(world_pos: Vector2) -> Vector2:
	var canvas_xform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_xform * world_pos
