extends GutTest
## Fluxo do jogo com as cenas reais (sem trocar de cena: cada sala é instanciada aqui).

const RoomScene := preload("res://scenes/run/room.tscn")
const CampusScene := preload("res://scenes/campus/campus.tscn")
const MenuScene := preload("res://scenes/ui/main_menu.tscn")


func before_all():
	# Telas de resultado pausam a árvore; o GUT (e este teste) precisam continuar rodando.
	var n: Node = self
	while n != get_tree().root:
		n.process_mode = Node.PROCESS_MODE_ALWAYS
		n = n.get_parent()


func before_each():
	GameState.save_path = "user://test_save.dat"
	GameState.profile = GameState.default_profile()
	GameState.run = {}


func after_each():
	get_tree().paused = false


func after_all():
	var n: Node = self
	while n != get_tree().root:
		n.process_mode = Node.PROCESS_MODE_INHERIT
		n = n.get_parent()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.dat"))
	GameState.save_path = "user://save.dat"
	GameState.load_game()


func _room(index: int, kind: String) -> Node:
	if not GameState.has_run():
		GameState.start_run()
	GameState.run.room = index
	GameState.run.plan[index] = kind
	var room := RoomScene.instantiate()
	add_child_autofree(room)
	return room


func _enemies(room: Node) -> Array:
	return room.get_children().filter(func(n): return n is Enemy and n.hp > 0)


func _kill_all(room: Node) -> void:
	for i in 20:
		await wait_seconds(0.9)
		var alive := _enemies(room)
		if alive.is_empty() and room.door_open:
			return
		for e in alive:
			e.take_damage(9999)


func _world_controls_ignore_mouse(node: Node) -> void:
	for c in node.get_children():
		if c is CanvasLayer and c.layer >= 20:
			continue
		if c is Control:
			assert_eq(c.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s bloqueia o mouse" % c.get_path())
		_world_controls_ignore_mouse(c)


func test_main_menu_has_buttons():
	var menu := MenuScene.instantiate()
	add_child_autofree(menu)
	await wait_physics_frames(2)
	var labels := menu.find_children("*", "Button", true, false).map(func(b): return b.text)
	assert_has(labels, "Novo jogo")
	assert_has(labels, "Sair")


func test_campus_has_hub_spots_and_mouse_is_free():
	var campus := CampusScene.instantiate()
	add_child_autofree(campus)
	await wait_physics_frames(3)
	assert_not_null(campus.player)
	var prompts := get_tree().get_nodes_in_group(&"interactable").map(func(n): return n.prompt)
	assert_has(prompts, "Lojinha do CCT")
	assert_has(prompts, "Ver a coleção de relíquias")
	assert_has(prompts, "Mercado da atlética")
	assert_true(prompts.any(func(p): return p.begins_with("Entrar na run")))
	assert_eq(prompts.filter(func(p): return p.begins_with("Ver CC") or p.begins_with("Ver Reitoria")).size(), 4)
	_world_controls_ignore_mouse(campus)


func test_combat_room_clear_opens_door_and_gives_bits():
	GameState.profile.reputation = GameState.ALLY_REP
	var room := _room(1, "combat")
	await wait_seconds(1.2)
	assert_eq(_enemies(room).size(), 4, "sala 2 tem 3 + 1 inimigos")
	_world_controls_ignore_mouse(room)
	await _kill_all(room)
	assert_true(room.door_open)
	assert_gt(room.get_children().filter(func(n): return n is Coin).size(), 0, "moedas no chão")


func test_teaching_room_spawns_professor_after_clear():
	var room := _room(0, "teaching")
	await _kill_all_until_professor(room)
	var prof = get_tree().get_nodes_in_group(&"interactable").filter(func(n): return n.prompt == "Falar com o professor")
	assert_eq(prof.size(), 1)
	assert_false(room.door_open, "a ponte só abre depois de escolher")
	room.apply_teaching(GameState.offer_teachings(1)[0])
	room._finish_professor(prof[0])
	assert_true(room.door_open)
	assert_eq(GameState.run.teachings.size(), 1)


func _kill_all_until_professor(room: Node) -> void:
	for i in 15:
		await wait_seconds(0.9)
		for e in _enemies(room):
			e.take_damage(9999)
		if get_tree().get_nodes_in_group(&"interactable").size() > 0:
			return


func test_shop_room_opens_door_and_sells_with_run_bits():
	var room := _room(4, "shop")
	await wait_physics_frames(3)
	assert_true(room.door_open)
	assert_eq(_enemies(room).size(), 0)
	GameState.run.bits = 30
	assert_true(GameState.buy(GameState.item("marmita"), "run"))
	assert_eq(GameState.run.bits, 10)


func test_item_hotkey_heals_in_run():
	var room := _room(2, "combat")
	await wait_physics_frames(2)
	GameState.run.items = {"marmita": 1}
	room.player.take_damage(50)
	room.use_item(0)
	assert_eq(room.player.hp, room.player.max_hp - 10)
	assert_eq(GameState.item_count("marmita"), 0)


func test_death_ends_run_and_keeps_profile():
	var room := _room(3, "combat")
	await wait_seconds(0.5)
	GameState.run.bits = 25
	room.player.take_damage(9999)
	await wait_seconds(1.5)
	assert_false(GameState.has_run())
	assert_eq(GameState.profile.deaths, 1)
	assert_eq(GameState.profile.bits, GameState.START_BITS)
	assert_false(GameState.last_result.victory)


func test_boss_room_victory_conquers_cct():
	var room := _room(11, "boss")
	await wait_seconds(1.3)
	var bosses := room.get_children().filter(func(n): return n is Boss)
	assert_eq(bosses.size(), 1)
	var boss: Boss = bosses[0]
	boss.take_damage(Boss.MAX_HP / 2)
	assert_eq(boss.phase, 2)
	GameState.run.bits = 40
	boss.take_damage(9999)
	await wait_seconds(2.0)
	assert_false(GameState.has_run())
	assert_true(GameState.profile.cct_conquered)
	assert_eq(GameState.profile.bits, GameState.START_BITS + 40)
	assert_eq(GameState.profile.relics.size(), 1, "boss sempre dá relíquia")


func test_boss_charge_hurts_player():
	var room := _room(11, "boss")
	await wait_seconds(5.0)
	assert_lt(room.player.hp, room.player.max_hp, "o boss investe e acerta o player parado")
