extends Node2D

## Autoload for drawing debug vectors and shapes in world space.
## Only active in dev builds. All draw calls are queued per frame
## and cleared after rendering.

enum CommandType { ARROW, CIRCLE, RECT, LINE, POINT, TEXT }

var _commands: Array[Dictionary] = []


func _ready() -> void:
	z_index = 4096
	process_mode = Node.PROCESS_MODE_ALWAYS

	if Game.build_type != "dev":
		set_process(false)
		visible = false
		return


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for cmd: Dictionary in _commands:
		var type: CommandType = cmd["type"] as CommandType
		match type:
			CommandType.ARROW:
				_draw_arrow(cmd)
			CommandType.CIRCLE:
				_draw_circle(cmd)
			CommandType.RECT:
				_draw_rect_outline(cmd)
			CommandType.LINE:
				_draw_line_cmd(cmd)
			CommandType.POINT:
				_draw_point(cmd)
			CommandType.TEXT:
				_draw_text(cmd)
	_commands.clear()


# --- Public API ---

func arrow(from: Vector2, to: Vector2, color: Color = Color.GREEN, width: float = 2.0) -> void:
	_commands.append({
		"type": CommandType.ARROW,
		"from": from,
		"to": to,
		"color": color,
		"width": width,
	})


func velocity(node: Node2D, vel: Vector2, color: Color = Color.GREEN) -> void:
	var scaled: Vector2 = vel * 0.1
	arrow(node.global_position, node.global_position + scaled, color, 2.0)


func circle(center: Vector2, radius: float, color: Color = Color.CYAN, resolution: int = 32) -> void:
	_commands.append({
		"type": CommandType.CIRCLE,
		"center": center,
		"radius": radius,
		"color": color,
		"resolution": resolution,
	})


func rect_outline(rect: Rect2, color: Color = Color.YELLOW, width: float = 1.0) -> void:
	_commands.append({
		"type": CommandType.RECT,
		"rect": rect,
		"color": color,
		"width": width,
	})


func line(from: Vector2, to: Vector2, color: Color = Color.WHITE, width: float = 1.0) -> void:
	_commands.append({
		"type": CommandType.LINE,
		"from": from,
		"to": to,
		"color": color,
		"width": width,
	})


func point(pos: Vector2, color: Color = Color.RED, radius: float = 4.0) -> void:
	_commands.append({
		"type": CommandType.POINT,
		"pos": pos,
		"color": color,
		"radius": radius,
	})


func text(pos: Vector2, label: String, color: Color = Color.WHITE) -> void:
	_commands.append({
		"type": CommandType.TEXT,
		"pos": pos,
		"label": label,
		"color": color,
	})


# --- Internal draw helpers ---

func _draw_arrow(cmd: Dictionary) -> void:
	var from: Vector2 = cmd["from"]
	var to: Vector2 = cmd["to"]
	var color: Color = cmd["color"]
	var width: float = cmd["width"]

	if from.is_equal_approx(to):
		draw_circle(from, 3.0, color)
		return

	draw_line(from, to, color, width)

	# Arrowhead: small triangle at the tip oriented along the arrow direction
	var direction: Vector2 = (to - from).normalized()
	var head_length: float = clampf((to - from).length() * 0.2, 6.0, 16.0)
	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var tip_base: Vector2 = to - direction * head_length
	var head_points: PackedVector2Array = PackedVector2Array([
		to,
		tip_base + perpendicular * head_length * 0.5,
		tip_base - perpendicular * head_length * 0.5,
	])
	draw_colored_polygon(head_points, color)


func _draw_circle(cmd: Dictionary) -> void:
	var center: Vector2 = cmd["center"]
	var radius: float = cmd["radius"]
	var color: Color = cmd["color"]
	var resolution: int = cmd["resolution"]

	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(resolution + 1):
		var angle: float = TAU * float(i) / float(resolution)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	for i: int in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, 1.0)


func _draw_rect_outline(cmd: Dictionary) -> void:
	var r: Rect2 = cmd["rect"]
	var color: Color = cmd["color"]
	var width: float = cmd["width"]

	var tl: Vector2 = r.position
	var tr: Vector2 = Vector2(r.position.x + r.size.x, r.position.y)
	var br: Vector2 = r.position + r.size
	var bl: Vector2 = Vector2(r.position.x, r.position.y + r.size.y)

	draw_line(tl, tr, color, width)
	draw_line(tr, br, color, width)
	draw_line(br, bl, color, width)
	draw_line(bl, tl, color, width)


func _draw_line_cmd(cmd: Dictionary) -> void:
	draw_line(cmd["from"], cmd["to"], cmd["color"], cmd["width"])


func _draw_point(cmd: Dictionary) -> void:
	draw_circle(cmd["pos"], cmd["radius"], cmd["color"])


func _draw_text(cmd: Dictionary) -> void:
	var pos: Vector2 = cmd["pos"]
	var label: String = cmd["label"]
	var color: Color = cmd["color"]
	var font: Font = ThemeDB.fallback_font
	var font_size: int = ThemeDB.fallback_font_size
	draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
