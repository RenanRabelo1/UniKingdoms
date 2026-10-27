extends GutTest


func test_main_scene_is_main_menu():
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/ui/main_menu.tscn")


func test_game_state_autoload_and_theme():
	assert_not_null(GameState)
	assert_not_null(get_tree().root.theme)
