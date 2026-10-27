extends GutTest

const KEY_BINDS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"move_up": [KEY_W, KEY_UP],
	&"move_down": [KEY_S, KEY_DOWN],
	&"special": [KEY_Q],
	&"dash": [KEY_SPACE],
	&"interact": [KEY_E],
}
const MOUSE_BINDS := {
	&"attack_basic": MOUSE_BUTTON_LEFT,
	&"attack_heavy": MOUSE_BUTTON_RIGHT,
}


func _physical_keys(action: StringName) -> Array:
	var keys := []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(event.physical_keycode)
	return keys


func test_key_actions_are_bound():
	for action in KEY_BINDS:
		assert_true(InputMap.has_action(action), "falta a ação %s" % action)
		var keys := _physical_keys(action)
		for key in KEY_BINDS[action]:
			assert_has(keys, key, "%s sem a tecla %s" % [action, OS.get_keycode_string(key)])


func test_mouse_actions_are_bound():
	for action in MOUSE_BINDS:
		assert_true(InputMap.has_action(action), "falta a ação %s" % action)
		var buttons := InputMap.action_get_events(action) \
			.filter(func(e): return e is InputEventMouseButton) \
			.map(func(e): return e.button_index)
		assert_has(buttons, MOUSE_BINDS[action])
