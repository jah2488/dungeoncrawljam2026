extends Node

## Runtime input remapping with save/restore.

var _default_actions: Dictionary = {}


func _ready() -> void:
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		_default_actions[action] = InputMap.action_get_events(action).duplicate()
	_restore_mappings()


func remap_action(action: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
	_save_mappings()


func reset_action(action: String) -> void:
	if not _default_actions.has(action):
		return
	InputMap.action_erase_events(action)
	for event in _default_actions[action]:
		InputMap.action_add_event(action, event)
	_save_mappings()


func reset_all() -> void:
	for action in _default_actions:
		reset_action(action)


func get_action_display(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "[unbound]"
	return events[0].as_text()


func get_remappable_actions() -> Array[String]:
	var actions: Array[String] = []
	for action in _default_actions.keys():
		actions.append(action)
	return actions


func _save_mappings() -> void:
	if not has_node("/root/SaveManager"):
		return
	var mappings: Dictionary = {}
	for action in _default_actions:
		var events := InputMap.action_get_events(action)
		var serialized: Array[Dictionary] = []
		for event in events:
			if event is InputEventKey:
				serialized.append({"type": "key", "physical_keycode": event.physical_keycode, "key_label": event.key_label})
			elif event is InputEventJoypadButton:
				serialized.append({"type": "joypad_button", "button_index": event.button_index})
			elif event is InputEventJoypadMotion:
				serialized.append({"type": "joypad_motion", "axis": event.axis, "axis_value": event.axis_value})
			elif event is InputEventMouseButton:
				serialized.append({"type": "mouse_button", "button_index": event.button_index})
		mappings[action] = serialized
	SaveManager.set_data("input_mappings", mappings)


func _restore_mappings() -> void:
	if not has_node("/root/SaveManager"):
		return
	var mappings: Dictionary = SaveManager.get_data("input_mappings", {})
	for action in mappings:
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for entry in mappings[action]:
			var event: InputEvent
			match entry.get("type", ""):
				"key":
					event = InputEventKey.new()
					event.physical_keycode = entry.get("physical_keycode", entry.get("keycode", 0))
					event.key_label = entry.get("key_label", 0)
				"joypad_button":
					event = InputEventJoypadButton.new()
					event.button_index = entry.button_index
				"joypad_motion":
					event = InputEventJoypadMotion.new()
					event.axis = entry.axis
					event.axis_value = entry.axis_value
				"mouse_button":
					event = InputEventMouseButton.new()
					event.button_index = entry.button_index
			if event:
				InputMap.action_add_event(action, event)
