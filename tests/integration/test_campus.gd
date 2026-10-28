extends GutTest
## Campus novo (Unifor-campus-kit): tamanho, alcance de tudo a partir do início, colisões, oclusão,
## encontros sem farm e carrinho elétrico.

const CampusScene := preload("res://scenes/campus/campus.tscn")
## Grade da checagem de alcance e raio do corpo do player (player.tscn).
const STEP := 32
const BODY := 14.0

var campus: Node


func before_all():
	# O menu do carrinho pausa a árvore; o teste precisa continuar rodando.
	var n: Node = self
	while n != get_tree().root:
		n.process_mode = Node.PROCESS_MODE_ALWAYS
		n = n.get_parent()


func after_all():
	var n: Node = self
	while n != get_tree().root:
		n.process_mode = Node.PROCESS_MODE_INHERIT
		n = n.get_parent()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_campus.dat"))
	GameState.save_path = "user://save.dat"
	GameState.load_game()


func before_each():
	GameState.save_path = "user://test_campus.dat"
	GameState.profile = GameState.default_profile()
	GameState.run = {}
	campus = CampusScene.instantiate()
	add_child_autofree(campus)
	await wait_physics_frames(3)


func after_each():
	get_tree().paused = false


func _free_at(p: Vector2) -> bool:
	var shape := CircleShape2D.new()
	shape.radius = BODY
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, p)
	q.collision_mask = Constants.LAYER_WORLD
	return campus.get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


## Células livres alcançáveis a partir do início (busca em largura na grade).
func _reachable() -> Dictionary:
	var size := CampusLayout.WORLD * 64 / STEP
	var start := Vector2i(CampusLayout.SPAWN / STEP)
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x < 1 or n.y < 1 or n.x >= size.x - 1 or n.y >= size.y - 1 or seen.has(n):
				continue
			if _free_at(Vector2(n * STEP) + Vector2.ONE * STEP / 2.0):
				seen[n] = true
				queue.append(n)
	return seen


func _near_reachable(reach: Dictionary, p: Vector2, radius: float) -> bool:
	var c := Vector2i(p / STEP)
	var r := int(ceil(radius / STEP))
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			var n := c + Vector2i(x, y)
			if reach.has(n) and (Vector2(n * STEP) + Vector2.ONE * STEP / 2.0).distance_to(p) <= radius:
				return true
	return false


func test_campus_is_much_bigger_and_built_from_the_kit():
	var old_area := 28 * 16
	assert_gt(CampusLayout.WORLD.x * CampusLayout.WORLD.y, old_area * 10, "área ao menos 10x a do campus antigo")
	var kit := campus.get_children().filter(func(n): return n.has_meta(&"kit_id"))
	assert_gt(kit.size(), 150, "objetos do kit no mapa")
	var ids := kit.map(func(n): return n.get_meta(&"kit_id"))
	for b in CampusLayout.BUILDINGS:
		assert_has(ids, b[0])


func test_every_place_is_reachable_from_spawn():
	var reach := _reachable()
	assert_gt(reach.size(), 15000, "boa parte do campus é caminhável")
	# Células livres fora do alcance = bolsões presos entre objetos (não devem existir em quantidade).
	var size := CampusLayout.WORLD * 64 / STEP
	var free := 0
	var pockets: Array[Vector2] = []
	for x in range(1, size.x - 1):
		for y in range(1, size.y - 1):
			var p := Vector2(x, y) * STEP + Vector2.ONE * STEP / 2.0
			if _free_at(p):
				free += 1
				if not reach.has(Vector2i(x, y)):
					pockets.append(p)
	gut.p("alcance: %d de %d células livres; %d presas %s" % [reach.size(), free, pockets.size(), pockets.slice(0, 12)])
	assert_lt(pockets.size(), 40, "quase nenhum bolsão preso")
	for it in get_tree().get_nodes_in_group(&"interactable"):
		assert_true(_near_reachable(reach, it.global_position, WorldController.INTERACT_RADIUS - 12.0),
			"alcança: %s" % it.prompt)
	for e in CampusLayout.ENCOUNTERS:
		for off in Encounter.OFFSETS:
			assert_true(_near_reachable(reach, e[2] + off, 24.0), "inimigo do encontro %s nasce em lugar livre" % e[0])
	for s in CampusLayout.STOPS:
		assert_true(_near_reachable(reach, s[1] + Vector2(0, 80), 24.0), "chegada do carrinho %s" % s[0])


func test_buildings_block_player_and_enemies_but_fields_do_not():
	var cct: Vector2 = CampusLayout.BUILDINGS.filter(func(b): return b[3] == "cct")[0][1]
	assert_false(_free_at(cct + Vector2(0, -120)), "o prédio do CCT bloqueia")
	var field: Vector2 = CampusLayout.BUILDINGS.filter(func(b): return b[0] == "campo-futebol-society")[0][1]
	assert_true(_free_at(field + Vector2(0, -200)), "o campo society é caminhável")
	var enemy: Enemy = load("res://scenes/actors/enemy.tscn").instantiate()
	enemy.data = load("res://data/enemies/bug.tres")
	campus.add_child(enemy)
	enemy.global_position = cct + Vector2(0, 120)
	await wait_physics_frames(2)
	assert_true(enemy.test_move(enemy.global_transform, Vector2(0, -260)), "inimigo também colide com o prédio")


func test_player_behind_building_makes_it_transparent():
	var lib: Vector2 = CampusLayout.BUILDINGS.filter(func(b): return b[3] == "biblioteca")[0][1]
	var node: Node2D = campus.get_children().filter(func(n): return n.get_meta(&"kit_id", "") == "biblioteca-central")[0]
	var rect := CampusKit.sprite_rect(node)
	campus.player.global_position = Vector2(lib.x, rect.position.y + 40)
	await wait_seconds(0.4)
	assert_lt(node.modulate.a, 1.0, "prédio fica transparente com o player atrás")
	campus.player.global_position = CampusLayout.SPAWN
	await wait_seconds(0.4)
	assert_eq(node.modulate.a, 1.0)


func test_encounter_pays_once_and_returns_after_a_run():
	var bits: int = GameState.profile.bits
	var enc: Encounter = campus.get_children().filter(func(n): return n is Encounter and n.id == "corredor")[0]
	campus.player.global_position = enc.global_position + Vector2(0, 300)
	await wait_physics_frames(3)
	assert_true(enc.started)
	for e in campus.get_children().filter(func(n): return n is Enemy):
		e.take_damage(9999)
	await wait_physics_frames(2)
	assert_eq(GameState.profile.bits, bits + GameState.CAMPUS_ENCOUNTER_BITS)
	assert_true(GameState.is_campus_cleared("corredor"))

	var again := CampusScene.instantiate()
	add_child_autofree(again)
	await wait_physics_frames(2)
	assert_false(again.get_children().any(func(n): return n is Encounter and n.id == "corredor"),
		"vencido não volta antes de uma run")
	GameState.start_run()
	GameState.end_run(false)
	assert_false(GameState.is_campus_cleared("corredor"), "volta depois que a run termina")


func test_electric_cart_travels_between_stops():
	var here: Interactable = get_tree().get_nodes_in_group(&"interactable").filter(
		func(n): return n.prompt == "Carrinho elétrico: parada Biblioteca")[0]
	here.used.emit()
	await wait_physics_frames(1)
	var button: Button = campus.find_children("*", "Button", true, false).filter(
		func(b): return b.text == "Estádio")[0]
	button.pressed.emit()
	await wait_physics_frames(2)
	var dest: Vector2 = CampusLayout.STOPS.filter(func(s): return s[0] == "Estádio")[0][1]
	assert_almost_eq(campus.player.global_position, dest + Vector2(0, 80), Vector2.ONE)
	assert_false(get_tree().paused)
