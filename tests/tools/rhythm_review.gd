extends SceneTree
## Capturas reproduzíveis da v1.2. Save isolado e timeout: não altera o progresso real.
## Godot --path . -s tests/tools/rhythm_review.gd -- <pasta de saída>

var gs
var out := "res://builds/review"


func _initialize() -> void:
	await process_frame
	create_timer(55.0).timeout.connect(func() -> void:
		push_error("REVIEW: timeout")
		quit(1))
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	gs = root.get_node("GameState")
	gs.save_path = "res://builds/review-save.dat"
	gs.new_game("Blue")
	gs.go(gs.SCENE_MENU)
	await _wait(0.5)
	await _shot("01-menu")
	gs.go(gs.SCENE_CAMPUS)
	await _wait(1.0)
	await _shot("02-campus")
	gs.start_run()
	gs.run.room = 2
	gs.run.plan[2] = "combat"
	gs.go(gs.SCENE_ROOM)
	await _wait(0.25)
	await _shot("03-reforcos")
	await _wait(1.0)
	current_scene.player.is_invincible = true
	current_scene.player.global_position = Vector2(570, 370)
	current_scene.player.special_meter.add(100)
	await _wait(0.4)
	await _shot("04-combate")
	current_scene.open_modal()
	load("res://scripts/ui/screens.gd").pause(current_scene, current_scene.close_modal)
	await _wait(0.2)
	await _shot("05-pausa")
	gs.run.room = 11
	gs.run.room_checkpoint = {}
	gs.go(gs.SCENE_ROOM)
	await _wait(1.25)
	current_scene.player.is_invincible = true
	for node in current_scene.get_children():
		if node.get("phase") != null:
			node.take_damage(500)
			node._throw(current_scene.player.global_position - node.global_position)
	await _wait(0.15)
	await _shot("06-mainframe")
	var state := FileAccess.open(out.path_join("state.json"), FileAccess.WRITE)
	state.store_string(gs.state_to_text())
	state.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	print("REVIEW: OK -> ", out)
	quit(0)


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(out.path_join(label + ".png"))
	if error != OK:
		push_error("REVIEW: falha ao salvar " + label)
		quit(1)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
