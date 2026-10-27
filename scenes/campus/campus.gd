extends WorldController
## Campus (hub): Biblioteca com relíquias e espelho, área do CCT com lojas, atlética e portão da run,
## e os reinos ainda trancados.

const FREE := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/"
const UNITS := FREE + "Units/%s Units/"
const ISLAND := Rect2i(1, 1, 28, 16)
const AREA := Rect2(84, 100, 1752, 968)
const SPAWN := Vector2(380, 560)
const DummyScene := preload("res://scenes/enemies/training_dummy.tscn")
const LOCKED := [
	["CCS — Ciências da Saúde", "Purple Buildings/Monastery.png", Vector2(520, 960)],
	["CCG — Comunicação e Gestão", "Yellow Buildings/Castle.png", Vector2(960, 990)],
	["CCJ — Ciências Jurídicas", "Red Buildings/Tower.png", Vector2(1400, 960)],
	["Reitoria — O Chanceler", "Black Buildings/Castle.png", Vector2(960, 330)],
]


func _ready() -> void:
	y_sort_enabled = true
	if GameState.has_run():
		GameState.continue_game()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	MapBuilder.island(self, ISLAND)
	MapBuilder.border(self, AREA)

	_biblioteca()
	_cct()
	for k in LOCKED:
		MapBuilder.building(self, FREE + "Buildings/" + k[1], k[2])
		MapBuilder.sign_label(self, k[0], k[2] + Vector2(0, 24), "Red")
		var it := _spot(k[2] + Vector2(0, 70), "Ver " + k[0].split(" —")[0])
		it.used.connect(func() -> void:
			hud.show_notice("%s está trancado. Este reino chega nas próximas versões." % k[0]))
	for p in [Vector2(160, 300), Vector2(180, 860), Vector2(700, 200), Vector2(1760, 260), Vector2(1760, 860),
			Vector2(760, 760), Vector2(1180, 760), Vector2(1660, 640), Vector2(300, 760), Vector2(1240, 180)]:
		MapBuilder.decor(self, ["tree", "bush", "rock"][rng.randi() % 3], p, rng)

	spawn_player(SPAWN)
	var cam := Camera2D.new()
	cam.limit_left = ISLAND.position.x * MapBuilder.TILE - 64
	cam.limit_top = ISLAND.position.y * MapBuilder.TILE - 64
	cam.limit_right = ISLAND.end.x * MapBuilder.TILE + 64
	cam.limit_bottom = ISLAND.end.y * MapBuilder.TILE + 64
	cam.position_smoothing_enabled = true
	player.add_child(cam)
	hud.room_text = "Campus · Bits no banco"
	hud.refresh()
	if GameState.profile.runs == 0:
		hud.show_notice("Bem-vindo ao campus! Converse com todos (E) e entre no Portão do CCT quando estiver pronto.")


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
	return it


func _biblioteca() -> void:
	MapBuilder.building(self, FREE + "Buildings/Blue Buildings/Monastery.png", Vector2(380, 420))
	MapBuilder.sign_label(self, "Biblioteca", Vector2(380, 440), "Blue")
	var vitrine := Sprite2D.new()
	vitrine.texture = load(FREE + "Terrain/Resources/Gold/Gold Stones/Gold Stone 4.png")
	vitrine.position.y = -30
	var vitrine_root := Node2D.new()
	vitrine_root.add_child(vitrine)
	add_child(vitrine_root)
	vitrine_root.global_position = Vector2(230, 540)
	MapBuilder.sign_label(self, "Relíquias", Vector2(230, 556), "Blue")
	var relics := _spot(Vector2(230, 540), "Ver a coleção de relíquias")
	relics.used.connect(func() -> void:
		open_modal()
		Screens.relics(self, close_modal))
	var tailor := _npc("Purple", "Pawn/Pawn_Idle.png", 8, Vector2(540, 520), "Espelho: mudar a cor do uniforme")
	tailor.used.connect(func() -> void:
		open_modal()
		Screens.customize(self, func(color: String) -> void:
			close_modal()
			GameState.profile.color = color
			GameState.save_game()
			GameState.go(GameState.SCENE_CAMPUS)))
	var dummy := DummyScene.instantiate()
	add_child(dummy)
	dummy.global_position = Vector2(620, 700)
	MapBuilder.sign_label(self, "Boneco de treino", Vector2(620, 730), "Blue")


func _cct() -> void:
	var gate_pos := Vector2(1380, 420)
	MapBuilder.building(self, FREE + "Buildings/Blue Buildings/Castle.png", gate_pos)
	var title := "CCT — Ciências Tecnológicas" + (" ✓ conquistado" if GameState.profile.cct_conquered else "")
	MapBuilder.sign_label(self, title, gate_pos + Vector2(0, 24), "Blue")
	var gate := _spot(gate_pos + Vector2(0, 80), "Entrar na run do CCT (12 salas)")
	gate.used.connect(func() -> void:
		GameState.start_run()
		GameState.go(GameState.SCENE_ROOM))

	MapBuilder.building(self, FREE + "Buildings/Blue Buildings/House1.png", Vector2(1080, 560))
	var shop := _npc("Yellow", "Pawn/Pawn_Idle Gold.png", 8, Vector2(1080, 620), "Lojinha do CCT")
	MapBuilder.sign_label(self, "Lojinha do CCT", Vector2(1080, 640))
	shop.used.connect(func() -> void:
		open_modal()
		Screens.shop(self, "cct", close_modal))

	MapBuilder.building(self, FREE + "Buildings/Red Buildings/Barracks.png", Vector2(1680, 520))
	MapBuilder.sign_label(self, GameState.ATLETICA_NAME, Vector2(1680, 540), "Red")
	var rep := _npc("Red", "Warrior/Warrior_Idle.png", 8, Vector2(1620, 610), "Falar com a %s" % GameState.ATLETICA_NAME)
	rep.used.connect(func() -> void:
		open_modal()
		Screens.mission(self, close_modal))
	var market := _npc("Red", "Pawn/Pawn_Idle Gold.png", 8, Vector2(1740, 610), "Mercado da atlética")
	market.used.connect(func() -> void:
		open_modal()
		Screens.shop(self, "atletica", close_modal))
