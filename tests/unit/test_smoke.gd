extends GutTest


func test_main_scene_is_arena_with_player():
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(main_path, "res://scenes/main.tscn")
	var main := (load(main_path) as PackedScene).instantiate()
	add_child_autofree(main)
	assert_true(main.get_node_or_null("Player") is Player)
	assert_true(main.get_node("HUD/SpecialBar") is ProgressBar)


func test_no_control_in_arena_swallows_mouse():
	# Controles com mouse_filter STOP/PASS consomem cliques antes do _unhandled_input do player.
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main)
	for node in main.find_children("*", "Control", true, false):
		assert_eq(node.mouse_filter, Control.MOUSE_FILTER_IGNORE,
			"%s bloqueia o mouse" % main.get_path_to(node))
