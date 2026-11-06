extends GutTest
## Regressões do ritmo: comandos, cancelamento da recuperação e tempo de simulação.

const PlayerScene := preload("res://scenes/player/player.tscn")
const DummyScene := preload("res://scenes/enemies/training_dummy.tscn")

var player: Player


func before_each():
	player = PlayerScene.instantiate()
	add_child_autofree(player)
	player.global_position = Vector2(500, 300)
	player.aim_direction = Vector2.RIGHT


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	player._unhandled_input(event)


func _dummy(offset := Vector2(70, 0)) -> TrainingDummy:
	var dummy: TrainingDummy = DummyScene.instantiate()
	add_child_autofree(dummy)
	dummy.global_position = player.global_position + offset
	return dummy


func test_click_near_end_of_cooldown_runs_once():
	var dummy := _dummy()
	await wait_physics_frames(2)
	player.attack(&"basic")
	await wait_seconds(0.16)
	_press(&"attack_heavy")
	await wait_seconds(0.4)
	assert_eq(dummy.hits, 2, "clique antecipado não some nem dispara duas vezes")
	assert_eq(dummy.last_damage, player.weapon.heavy_damage)


func test_expired_click_does_not_fire_later():
	var dummy := _dummy()
	await wait_physics_frames(2)
	player.attack(&"heavy")
	_press(&"attack_basic")
	await wait_seconds(player.weapon.heavy_cooldown + 0.2)
	assert_eq(dummy.hits, 1, "não armazena ataques por toda a recuperação")


func test_latest_buffered_attack_replaces_previous_intent():
	var dummy := _dummy()
	await wait_physics_frames(2)
	player.attack(&"basic")
	await wait_seconds(0.16)
	_press(&"attack_basic")
	_press(&"attack_heavy")
	await wait_seconds(0.4)
	assert_eq(dummy.hits, 2, "uma intenção ofensiva de cada vez")
	assert_eq(dummy.last_damage, player.weapon.heavy_damage, "último clique define o próximo golpe")


func test_dash_cancels_heavy_recovery():
	player.attack(&"heavy")
	assert_true(player.dash())
	await wait_seconds(Constants.DASH_DURATION + 0.04)
	assert_true(player.attack(&"basic"), "pode voltar a atacar ao terminar a esquiva")


func test_dash_ends_previous_swing():
	var dummy := _dummy(Vector2(240, 0))
	await wait_physics_frames(2)
	player.attack(&"heavy")
	assert_eq(dummy.hits, 0)
	player.dash()
	await wait_seconds(Constants.DASH_DURATION + 0.1)
	assert_eq(dummy.hits, 0, "dash não arrasta a cápsula do golpe antigo")


func test_attack_cannot_start_during_dash():
	player.dash()
	assert_false(player.attack(&"basic"), "golpe aguardará o fim do dash")


func test_dash_strike_is_consumed_by_first_attack():
	player.dash()
	await wait_seconds(Constants.DASH_DURATION + 0.03)
	var dummy := _dummy()
	await wait_physics_frames(2)
	player.attack(&"basic")
	assert_eq(dummy.last_damage, roundi(player.weapon.basic_damage * Constants.DASH_STRIKE_DAMAGE_MULTIPLIER))
	await wait_seconds(player.weapon.basic_cooldown + 0.04)
	player.attack(&"basic")
	assert_eq(dummy.last_damage, player.weapon.basic_damage, "avanço fortalece só um golpe")


func test_dash_strike_expires():
	player.dash()
	await wait_seconds(Constants.DASH_DURATION + Constants.DASH_STRIKE_WINDOW + 0.05)
	var dummy := _dummy()
	await wait_physics_frames(2)
	player.attack(&"basic")
	assert_eq(dummy.last_damage, player.weapon.basic_damage)


func test_combat_cooldown_does_not_advance_when_simulation_is_stopped():
	player.attack(&"heavy")
	player.set_physics_process(false)
	await wait_seconds(player.weapon.heavy_cooldown + 0.1)
	assert_false(player.attack(&"basic"), "pausa não adianta a recarga do ataque")
	player.set_physics_process(true)
	await wait_seconds(player.weapon.heavy_cooldown + 0.05)
	assert_true(player.attack(&"basic"))


func test_large_attack_speed_bonus_never_removes_cooldown():
	player.setup({&"attack_speed": 2.0})
	assert_true(player.attack(&"basic"))
	assert_false(player.attack(&"basic"), "bônus acumulados não permitem ataques infinitos no mesmo frame")


func test_invalid_attack_kind_does_not_start_a_swing():
	assert_false(player.attack(&"unknown"))
	assert_true(player.attack(&"basic"))


func test_attack_buffered_during_dash_executes_when_it_ends():
	player.dash()
	_press(&"attack_heavy")
	var dummy := _dummy(Vector2(190, 0))
	await wait_seconds(Constants.DASH_DURATION + 0.08)
	assert_eq(dummy.hits, 1)
	assert_eq(dummy.last_damage, roundi(player.weapon.heavy_damage * Constants.DASH_STRIKE_DAMAGE_MULTIPLIER))


func test_dash_has_priority_over_attack_queued_in_same_frame():
	var dummy := _dummy()
	await wait_physics_frames(2)
	_press(&"attack_heavy")
	_press(&"dash")
	await wait_physics_frames(1)
	assert_true(player.is_invincible)
	assert_eq(dummy.hits, 0, "não gasta o ataque na posição antiga antes de esquivar")


func test_combat_status_reports_recovery_and_combo():
	assert_true(player.combat_status().dash_ready)
	player.attack(&"basic")
	assert_eq(player.combat_status().combo.steps, 1)
	player.dash()
	assert_false(player.combat_status().dash_ready)
	assert_almost_eq(player.combat_status().dash_ratio, 0.0, 0.001)
	assert_false(player.combat_status().dash_strike_ready)
	await wait_seconds(Constants.DASH_DURATION + 0.04)
	assert_true(player.combat_status().dash_strike_ready)
	await wait_seconds(Constants.DASH_COOLDOWN)
	assert_true(player.combat_status().dash_ready)
	assert_false(player.combat_status().dash_strike_ready)
