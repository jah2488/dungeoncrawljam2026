extends Node

## Scene manager with async loading, transitions, and overlay stack.

const MAIN_MENU := "res://scenes/title_screen.tscn"
const SETTINGS := "res://scenes/settings.tscn"
const TEST_SCENE := "res://scenes/test_scene.tscn"
const TRANSITIONS_SCENE := "res://scenes/transitions.tscn"

var _gui_layer: CanvasLayer = null
var _transitions: Node = null
var _current_scene: Node = null
var _overlay_stack: Array[Node] = []


func _ready() -> void:
	_gui_layer = CanvasLayer.new()
	_gui_layer.layer = 100
	_gui_layer.name = "GUILayer"
	add_child(_gui_layer)

	var transitions_res: Resource = load(TRANSITIONS_SCENE)
	if transitions_res:
		_transitions = (transitions_res as PackedScene).instantiate()
		add_child(_transitions)


func change_scene(scene_path: String, transition_time: float = 0.5) -> void:
	if has_node("/root/Events"):
		Events.SceneChangeStarted.emit(scene_path)

	if _transitions:
		await _transitions.transition_in(transition_time)

	pop_all_overlays()
	if _current_scene:
		_current_scene.queue_free()
		_current_scene = null

	ResourceLoader.load_threaded_request(scene_path)
	while true:
		var progress: Array = []
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(scene_path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + scene_path)
			if _transitions:
				await _transitions.transition_out(transition_time)
			return
		await get_tree().process_frame

	var resource: Resource = ResourceLoader.load_threaded_get(scene_path)
	if resource == null:
		push_error("SceneManager: Resource is null after loading: " + scene_path)
		if _transitions:
			await _transitions.transition_out(transition_time)
		return
	var new_scene: Node = (resource as PackedScene).instantiate()

	if new_scene is Control:
		_gui_layer.add_child(new_scene)
	else:
		get_tree().root.add_child(new_scene)
	_current_scene = new_scene

	if _transitions:
		await _transitions.transition_out(transition_time)

	if has_node("/root/Events"):
		Events.SceneChangeCompleted.emit(scene_path)


func push_overlay(scene_path: String) -> Node:
	var scene: Node = (load(scene_path) as PackedScene).instantiate()
	_gui_layer.add_child(scene)
	_overlay_stack.append(scene)
	return scene


func pop_overlay() -> void:
	if _overlay_stack.is_empty():
		return
	var overlay: Node = _overlay_stack.pop_back() as Node
	overlay.queue_free()


func pop_all_overlays() -> void:
	while not _overlay_stack.is_empty():
		pop_overlay()


func has_overlay() -> bool:
	return not _overlay_stack.is_empty()
