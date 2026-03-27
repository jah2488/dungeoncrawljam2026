extends Node

## Spawns one-shot particle effects at world positions.
## Usage:
##   Particles.spawn_at(hit_position, Particles.HIT_SPARKS)
##   Particles.spawn_at(land_position, Particles.DUST_PUFF)

const HIT_SPARKS := "res://resources/particles/hit_sparks.tscn"
const DUST_PUFF := "res://resources/particles/dust_puff.tscn"
const EXPLOSION := "res://resources/particles/explosion.tscn"
const COLLECT_SPARKLE := "res://resources/particles/collect_sparkle.tscn"
const TRAIL := "res://resources/particles/trail.tscn"

var _cache: Dictionary = {}


func _load_scene(path: String) -> PackedScene:
	if _cache.has(path):
		return _cache[path] as PackedScene
	var scene: PackedScene = load(path) as PackedScene
	_cache[path] = scene
	return scene


## Spawn a 2D one-shot particle effect at a world position.
## Returns the particle node (useful for attaching trail particles to a moving object).
func spawn_at(world_position: Vector2, particle_scene_path: String) -> GPUParticles2D:
	var scene: PackedScene = _load_scene(particle_scene_path)
	if scene == null:
		push_error("Particles: Failed to load scene: " + particle_scene_path)
		return null
	var particles: GPUParticles2D = scene.instantiate() as GPUParticles2D
	particles.position = world_position
	particles.emitting = true
	_get_parent_node().add_child(particles)
	return particles


## Spawn a 3D one-shot particle effect at a world position.
func spawn_at_3d(world_position: Vector3, particle_scene_path: String) -> GPUParticles3D:
	var scene: PackedScene = _load_scene(particle_scene_path)
	if scene == null:
		push_error("Particles: Failed to load scene: " + particle_scene_path)
		return null
	var particles: GPUParticles3D = scene.instantiate() as GPUParticles3D
	particles.position = world_position
	particles.emitting = true
	_get_parent_node().add_child(particles)
	return particles


func _get_parent_node() -> Node:
	var tree: SceneTree = get_tree()
	if tree.current_scene != null:
		return tree.current_scene
	return tree.root
