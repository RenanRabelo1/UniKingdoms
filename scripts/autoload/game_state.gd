extends Node
## Estado global: perfil (permanente), run atual, economia, reputação, missões, save e troca de cena.

signal enemy_killed(enemy: Node)
signal bits_changed
signal items_changed
## Aviso curto para o jogador (missão concluída, relíquia, emboscada...).
signal notice(text: String)

const ROOM_COUNT := 12
const SHOP_ROOMS := [4, 8]
const EXTRA_TEACHING_ROOMS := 2
const START_BITS := 50
const MISSION_REP := 25
const MISSION_BITS := 60
const ALLY_REP := 50
const AMBUSH_CHANCE := 0.25
const CAMPUS_ENCOUNTER_BITS := 8
const COLORS := ["Blue", "Yellow", "Purple", "Black"]
const COLOR_NAMES := {"Blue": "Azul", "Yellow": "Amarelo", "Purple": "Roxo", "Black": "Preto"}
## Itens usáveis na run, na ordem das teclas 1, 2 e 3.
const USABLE_ITEMS := ["marmita", "powerbank", "codigo_penal"]
const ATLETICA_NAME := "Atlética Engrenagem"

const SCENE_MENU := "res://scenes/ui/main_menu.tscn"
const SCENE_CAMPUS := "res://scenes/campus/campus.tscn"
const SCENE_ROOM := "res://scenes/run/room.tscn"

const TEACHINGS: Array[TeachingData] = [
	preload("res://data/teachings/laco_infinito.tres"), preload("res://data/teachings/recursao.tres"),
	preload("res://data/teachings/compilacao.tres"), preload("res://data/teachings/alta_tensao.tres"),
	preload("res://data/teachings/capacitor.tres"), preload("res://data/teachings/aterramento.tres"),
	preload("res://data/teachings/planta_baixa.tres"), preload("res://data/teachings/fundacao.tres"),
	preload("res://data/teachings/escala.tres"), preload("res://data/teachings/overclock.tres"),
	preload("res://data/teachings/coleta_lixo.tres"),
]
const ITEMS: Array[ItemData] = [
	preload("res://data/items/marmita.tres"), preload("res://data/items/powerbank.tres"),
	preload("res://data/items/codigo_penal.tres"), preload("res://data/items/jaleco.tres"),
]
const RELICS: Array[RelicData] = [
	preload("res://data/relics/patinho.tres"), preload("res://data/relics/martelo.tres"),
	preload("res://data/relics/machadinha.tres"), preload("res://data/relics/estilete.tres"),
	preload("res://data/relics/picareta.tres"), preload("res://data/relics/pepita.tres"),
]
const MISSIONS := [
	{"id": "caca_bugs", "text": "Caça aos Bugs: derrote 15 Bugs", "enemy": "bug", "goal": 15},
	{"id": "desmonte", "text": "Desmonte: derrote 8 Robôs", "enemy": "robo", "goal": 8},
	{"id": "fogos", "text": "Fogos de artifício: destrua 6 Barris", "enemy": "barril", "goal": 6},
	{"id": "maratona", "text": "Maratona: chegue à sala 7 de uma run", "room": 7, "goal": 1},
]

## Trocado pelos testes para não apagar o save do jogador.
var save_path := "user://save.dat"
var profile := {}
## Vazio quando não há run em andamento.
var run := {}
## Resumo da última run encerrada (mostrado na tela de resultado).
var last_result := {}
## Último ponto seguro da run. Saves de missão não promovem loot de combate incompleto.
var _checkpoint_run: Dictionary = {}
var _checkpoint_stash: Dictionary = {}
var _checkpoint_path := ""


func _ready() -> void:
	randomize()
	# Controles dentro de CanvasLayer não herdam o tema da janela; o tema padrão vale para todos.
	ThemeDB.get_default_theme().merge_with(UI.theme())
	get_tree().root.theme = UI.theme()
	DisplayServer.window_set_title("Reinos da Unifor")
	if not load_game():
		profile = default_profile()


static func default_profile(color := "Blue") -> Dictionary:
	return {
		"color": color, "bits": START_BITS, "stash": {}, "relics": [], "unlocked": [],
		"cct_conquered": false, "reputation": 0, "mission": {}, "last_mission": "",
		"missions_done": 0, "runs": 0, "wins": 0, "deaths": 0,
		# Encontros do campus já vencidos; voltam a aparecer quando uma run termina (sem farm).
		"campus_cleared": [],
	}


func new_game(color: String) -> void:
	profile = default_profile(color)
	run = {}
	save_game()


func is_campus_cleared(id: String) -> bool:
	return id in profile.campus_cleared


## Encontro do campus vencido: paga no banco uma vez até a próxima run terminar.
func clear_campus_encounter(id: String) -> void:
	if is_campus_cleared(id):
		return
	profile.campus_cleared.append(id)
	profile.bits += CAMPUS_ENCOUNTER_BITS
	save_game()
	bits_changed.emit()


func has_run() -> bool:
	return not run.is_empty()


# --- Run ---------------------------------------------------------------------

func start_run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	run = {"room": 0, "plan": make_plan(rng), "hp": -1, "bits": 0, "teachings": [],
		"extra": {}, "items": {}, "kills": 0, "special": 0.0,
		"seed": rng.randi(), "room_checkpoint": {}}
	if take_from_stash("jaleco"):
		_add_extra(&"max_hp", item("jaleco").amount)
		notice.emit("Você vestiu o Jaleco: +%d de vida máxima nesta run." % item("jaleco").amount)
	profile.runs += 1
	_remember_checkpoint()
	_check_room_mission()
	save_game()


## 12 salas: ensinamento na primeira, mercados fixos, 2 ensinamentos sorteados e boss no fim.
static func make_plan(rng: RandomNumberGenerator) -> Array:
	var plan := []
	plan.resize(ROOM_COUNT)
	plan.fill("combat")
	plan[0] = "teaching"
	plan[ROOM_COUNT - 1] = "boss"
	for i in SHOP_ROOMS:
		plan[i] = "shop"
	var free := range(1, ROOM_COUNT - 1).filter(func(i: int) -> bool: return plan[i] == "combat")
	for k in EXTRA_TEACHING_ROOMS:
		plan[free.pop_at(rng.randi_range(0, free.size() - 1))] = "teaching"
	return plan


func room_type() -> String:
	return run.plan[run.room]


func advance_room(hp: int) -> void:
	run.hp = hp
	run.room += 1
	run.room_checkpoint = {}
	_remember_checkpoint()
	_check_room_mission()
	save_game()


## O combate retoma do início; sala vencida retoma na recompensa ou na ponte aberta.
func room_phase() -> String:
	var checkpoint: Dictionary = run.get("room_checkpoint", {})
	if checkpoint.get("room", -1) != run.get("room", -2):
		return "fighting"
	return checkpoint.get("phase", "fighting")


func checkpoint_room(hp: int, phase: String, summary: Dictionary = {}, special := -1.0) -> void:
	if not has_run() or phase not in ["reward", "cleared"]:
		return
	run.hp = hp
	if special >= 0.0:
		run.special = clampf(special, 0.0, SpecialMeter.MAX)
	run.room_checkpoint = {"room": run.room, "phase": phase, "summary": summary.duplicate(true)}
	save_game()


## Após consumir um item em sala já vencida, salva efeito e consumo na mesma transação.
func sync_room_player(hp: int, special := -1.0) -> void:
	var phase := room_phase()
	if phase == "fighting":
		return
	checkpoint_room(hp, phase, run.room_checkpoint.get("summary", {}), special)


## Encerra a run. Morte perde os Bits da run; vitória guarda os Bits e conquista o CCT.
func end_run(victory: bool) -> Dictionary:
	var result := {"victory": victory, "room": run.room + 1, "bits": run.bits, "kills": run.kills,
		"unlocked": []}
	if victory:
		profile.bits += run.bits
		profile.wins += 1
		if not profile.cct_conquered:
			profile.cct_conquered = true
			for t in TEACHINGS:
				if t.locked:
					profile.unlocked.append(String(t.id))
					result.unlocked.append(t.display_name)
	else:
		profile.deaths += 1
	run = {}
	profile.campus_cleared = []
	last_result = result
	save_game()
	bits_changed.emit()
	return result


## Bônus somados de relíquias, ensinamentos e extras da run (Jaleco, mercado).
func stats() -> Dictionary:
	var s := {}
	for id in profile.relics:
		var r := relic(id)
		if r:
			s[r.stat] = s.get(r.stat, 0.0) + r.amount
	if has_run():
		for id in run.teachings:
			var t := teaching(id)
			s[t.stat] = s.get(t.stat, 0.0) + t.amount
		for k in run.extra:
			s[k] = s.get(k, 0.0) + run.extra[k]
	return s


func _add_extra(stat_key: StringName, amount: float) -> void:
	run.extra[stat_key] = run.extra.get(stat_key, 0.0) + amount


# --- Ensinamentos ------------------------------------------------------------

func offer_teachings(count := 3) -> Array:
	var taken: Array = run.get("teachings", [])
	var pool := TEACHINGS.filter(func(t: TeachingData) -> bool:
		return not String(t.id) in taken and (not t.locked or String(t.id) in profile.unlocked))
	pool.shuffle()
	return pool.slice(0, count)


func take_teaching(t: TeachingData) -> void:
	if has_run() and not String(t.id) in run.teachings:
		run.teachings.append(String(t.id))


func teaching(id: String) -> TeachingData:
	for t in TEACHINGS:
		if String(t.id) == id:
			return t
	return null


# --- Bits, mercado e itens ---------------------------------------------------

## Bits na mão agora: os da run durante a run, os do banco fora dela.
func wallet() -> int:
	return run.bits if has_run() else profile.bits


func add_bits(amount: int) -> int:
	var gain := roundi(amount * (1.0 + stats().get(&"bits_gain", 0.0)))
	if has_run():
		run.bits += gain
	else:
		profile.bits += gain
	bits_changed.emit()
	return gain


## Desconto do mercado da atlética: 0.4% por ponto de reputação (até 40%).
func discount() -> float:
	return clampf(profile.reputation, 0.0, 100.0) * 0.004


## market: "cct" (campus), "atletica" (campus, com desconto) ou "run" (sala de mercado).
func price(it: ItemData, market: String) -> int:
	return roundi(it.price * (1.0 - discount())) if market == "atletica" else it.price


func buy(it: ItemData, market: String) -> bool:
	var cost := price(it, market)
	var id := String(it.id)
	if market == "run":
		if run.bits < cost:
			return false
		run.bits -= cost
		if it.effect == "max_hp":
			_add_extra(&"max_hp", it.amount)
		else:
			run.items[id] = run.items.get(id, 0) + 1
	else:
		if profile.bits < cost:
			return false
		profile.bits -= cost
		profile.stash[id] = profile.stash.get(id, 0) + 1
	bits_changed.emit()
	items_changed.emit()
	save_game()
	return true


func item(id: String) -> ItemData:
	for it in ITEMS:
		if String(it.id) == id:
			return it
	return null


func item_count(id: String) -> int:
	var n: int = profile.stash.get(id, 0)
	if has_run():
		n += run.items.get(id, 0)
	return n


## Gasta primeiro o que foi comprado na run, depois o estoque permanente.
func consume_item(id: String) -> bool:
	if has_run() and run.items.get(id, 0) > 0:
		run.items[id] -= 1
	elif not take_from_stash(id):
		return false
	items_changed.emit()
	return true


func take_from_stash(id: String) -> bool:
	if profile.stash.get(id, 0) <= 0:
		return false
	profile.stash[id] -= 1
	return true


# --- Relíquias ---------------------------------------------------------------

## Sorteia uma relíquia ainda não obtida. Ela vira permanente na hora.
func roll_relic(chance: float) -> RelicData:
	var missing := RELICS.filter(func(r: RelicData) -> bool: return not String(r.id) in profile.relics)
	if missing.is_empty() or randf() >= chance:
		return null
	var r: RelicData = missing.pick_random()
	profile.relics.append(String(r.id))
	save_game(true)
	return r


func relic(id: String) -> RelicData:
	for r in RELICS:
		if String(r.id) == id:
			return r
	return null


# --- Atlética: reputação e missões -------------------------------------------

func is_ally() -> bool:
	return profile.reputation >= ALLY_REP


func ambush_chance() -> float:
	return 0.0 if is_ally() else AMBUSH_CHANCE


func accept_mission() -> Dictionary:
	if profile.mission.is_empty():
		var options := MISSIONS.filter(func(m: Dictionary) -> bool: return m.id != profile.last_mission)
		profile.mission = options.pick_random().duplicate()
		profile.mission.progress = 0
		save_game()
	return profile.mission


func notify_kill(enemy: Node) -> void:
	enemy_killed.emit(enemy)
	if has_run():
		run.kills += 1
	var data = enemy.get("data")
	var m: Dictionary = profile.mission
	if data is EnemyData and m.get("enemy", "") == String(data.id):
		m.progress += 1
		if m.progress >= m.goal:
			_complete_mission()


func _check_room_mission() -> void:
	var m: Dictionary = profile.mission
	if m.has("room") and has_run() and run.room + 1 >= m.room:
		_complete_mission()


func _complete_mission() -> void:
	profile.reputation += MISSION_REP
	profile.bits += MISSION_BITS
	profile.missions_done += 1
	profile.last_mission = profile.mission.id
	profile.mission = {}
	notice.emit("Missão da %s concluída! +%d de reputação e +%d Bits no banco." % [ATLETICA_NAME, MISSION_REP, MISSION_BITS])
	bits_changed.emit()
	save_game(true)


# --- Save e cenas --------------------------------------------------------------

func save_game(preserve_combat_checkpoint := false) -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_error("Não foi possível salvar em %s (%s)" % [save_path, FileAccess.get_open_error()])
		return
	var resume_run: Dictionary = run
	var resume_profile: Dictionary = profile
	var preserve: bool = preserve_combat_checkpoint and has_run() and room_phase() == "fighting" \
		and _checkpoint_path == save_path and _checkpoint_run.get("room", -1) == run.room \
		and _checkpoint_run.get("seed", -1) == run.get("seed", -2)
	if preserve:
		resume_run = _checkpoint_run
		resume_profile = profile.duplicate(true)
		# Repetir a sala também devolve o consumível gasto nela; prêmios da missão são permanentes.
		resume_profile.stash = _checkpoint_stash.duplicate(true)
	f.store_var({"version": 2, "profile": resume_profile, "run": resume_run})
	if not preserve:
		_remember_checkpoint()


func _remember_checkpoint() -> void:
	_checkpoint_run = run.duplicate(true)
	_checkpoint_stash = profile.get("stash", {}).duplicate(true)
	_checkpoint_path = save_path


func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var f := FileAccess.open(save_path, FileAccess.READ)
	var data = f.get_var() if f else null
	if not data is Dictionary or not data.has("profile"):
		return false
	profile = default_profile()
	profile.merge(data.profile, true)
	run = data.get("run", {})
	if has_run():
		# Saves v1 não tinham checkpoints nem semente; continuam no início da sala salva.
		if not run.has("room_checkpoint"):
			run.room_checkpoint = {}
		if not run.has("seed"):
			run.seed = 0
		if not run.has("special"):
			run.special = 0.0
	_remember_checkpoint()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func go(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(scene_path)


func continue_game() -> void:
	go(SCENE_ROOM if has_run() else SCENE_CAMPUS)


func state_to_text() -> String:
	var snapshot := {"profile": profile, "run": run}
	var scene := get_tree().current_scene
	if is_instance_valid(scene) and scene.has_method("encounter_state"):
		snapshot.encounter = scene.encounter_state()
	return JSON.stringify(snapshot)
