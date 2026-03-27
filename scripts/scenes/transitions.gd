extends CanvasLayer

## Screen transition effects library.
##
## A flexible transition system that uses shader-based effects to cover and
## reveal the screen during scene changes. Each effect is driven by a single
## [code]progress[/code] uniform (0.0 = scene visible, 1.0 = scene covered).
##
## [b]Available effects:[/b]
## [br]- [code]"fade"[/code] — Simple alpha fade to a solid color.
## [br]- [code]"circle"[/code] — Circle wipe from center (Celeste-style iris).
## [br]- [code]"diamond"[/code] — Diamond grid dissolve (Undertale / retro RPG style).
## [br]- [code]"pixelate"[/code] — Scene pixelates into larger blocks then fades to solid.
## [br]- [code]"horizontal_wipe"[/code] — Clean horizontal wipe from left to right.
## [br]- [code]"vertical_wipe"[/code] — Clean vertical wipe from top to bottom.
##
## [b]Usage with SceneManager:[/b]
## [codeblock]
## # Default fade transition:
## await _transitions.transition_in(0.5)
## # ... swap scene ...
## await _transitions.transition_out(0.5)
##
## # Circle wipe transition:
## await _transitions.transition_in(0.5, "circle")
## # ... swap scene ...
## await _transitions.transition_out(0.5, "circle")
##
## # Change color, then diamond dissolve:
## _transitions.set_color(Color.WHITE)
## await _transitions.transition_in(0.4, "diamond")
## # ... swap scene ...
## await _transitions.transition_out(0.4, "diamond")
## [/codeblock]
##
## [b]Standalone usage:[/b]
## [codeblock]
## var transitions: Transitions = preload("res://scenes/transitions.tscn").instantiate()
## add_child(transitions)
## await transitions.transition_in(0.3, "pixelate")
## # Screen is now covered — do your work.
## await transitions.transition_out(0.3, "pixelate")
## [/codeblock]

## The overlay ColorRect that covers the screen.
@onready var _overlay: ColorRect = $Overlay

## Preloaded shader resources, keyed by effect name.
var _shaders: Dictionary = {}

## The currently active tween, if any.
var _tween: Tween = null

## The current effect name, tracked so we can avoid redundant shader swaps.
var _current_effect: String = ""


func _ready() -> void:
	_load_shaders()
	_apply_shader("fade")
	_set_progress(0.0)


## Transition in (cover the screen with the effect). Awaitable.
## [br][br][param duration]: How long the transition takes in seconds.
## [br][param effect]: Which effect to use. One of:
## [code]"fade"[/code], [code]"circle"[/code], [code]"diamond"[/code],
## [code]"pixelate"[/code], [code]"horizontal_wipe"[/code], [code]"vertical_wipe"[/code].
func transition_in(duration: float = 0.5, effect: String = "fade") -> void:
	_apply_shader(effect)
	await _animate_progress(0.0, 1.0, duration)


## Transition out (reveal the screen by reversing the effect). Awaitable.
## [br][br][param duration]: How long the transition takes in seconds.
## [br][param effect]: Which effect to use. Should match the effect used in [method transition_in].
func transition_out(duration: float = 0.5, effect: String = "fade") -> void:
	_apply_shader(effect)
	await _animate_progress(1.0, 0.0, duration)


## Set the color used by transition shaders.
## [br][br]This updates the [code]color[/code] uniform on the current shader material.
## Call this before [method transition_in] to change the transition color.
func set_color(new_color: Color) -> void:
	var mat: ShaderMaterial = _overlay.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("color", new_color)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Load all shader files into the _shaders dictionary.
func _load_shaders() -> void:
	_shaders["fade"] = preload("res://scripts/scenes/shaders/fade.gdshader")
	_shaders["circle"] = preload("res://scripts/scenes/shaders/circle.gdshader")
	_shaders["diamond"] = preload("res://scripts/scenes/shaders/diamond.gdshader")
	_shaders["pixelate"] = preload("res://scripts/scenes/shaders/pixelate.gdshader")
	_shaders["horizontal_wipe"] = preload("res://scripts/scenes/shaders/horizontal_wipe.gdshader")
	_shaders["vertical_wipe"] = preload("res://scripts/scenes/shaders/vertical_wipe.gdshader")


## Apply a shader by name to the overlay ColorRect.
func _apply_shader(effect: String) -> void:
	if effect == _current_effect:
		return

	if not _shaders.has(effect):
		push_warning("Transitions: Unknown effect '%s', falling back to 'fade'." % effect)
		effect = "fade"

	var shader: Shader = _shaders[effect] as Shader
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	_overlay.material = mat
	_current_effect = effect


## Set the progress uniform directly (no animation).
func _set_progress(value: float) -> void:
	var mat: ShaderMaterial = _overlay.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("progress", value)


## Animate the progress uniform from [param from] to [param to] over [param duration] seconds.
func _animate_progress(from: float, to: float, duration: float) -> void:
	# Kill any in-flight tween to prevent conflicts.
	if _tween and _tween.is_valid():
		_tween.kill()

	_set_progress(from)

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_method(_set_progress, from, to, duration)
	await _tween.finished
