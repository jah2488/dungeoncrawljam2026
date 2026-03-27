extends Node

## Pooled audio player system.
## All sounds play on the "FX" bus by default.
## Usage:
##   Audio.play(sound_stream)
##   Audio.play(sound_stream, 0.8, 1.0)  # volume in linear 0-1

var num_players: int = 12
var bus: String = "FX"
var available: Array[AudioStreamPlayer] = []
var queue: Array[Dictionary] = []
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for i: int in num_players:
		var p := AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.volume_db = -18.0
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus = bus
	_restore_volume()


func _process(_delta: float) -> void:
	if not queue.is_empty() and not available.is_empty():
		var queued: Dictionary = queue.pop_front() as Dictionary
		var player: AudioStreamPlayer = available.pop_front() as AudioStreamPlayer
		player.stream = queued.stream
		player.volume_db = queued.volume
		player.pitch_scale = queued.pitch_scale + randf_range(-0.15, 0.15)
		player.bus = bus
		player.play()


func _on_stream_finished(stream: AudioStreamPlayer) -> void:
	available.append(stream)


## Ensure the required audio buses exist (Master is always bus 0).
func _ensure_buses() -> void:
	for bus_name: String in ["FX", "Music"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx: int = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


## Queue a sound for playback. Volume is in dB.
func play(sound: AudioStream, volume_db: float = -18.0, pitch_scale: float = 1.0) -> void:
	if sound == null:
		return
	queue.append({
		"stream": sound,
		"volume": volume_db,
		"pitch_scale": pitch_scale,
	})


## Play a sound from a file path (with caching).
func play_path(sound_path: String, volume_db: float = -18.0, pitch_scale: float = 1.0) -> void:
	var paths := sound_path.split(",")
	var chosen := paths[randi() % paths.size()].strip_edges()
	if not chosen.begins_with("res://"):
		chosen = "res://" + chosen
	if not _cache.has(chosen):
		_cache[chosen] = load(chosen)
	play(_cache[chosen], volume_db, pitch_scale)


## Play immediately (bypasses queue).
func play_now(sound: AudioStream, volume_db: float = -18.0) -> void:
	if sound == null or available.is_empty():
		return
	var player: AudioStreamPlayer = available.pop_front() as AudioStreamPlayer
	player.stream = sound
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.85, 1.15)
	player.bus = bus
	player.play()


func stop_all() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()


func clear_queue() -> void:
	queue.clear()


## Volume management — sliders pass linear 0.0–1.0, stored as dB internally.
func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	var clamped: float = clampf(linear_volume, 0.0, 1.0)
	if clamped < 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamped))
	_save_volume()


func get_bus_volume(bus_name: String) -> float:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return 1.0
	if AudioServer.is_bus_mute(bus_idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))


func _save_volume() -> void:
	if not has_node("/root/SaveManager"):
		return
	var volumes: Dictionary = {}
	for bus_name: String in ["Master", "FX", "Music"]:
		volumes[bus_name] = get_bus_volume(bus_name)
	SaveManager.set_data("audio_settings", volumes)


func _restore_volume() -> void:
	if not has_node("/root/SaveManager"):
		return
	var volumes: Dictionary = SaveManager.get_data("audio_settings", {})
	for bus_name: String in volumes:
		set_bus_volume(bus_name, volumes[bus_name])
