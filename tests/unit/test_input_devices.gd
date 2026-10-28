extends GutTest
## As ações precisam responder a qualquer teclado/mouse (device -1), não a um id fixo.


func test_actions_match_any_device():
	for dev in [0, 1, 16, 32]:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_A
		key.device = dev
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.device = dev
		assert_true(InputMap.event_is_action(key, &"move_left"), "teclado no device %d" % dev)
		assert_true(InputMap.event_is_action(click, &"attack_basic"), "mouse no device %d" % dev)
