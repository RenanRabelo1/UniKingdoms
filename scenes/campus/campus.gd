extends WorldController
## Campus (hub) montado com o Unifor-campus-kit a partir de CampusLayout: Biblioteca (relíquias, espelho,
## boneco), Lojinha e portão do CCT, DCE com a atlética, reinos trancados, carrinho elétrico, totens
## com o mapa e encontros espalhados.

const T := 64
const FREE := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/"
const UNITS := FREE + "Units/%s Units/"
const DummyScene := preload("res://scenes/enemies/training_dummy.tscn")

## Retângulos (px) onde a vegetação não pode pôr colisão: calçadas, praças, água e áreas de encontro.
var _keep_clear: Array[Rect2] = []
## Sprites dos prédios (px): a vegetação não cobre fachadas.
var _building_rects: Array[Rect2] = []
var _stops: Array = []
var _decor_points: Array[Vector2] = []
## Desenho do mapa (totens / M): [cor, retângulo] do chão e [retângulo, nome] dos prédios.
var map_ground: Array = []
var map_buildings: Array = []


func _ready() -> void:
	y_sort_enabled = true
	if GameState.has_run():
		GameState.continue_game()
		return
	_build_ground()
	_build_buildings()
	_build_hub()
	_build_stops_and_totems()
	_build_encounters()
	_build_vegetation()
	var world := Rect2(Vector2.ZERO, Vector2(CampusLayout.WORLD * T))
	MapBuilder.border(self, world)

	spawn_player(CampusLayout.SPAWN)
	var cam := Camera2D.new()
	cam.name = &"Camera2D"
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(world.size.x)
	cam.limit_bottom = int(world.size.y)
	cam.position_smoothing_enabled = true
	player.add_child(cam)
	hud.room_text = "Campus · [M] mapa · Banco"
	hud.refresh()
	if GameState.profile.runs == 0:
		hud.show_notice("Bem-vindo ao campus! Explore (M abre o mapa), converse com todos (E) e entre no CCT quando estiver pronto.")


func _process(delta: float) -> void:
	super._process(delta)
	if player:
		CampusKit.update_occlusion(get_tree(), player.body_center())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"campus_map") and not modal_open and player:
		get_viewport().set_input_as_handled()
		open_map()
		return
	super._unhandled_input(event)


func open_map() -> void:
	open_modal()
	Screens.campus_map(self, self, close_modal)


func _on_player_died() -> void:
	hud.show_notice("Você desmaiou no campus. Acordou na Biblioteca.")
	await get_tree().create_timer(1.5).timeout
	GameState.go(GameState.SCENE_CAMPUS)


# --- Chão ----------------------------------------------------------------------

func _build_ground() -> void:
	var stubs := _building_paths()
	for r: Rect2i in stubs:
		_keep_clear.append(Rect2(r.position * T, r.size * T))
	for entry in CampusLayout.GROUND:
		var rects: Array = entry[1]
		var cells := CampusKit.cells_of(rects)
		if entry[0] == "concreto-claro":
			cells.merge(CampusKit.cells_of(stubs))
		CampusKit.ground(self, entry[0], cells)
		if entry[0] != "grama-tropical" and entry[0] != "grama-clara":
			for r: Rect2i in rects:
				map_ground.append([entry[0], Rect2(r.position * T, r.size * T)])
		if entry[0] in ["concreto-claro", "piso-praca", "agua-lagoa", "deck-madeira", "asfalto"]:
			for r: Rect2i in rects:
				_keep_clear.append(Rect2(r.position * T, r.size * T))
	_water_walls()


## Acesso de cada prédio: calçada de 2 tiles da porta até a primeira calçada horizontal abaixo.
func _building_paths() -> Array:
	var paths := []
	for b in CampusLayout.BUILDINGS:
		if b[2] == "" or b[0] in CampusKit.FLAT or b[0] in ["estacionamento-solar", "portaria-principal"]:
			continue
		var base: Vector2 = b[1]
		var col := int(base.x / T) - 1
		var row := int(base.y / T)
		for walk_row: int in CampusLayout.WALK_ROWS:
			if walk_row >= row:
				if walk_row > row:
					paths.append(Rect2i(col, row, 2, walk_row - row))
				break
	return paths


## A lagoa bloqueia; o deck por cima dela, não.
func _water_walls() -> void:
	var water := CampusKit.cells_of(CampusLayout.GROUND.filter(func(e): return e[0] == "agua-lagoa")[0][1])
	var deck := CampusKit.cells_of(CampusLayout.GROUND.filter(func(e): return e[0] == "deck-madeira")[0][1])
	var rects := []
	for y in CampusLayout.WORLD.y:
		var start := -1
		for x in CampusLayout.WORLD.x + 1:
			var c := Vector2i(x, y)
			var solid := water.has(c) and not deck.has(c)
			if solid and start < 0:
				start = x
			elif not solid and start >= 0:
				rects.append(Rect2(start * T, y * T, (x - start) * T, T))
				start = -1
	MapBuilder.walls(self, rects)


# --- Prédios e hub -------------------------------------------------------------

func _build_buildings() -> void:
	for b in CampusLayout.BUILDINGS:
		var node := CampusKit.place(self, b[0], b[1])
		var rect := CampusKit.sprite_rect(node)
		if node.z_index >= 0:
			_building_rects.append(rect)
		else:
			_keep_clear.append(rect)
		var label: String = b[2]
		if b[3] == "atletica":
			label = "DCE · " + GameState.ATLETICA_NAME
		elif b[3] == "cct" and GameState.profile.cct_conquered:
			label += " ✓ conquistado"
		if label != "":
			MapBuilder.sign_label(self, label, b[1] + Vector2(0, 10), _sign_color(b[3]))
			map_buildings.append([rect, label])
		else:
			map_buildings.append([rect, ""])
		if b[3] in CampusLayout.LOCKED:
			var title: String = CampusLayout.LOCKED[b[3]]
			var it := _spot(b[1] + Vector2(0, 60), "Ver " + title.split(" —")[0])
			it.used.connect(func() -> void:
				hud.show_notice("%s está trancado. Este reino chega nas próximas versões." % title))


func _sign_color(role: String) -> String:
	match role:
		"cct", "biblioteca": return "Blue"
		"atletica", "ccs", "ccg", "ccj", "reitoria": return "Red"
	return "Yellow"


func _role_pos(role: String) -> Vector2:
	for b in CampusLayout.BUILDINGS:
		if b[3] == role:
			return b[1]
	return Vector2.ZERO


func _build_hub() -> void:
	var lib := _role_pos("biblioteca")
	var vitrine := Node2D.new()
	var stone := Sprite2D.new()
	stone.texture = load(FREE + "Terrain/Resources/Gold/Gold Stones/Gold Stone 4.png")
	stone.position.y = -30
	vitrine.add_child(stone)
	add_child(vitrine)
	vitrine.global_position = lib + Vector2(-240, 70)
	MapBuilder.sign_label(self, "Relíquias", vitrine.global_position + Vector2(0, 16), "Blue")
	var relics := _spot(vitrine.global_position, "Ver a coleção de relíquias")
	relics.used.connect(func() -> void:
		open_modal()
		Screens.relics(self, close_modal))

	var tailor := _npc("Purple", "Pawn/Pawn_Idle.png", 8, lib + Vector2(240, 70), "Espelho: mudar a cor do uniforme")
	tailor.used.connect(func() -> void:
		open_modal()
		Screens.customize(self, func(color: String) -> void:
			close_modal()
			GameState.profile.color = color
			GameState.save_game()
			GameState.go(GameState.SCENE_CAMPUS)))

	var dummy := DummyScene.instantiate()
	add_child(dummy)
	dummy.global_position = lib + Vector2(380, 380)
	MapBuilder.sign_label(self, "Boneco de treino", dummy.global_position + Vector2(0, 30), "Blue")
	_keep_clear.append(Rect2(dummy.global_position - Vector2(120, 140), Vector2(240, 240)))

	var cct := _role_pos("cct")
	var gate := _spot(cct + Vector2(0, 70), "Entrar na run do CCT (12 salas)")
	gate.used.connect(func() -> void:
		GameState.start_run()
		GameState.go(GameState.SCENE_ROOM))

	var shop := _npc("Yellow", "Pawn/Pawn_Idle Gold.png", 8, _role_pos("shop") + Vector2(0, 70), "Lojinha do CCT")
	shop.used.connect(func() -> void:
		open_modal()
		Screens.shop(self, "cct", close_modal))

	var dce := _role_pos("atletica")
	var rep := _npc("Red", "Warrior/Warrior_Idle.png", 8, dce + Vector2(-80, 140), "Falar com a %s" % GameState.ATLETICA_NAME)
	rep.used.connect(func() -> void:
		open_modal()
		Screens.mission(self, close_modal))
	var market := _npc("Red", "Pawn/Pawn_Idle Gold.png", 8, dce + Vector2(80, 140), "Mercado da atlética")
	market.used.connect(func() -> void:
		open_modal()
		Screens.shop(self, "atletica", close_modal))


func _build_stops_and_totems() -> void:
	for s in CampusLayout.STOPS:
		CampusKit.place(self, "ponto-carrinho-eletrico", s[1])
		var cart := CampusKit.place(self, "carrinho-eletrico", s[1] + Vector2(150, 40))
		_keep_clear.append(CampusKit.sprite_rect(cart).grow(24))
		var it := _spot(s[1] + Vector2(0, 30), "Carrinho elétrico: parada %s" % s[0])
		it.used.connect(func() -> void: _open_stops(s[0]))
		_stops.append(s)
		_keep_clear.append(Rect2(s[1] - Vector2(140, 200), Vector2(280, 280)))
	for p: Vector2 in CampusLayout.TOTEMS:
		CampusKit.place(self, "totem-orientacao", p)
		var it := _spot(p + Vector2(0, 30), "Totem: ver o mapa do campus")
		it.used.connect(open_map)
		_keep_clear.append(Rect2(p - Vector2(80, 140), Vector2(160, 200)))


func _open_stops(here: String) -> void:
	open_modal()
	var others := _stops.filter(func(s) -> bool: return s[0] != here)
	Screens.cart_stops(self, here, others.map(func(s): return s[0]), func(dest: String) -> void:
		close_modal()
		if dest == "":
			return
		for s in _stops:
			if s[0] == dest:
				player.global_position = s[1] + Vector2(0, 80)
				player.get_node(^"Camera2D").reset_smoothing()
				hud.show_notice("Carrinho elétrico: você chegou à parada %s." % dest))


func _build_encounters() -> void:
	for e in CampusLayout.ENCOUNTERS:
		_keep_clear.append(Rect2(e[2] - Vector2(260, 260), Vector2(520, 520)))
		if GameState.is_campus_cleared(e[0]):
			continue
		var enc := Encounter.new()
		enc.id = e[0]
		enc.message = e[1]
		enc.enemy_ids = e[3].map(func(id): return "bug" if id == "atletica" and GameState.is_ally() else id)
		add_child(enc)
		enc.global_position = e[2]
		enc.cleared.connect(_on_encounter_cleared)
		enc.triggered.connect(func(x: Encounter) -> void: hud.show_notice(x.message))


func _on_encounter_cleared(enc: Encounter) -> void:
	GameState.clear_campus_encounter(enc.id)
	hud.refresh()
	hud.show_notice("Área liberada! +%d Bits no banco." % GameState.CAMPUS_ENCOUNTER_BITS)


# --- Vegetação e mobiliário ----------------------------------------------------

func _build_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var w := CampusLayout.WORLD.x * T
	var h := CampusLayout.WORLD.y * T
	# Coqueiros na Av. Washington Soares e palmeiras ao longo da Av. Valmir Pontes.
	for y in range(160, h - 300, 300):
		_try_place("coqueiro", Vector2(w - 260, y))
	for x in range(1500, w - 300, 320):
		_try_place(["palmeira-alta", "palmeiras-duplas"][(x / 320) % 2], Vector2(x, 1060))
		_try_place("palmeira-jovem", Vector2(x + 160, 800))
	# Ipês e postes ao longo das calçadas centrais.
	for x in range(200, w - 300, 420):
		_try_place("arvore-florida-amarela", Vector2(x, 1900))
		_try_place("poste-luz", Vector2(x + 210, 1910))
		_try_place("arvore-copa-redonda", Vector2(x + 100, 3180))
		_try_place("poste-luz", Vector2(x + 310, 3190))
	for y in range(1100, h - 300, 420):
		for col in [20, 46, 72]:
			_try_place("poste-luz", Vector2(col * T - 30, y))
			_try_place("arvore-copa-larga", Vector2(col * T + 2 * T + 150, y + 200))
	# Margem da lagoa.
	for p in [Vector2(1150, 3420), Vector2(150, 3300), Vector2(500, 3290), Vector2(1220, 4300),
			Vector2(1100, 4560), Vector2(500, 4580), Vector2(820, 4590)]:
		_try_place(["palmeira-alta", "coqueiro", "arvore-copa-larga"][rng.randi() % 3], p)
	for p in [Vector2(1010, 3560), Vector2(1030, 4060), Vector2(200, 3380), Vector2(700, 3380), Vector2(1090, 4400)]:
		CampusKit.place(self, "capim-lagoa", p)
	for p in [Vector2(300, 3700), Vector2(600, 3950), Vector2(420, 4250), Vector2(850, 3800), Vector2(700, 4400)]:
		CampusKit.place(self, "vitoria-regia", p)
	# Praças e frentes de prédio.
	for p in [Vector2(4040, 2440), Vector2(4560, 2440), Vector2(4300, 2960)]:
		_try_place("guarda-sol-mesa", p)
	for p in [Vector2(4800, 3330), Vector2(5450, 3330), Vector2(3350, 3800), Vector2(2380, 2650), Vector2(5600, 4000)]:
		_try_place("banco-concreto", p)
	for p in [Vector2(4100, 3330), Vector2(2200, 2050), Vector2(5600, 2050), Vector2(1500, 3330)]:
		_try_place("banco-madeira", p)
	for p in [Vector2(3120, 2700), Vector2(4700, 1600), Vector2(2900, 1100)]:
		_try_place("bicicletario", p)
	for p in [Vector2(2950, 2600), Vector2(5400, 3450), Vector2(4250, 3640), Vector2(1600, 2050)]:
		_try_place(["lixeira", "lixeiras-reciclagem", "bebedouro"][rng.randi() % 3], p)
	_try_place("banca-lanchonete", Vector2(2280, 2860))
	_try_place("mesa-piquenique", Vector2(2150, 3000))
	for p in [Vector2(4920, 3330), Vector2(5320, 3330)]:
		_try_place("canteiro-flores", p)
	for p in [Vector2(5400, 3720), Vector2(5990, 3720), Vector2(5400, 4400), Vector2(5990, 4400)]:
		_try_place("cerca-viva-horizontal", p)
	# Árvores soltas nos gramados (verificadas contra prédios, calçadas e áreas livres).
	var placed := 0
	for i in 900:
		if placed >= 140:
			break
		var p := Vector2(rng.randf_range(80, w - 300), rng.randf_range(260, h - 260))
		var id: String = ["arvore-copa-larga", "arvore-copa-redonda", "arvore-alta", "palmeira-alta",
			"arvore-florida-amarela", "arbusto-redondo", "pedra-grande", "palmeira-jovem"][rng.randi() % 8]
		if _try_place(id, p, 200.0):
			placed += 1



## Põe o objeto só se a colisão não cair em calçada/praça/água/encontro e o sprite não cobrir prédio.
func _try_place(id: String, pos: Vector2, min_gap := 0.0) -> bool:
	if min_gap > 0.0:
		for q in _decor_points:
			if q.distance_to(pos) < min_gap:
				return false
	var probe := CampusKit.place(self, id, pos)
	var sprite_rect := CampusKit.sprite_rect(probe)
	var base := Rect2(pos - Vector2(40, 30), Vector2(80, 36))
	var ok := not _hits(base, _keep_clear) and not _hits(sprite_rect.grow(-20), _building_rects)
	if not ok:
		probe.free()
		return false
	_decor_points.append(pos)
	return true


func _hits(r: Rect2, list: Array[Rect2]) -> bool:
	for o in list:
		if r.intersects(o):
			return true
	return false


# --- Utilitários ---------------------------------------------------------------

func _spot(pos: Vector2, prompt: String) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt
	add_child(it)
	it.global_position = pos
	return it


func _npc(color: String, file: String, frames: int, pos: Vector2, prompt: String) -> Interactable:
	var it := Interactable.npc({"idle": [UNITS % color + file, 192, 192, 0, frames, 10.0, true]}, prompt)
	add_child(it)
	it.global_position = pos
	_keep_clear.append(Rect2(pos - Vector2(80, 120), Vector2(160, 180)))
	return it
