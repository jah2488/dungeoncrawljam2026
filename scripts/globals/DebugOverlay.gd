extends CanvasLayer

## Toggle-able debug overlay — FPS, memory, custom vars.
## Hidden in production builds. Press F3 to toggle.

var _visible: bool = false
var _custom_vars: Dictionary = {}

@onready var _label: Label = $Panel/Label


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if Game.build_type != "dev":
		set_process(false)
		set_process_input(false)
		return


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F3:
		_visible = not _visible
		visible = _visible


func _process(_delta: float) -> void:
	if not _visible:
		return

	var lines: PackedStringArray = []
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	lines.append("Frame: %d" % Engine.get_frames_drawn())

	var mem := OS.get_static_memory_usage()
	lines.append("Memory: %.1f MB" % (mem / 1048576.0))

	var vid_mem := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	lines.append("VRAM: %.1f MB" % (vid_mem / 1048576.0))

	lines.append("Objects: %d" % Performance.get_monitor(Performance.OBJECT_COUNT))
	lines.append("Nodes: %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	lines.append("Draw calls: %d" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

	for key in _custom_vars:
		lines.append("%s: %s" % [key, str(_custom_vars[key])])

	_label.text = "\n".join(lines)


func set_var(key: String, value: Variant) -> void:
	_custom_vars[key] = value


func clear_var(key: String) -> void:
	_custom_vars.erase(key)
