@tool
class_name LevelGenerator
extends Node3D

@export_file("*.csv") var csv_file: String = ""
@export var cell_size: float = 4.0
@export var wall_height: float = 4.0
@export var wall_thickness: float = 0.1
@export var wall_character: String = "0"
@export var ground_character: String = "1"

@export_group("Wall Material")
@export var wall_texture: Texture2D
@export var wall_normal_texture: Texture2D
@export var wall_uv_scale: Vector3 = Vector3(1, 1, 1)

@export_group("Floor Material")
@export var floor_color: Color = Color(0.389, 0.196, 0.020)
@export var floor_texture: Texture2D
@export var floor_normal_texture: Texture2D
@export var floor_uv_scale: Vector3 = Vector3(10, 10, 10)

@export_group("Tile Scenes")
@export var tile_scenes: Dictionary[String, PackedScene] = { }
@export var unknown_tile_scene: PackedScene

@export_tool_button("Regenerate Level", "Reload") var _regenerate_btn: Callable = regenerate

var _grid: Array = []
var _rows: int = 0
var _cols: int = 0


func _ready() -> void:
    regenerate()


func regenerate() -> void:
    _clear_generated()
    if csv_file.is_empty():
        push_warning("LevelGenerator: No CSV file assigned")
        return
    _parse_csv()
    _generate_floor()
    _generate_walls()
    _place_tiles()


func _clear_generated() -> void:
    _grid = []
    _rows = 0
    _cols = 0
    for child in get_children():
        child.queue_free()


func _parse_csv() -> void:
    var file := FileAccess.open(csv_file, FileAccess.READ)
    if not file:
        push_error("LevelGenerator: Could not open %s" % csv_file)
        return
    while not file.eof_reached():
        var line := file.get_line().strip_edges()
        if line.is_empty():
            continue
        var row: Array[String] = []
        for cell in line.split(","):
            row.append(cell.strip_edges())
        _grid.append(row)
    _rows = _grid.size()
    if _rows > 0:
        _cols = _grid[0].size()


func _get_cell(row: int, col: int) -> String:
    if row < 0 or row >= _rows or col < 0 or col >= _cols:
        return ""
    return _grid[row][col]


func _is_wall(row: int, col: int) -> bool:
    return _get_cell(row, col) == wall_character


func _cell_position(row: int, col: int) -> Vector3:
    return Vector3(col * cell_size, 0.0, row * cell_size)


func _generate_floor() -> void:
    var floor_body := StaticBody3D.new()
    floor_body.name = "GeneratedFloor"

    var width := _cols * cell_size
    var depth := _rows * cell_size

    var mesh := BoxMesh.new()
    mesh.size = Vector3(width, 0.2, depth)

    var mat := StandardMaterial3D.new()
    mat.albedo_color = floor_color
    if floor_texture:
        mat.albedo_texture = floor_texture
    if floor_normal_texture:
        mat.normal_enabled = true
        mat.normal_texture = floor_normal_texture
    mat.uv1_scale = floor_uv_scale
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

    var mesh_inst := MeshInstance3D.new()
    mesh_inst.mesh = mesh
    mesh_inst.material_override = mat

    var shape := BoxShape3D.new()
    shape.size = Vector3(width, 0.2, depth)
    var collision := CollisionShape3D.new()
    collision.shape = shape

    floor_body.add_child(mesh_inst)
    floor_body.add_child(collision)
    floor_body.position = Vector3(
        (_cols - 1) * cell_size / 2.0,
        -0.1,
        (_rows - 1) * cell_size / 2.0,
    )

    add_child(floor_body)


func _generate_walls() -> void:
    var wall_mat := StandardMaterial3D.new()
    if wall_texture:
        wall_mat.albedo_texture = wall_texture
    if wall_normal_texture:
        wall_mat.normal_enabled = true
        wall_mat.normal_texture = wall_normal_texture
    wall_mat.uv1_scale = wall_uv_scale
    wall_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

    for row in range(_rows):
        for col in range(_cols):
            if _is_wall(row, col):
                continue

            var center := _cell_position(row, col)
            var half := cell_size / 2.0

            if _is_wall(row - 1, col):
                _create_wall(center + Vector3(0, 0, -half), 0.0, wall_mat)
            if _is_wall(row + 1, col):
                _create_wall(center + Vector3(0, 0, half), 0.0, wall_mat)
            if _is_wall(row, col - 1):
                _create_wall(center + Vector3(-half, 0, 0), PI / 2.0, wall_mat)
            if _is_wall(row, col + 1):
                _create_wall(center + Vector3(half, 0, 0), PI / 2.0, wall_mat)


func _create_wall(pos: Vector3, y_rot: float, material: StandardMaterial3D) -> void:
    var wall := StaticBody3D.new()
    wall.name = "Wall"

    var mesh := BoxMesh.new()
    mesh.size = Vector3(cell_size, wall_height, wall_thickness)

    var mesh_inst := MeshInstance3D.new()
    mesh_inst.mesh = mesh
    mesh_inst.material_override = material

    var shape := BoxShape3D.new()
    shape.size = Vector3(cell_size, wall_height, wall_thickness)
    var collision := CollisionShape3D.new()
    collision.shape = shape

    wall.add_child(mesh_inst)
    wall.add_child(collision)
    wall.position = Vector3(pos.x, wall_height / 2.0, pos.z)
    wall.rotation.y = y_rot

    add_child(wall)


func _place_tiles() -> void:
    for row in range(_rows):
        for col in range(_cols):
            var val := _get_cell(row, col)
            if val.is_empty() or val == ground_character or val == wall_character:
                continue
            var scene: PackedScene
            if tile_scenes.has(val):
                scene = tile_scenes[val]
            else:
                push_warning("LevelGenerator: No scene mapped for '%s' at (%d, %d)" % [val, row, col])
                scene = unknown_tile_scene
            if not scene:
                continue
            var instance := scene.instantiate()
            var pos := _cell_position(row, col)
            instance.position = Vector3(pos.x, 0.0, pos.z)
            add_child(instance)
