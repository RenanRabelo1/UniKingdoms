extends GutTest
## Ritmo das ondas e checkpoints com cenas reais e save isolado no projeto.

const RoomScene := preload("res://scenes/run/room.tscn")
const TEST_SAVE := "res://tests/.pacing-save.dat"

var _saved_profile: Dictionary
var _saved_run: Dictionary
var _saved_path: String


func before_all() -> void:
	_saved_profile = GameState.profile.duplicate(true)
	_saved_run = GameState.run.duplicate(true)
	_saved_path = GameState.save_path


func before_each() -> void:
	GameState.save_path = TEST_SAVE
	GameState.profile = GameState.default_profile()
	GameState.profile.reputation = GameState.ALLY_REP
	GameState.run = {}


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	GameState.profile = _saved_profile
	GameState.run = _saved_run
	GameState.save_path = _saved_path


func _room(index: int, kind := "combat") -> Node:
	GameState.start_run()
	GameState.run.room = index
	GameState.run.plan[index] = kind
	var room := RoomScene.instantiate()
	add_child_autofree(room)
	room.player.is_invincible = true
	return room


func _enemies(room: Node) -> Array:
	return room.get_children().filter(func(n: Node) -> bool: return n is Enemy and n.hp > 0)


func _clear(room: Node) -> void:
	for i in 30:
		await wait_seconds(0.15)
		for e in _enemies(room):
			e.take_damage(9999)
		if room.door_open or get_tree().get_nodes_in_group(&"interactable").any(
			func(n: Node) -> bool: return n.prompt == "Falar com o professor"):
			return


func test_spawn_is_announced_before_enemies_appear() -> void:
	var room := _room(1)
	await wait_physics_frames(2)
	assert_eq(_enemies(room).size(), 0)
	assert_gt(get_tree().get_nodes_in_group(&"spawn_warning").size(), 0,
		"a primeira onda marca o chão antes de causar dano")
	await wait_seconds(0.85)
	assert_eq(_enemies(room).size(), 4)


func test_reinforcements_arrive_before_the_last_enemy_dies_without_exceeding_cap() -> void:
	var room := _room(7)
	await wait_seconds(0.9)
	var first_wave := _enemies(room)
	assert_eq(first_wave.size(), 6)
	for i in first_wave.size() - 1:
		first_wave[i].take_damage(9999)
	await wait_seconds(0.85)
	var alive := _enemies(room).size()
	assert_gt(alive, 1, "não exige caçar o último inimigo para manter pressão")
	assert_lte(alive, 6, "reforços respeitam o limite incluindo sobreviventes")


func test_cleared_room_restores_without_replaying_enemies_or_rewards() -> void:
	var room := _room(1)
	await _clear(room)
	assert_true(room.door_open)
	var earned: int = GameState.run.bits
	assert_gt(earned, 0, "moedas pendentes entram no checkpoint")
	room.queue_free()
	await wait_physics_frames(2)
	assert_true(GameState.load_game())
	var restored := RoomScene.instantiate()
	add_child_autofree(restored)
	await wait_seconds(1.0)
	assert_true(restored.door_open, "Continuar reabre a sala já vencida")
	assert_eq(_enemies(restored).size(), 0)
	assert_eq(GameState.run.bits, earned, "restaurar não repete recompensa")


func test_teaching_checkpoint_restores_professor_then_keeps_choice() -> void:
	var room := _room(0, "teaching")
	await _clear(room)
	room.queue_free()
	await wait_physics_frames(2)
	assert_true(GameState.load_game())
	var restored := RoomScene.instantiate()
	add_child_autofree(restored)
	await wait_physics_frames(2)
	var teachers := get_tree().get_nodes_in_group(&"interactable").filter(
		func(n: Node) -> bool: return n.prompt == "Falar com o professor")
	assert_eq(teachers.size(), 1, "recompensa pendente reaparece sem repetir combate")
	if teachers.is_empty():
		return
	restored.apply_teaching(GameState.offer_teachings(1)[0])
	restored._finish_professor(teachers[0])
	var choice: String = GameState.run.teachings[0]
	restored.queue_free()
	await wait_physics_frames(2)
	assert_true(GameState.load_game())
	var completed := RoomScene.instantiate()
	add_child_autofree(completed)
	await wait_physics_frames(2)
	assert_true(completed.door_open)
	assert_eq(GameState.run.teachings, [choice])
	assert_eq(get_tree().get_nodes_in_group(&"interactable").size(), 0)


func test_missing_time_bonus_never_blocks_the_exit() -> void:
	var room := _room(1)
	assert_true(room.has_method("encounter_state"), "encontro expõe objetivo/tempo verificável")
	if not room.has_method("encounter_state"):
		return
	room.set("_combat_elapsed", 9999.0)
	await _clear(room)
	assert_true(room.door_open)
	var state: Dictionary = room.call("encounter_state")
	assert_false(state.bonus_earned)
	assert_eq(state.remaining, 0)


func test_coin_credit_is_idempotent_and_keeps_visual_flight() -> void:
	GameState.start_run()
	var coin := Coin.new()
	coin.value = 9
	add_child_autofree(coin)
	assert_true(coin.has_method("credit"), "crédito separado do voo permite checkpoint seguro")
	if not coin.has_method("credit"):
		return
	coin.call("credit")
	coin.call("credit")
	assert_eq(GameState.run.bits, 9)
	assert_false(coin.is_queued_for_deletion(), "animação pode continuar após crédito")


func test_boss_summons_are_announced_and_share_the_enemy_cap() -> void:
	var room := _room(11, "boss")
	await wait_seconds(1.1)
	var boss: Boss = room.get_children().filter(func(n: Node) -> bool: return n is Boss)[0]
	boss.summon_requested.emit(10)
	assert_eq(_enemies(room).size(), 0, "reforços do chefe também avisam antes de nascer")
	assert_gt(get_tree().get_nodes_in_group(&"spawn_warning").size(), 0)
	await wait_seconds(0.75)
	assert_eq(_enemies(room).size(), 6)
	boss.summon_requested.emit(3)
	await wait_seconds(0.75)
	assert_eq(_enemies(room).size(), 6, "não acumula uma multidão durante o chefe")


func test_heal_in_shop_survives_purchase_and_reload() -> void:
	var room := _room(4, "shop")
	room.player.hp = 50
	GameState.run.items = {"marmita": 1}
	GameState.run.bits = 100
	GameState.checkpoint_room(50, "cleared")
	room.use_item(0)
	assert_eq(room.player.hp, 90)
	assert_true(GameState.buy(GameState.item("powerbank"), "run"))
	assert_true(GameState.load_game())
	assert_eq(GameState.run.hp, 90, "compra não grava vida antiga depois de consumir cura")
	assert_eq(GameState.item_count("marmita"), 0)
	assert_eq(GameState.item_count("powerbank"), 1)


func test_boss_death_cancels_hazards_and_pending_summons() -> void:
	var room := _room(11, "boss")
	await wait_seconds(1.1)
	var boss: Boss = room.get_children().filter(func(n: Node) -> bool: return n is Boss)[0]
	var projectile: Projectile = load("res://scenes/actors/projectile.tscn").instantiate()
	projectile.position = room.player.position + Vector2(100, 0)
	projectile.velocity = Vector2(-500, 0)
	projectile.damage = 9999
	room.add_child(projectile)
	room.player.is_invincible = false
	boss.summon_requested.emit(3)
	boss.take_damage(9999)
	await wait_seconds(0.8)
	assert_false(room.player.is_dead, "vitória já conquistada não é roubada na animação final")
	assert_eq(_enemies(room).size(), 0)
	assert_eq(room.get_children().filter(func(n: Node) -> bool: return n is Projectile).size(), 0)
	assert_eq(get_tree().get_nodes_in_group(&"spawn_warning").size(), 0)
	room.queue_free()
	await wait_physics_frames(2)


func test_powerbank_in_cleared_room_keeps_charge_and_consumption() -> void:
	var room := _room(4, "shop")
	GameState.run.items = {"powerbank": 1}
	room.player.special_meter.value = 0.0
	room.use_item(1)
	assert_true(GameState.load_game())
	assert_almost_eq(GameState.run.special, 50.0, 0.01)
	assert_eq(GameState.item_count("powerbank"), 0)


func test_no_spawn_position_is_returned_when_every_point_is_blocked() -> void:
	var room := _room(4, "shop")
	for y in range(80, 600, 40):
		for x in range(80, 1100, 40):
			room._obstacles.append(Vector2(x, y))
	assert_false(room._spawn_point().is_finite(), "nenhum ponto livre: adia, nunca nasce preso")
