extends GutTest

const PlayerScene := preload("res://scenes/player/player.tscn")
const DummyScene := preload("res://scenes/enemies/training_dummy.tscn")

var player: Player
var weapon: WeaponData


func before_each():
	player = PlayerScene.instantiate()
	add_child_autofree(player)
	player.global_position = Vector2(500, 300)
	player.aim_direction = Vector2.RIGHT
	weapon = player.weapon


func _dummy_at(pos: Vector2) -> TrainingDummy:
	var dummy: TrainingDummy = DummyScene.instantiate()
	add_child_autofree(dummy)
	dummy.global_position = pos
	return dummy


func test_basic_attack_hits_target_in_aim_direction():
	var front := _dummy_at(player.global_position + Vector2(weapon.reach, 0))
	var behind := _dummy_at(player.global_position - Vector2(weapon.reach, 0))
	await wait_physics_frames(2)
	player.attack(&"basic")
	assert_eq(front.last_damage, weapon.basic_damage)
	assert_eq(behind.last_damage, 0)


func test_heavy_attack_uses_heavy_damage():
	var front := _dummy_at(player.global_position + Vector2(weapon.reach, 0))
	await wait_physics_frames(2)
	player.attack(&"heavy")
	assert_eq(front.last_damage, weapon.heavy_damage)


func test_attack_respects_cooldown():
	var front := _dummy_at(player.global_position + Vector2(weapon.reach, 0))
	await wait_physics_frames(2)
	assert_true(player.attack(&"basic"))
	assert_false(player.attack(&"basic"), "segundo golpe imediato deve ser ignorado")
	assert_eq(front.hits, 1)


func test_combo_finisher_applies_multiplier():
	var front := _dummy_at(player.global_position + Vector2(weapon.reach, 0))
	await wait_physics_frames(2)
	player.attack(&"basic")
	await wait_seconds(weapon.basic_cooldown + 0.05)
	player.attack(&"basic")
	await wait_seconds(weapon.basic_cooldown + 0.05)
	player.attack(&"heavy")
	var combo: ComboData = load("res://data/combos/combo_bbp.tres")
	assert_eq(front.last_damage, roundi(weapon.heavy_damage * combo.damage_multiplier))
	assert_eq(front.last_source, combo.display_name)


func test_dash_moves_fast_with_iframes_and_cooldown():
	var start := player.global_position
	assert_true(player.dash())
	assert_true(player.is_invincible)
	assert_false(player.dash(), "dash em recarga")
	await wait_seconds(Constants.DASH_DURATION + 0.05)
	assert_false(player.is_invincible)
	assert_gt(player.global_position.x - start.x, Constants.PLAYER_SPEED * Constants.DASH_DURATION,
		"dash deve ir mais longe que andar no mesmo tempo")
	await wait_seconds(Constants.DASH_COOLDOWN)
	assert_true(player.dash())


func test_special_needs_full_meter_and_hits_area():
	var near := _dummy_at(player.global_position + Vector2(0, Constants.SPECIAL_RADIUS * 0.5))
	var far := _dummy_at(player.global_position + Vector2(0, Constants.SPECIAL_RADIUS * 2))
	await wait_physics_frames(2)
	assert_false(player.use_special())
	player.special_meter.add_damage(SpecialMeter.MAX)
	assert_true(player.use_special())
	assert_eq(near.last_damage, Constants.SPECIAL_DAMAGE)
	assert_eq(far.last_damage, 0)
	assert_eq(player.special_meter.value, 0.0)


## Coloca o boneco com o centro da hurtbox a `dist` px do corpo do player, na direção `dir`.
func _dummy_body_at(dir: Vector2, dist: float) -> TrainingDummy:
	var dummy := _dummy_at(Vector2.ZERO)
	var hb_center: Vector2 = (dummy.get_node(^"Hurtbox") as Hurtbox).center
	dummy.global_position = player.body_center() + dir * dist - hb_center
	return dummy


## Distância horizontal máxima (corpo do player → centro da hurtbox do boneco) em que o golpe encosta.
func _max_contact() -> float:
	return weapon.reach + weapon.hit_radius + 30.0


func test_hits_in_all_eight_directions_and_not_behind():
	for i in 8:
		var dir := Vector2.RIGHT.rotated(TAU * i / 8.0)
		var front := _dummy_body_at(dir, 70.0)
		var behind := _dummy_body_at(-dir, 70.0)
		await wait_physics_frames(2)
		player.aim_direction = dir
		await wait_seconds(weapon.basic_cooldown + 0.05)
		assert_true(player.attack(&"basic"))
		assert_eq(front.hits, 1, "acerta na direção %d" % i)
		assert_eq(behind.hits, 0, "não acerta atrás na direção %d" % i)
		front.free()
		behind.free()
		# Espera o golpe acabar antes de pôr os próximos bonecos (senão o arco atual os pega).
		await wait_seconds(Constants.SWING_ACTIVE_TIME + 0.05)


func test_reach_edge_matches_capsule():
	var inside := _dummy_body_at(Vector2.RIGHT, _max_contact() - 6.0)
	var outside := _dummy_body_at(Vector2.LEFT, _max_contact() + 6.0)
	await wait_physics_frames(2)
	player.attack(&"basic")
	assert_eq(inside.hits, 1, "na borda do alcance, acerta")
	player.aim_direction = Vector2.LEFT
	await wait_seconds(weapon.basic_cooldown + 0.05)
	player.attack(&"basic")
	assert_eq(outside.hits, 0, "um pouco além do alcance, não acerta")


func test_target_entering_during_active_window_is_hit_once():
	var dummy := _dummy_body_at(Vector2.RIGHT, _max_contact() + 40.0)
	await wait_physics_frames(2)
	player.attack(&"basic")
	assert_eq(dummy.hits, 0, "fora do alcance no clique")
	await wait_seconds(Constants.SWING_ACTIVE_TIME * 0.4)
	dummy.global_position.x -= 80.0
	await wait_seconds(Constants.SWING_ACTIVE_TIME)
	assert_eq(dummy.hits, 1, "entrou no arco enquanto a espada passava: um acerto só")


func test_one_swing_never_hits_the_same_target_twice():
	var dummy := _dummy_body_at(Vector2.RIGHT, 60.0)
	await wait_physics_frames(2)
	player.attack(&"heavy")
	await wait_seconds(Constants.SWING_ACTIVE_TIME + 0.1)
	assert_eq(dummy.hits, 1)


func test_swing_ends_after_active_window():
	var dummy := _dummy_body_at(Vector2.RIGHT, _max_contact() + 40.0)
	await wait_physics_frames(2)
	player.attack(&"basic")
	await wait_seconds(Constants.SWING_ACTIVE_TIME + 0.05)
	dummy.global_position.x -= 80.0
	await wait_physics_frames(3)
	assert_eq(dummy.hits, 0, "depois da janela ativa, o golpe acabou")


func test_swing_follows_the_player_while_moving():
	var dummy := _dummy_body_at(Vector2.RIGHT, _max_contact() + 30.0)
	await wait_physics_frames(2)
	player.attack(&"basic")
	assert_eq(dummy.hits, 0, "fora do alcance no clique")
	player.global_position.x += 50.0
	await wait_physics_frames(3)
	assert_eq(dummy.hits, 1, "o arco acompanha o player que avança durante o golpe")
