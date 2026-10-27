extends GutTest


func test_main_scene_is_arena_with_player():
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(main_path, "res://scenes/main.tscn")
	var main := (load(main_path) as PackedScene).instantiate()
	add_child_autofree(main)
	assert_true(main.get_node_or_null("Player") is Player)
	assert_true(main.get_node("HUD/SpecialBar") is ProgressBar)
