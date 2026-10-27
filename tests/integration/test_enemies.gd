extends GutTest

const PlayerScene := preload("res://scenes/player/player.tscn")
const EnemyScene := preload("res://scenes/actors/enemy.tscn")

var player: Player


func before_each():
	player = PlayerScene.instantiate()
	add_child_autofree(player)
	player.global_position = Vector2(500, 300)


func _enemy(id: String, offset: Vector2) -> Enemy:
	var e: Enemy = EnemyScene.instantiate()
	e.data = load("res://data/enemies/%s.tres" % id)
	add_child_autofree(e)
	e.global_position = player.global_position + offset
	return e


# B1
func test_player_damage_iframes_and_death():
	watch_signals(player)
	assert_true(player.take_damage(30))
	assert_eq(player.hp, Constants.PLAYER_MAX_HP - 30)
	assert_false(player.take_damage(30), "invencível logo depois do golpe")
	await wait_seconds(Constants.HURT_IFRAMES + 0.05)
	player.dash()
	assert_false(player.take_damage(30), "invencível durante o dash")
	await wait_seconds(Constants.DASH_DURATION + 0.05)
	assert_true(player.take_damage(500))
	assert_eq(player.hp, 0)
	assert_true(player.is_dead)
	assert_signal_emitted(player, "died")


func test_setup_applies_max_hp_bonus_and_heal_caps():
	player.setup({&"max_hp": 25.0})
	assert_eq(player.max_hp, Constants.PLAYER_MAX_HP + 25)
	player.take_damage(40)
	player.heal(1000)
	assert_eq(player.hp, player.max_hp)


# B2
func test_enemy_takes_player_hits_and_dies():
	var bug := _enemy("bug", Vector2(player.weapon.reach, 0))
	watch_signals(bug)
	await wait_physics_frames(2)
	player.aim_direction = Vector2.RIGHT
	player.attack(&"heavy")
	assert_eq(bug.hp, bug.data.max_hp - player.weapon.heavy_damage)
	bug.take_damage(1000)
	assert_signal_emitted(bug, "died")
	await wait_physics_frames(1)
	assert_false(is_instance_valid(bug))


# B3
func test_bug_chases_and_hits_on_contact():
	var bug := _enemy("bug", Vector2(220, 0))
	await wait_seconds(0.5)
	assert_lt(bug.global_position.distance_to(player.global_position), 200.0, "Bug se aproximou")
	await wait_seconds(1.5)
	assert_lt(player.hp, Constants.PLAYER_MAX_HP, "Bug causou dano de perto")
	assert_eq((Constants.PLAYER_MAX_HP - player.hp) % bug.data.damage, 0)


# B4
func test_robo_keeps_distance_and_projectile_hits():
	var robo := _enemy("robo", Vector2(200, 0))
	await wait_seconds(2.5)
	assert_gt(robo.global_position.distance_to(player.global_position), 100.0, "Robô fica longe")
	assert_eq(Constants.PLAYER_MAX_HP - player.hp, robo.data.damage, "dinamite acertou")


func test_barril_explodes_near_player():
	var barril := _enemy("barril", Vector2(80, 0))
	var damage := barril.data.damage
	await wait_seconds(1.8)
	assert_false(is_instance_valid(barril), "o barril some ao explodir")
	assert_eq(Constants.PLAYER_MAX_HP - player.hp, damage)


func test_kill_notifies_game_state():
	watch_signals(GameState)
	var bug := _enemy("bug", Vector2(300, 0))
	bug.take_damage(1000)
	assert_signal_emitted(GameState, "enemy_killed")
