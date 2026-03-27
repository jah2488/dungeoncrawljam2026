extends Control

## System Test Gym — one scene to test every generator feature.
## Buttons are created programmatically based on which autoloads are available.

@onready var _content: VBoxContainer = %Content
@onready var _scroll: ScrollContainer = %ScrollContainer

var _demo_sprite: Sprite2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_add_header("System Test Gym", "Press buttons to test each system. Check the console for output.")

	if has_node("/root/Toast"):
		_build_toast_section()
	if has_node("/root/SceneManager"):
		_build_transitions_section()
	if has_node("/root/Particles"):
		_build_particles_section()
	if has_node("/root/DamageNumbers"):
		_build_damage_numbers_section()
	if has_node("/root/Juice"):
		_build_juice_section()
	if has_node("/root/Dialog"):
		_build_dialog_section()
	if has_node("/root/DebugDraw"):
		_build_debug_draw_section()
	if has_node("/root/Audio"):
		_build_audio_section()
	if has_node("/root/SceneManager"):
		_build_scene_manager_section()

	_add_separator()
	_add_back_button()


# ── Toast ────────────────────────────────────────────────────────────────────

func _build_toast_section() -> void:
	_add_section("Toast Notifications")
	_add_desc("Non-blocking messages in the bottom-right corner. Stack up to 5.")
	var grid: GridContainer = _add_grid(3)
	_add_btn(grid, "Success", func() -> void: Toast.success("Operation completed!"))
	_add_btn(grid, "Warning", func() -> void: Toast.warning("Low disk space"))
	_add_btn(grid, "Error", func() -> void: Toast.error("Connection lost"))
	_add_btn(grid, "Custom (Cyan)", func() -> void: Toast.show_toast("Custom color toast", 3.0, Color.CYAN))
	_add_btn(grid, "Long (8s)", func() -> void: Toast.show_toast("This toast lasts 8 seconds", 8.0, Color.MAGENTA))
	_add_btn(grid, "Spam (test limit)", func() -> void:
		for i: int in 7:
			Toast.show_toast("Toast #%d" % (i + 1), 4.0, Color(randf(), randf(), randf()))
	)


# ── Transitions ──────────────────────────────────────────────────────────────

func _build_transitions_section() -> void:
	_add_section("Screen Transitions")
	_add_desc("Each button plays the transition in, holds 0.8s, then reverses out.")
	var grid: GridContainer = _add_grid(3)
	for effect: String in ["fade", "circle", "diamond", "pixelate", "horizontal_wipe", "vertical_wipe"]:
		var eff: String = effect
		_add_btn(grid, eff.capitalize(), func() -> void: _play_transition(eff))
	_add_btn(grid, "White Diamond", func() -> void: _play_transition("diamond", Color.WHITE))
	_add_btn(grid, "Red Fade", func() -> void: _play_transition("fade", Color.RED))


func _play_transition(effect: String, color: Color = Color(0.1, 0.1, 0.1, 1.0)) -> void:
	var transitions: Node = SceneManager._transitions
	if transitions == null:
		Toast.warning("No transitions node loaded") if has_node("/root/Toast") else push_warning("No transitions")
		return
	transitions.set_color(color)
	await transitions.transition_in(0.5, effect)
	await get_tree().create_timer(0.8).timeout
	await transitions.transition_out(0.5, effect)
	transitions.set_color(Color(0.1, 0.1, 0.1, 1.0))


# ── Particles ────────────────────────────────────────────────────────────────

func _build_particles_section() -> void:
	_add_section("Particle Effects")
	_add_desc("One-shot particle effects spawned at button position. Auto-cleanup.")
	var grid: GridContainer = _add_grid(3)
	_add_btn(grid, "Hit Sparks", func() -> void: _spawn_particle_at_btn(grid, Particles.HIT_SPARKS))
	_add_btn(grid, "Dust Puff", func() -> void: _spawn_particle_at_btn(grid, Particles.DUST_PUFF))
	_add_btn(grid, "Explosion", func() -> void: _spawn_particle_at_btn(grid, Particles.EXPLOSION))
	_add_btn(grid, "Collect Sparkle", func() -> void: _spawn_particle_at_btn(grid, Particles.COLLECT_SPARKLE))
	_add_btn(grid, "Burst (all)", func() -> void:
		var pos: Vector2 = grid.global_position + grid.size * 0.5
		Particles.spawn_at(pos, Particles.HIT_SPARKS)
		Particles.spawn_at(pos + Vector2(40, 0), Particles.EXPLOSION)
		Particles.spawn_at(pos + Vector2(-40, 0), Particles.COLLECT_SPARKLE)
	)


func _spawn_particle_at_btn(container: Control, path: String) -> void:
	var pos: Vector2 = container.global_position + container.size * 0.5
	Particles.spawn_at(pos, path)


# ── Damage Numbers ───────────────────────────────────────────────────────────

func _build_damage_numbers_section() -> void:
	_add_section("Damage Numbers")
	_add_desc("Floating numbers that pop up and fade. World-to-screen conversion built in.")
	var grid: GridContainer = _add_grid(4)
	_add_btn(grid, "Damage 42", func() -> void: _spawn_dmg_at_grid(grid, "damage", 42))
	_add_btn(grid, "Damage 999", func() -> void: _spawn_dmg_at_grid(grid, "damage", 999))
	_add_btn(grid, "Heal +25", func() -> void: _spawn_dmg_at_grid(grid, "heal", 25))
	_add_btn(grid, "XP +100", func() -> void: _spawn_dmg_at_grid(grid, "xp", 100))
	_add_btn(grid, "Custom (Cyan)", func() -> void:
		var pos: Vector2 = grid.global_position + Vector2(randf_range(0, grid.size.x), 0)
		DamageNumbers.spawn(pos, "CRIT!", Color.CYAN)
	)
	_add_btn(grid, "Random Burst", func() -> void:
		for i: int in 8:
			var pos: Vector2 = grid.global_position + Vector2(randf_range(0, grid.size.x), randf_range(-20, 20))
			var amount: int = randi_range(1, 500)
			DamageNumbers.spawn_damage(pos, amount)
	)


func _spawn_dmg_at_grid(grid: Control, type: String, amount: int) -> void:
	var pos: Vector2 = grid.global_position + Vector2(randf_range(20, grid.size.x - 20), 0)
	match type:
		"damage": DamageNumbers.spawn_damage(pos, amount)
		"heal": DamageNumbers.spawn_heal(pos, amount)
		"xp": DamageNumbers.spawn_xp(pos, amount)


# ── Juice ────────────────────────────────────────────────────────────────────

func _build_juice_section() -> void:
	_add_section("Juice / Screen Shake")
	_add_desc("Tweened effects for game feel. Shake requires a camera in the scene.")
	var grid: GridContainer = _add_grid(3)

	_add_btn(grid, "Shake (Light)", func() -> void:
		var cam: Node = _get_camera()
		if cam: Juice.shake(cam, 3.0, 0.2)
	)
	_add_btn(grid, "Shake (Heavy)", func() -> void:
		var cam: Node = _get_camera()
		if cam: Juice.shake(cam, 12.0, 0.4)
	)
	_add_btn(grid, "Hitstop (0.1s)", func() -> void: Juice.hitstop(0.1))

	# Create a demo sprite for visual effects
	var demo_container: HBoxContainer = HBoxContainer.new()
	demo_container.add_theme_constant_override("separation", 20)
	demo_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(demo_container)

	var demo_panel: PanelContainer = PanelContainer.new()
	demo_panel.custom_minimum_size = Vector2(80, 80)
	var demo_style: StyleBoxFlat = StyleBoxFlat.new()
	demo_style.bg_color = Color(0.3, 0.5, 0.8, 1.0)
	demo_style.corner_radius_top_left = 8
	demo_style.corner_radius_top_right = 8
	demo_style.corner_radius_bottom_left = 8
	demo_style.corner_radius_bottom_right = 8
	demo_panel.add_theme_stylebox_override("panel", demo_style)
	demo_container.add_child(demo_panel)

	var demo_label: Label = Label.new()
	demo_label.text = "Target"
	demo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	demo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	demo_panel.add_child(demo_label)

	var effects_grid: GridContainer = _make_grid(3)
	demo_container.add_child(effects_grid)

	_add_btn(effects_grid, "Flash White", func() -> void: Juice.flash(demo_panel, Color.WHITE, 0.15))
	_add_btn(effects_grid, "Flash Red", func() -> void: Juice.flash(demo_panel, Color.RED, 0.2))
	_add_btn(effects_grid, "Float Text", func() -> void:
		Juice.float_text("COMBO!", demo_panel.global_position + Vector2(40, -10), get_tree().root, Color.YELLOW)
	)
	_add_btn(effects_grid, "Combo!", func() -> void:
		var cam: Node = _get_camera()
		if cam: Juice.shake(cam, 8.0, 0.3)
		Juice.flash(demo_panel, Color.RED, 0.1)
		Juice.float_text("CRITICAL!", demo_panel.global_position + Vector2(20, -10), get_tree().root, Color.ORANGE_RED)
		if has_node("/root/DamageNumbers"):
			DamageNumbers.spawn_damage(demo_panel.global_position, 9999)
		if has_node("/root/Particles"):
			Particles.spawn_at(demo_panel.global_position + demo_panel.size * 0.5, Particles.HIT_SPARKS)
	)


func _get_camera() -> Node:
	var cam_2d: Camera2D = get_viewport().get_camera_2d()
	if cam_2d: return cam_2d
	var cam_3d: Camera3D = get_viewport().get_camera_3d()
	if cam_3d: return cam_3d
	return null


# ── Dialog ───────────────────────────────────────────────────────────────────

func _build_dialog_section() -> void:
	_add_section("Dialog System")
	_add_desc("Bottom-of-screen text box with typewriter effect. Press Space/Enter to advance.")
	var grid: GridContainer = _add_grid(3)
	_add_btn(grid, "Simple Message", func() -> void:
		await Dialog.show_text("Hello! This is a typewriter dialog. Press Space to dismiss.")
	)
	_add_btn(grid, "Long Text", func() -> void:
		await Dialog.show_text("This is a longer message that tests how the dialog box handles wrapping text across multiple lines. The panel should contain everything neatly within the box at the bottom of the screen.")
	)
	_add_btn(grid, "BBCode", func() -> void:
		await Dialog.show_text("[color=ff4444]Red text[/color], [b]bold[/b], [i]italic[/i], and [color=44ff44]green[/color]!")
	)
	_add_btn(grid, "3-Message Sequence", func() -> void:
		var msgs: Array[String] = [
			"This is message 1 of 3. Press Space to continue...",
			"Message 2! The dialog system queues these up automatically.",
			"Final message. After dismissing this, dialog_finished fires."
		]
		await Dialog.show_sequence(msgs)
		if has_node("/root/Toast"):
			Toast.success("Dialog sequence completed!")
	)


# ── Debug Draw ───────────────────────────────────────────────────────────────

func _build_debug_draw_section() -> void:
	_add_section("Debug Draw")
	_add_desc("Dev-only vector drawing in world space. Shapes clear each frame — hold the button or it flashes briefly.")
	var grid: GridContainer = _add_grid(3)
	_add_btn(grid, "Arrow", func() -> void:
		DebugDraw.arrow(Vector2(100, 500), Vector2(300, 450), Color.GREEN, 2.0)
	)
	_add_btn(grid, "Circle", func() -> void:
		DebugDraw.circle(Vector2(400, 500), 40.0, Color.CYAN)
	)
	_add_btn(grid, "Rectangle", func() -> void:
		DebugDraw.rect_outline(Rect2(500, 470, 120, 60), Color.YELLOW, 2.0)
	)
	_add_btn(grid, "Point", func() -> void:
		DebugDraw.point(Vector2(250, 500), Color.RED, 6.0)
	)
	_add_btn(grid, "Text", func() -> void:
		DebugDraw.text(Vector2(100, 530), "DEBUG TEXT HERE", Color.WHITE)
	)
	_add_btn(grid, "All at once", func() -> void:
		DebugDraw.arrow(Vector2(100, 500), Vector2(250, 450), Color.GREEN, 2.0)
		DebugDraw.circle(Vector2(350, 480), 35.0, Color.CYAN)
		DebugDraw.rect_outline(Rect2(430, 460, 100, 50), Color.YELLOW, 2.0)
		DebugDraw.point(Vector2(300, 500), Color.RED, 6.0)
		DebugDraw.text(Vector2(100, 540), "ALL SHAPES", Color.MAGENTA)
		DebugDraw.line(Vector2(550, 450), Vector2(700, 520), Color.ORANGE, 2.0)
	)
	_add_desc("Note: Debug Draw is disabled in production builds (Game.build_type != 'dev').")


# ── Audio ────────────────────────────────────────────────────────────────────

func _build_audio_section() -> void:
	_add_section("Audio System")
	_add_desc("Pooled audio with 12 players. No sound files included by default — add .ogg/.wav to audio/fx/.")
	var grid: GridContainer = _add_grid(3)
	_add_btn(grid, "Stop All", func() -> void: Audio.stop_all())
	_add_btn(grid, "Clear Queue", func() -> void: Audio.clear_queue())
	_add_btn(grid, "Bus Info", func() -> void:
		var info: String = "Master: %.0f%%  FX: %.0f%%  Music: %.0f%%" % [
			Audio.get_bus_volume("Master") * 100,
			Audio.get_bus_volume("FX") * 100,
			Audio.get_bus_volume("Music") * 100
		]
		if has_node("/root/Toast"):
			Toast.show_toast(info, 3.0, Color.CYAN)
		print(info)
	)


# ── Scene Manager ────────────────────────────────────────────────────────────

func _build_scene_manager_section() -> void:
	_add_section("Scene Manager")
	_add_desc("Manages scene changes with transitions, and an overlay stack (pause menu, settings).")
	var grid: GridContainer = _add_grid(3)
	_add_btn(grid, "Push Settings", func() -> void:
		SceneManager.push_overlay(SceneManager.SETTINGS)
	)
	_add_btn(grid, "Has Overlay?", func() -> void:
		var result: String = "Yes" if SceneManager.has_overlay() else "No"
		if has_node("/root/Toast"):
			Toast.show_toast("Has overlay: " + result)
		print("Has overlay: ", result)
	)
	_add_btn(grid, "Go to Title", func() -> void:
		SceneManager.change_scene(SceneManager.MAIN_MENU)
	)


# ── UI Helpers ───────────────────────────────────────────────────────────────

func _add_header(title: String, subtitle: String) -> void:
	var header: Label = Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 28)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(header)

	var sub: Label = Label.new()
	sub.text = subtitle
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(sub)
	_add_separator()


func _add_section(title: String) -> void:
	_add_separator()
	var label: Label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_content.add_child(label)


func _add_desc(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(label)


func _add_separator() -> void:
	var sep: HSeparator = HSeparator.new()
	_content.add_child(sep)


func _make_grid(columns: int) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	return grid


func _add_grid(columns: int) -> GridContainer:
	var grid: GridContainer = _make_grid(columns)
	_content.add_child(grid)
	return grid


func _add_btn(parent: Node, label: String, callback: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = label
	btn.custom_minimum_size.x = 140
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _add_back_button() -> void:
	var btn: Button = Button.new()
	btn.text = "Back to Title"
	btn.custom_minimum_size = Vector2(200, 40)
	btn.pressed.connect(func() -> void:
		if has_node("/root/SceneManager"):
			SceneManager.change_scene(SceneManager.MAIN_MENU)
		else:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	var center: CenterContainer = CenterContainer.new()
	center.add_child(btn)
	_content.add_child(center)
