extends CharacterBody3D

const CELL_SIZE = 4.0
const ANIM_DURATION = 0.13

# Cardinal direction vectors indexed by facing (0=North/-Z, 1=East/+X, 2=South/+Z, 3=West/-X)
const CARDINAL_DIRS = [
    Vector3(0, 0, -1),
    Vector3(1, 0, 0),
    Vector3(0, 0, 1),
    Vector3(-1, 0, 0),
]

# Maps movement input actions to their relative direction offset from facing
const MOVE_ACTIONS = {
    &"move_forward": 0,
    &"move_right": 1,
    &"move_back": 2,
    &"move_left": 3,
}

var facing: int = 0
var target_rot: float = 0.0
var grid_position: Vector3
var is_moving: bool = false
var _raycasts: Array[RayCast3D] = []
var _debug_highlight: MeshInstance3D

var is_interacting_with: Interactable = null

# UI movement button signal data
var _do_turn_left: bool = false
var _do_turn_right: bool = false
var _do_move_dir: int = -1

# Player Stats
@export var max_hp := 99
@export var hp := 99
@export var damage := 10


func _ready() -> void:
    global_position.y = 0.8
    grid_position = _snap_to_grid(position)
    position = grid_position
    _create_raycasts()
    # _create_debug_highlight()
    _update_interaction_tile()
    Events.PlayerTurned.connect(
        func(rot: float) -> void:
            if rot < 0:
                _do_turn_left = true
            else:
                _do_turn_right = true
    )
    Events.PlayerMoved.connect(func(dir: int) -> void: _do_move_dir = dir)
    Events.PlayerAttacked.connect(_on_player_attacked)
    Events.PlayerDefended.connect(_on_player_defended)
    Events.PlayerTakesDamage.connect(_on_player_takes_damage)


func _physics_process(_delta: float) -> void:
    if is_moving:
        return

    if Input.is_action_just_pressed(&"interact") and is_interacting_with:
        is_interacting_with.interact()
        return

    if Input.is_action_just_pressed(&"turn_right") or _do_turn_right:
        _do_turn_right = false
        facing = (facing + 1) % 4
        target_rot -= deg_to_rad(90.0)
        _animate_rotation()
        return

    if Input.is_action_just_pressed(&"turn_left") or _do_turn_left:
        _do_turn_left = false
        facing = (facing + 3) % 4
        target_rot += deg_to_rad(90.0)
        _animate_rotation()
        return

    var move_dir := Vector3.ZERO

    for action in MOVE_ACTIONS:
        var relative_dir: int = MOVE_ACTIONS[action]
        if Input.is_action_just_pressed(action) or _do_move_dir == relative_dir:
            _do_move_dir = -1
            var world_dir_index: int = (facing + relative_dir) % 4
            if not _is_blocked(relative_dir) and _is_tile_passable(CARDINAL_DIRS[world_dir_index]):
                move_dir = CARDINAL_DIRS[world_dir_index]
            break

    if move_dir != Vector3.ZERO:
        grid_position = _snap_to_grid(grid_position + move_dir * CELL_SIZE)
        _animate_movement()


func _create_raycasts() -> void:
    # Forward (-Z), Right (+X), Back (+Z), Left (-X) in local space
    var directions := [
        Vector3(0, 0, -CELL_SIZE),
        Vector3(CELL_SIZE, 0, 0),
        Vector3(0, 0, CELL_SIZE),
        Vector3(-CELL_SIZE, 0, 0),
    ]
    for dir in directions:
        var ray := RayCast3D.new()
        ray.position.y = $Camera3D.position.y
        ray.target_position = dir
        ray.exclude_parent = true
        ray.collision_mask = 1
        add_child(ray)
        _raycasts.append(ray)


func _is_blocked(relative_dir: int) -> bool:
    var ray := _raycasts[relative_dir]
    ray.force_raycast_update()
    return ray.get_collider() != null


func _is_tile_passable(move_dir: Vector3) -> bool:
    var target_pos = global_position + move_dir * CELL_SIZE
    var grid_pos = Game.world_to_grid(target_pos)
    var tile = Game.tile_registry.get(grid_pos)
    if tile and tile is Interactable:
        return tile.is_passable
    return true # no tile = passable


func _animate_rotation() -> void:
    is_moving = true
    var t := create_tween()
    t.tween_property(self, "rotation:y", target_rot, ANIM_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
    t.tween_callback(
        func():
            is_moving = false
            _update_interaction_tile()
    )
    Events.PlayerLocation.emit(Game.world_to_grid(global_position), target_rot)


func _animate_movement() -> void:
    is_moving = true
    var t := create_tween()
    t.tween_property(self, "position", grid_position, ANIM_DURATION).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
    t.tween_callback(
        func():
            position = grid_position
            is_moving = false
            var stepped_tile = Game.tile_registry.get(Game.world_to_grid(global_position))
            if stepped_tile:
                stepped_tile.on_stepped_on()
            _update_interaction_tile()
    )
    Events.PlayerLocation.emit(Game.world_to_grid(global_position), target_rot)


func _update_interaction_tile() -> void:
    var facing_pos = global_position + CARDINAL_DIRS[facing] * CELL_SIZE
    var grid_pos = Game.world_to_grid(facing_pos)
    var new_tile = Game.tile_registry.get(grid_pos) as Interactable
    if new_tile == is_interacting_with:
        return

    if is_interacting_with:
        is_interacting_with.on_unfocused()
        if is_interacting_with.is_enemy:
            Events.EndCombat.emit()

    is_interacting_with = new_tile

    if is_interacting_with:
        is_interacting_with.on_focused()
        is_interacting_with.get_options()
        if is_interacting_with.is_enemy:
            Events.StartCombat.emit()
        #start combat?


func _on_player_attacked() -> void:
    if is_interacting_with and is_interacting_with.in_combat:
        print("Player attacked")
        is_interacting_with.take_damage(damage)
        is_interacting_with.interact("attack")


func _on_player_defended() -> void:
    if is_interacting_with and is_interacting_with.in_combat:
        print("Player blocked")
        is_interacting_with.interact("block")


func _on_player_takes_damage(amount: int, source: Interactable) -> void:
    print("Player takes (" + str(amount) + " damage from ", source)
    hp -= amount


func _process(_delta: float) -> void:
    _update_debug_highlight()


func _create_debug_highlight() -> void:
    _debug_highlight = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(CELL_SIZE, CELL_SIZE, CELL_SIZE)
    _debug_highlight.mesh = box

    var mat := StandardMaterial3D.new()
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.0, 0.8, 0.7, 0.3)
    mat.no_depth_test = true
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _debug_highlight.material_override = mat

    _debug_highlight.top_level = true
    get_parent().add_child.call_deferred(_debug_highlight)


func _update_debug_highlight() -> void:
    if not is_instance_valid(_debug_highlight) or not _debug_highlight.is_inside_tree():
        return
    var facing_offset: Vector3 = CARDINAL_DIRS[facing] * CELL_SIZE
    var active_grid: Vector2i = Game.world_to_grid(global_position + facing_offset)
    var active_world: Vector3 = Game.grid_to_world(active_grid)
    _debug_highlight.global_position = Vector3(active_world.x, 2.0, active_world.z)


func _snap_to_grid(pos: Vector3) -> Vector3:
    return Vector3(
        roundf(pos.x / CELL_SIZE) * CELL_SIZE,
        pos.y,
        roundf(pos.z / CELL_SIZE) * CELL_SIZE,
    )
