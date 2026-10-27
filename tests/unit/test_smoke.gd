extends GutTest


func test_main_scene_instantiates():
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(main_path, "res://scenes/main.tscn")
	var main := (load(main_path) as PackedScene).instantiate()
	add_child_autofree(main)
	assert_not_null(main.get_node_or_null("Title"))
