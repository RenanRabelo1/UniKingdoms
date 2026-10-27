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
