extends WorldController
## Sala do CCT: composições por dados, reforços anunciados e checkpoints sem prêmio duplicado.

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
const RELIC_CHANCE := 0.08
const TYPE_NAMES := {"combat": "Combate", "teaching": "Ensinamento", "shop": "Mercado", "boss": "Chefe"}
const MONK := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/%s Units/Monk/Idle.png"
const MERCHANT := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Yellow Units/Pawn/Pawn_Idle Gold.png"
const BRIDGE := "res://Tiny Swords/Tiny Swords (Update 010)/Terrain/Bridge/Bridge_All.png"

var rng := RandomNumberGenerator.new()
var room_index := 0
var room_kind := "combat"
var door_open := false
var encounter: EncounterData
var _pending: Array[StringName] = []
var _alive := 0
var _announced := 0
var _total_enemies := 0
var _defeated := 0
var _wave_number := 0
var _combat_elapsed := 0.0
var _challenge_time := 0.0
var _bonus_earned := false
var _resolved := false
var _hud_second := -1
var _gate: CollisionShape2D
var _bridge: Sprite2D
var _leaving := false
var _obstacles: Array[Vector2] = []


func _ready() -> void:
	y_sort_enabled = true
	if not GameState.has_run():
		GameState.start_run()
	room_index = GameState.run.room
	room_kind = GameState.room_type()
	rng.seed = int(GameState.run.get("seed", 0)) + room_index * 7919
	encounter = EncounterDirector.profile_for(room_index)
	MapBuilder.island(self, ISLAND)
	_build_walls()
	_build_bridge()
	if room_kind != "boss":
		_build_decor()
	spawn_player(SPAWN, GameState.run.hp)
	hud.room_text = "Sala %d/%d · %s" % [room_index + 1, GameState.ROOM_COUNT, TYPE_NAMES[room_kind]]
	hud.refresh()
	var checkpoint: Dictionary = GameState.run.get("room_checkpoint", {})
	if GameState.room_phase() != "fighting":
		_resolved = true
		var summary: Dictionary = checkpoint.get("summary", {})
		_bonus_earned = summary.get("bonus_earned", false)
		_wave_number = summary.get("wave", 0)
		_total_enemies = summary.get("total", 0)
		_defeated = summary.get("defeated", 0)
		_combat_elapsed = summary.get("elapsed", 0.0)
		_challenge_time = summary.get("time_limit", 0.0)
		if GameState.room_phase() == "reward":
			_spawn_professor()
		else:
			if room_kind == "shop":
				_spawn_merchant()
			open_door()
		return
	match room_kind:
		"shop":
			_spawn_merchant()
			open_door()
			GameState.checkpoint_room(player.hp, "cleared")
		"boss":
			hud.set_objective("Prova final", "Observe o aviso de cada ataque e responda na recuperação.")
			get_tree().create_timer(1.0, false).timeout.connect(_spawn_boss)
		_:
			_plan_waves()
			_next_wave()


func _process(delta: float) -> void:
	super(delta)
	if not _resolved and room_kind in ["combat", "teaching"] and not player.is_dead:
		_combat_elapsed += delta
		var second := ceili(maxf(0.0, _challenge_time - _combat_elapsed))
		if second != _hud_second:
			_update_objective()
	if door_open and not _leaving and player.global_position.y < 24.0:
		_leaving = true
		Coin.settle_all(self)
		GameState.run.special = player.special_meter.value
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
	if door_open:
		return
	door_open = true
	for c in get_children():
		if c is Coin:
			c.magnet_radius = 5000.0
	_gate.set_deferred(&"disabled", true)
	_bridge.visible = true
	MapBuilder.sign_label(self, "Próxima sala ▲", Vector2(DOOR_X, 92))
	if room_kind == "shop":
		hud.set_objective("Pausa no mercado", "Compre itens ou siga pela ponte ao norte.")
	else:
		var detail := "Ponte aberta ao norte · progresso salvo"
		if _bonus_earned:
			detail = "+%d Bits de ritmo · %s" % [encounter.challenge_bonus, detail]
		hud.set_objective("Sala concluída", detail, 1.0)


# --- Combate -------------------------------------------------------------------

func _plan_waves() -> void:
	_pending = EncounterDirector.plan(room_index, rng, GameState.ambush_chance())
	_total_enemies = _pending.size()
	_challenge_time = encounter.challenge_time(_total_enemies)
	if &"atletica" in _pending:
		GameState.notice.emit("Emboscada da %s! Faça missões para eles virarem aliados." % GameState.ATLETICA_NAME)
	else:
		GameState.notice.emit(encounter.tactic)
	_update_objective()


func _next_wave() -> void:
	if _resolved or player.is_dead or _announced > 0:
		return
	if _pending.is_empty():
		if _alive == 0:
			_on_cleared()
		return
	var count := EncounterDirector.reinforcement_count(_alive, _pending.size(), encounter)
	if count == 0:
		return
	_wave_number += 1
	var ids: Array[StringName] = []
	for i in count:
		ids.append(_pending.pop_front())
	_announce_wave(ids)


func _announce_wave(ids: Array[StringName]) -> void:
	var incoming: Array[Dictionary] = []
	var points: Array[Vector2] = []
	for id in ids:
		var pos := _spawn_point(points)
		if not pos.is_finite():
			if room_kind != "boss":
				_pending.push_front(id)
			continue
		points.append(pos)
		var marker := SpawnWarning.new()
		marker.tint = encounter.accent
		marker.duration = encounter.spawn_warning
		marker.position = pos
		add_child(marker)
		incoming.append({"id": id, "pos": pos, "marker": marker})
	_announced = incoming.size()
	if incoming.is_empty():
		if room_kind != "boss":
			get_tree().create_timer(encounter.spawn_warning, false).timeout.connect(_next_wave)
		return
	_update_objective()
	get_tree().create_timer(encounter.spawn_warning, false).timeout.connect(
		func() -> void: _deploy_wave(incoming))


func _deploy_wave(incoming: Array[Dictionary]) -> void:
	for entry in incoming:
		if is_instance_valid(entry.marker):
			entry.marker.queue_free()
		if not player.is_dead and not _resolved:
			spawn_enemy(ENEMIES[entry.id], entry.pos)
	_announced = 0
	_update_objective()


func spawn_enemy(data: EnemyData, pos: Vector2) -> Enemy:
	var e: Enemy = EnemyScene.instantiate()
	e.data = data
	e.hp_scale = 1.0 + encounter.hp_per_room * room_index
	e.died.connect(_on_enemy_died)
	add_child(e)
	e.global_position = pos
	Fx.spawn(self, "dust", pos, 1.5)
	_alive += 1
	return e


func _spawn_point(reserved: Array[Vector2] = []) -> Vector2:
	for attempt in 30:
		var pos := Vector2(rng.randf_range(AREA.position.x + 30, AREA.end.x - 30),
			rng.randf_range(AREA.position.y + 30, AREA.end.y - 30))
		if _valid_spawn(pos, reserved):
			return pos
	# Sorteio ruim nunca autoriza nascer dentro de obstáculo ou em cima do jogador.
	for y in range(int(AREA.position.y + 32), int(AREA.end.y - 16), 48):
		for x in range(int(AREA.position.x + 32), int(AREA.end.x - 16), 48):
			var pos := Vector2(x, y)
			if _valid_spawn(pos, reserved):
				return pos
	return Vector2.INF


func _valid_spawn(pos: Vector2, reserved: Array[Vector2]) -> bool:
	return pos.distance_to(player.global_position) > 260.0 and _free_spot(pos, 65.0) and not reserved.any(
		func(p: Vector2) -> bool: return p.distance_to(pos) < 75.0)


func _on_enemy_died(e: Enemy) -> void:
	_alive -= 1
	_defeated += 1
	Coin.drop(self, e.global_position, e.data.bits)
	if room_kind != "boss":
		_update_objective()
		# Deferred: o sinal died chega antes de notify_kill e do heal-on-kill do player.
		_next_wave.call_deferred()


func _on_cleared() -> void:
	if player.is_dead or _resolved:
		return
	_resolved = true
	GameAudio.play(self, &"clear")
	_bonus_earned = _combat_elapsed <= _challenge_time
	if _bonus_earned:
		Coin.drop(self, player.global_position, encounter.challenge_bonus)
		GameState.notice.emit("Ritmo excelente! +%d Bits de bônus." % encounter.challenge_bonus)
	Coin.settle_all(self)
	if room_kind == "teaching":
		GameState.checkpoint_room(player.hp, "reward", encounter_state(), player.special_meter.value)
		_spawn_professor()
		return
	Coin.drop(self, Vector2(DOOR_X, 300), 10 + 2 * room_index)
	Coin.settle_all(self)
	_give_relic(RELIC_CHANCE)
	GameState.checkpoint_room(player.hp, "cleared", encounter_state(), player.special_meter.value)
	open_door()


func encounter_state() -> Dictionary:
	return {"profile": String(encounter.id) if encounter else "", "wave": _wave_number,
		"alive": _alive, "incoming": _announced, "remaining": _alive + _announced + _pending.size(),
		"defeated": _defeated, "total": _total_enemies, "elapsed": _combat_elapsed,
		"time_limit": _challenge_time, "bonus_earned": _bonus_earned, "resolved": _resolved}


func _update_objective() -> void:
	if _resolved or room_kind not in ["combat", "teaching"]:
		return
	_hud_second = ceili(maxf(0.0, _challenge_time - _combat_elapsed))
	var detail := "%d/%d derrotados" % [_defeated, _total_enemies]
	if _announced > 0:
		detail += " · reforços chegando"
	if _hud_second > 0:
		detail += " · bônus +%d Bits: %ds" % [encounter.challenge_bonus, _hud_second]
	else:
		detail += " · elimine os restantes, sem pressa"
	var progress := float(_defeated) / maxi(_total_enemies, 1)
	hud.set_objective(encounter.display_name, detail, progress)


func _give_relic(chance: float) -> void:
	var r := GameState.roll_relic(chance)
	if r:
		Fx.spawn(self, "explosion", player.global_position, 0.6)
		GameState.notice.emit("Relíquia encontrada: %s! %s (permanente)" % [r.display_name, r.description])
		player.setup(GameState.stats(), player.hp)


# --- Recompensas e NPCs --------------------------------------------------------

func _spawn_professor() -> void:
	hud.set_objective("Ensinamento disponível", "Fale com o professor [E] e escolha sua melhoria.", 1.0)
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
	Coin.settle_all(self)
	GameState.checkpoint_room(player.hp, "cleared", encounter_state(), player.special_meter.value)
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
	boss.summon_requested.connect(_on_boss_summon)
	boss.died.connect(_on_boss_died)
	GameState.notice.emit("O Prof. Mainframe, chefe do CCT, quer te reprovar!")


func _on_boss_summon(count: int) -> void:
	if _resolved or player.is_dead or _announced > 0:
		return
	var ids: Array[StringName] = []
	for i in mini(count, maxi(0, encounter.max_active - _alive)):
		ids.append(&"bug")
	if not ids.is_empty():
		_announce_wave(ids)


func _on_boss_died(_boss: Boss) -> void:
	if player.is_dead:
		return
	_resolved = true
	player.is_invincible = true
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	for child in get_children():
		if child is Enemy or child is Projectile or child is SpawnWarning:
			child.set_physics_process(false)
			child.queue_free()
	_alive = 0
	hud.set_objective("Professor derrotado", "CCT conquistado!", 1.0)
	get_tree().create_timer(1.5, false).timeout.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	if player.is_dead:
		return
	_give_relic(1.0)
	Coin.settle_all(self)
	var result := GameState.end_run(true)
	open_modal()
	Screens.result(self, result)


func _on_player_died() -> void:
	get_tree().create_timer(1.2, false).timeout.connect(func() -> void:
		var result := GameState.end_run(false)
		open_modal()
		Screens.result(self, result))
