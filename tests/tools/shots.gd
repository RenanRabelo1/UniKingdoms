extends SceneTree
## Capturas de tela do campus para revisão visual (precisa de janela, não roda em --headless).
## Uso: godot --path . -s tests/tools/shots.gd -- <pasta de saída>
## Salva a visão geral do mapa, alguns pontos do campus, o mapa (M) e uma sala da run.
## Sem tipos de classe aqui: scripts -s compilam antes dos autoloads existirem.

const SPOTS := {
	"biblioteca": Vector2(5120, 3260), "convivencia": Vector2(4300, 3000), "cct": Vector2(3500, 3830),
	"dce": Vector2(2620, 2700), "estadio": Vector2(1300, 2450), "lagoa": Vector2(1340, 3900),
	"nami": Vector2(4700, 900), "esportes": Vector2(2100, 2000), "debug_combate": Vector2(5500, 3700),
}

var gs
var out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(out)
	await process_frame
	gs = root.get_node("GameState")
	gs.save_path = "user://shots_save.dat"
	gs.new_game("Blue")
	var t0 := Time.get_ticks_msec()
	gs.go(gs.SCENE_CAMPUS)
	while current_scene == null or current_scene.name != "Campus" or current_scene.get("player") == null:
		await process_frame
	print("PERF: campus carregou em %d ms" % (Time.get_ticks_msec() - t0))
	await _wait(1.5)
	var campus = current_scene
	var cam = campus.player.get_node("Camera2D")

	var overview := Camera2D.new()
	campus.add_child(overview)
	overview.global_position = Vector2(3200, 2400)
	overview.zoom = Vector2.ONE * 0.135
	overview.make_current()
	await _wait(0.5)
	await _shot("visao_geral")
	cam.make_current()

	for k in SPOTS:
		campus.player.global_position = SPOTS[k]
		cam.reset_smoothing()
		if k == "debug_combate":
			var hb_class = load("res://scripts/combat/hurtbox.gd")
			hb_class.debug_draw = true
		await _wait(0.6)
		if k == "debug_combate":
			campus.player.aim_direction = Vector2.RIGHT
			campus.player.attack(&"basic")
			await _wait(0.05)
		await _shot(k)

	load("res://scripts/combat/hurtbox.gd").debug_draw = false
	await _perf_walk(campus, cam)
	campus.player.global_position = SPOTS["biblioteca"]
	campus.open_map()
	await _wait(0.4)
	await _shot("mapa")

	gs.start_run()
	gs.go(gs.SCENE_ROOM)
	await _wait(1.5)
	load("res://scripts/combat/hurtbox.gd").debug_draw = true
	await _wait(0.8)
	await _shot("sala_debug")
	load("res://scripts/combat/hurtbox.gd").debug_draw = false
	gs.end_run(false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	print("SHOTS: ok -> ", out)
	quit()


## Percorre o campus inteiro (em zigue-zague, 12 s) medindo o tempo real entre quadros.
func _perf_walk(campus, cam) -> void:
	var worst := 0.0
	var frames := 0
	var start := Time.get_ticks_msec()
	var last := Time.get_ticks_usec()
	while Time.get_ticks_msec() - start < 12000:
		var t := (Time.get_ticks_msec() - start) / 12000.0
		var row := int(t * 6.0)
		var x := fmod(t * 6.0, 1.0)
		if row % 2 == 1:
			x = 1.0 - x
		campus.player.global_position = Vector2(300 + x * 5600, 400 + row * 800)
		await process_frame
		var now := Time.get_ticks_usec()
		if frames > 10:
			worst = maxf(worst, (now - last) / 1000.0)
		last = now
		frames += 1
	print("PERF: %d quadros em 12 s (%.0f FPS médio), pior quadro %.1f ms, nós %d, draw calls %d" % [
		frames, frames / 12.0, worst, Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
