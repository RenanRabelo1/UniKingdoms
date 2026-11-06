extends GutTest
## Regressões de ritmo: inimigos anunciam, se reposicionam e reagem aos golpes.

const PlayerScene := preload("res://scenes/player/player.tscn")
const EnemyScene := preload("res://scenes/actors/enemy.tscn")
const BossScene := preload("res://scenes/actors/boss.tscn")
const ProjectileScene := preload("res://scenes/actors/projectile.tscn")

var player: Player
var _world: Node2D


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)
	player = PlayerScene.instantiate()
	_world.add_child(player)
	player.global_position = Vector2(500, 300)


func _enemy(id: String, offset: Vector2) -> Enemy:
	var enemy: Enemy = EnemyScene.instantiate()
	enemy.data = load("res://data/enemies/%s.tres" % id).duplicate()
	_world.add_child(enemy)
	enemy.global_position = player.global_position + offset
	return enemy


func _wall(pos: Vector2, size: Vector2) -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.collision_layer = Constants.LAYER_WORLD
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collider.shape = rectangle
	wall.add_child(collider)
	_world.add_child(wall)
	wall.global_position = pos
	return wall


func test_ranged_enemy_repositions_between_shots() -> void:
	var robo := _enemy("robo", Vector2(200, 0))
	var movement := robo._desired_velocity(Vector2.LEFT * 200.0, 200.0)
	assert_gt(absf(movement.y), 1.0, "Robô se move lateralmente na distância de tiro")


func test_melee_attack_does_not_snap_to_a_dodge_behind() -> void:
	var bug := _enemy("bug", Vector2(35, 0))
	bug.set_physics_process(false)
	bug._start_windup()
	player.global_position = bug.global_position + Vector2(35, 0)
	bug._strike(player.global_position - bug.global_position, 35.0)
	assert_eq(player.hp, player.max_hp, "sair do arco anunciado evita o golpe")


func test_player_heavy_hit_pushes_enemy_away() -> void:
	var bug := _enemy("bug", Vector2(75, 0))
	bug.hp = 200
	await wait_physics_frames(2)
	var before := bug.global_position.x
	player.aim_direction = Vector2.RIGHT
	player.attack(&"heavy")
	await wait_seconds(0.1)
	assert_gt(bug.global_position.x, before + 8.0, "impacto abre espaço para o jogador")


func test_atletica_has_distinct_charge_archetype() -> void:
	var atletica := _enemy("atletica", Vector2(220, 0))
	assert_eq(atletica.data.kind, "charger", "Atlética investe em vez de repetir o Bug")


func test_chaser_can_step_around_a_small_obstacle() -> void:
	player.global_position = Vector2(650, 300)
	var bug := _enemy("bug", Vector2(-250, 0))
	_wall(Vector2(455, 300), Vector2(22, 90))
	await wait_seconds(2.1)
	assert_gt(bug.global_position.x, 485.0, "Bug contorna o obstáculo local")


func test_boss_fan_has_warning_before_projectiles() -> void:
	var boss: Boss = BossScene.instantiate()
	_world.add_child(boss)
	boss.global_position = Vector2(500, 100)
	boss._throw(Vector2.DOWN * 200.0)
	assert_eq(_projectile_count(), 0, "leque começa pelo aviso, sem tiro instantâneo")
	await wait_seconds(0.8)
	assert_gt(_projectile_count(), 0, "leque é disparado depois da janela de esquiva")
	for child in _world.get_children():
		if child is Projectile:
			child.queue_free()


func _projectile_count() -> int:
	var count := 0
	for child in _world.get_children():
		if child is Projectile:
			count += 1
	return count


func test_fast_projectile_cannot_skip_a_thin_wall() -> void:
	_wall(Vector2(55, 80), Vector2(4, 80))
	var projectile: Projectile = ProjectileScene.instantiate()
	_world.add_child(projectile)
	projectile.global_position = Vector2(0, 80)
	projectile.velocity = Vector2.RIGHT * 6000.0
	projectile.set_physics_process(false)
	await wait_physics_frames(2)
	projectile._physics_process(1.0 / 60.0)
	assert_true(projectile.is_queued_for_deletion(), "trajeto varrido detecta a parede entre quadros")


func test_armed_barrel_can_be_pushed_without_resetting_its_fuse() -> void:
	var barrel := _enemy("barril", Vector2(40, 0))
	barrel._start_windup()
	var remaining := barrel._timer
	barrel.apply_impulse(Vector2.RIGHT, 2.0)
	assert_eq(barrel._state, Enemy.State.WINDUP, "golpe não desarma o pavio")
	assert_eq(barrel._timer, remaining, "golpe não prolonga a explosão")
	await wait_seconds(barrel.data.windup + 0.1)
	assert_false(is_instance_valid(barrel), "barril explodiu depois de ser empurrado")
	assert_eq(player.hp, player.max_hp, "empurrar o barril para fora do raio evita o dano")


func test_stagger_interrupts_a_melee_windup() -> void:
	var bug := _enemy("bug", Vector2(35, 0))
	bug._start_windup()
	bug.apply_impulse(Vector2.RIGHT)
	assert_eq(bug._state, Enemy.State.STAGGER)
	await wait_seconds(bug.data.stagger_time * 0.5)
	assert_eq(player.hp, player.max_hp, "inimigo interrompido não conclui o golpe")


func test_charge_does_not_hit_through_a_wall() -> void:
	player.global_position = Vector2(520, 300)
	var atletica := _enemy("atletica", Vector2(-40, 0))
	var boss: Boss = BossScene.instantiate()
	_world.add_child(boss)
	boss.global_position = Vector2(480, 300)
	boss.set_physics_process(false)
	atletica.set_physics_process(false)
	_wall(Vector2(500, 300), Vector2(4, 120))
	await wait_physics_frames(2)
	atletica._state = Enemy.State.CHARGE
	atletica._timer = 0.2
	atletica._attack_dir = Vector2.RIGHT
	atletica._physics_process(1.0 / 60.0)
	assert_eq(player.hp, player.max_hp, "Atlética não causa contato através da parede")
	player.hp = player.max_hp
	player.is_invincible = false
	boss._state = Boss.State.CHARGE
	boss._timer = 0.2
	boss._dir = Vector2.RIGHT
	boss._physics_process(1.0 / 60.0)
	assert_eq(player.hp, player.max_hp, "professor não causa contato através da parede")


func test_projectile_explodes_and_damages_only_once() -> void:
	var projectile: Projectile = ProjectileScene.instantiate()
	_world.add_child(projectile)
	projectile.global_position = player.global_position
	projectile._on_body_entered(player)
	var hp_after_hit := player.hp
	player.is_invincible = false
	projectile._on_body_entered(player)
	assert_eq(player.hp, hp_after_hit, "callbacks sobrepostos não repetem o dano")
