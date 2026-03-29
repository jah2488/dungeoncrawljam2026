extends Node

enum GameState { STARTING, PLAYING, PAUSED, QUITTING }

const PAUSE_MENU := "res://scenes/pause_menu.tscn"

var game_state: GameState = GameState.STARTING
var boot_time: float = 0.0
var build_type: String = "dev"
var debug: bool = false

var tile_registry: Dictionary[Vector2i, Node] = { }


func world_to_grid(global_pos: Vector3) -> Vector2i:
    return Vector2i(roundi(global_pos.x / 4.0), roundi(global_pos.z / 4.0))


func grid_to_world(grid_pos: Vector2i) -> Vector3:
    return Vector3(grid_pos.x * 4, 0, grid_pos.y * 4)


func register_tile(tile: Node3D) -> void:
    tile_registry[world_to_grid(tile.global_position)] = tile


func unregister_tile(tile: Node3D) -> void:
    tile_registry.erase(world_to_grid(tile.global_position))


func unregister_tile_at(grid_pos: Vector2i) -> void:
    tile_registry.erase(grid_pos)


func _ready() -> void:
    boot_time = Time.get_unix_time_from_system()
    build_type = ProjectSettings.get_setting("application/config/build_type", "dev")
    process_mode = Node.PROCESS_MODE_ALWAYS
    if has_node("/root/Events"):
        Events.GameStarted.connect(_on_game_started)
        Events.GameQuit.connect(_on_game_quit)
    else:
        # Without Events, transition to PLAYING immediately.
        game_state = GameState.PLAYING


func _input(_event: InputEvent) -> void:
    if not Input.is_action_just_pressed(&"pause"):
        return

    if game_state == GameState.PLAYING:
        pause()
        if has_node("/root/SceneManager") and not SceneManager.has_overlay():
            SceneManager.push_overlay(PAUSE_MENU)
    elif game_state == GameState.PAUSED:
        if has_node("/root/SceneManager") and SceneManager.has_overlay():
            SceneManager.pop_overlay()
            # Only resume if we just closed the last overlay (the pause menu itself).
            # If settings was on top, popping it should keep us paused.
            if not SceneManager.has_overlay():
                resume()
        else:
            resume()


func pause() -> void:
    game_state = GameState.PAUSED
    get_tree().paused = true
    if has_node("/root/Events"):
        Events.PauseGame.emit()


func resume() -> void:
    game_state = GameState.PLAYING
    get_tree().paused = false
    if has_node("/root/Events"):
        Events.ResumeGame.emit()


func _on_game_started() -> void:
    game_state = GameState.PLAYING


func _on_game_quit() -> void:
    game_state = GameState.QUITTING
    get_tree().quit()
