extends WorldController
## Sala da run do CCT: monta a ilha, solta as ondas, dá a recompensa e abre a ponte para a próxima.

const EnemyScene := preload("res://scenes/actors/enemy.tscn")
const BossScene := preload("res://scenes/actors/boss.tscn")
const ENEMIES := {
	"bug": preload("res://data/enemies/bug.tres"), "robo": preload("res://data/enemies/robo.tres"),
	"barril": preload("res://data/enemies/barril.tres"), "atletica": preload("res://data/enemies/atletica.tres"),
}
const ISLAND := Rect2i(1, 1, 16, 8)
## Área onde o player anda (dentro da borda da ilha).
const AREA := Rect2(84, 84, 984, 480)
const DOOR_X := 576.0
const SPAWN := Vector2(576, 520)
const WAVE_SIZE := 6
const RELIC_CHANCE := 0.08
const TYPE_NAMES := {"combat": "Combate", "teaching": "Ensinamento", "shop": "Mercado", "boss": "Chefe"}
const MONK := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/%s Units/Monk/Idle.png"
const MERCHANT := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Yellow Units/Pawn/Pawn_Idle Gold.png"
const BRIDGE := "res://Tiny Swords/Tiny Swords (Update 010)/Terrain/Bridge/Bridge_All.png"

var rng := RandomNumberGenerator.new()
var room_index := 0
var room_kind := "combat"
var door_open := false
var _waves: Array = []
var _alive := 0
var _gate: CollisionShape2D
var _bridge: Sprite2D
var _leaving := false
var _obstacles: Array[Vector2] = []


func _ready() -> void:
	y_sort_enabled = true
	if not GameState.has_run():
		GameState.start_run()
	rng.randomize()
	room_index = GameState.run.room
	room_kind = GameState.room_type()
	MapBuilder.island(self, ISLAND)
	_build_walls()
	_build_bridge()
	if room_kind != "boss":
		_build_decor()
	spawn_player(SPAWN, GameState.run.hp)
	hud.room_text = "Sala %d/%d · %s" % [room_index + 1, GameState.ROOM_COUNT, TYPE_NAMES[room_kind]]
	hud.refresh()
	match room_kind:
		"shop":
			_spawn_merchant()
			open_door()
		"boss":
			get_tree().create_timer(1.0, false).timeout.connect(_spawn_boss)
		_:
			_plan_waves()
			get_tree().create_timer(0.8, false).timeout.connect(_next_wave)


func _process(delta: float) -> void:
	super(delta)
	if door_open and not _leaving and player.global_position.y < 24.0:
		_leaving = true
		GameState.advance_room(player.hp)
		GameState.go(GameState.SCENE_ROOM)


# --- Mapa --------------------------------------------------------------------

func _build_walls() -> void:
	var t := 40.0
	var body := MapBuilder.walls(self, [
		Rect2(AREA.position.x - t, AREA.end.y, AREA.size.x + 2 * t, t),
		Rect2(AREA.position.x - t, AREA.position.y, t, AREA.size.y),
		Rect2(AREA.end.x, AREA.position.y, t, AREA.size.y),
		Rect2(AREA.position.x - t, AREA.position.y - t, DOOR_X - 36 - AREA.position.x + t, t),
		Rect2(DOOR_X + 36, AREA.position.y - t, AREA.end.x + t - DOOR_X - 36, t),
		# Corredor da ponte (por cima da água).
		Rect2(DOOR_X - 36 - t, -200, t, AREA.position.y - t + 200),
		Rect2(DOOR_X + 36, -200, t, AREA.position.y - t + 200),
	])
	_gate = MapBuilder.add_rect(body, Rect2(DOOR_X - 36, AREA.position.y - t, 72, t))


func _build_bridge() -> void:
	_bridge = Sprite2D.new()
	_bridge.texture = load(BRIDGE)
	_bridge.region_enabled = true
	_bridge.region_rect = Rect2(0, 64, 64, 160)
	_bridge.z_index = -5
	_bridge.position = Vector2(DOOR_X, 10)
	_bridge.visible = false
	add_child(_bridge)


func _build_decor() -> void:
	for i in rng.randi_range(4, 7):
		for attempt in 20:
			var pos := Vector2(rng.randf_range(AREA.position.x + 40, AREA.end.x - 40),
				rng.randf_range(AREA.position.y + 50, AREA.end.y - 30))
			if _free_spot(pos, 110.0):
				var kind: String = ["tree", "rock", "bush", "bush"][rng.randi() % 4]
				MapBuilder.decor(self, kind, pos, rng)
				_obstacles.append(pos)
				break


func _free_spot(pos: Vector2, min_dist: float) -> bool:
	if pos.distance_to(SPAWN) < 140.0 or (absf(pos.x - DOOR_X) < 110.0 and pos.y < 220.0):
		return false
	for o in _obstacles:
		if pos.distance_to(o) < min_dist:
			return false
	return true


func open_door() -> void:
	door_open = true
	for c in get_children():
		if c is Coin:
			c.magnet_radius = 5000.0
	_gate.set_deferred(&"disabled", true)
	_bridge.visible = true
	MapBuilder.sign_label(self, "Próxima sala ▲", Vector2(DOOR_X, 92))


# --- Combate -------------------------------------------------------------------

func _plan_waves() -> void:
	var pool := ["bug", "bug"]
	if room_index >= 1:
		pool.append("robo")
	if room_index >= 3:
		pool.append("barril")
	var ids := []
	for i in 3 + room_index:
		ids.append(pool[rng.randi() % pool.size()])
	if room_index > 0 and rng.randf() < GameState.ambush_chance():
		for i in 2 + int(room_index >= 6):
			ids.push_front("atletica")
		GameState.notice.emit("Emboscada da %s! Faça missões para eles virarem aliados." % GameState.ATLETICA_NAME)
	while not ids.is_empty():
		_waves.append(ids.slice(0, WAVE_SIZE))
		ids = ids.slice(WAVE_SIZE)


func _next_wave() -> void:
	if _waves.is_empty():
		_on_cleared()
		return
	for id in _waves.pop_front():
		spawn_enemy(ENEMIES[id], _spawn_point())


func spawn_enemy(data: EnemyData, pos: Vector2) -> Enemy:
	var e: Enemy = EnemyScene.instantiate()
	e.data = data
	e.hp_scale = 1.0 + 0.08 * room_index
	e.died.connect(_on_enemy_died)
	add_child(e)
	e.global_position = pos
	Fx.spawn(self, "dust", pos, 1.5)
	_alive += 1
	return e


func _spawn_point() -> Vector2:
	var pos := Vector2.ZERO
	for attempt in 30:
		pos = Vector2(rng.randf_range(AREA.position.x + 30, AREA.end.x - 30),
			rng.randf_range(AREA.position.y + 30, AREA.end.y - 30))
		if pos.distance_to(player.global_position) > 260.0 and _free_spot(pos, 50.0):
			break
	return pos


func _on_enemy_died(e: Enemy) -> void:
	_alive -= 1
	Coin.drop(self, e.global_position, e.data.bits)
	if _alive == 0 and room_kind != "boss":
		get_tree().create_timer(0.7, false).timeout.connect(_next_wave)


func _on_cleared() -> void:
	if player.is_dead:
		return
	if room_kind == "teaching":
		_spawn_professor()
		return
	Coin.drop(self, Vector2(DOOR_X, 300), 10 + 2 * room_index)
	_give_relic(RELIC_CHANCE)
	get_tree().create_timer(0.5, false).timeout.connect(open_door)


func _give_relic(chance: float) -> void:
	var r := GameState.roll_relic(chance)
	if r:
		Fx.spawn(self, "explosion", player.global_position, 0.6)
		GameState.notice.emit("Relíquia encontrada: %s! %s (permanente)" % [r.display_name, r.description])
		player.setup(GameState.stats(), player.hp)


# --- Recompensas e NPCs --------------------------------------------------------

func _spawn_professor() -> void:
	var color: String = ["Blue", "Purple", "Yellow"][rng.randi() % 3]
	var prof := Interactable.npc({"idle": [MONK % color, 192, 192, 0, 6, 10.0, true]}, "Falar com o professor")
	add_child(prof)
	prof.global_position = Vector2(DOOR_X, 300)
	Fx.spawn(self, "dust", prof.global_position, 2.0)
	GameState.notice.emit("Um professor quer te ensinar algo.")
	prof.used.connect(func() -> void:
		var offers := GameState.offer_teachings(3)
		if offers.is_empty():
			GameState.notice.emit("Você já aprendeu tudo que os professores do CCT ensinam!")
			Coin.drop(self, prof.global_position, 20)
			_finish_professor(prof)
			return
		open_modal()
		Screens.teaching_choice(self, offers, func(t: TeachingData) -> void:
			close_modal()
			apply_teaching(t)
			hud.show_notice("Aprendeu %s: %s" % [t.display_name, t.description])
			_finish_professor(prof)))


func _finish_professor(prof: Interactable) -> void:
	prof.enabled = false
	Fx.spawn(self, "dust", prof.global_position, 2.0)
	prof.queue_free()
	open_door()


func _spawn_merchant() -> void:
	var npc := Interactable.npc({"idle": [MERCHANT, 192, 192, 0, 8, 10.0, true]}, "Comprar no mercado da sala")
	add_child(npc)
	npc.global_position = Vector2(DOOR_X, 280)
	MapBuilder.sign_label(self, "Mercado", Vector2(DOOR_X, 300))
	npc.used.connect(func() -> void:
		open_modal()
		Screens.shop(self, "run", func() -> void:
			close_modal()
			player.setup(GameState.stats(), player.hp)
			hud.refresh()))


# --- Boss e fim da run ---------------------------------------------------------

func _spawn_boss() -> void:
	var boss: Boss = BossScene.instantiate()
	add_child(boss)
	boss.global_position = Vector2(DOOR_X, 220)
	Fx.spawn(self, "explosion", boss.global_position, 1.5)
	hud.show_boss(Boss.DISPLAY_NAME, Boss.MAX_HP)
	boss.hp_changed.connect(hud.set_boss_hp)
	boss.summon_requested.connect(func(count: int) -> void:
		for i in count:
			spawn_enemy(ENEMIES["bug"], _spawn_point()))
	boss.died.connect(func(_b: Boss) -> void:
		get_tree().create_timer(1.5, false).timeout.connect(_on_boss_defeated))
	GameState.notice.emit("O Prof. Mainframe, chefe do CCT, quer te reprovar!")


func _on_boss_defeated() -> void:
	if player.is_dead:
		return
	_give_relic(1.0)
	var result := GameState.end_run(true)
	open_modal()
	Screens.result(self, result)


func _on_player_died() -> void:
	get_tree().create_timer(1.2, false).timeout.connect(func() -> void:
		var result := GameState.end_run(false)
		open_modal()
		Screens.result(self, result))
