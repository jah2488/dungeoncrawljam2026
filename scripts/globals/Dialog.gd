extends CanvasLayer

## Bottom-of-screen dialog box system with typewriter effect.
## Autoload — shows dialog messages one at a time with character-by-character reveal.
## Supports optional portrait, BBCode text, and sequential message chains.

signal dialog_finished

const CHARS_PER_SECOND: float = 30.0
const BOX_MARGIN: int = 20
const BOX_MAX_HEIGHT: int = 120
const CORNER_RADIUS: int = 8
const PANEL_PADDING: int = 16
const BG_COLOR: Color = Color(0.08, 0.08, 0.1, 0.92)
const PORTRAIT_SIZE: int = 64
const PORTRAIT_BORDER_COLOR: Color = Color(0.3, 0.3, 0.35, 1.0)
const FONT_SIZE: int = 16
const INDICATOR_BOB_DISTANCE: float = 4.0
const INDICATOR_BOB_DURATION: float = 0.6

var _root_control: Control
var _panel: PanelContainer
var _hbox: HBoxContainer
var _portrait_panel: PanelContainer
var _portrait_rect: TextureRect
var _text_label: RichTextLabel
var _indicator: Label

var _active: bool = false
var _typing: bool = false
var _type_tween: Tween
var _bob_tween: Tween
var _indicator_base_y: float = 0.0

var _sequence_queue: Array[String] = []
var _sequence_portrait: Texture2D = null


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_ui()
	_hide_dialog()


func show_text(message: String, portrait: Texture2D = null) -> void:
	_show_portrait(portrait)
	_text_label.text = message
	_text_label.visible_characters = 0
	_indicator.visible = false
	_show_dialog()

	var total_length: int = _text_label.get_total_character_count()
	if total_length == 0:
		_finish_typing()
		await _wait_for_dismiss()
		return

	var duration: float = float(total_length) / CHARS_PER_SECOND
	_typing = true

	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()
	_type_tween = create_tween()
	_type_tween.tween_property(_text_label, "visible_characters", total_length, duration)
	_type_tween.tween_callback(_finish_typing)

	await _wait_for_dismiss()


func show_sequence(messages: Array[String], portrait: Texture2D = null) -> void:
	_sequence_portrait = portrait
	_sequence_queue = messages.duplicate()

	while _sequence_queue.size() > 0:
		var msg: String = _sequence_queue[0]
		_sequence_queue.remove_at(0)
		await show_text(msg, _sequence_portrait)

	dialog_finished.emit()


func is_active() -> bool:
	return _active


func _input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()

		if _typing:
			_complete_text_instantly()
		else:
			_dismiss()


func _complete_text_instantly() -> void:
	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()
	_finish_typing()


func _finish_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	_show_indicator()


func _wait_for_dismiss() -> void:
	await _dismissed


signal _dismissed


func _dismiss() -> void:
	_hide_dialog()
	_dismissed.emit()


func _show_dialog() -> void:
	_active = true
	_root_control.visible = true


func _hide_dialog() -> void:
	_active = false
	_root_control.visible = false
	_stop_indicator_bob()


func _show_portrait(portrait: Texture2D) -> void:
	if portrait != null:
		_portrait_rect.texture = portrait
		_portrait_panel.visible = true
	else:
		_portrait_panel.visible = false


func _show_indicator() -> void:
	_indicator.visible = true
	_start_indicator_bob()


func _start_indicator_bob() -> void:
	_stop_indicator_bob()
	_bob_tween = create_tween()
	_bob_tween.set_loops()
	_bob_tween.tween_property(
		_indicator, "position:y",
		_indicator_base_y - INDICATOR_BOB_DISTANCE,
		INDICATOR_BOB_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(
		_indicator, "position:y",
		_indicator_base_y,
		INDICATOR_BOB_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_indicator_bob() -> void:
	if _bob_tween != null and _bob_tween.is_valid():
		_bob_tween.kill()


func _build_ui() -> void:
	# Root control — full-screen, ignores mouse.
	_root_control = Control.new()
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root_control)

	# Panel anchored to bottom of screen.
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = BOX_MARGIN
	_panel.offset_right = -BOX_MARGIN
	_panel.offset_bottom = -BOX_MARGIN
	_panel.offset_top = -(BOX_MARGIN + BOX_MAX_HEIGHT)
	_panel.custom_minimum_size.y = BOX_MAX_HEIGHT

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = BG_COLOR
	panel_style.corner_radius_top_left = CORNER_RADIUS
	panel_style.corner_radius_top_right = CORNER_RADIUS
	panel_style.corner_radius_bottom_left = CORNER_RADIUS
	panel_style.corner_radius_bottom_right = CORNER_RADIUS
	panel_style.content_margin_left = PANEL_PADDING
	panel_style.content_margin_right = PANEL_PADDING
	panel_style.content_margin_top = PANEL_PADDING
	panel_style.content_margin_bottom = PANEL_PADDING
	_panel.add_theme_stylebox_override("panel", panel_style)
	_root_control.add_child(_panel)

	# HBox for portrait + text.
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 12)
	_panel.add_child(_hbox)

	# Portrait container with thin border.
	_portrait_panel = PanelContainer.new()
	_portrait_panel.custom_minimum_size = Vector2(PORTRAIT_SIZE + 4, PORTRAIT_SIZE + 4)
	_portrait_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var portrait_style: StyleBoxFlat = StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	portrait_style.border_color = PORTRAIT_BORDER_COLOR
	portrait_style.border_width_left = 2
	portrait_style.border_width_right = 2
	portrait_style.border_width_top = 2
	portrait_style.border_width_bottom = 2
	portrait_style.corner_radius_top_left = 4
	portrait_style.corner_radius_top_right = 4
	portrait_style.corner_radius_bottom_left = 4
	portrait_style.corner_radius_bottom_right = 4
	portrait_style.content_margin_left = 0
	portrait_style.content_margin_right = 0
	portrait_style.content_margin_top = 0
	portrait_style.content_margin_bottom = 0
	_portrait_panel.add_theme_stylebox_override("panel", portrait_style)
	_hbox.add_child(_portrait_panel)

	_portrait_rect = TextureRect.new()
	_portrait_rect.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_panel.add_child(_portrait_rect)

	# Text area — wraps remaining space.
	var text_container: Control = Control.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hbox.add_child(text_container)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = false
	_text_label.scroll_active = false
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_text_label.add_theme_color_override("default_color", Color.WHITE)
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_container.add_child(_text_label)

	# "Press to continue" indicator.
	_indicator = Label.new()
	_indicator.text = "▼"
	_indicator.add_theme_font_size_override("font_size", 14)
	_indicator.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))
	_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_indicator.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_indicator.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_indicator.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_indicator.offset_left = -20
	_indicator.offset_top = -20
	_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicator.visible = false
	text_container.add_child(_indicator)
	_indicator_base_y = _indicator.offset_top
