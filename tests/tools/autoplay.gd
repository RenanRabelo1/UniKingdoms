extends SceneTree
## Verificação ponta a ponta com trocas de cena reais (sem GUT).
## Uso: godot --headless --path . -s tests/tools/autoplay.gd
## Joga uma run inteira até a vitória, uma run até a morte e o "Continuar". Sai com código 1 se algo falhar.
## Sem tipos de classe aqui: scripts -s compilam antes dos autoloads existirem.

var gs
var failures := []


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	gs.save_path = "user://autoplay_save.dat"
	gs.new_game("Purple")

	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await _wait(0.5)
	_check(current_scene.name == "MainMenu", "menu principal abre")

	gs.go(gs.SCENE_CAMPUS)
	await _wait(0.6)
	_check(current_scene.name == "Campus", "campus abre")

	await _victory_run()
	await _death_run()
	await _continue_run()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	print("AUTOPLAY: %s" % ("OK" if failures.is_empty() else "FALHOU: " + ", ".join(failures)))
	quit(0 if failures.is_empty() else 1)


func _victory_run() -> void:
	gs.start_run()
	var plan: Array = gs.run.plan.duplicate()
	gs.go(gs.SCENE_ROOM)
	for i in gs.ROOM_COUNT:
		await _wait(1.0)
		var room = current_scene
		_check(room.name == "Room" and gs.run.room == i, "sala %d carregou" % (i + 1))
		await _clear(room)
		if plan[i] == "boss":
			break
		_check(room.door_open, "ponte da sala %d abriu (%s)" % [i + 1, plan[i]])
		await _wait(1.5)  # tempo de as moedas voarem até o player, como ao andar até a ponte
		room.player.global_position = Vector2(576, 10)
		await _wait(0.6)
	await _wait(2.0)
	_check(not gs.has_run() and gs.profile.cct_conquered, "vitória conquista o CCT")
	_check(gs.profile.relics.size() >= 1, "boss deu relíquia")
	_check(gs.profile.bits > gs.START_BITS, "Bits da run foram guardados no banco")
	_press("Voltar ao campus")
	await _wait(0.8)
	_check(current_scene.name == "Campus", "volta ao campus depois da vitória")
	print("vitória: bits no banco=%d, relíquias=%s" % [gs.profile.bits, gs.profile.relics])


func _death_run() -> void:
	gs.start_run()
	gs.go(gs.SCENE_ROOM)
	await _wait(1.0)
	current_scene.player.take_damage(9999)
	await _wait(1.8)
	_check(not gs.has_run() and gs.profile.deaths == 1, "morte encerra a run")
	_check(_press("Voltar ao campus"), "tela de Reprovado tem o botão")
	await _wait(0.8)
	_check(current_scene.name == "Campus", "volta ao campus depois da morte")


func _continue_run() -> void:
	gs.start_run()
	gs.advance_room(80)
	gs.go(gs.SCENE_MENU)
	await _wait(0.6)
	_check(_press("Continuar"), "menu mostra Continuar com save")
	await _wait(1.0)
	_check(current_scene.name == "Room" and gs.run.room == 1, "continuar retoma a sala salva")
	_check(current_scene.player.hp == 80, "continuar mantém a vida salva")
	gs.end_run(false)


func _clear(room) -> void:
	for t in 80:
		await _wait(0.4)
		room.player.is_invincible = true
		for n in room.get_children():
			if n.has_method("take_damage") and n.get("hp") != null and n.hp > 0 and n != room.player:
				n.take_damage(9999)
		for it in get_nodes_in_group(&"interactable"):
			if it.prompt == "Falar com o professor" and it.enabled:
				it.used.emit()
				await _wait(0.2)
				_check(_press("Escolher [1]"), "escolha de ensinamento aparece")
		if room.door_open or not gs.has_run():
			return


func _press(prefix: String) -> bool:
	for b in root.find_children("*", "Button", true, false):
		if b.text.begins_with(prefix) and b.is_visible_in_tree():
			b.pressed.emit()
			return true
	return false


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  FALHA ") + what)
	if not ok:
		failures.append(what)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
