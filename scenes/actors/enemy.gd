class_name Enemy
extends CharacterBody2D
## Inimigo guiado por dados, com intenção visível e reação física aos golpes.

signal died(enemy: Enemy)

enum State { MOVE, WINDUP, RECOVER, CHARGE, STAGGER }

const ProjectileScene := preload("res://scenes/actors/projectile.tscn")

@export var data: EnemyData
var hp_scale := 1.0
var hp: int
var target: Node2D
## Distância máxima para perseguir o player (no campus); INF na run.
var aggro_range := INF

var _state := State.MOVE
var _timer := 0.0
var _cooldown := 0.0
var _attack_dir := Vector2.RIGHT
var _impact_velocity := Vector2.ZERO
var _orbit_side := 1.0
var _steer_side := 1.0
var _hit_this_charge := false
var _flash_left := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	hp = roundi(data.max_hp * hp_scale)
	var shape := CircleShape2D.new()
	shape.radius = data.body_radius
	$CollisionShape2D.shape = shape
	Hurtbox.attach(self, data.hurtbox_size, data.hurtbox_center)
	sprite.sprite_frames = SheetFrames.build(data.animations)
	sprite.scale = Vector2.ONE * data.sprite_scale
	sprite.position = data.sprite_offset
	sprite.play(&"idle")
	_cooldown = randf_range(data.initial_attack_delay.x, data.initial_attack_delay.y)
	_orbit_side = -1.0 if get_instance_id() % 2 == 0 else 1.0
	_steer_side = _orbit_side
	if target == null:
		target = get_tree().get_first_node_in_group(&"player")


func _physics_process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	sprite.modulate = Color(2.5, 2.5, 2.5) if _flash_left > 0.0 else Color.WHITE
	queue_redraw()
	if hp <= 0 or not is_instance_valid(target) or target.is_dead:
		velocity = Vector2.ZERO
		sprite.play(&"idle")
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	var to := target.global_position - global_position
	var dist := to.length()
	match _state:
		State.MOVE:
			velocity = _steer(_desired_velocity(to, dist)) if dist <= aggro_range else Vector2.ZERO
			if dist <= minf(data.attack_range, aggro_range) and _cooldown <= 0.0 and _has_line_of_sight():
				_start_windup()
		State.WINDUP:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_strike(to, dist)
		State.CHARGE:
			velocity = _attack_dir * data.charge_speed
			_timer -= delta
			if not _hit_this_charge and dist <= data.charge_hit_radius and _has_line_of_sight():
				_hit_this_charge = target.take_damage(data.damage, data.display_name)
			if _timer <= 0.0:
				_recover()
		State.RECOVER:
			# O atirador reposiciona enquanto recarrega; golpes de contato deixam uma abertura.
			velocity = _steer(_desired_velocity(to, dist)) if data.kind == "ranged" else Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_state = State.MOVE
		State.STAGGER:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_state = State.MOVE
	velocity += _impact_velocity
	_impact_velocity = _impact_velocity.move_toward(Vector2.ZERO, data.knockback_decay * delta)
	if _state == State.MOVE or (_state == State.RECOVER and data.kind == "ranged"):
		sprite.play(&"run" if velocity.length() > 5.0 else &"idle")
	var facing := to if _state == State.MOVE else _attack_dir
	if absf(facing.x) > 0.01:
		sprite.flip_h = facing.x < 0.0
	move_and_slide()
	if _state == State.CHARGE and get_slide_collision_count() > 0:
		_recover()


func _desired_velocity(to: Vector2, dist: float) -> Vector2:
	var dir := to.normalized()
	if data.kind == "ranged":
		if dist > data.attack_range * 0.9:
			return dir * data.speed
		if dist < data.attack_range * 0.5:
			return -dir * data.speed
		return dir.orthogonal() * _orbit_side * data.speed * data.orbit_speed_ratio
	return dir * data.speed if dist > data.body_radius + 10.0 else Vector2.ZERO


## Busca uma direção local livre, mantendo o lado escolhido para não oscilar na parede.
func _steer(desired: Vector2) -> Vector2:
	if desired.is_zero_approx():
		return desired
	var direction := desired.normalized()
	if not test_move(global_transform, direction * data.steering_probe):
		return desired
	for side in [_steer_side, -_steer_side]:
		for angle in [PI / 4.0, PI / 2.0, PI * 0.75]:
			var candidate := direction.rotated(angle * side)
			if not test_move(global_transform, candidate * data.steering_probe):
				_steer_side = side
				return candidate * desired.length()
	return Vector2.ZERO


func _has_line_of_sight() -> bool:
	var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, Constants.LAYER_WORLD)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _start_windup() -> void:
	_state = State.WINDUP
	_timer = data.windup
	_attack_dir = (target.global_position - global_position).normalized()
	if _attack_dir.is_zero_approx():
		_attack_dir = Vector2.RIGHT
	velocity = Vector2.ZERO
	sprite.play(&"attack")
	queue_redraw()


func _strike(to: Vector2, dist: float) -> void:
	_cooldown = data.attack_cooldown
	_recover()
	match data.kind:
		"ranged":
			var projectile: Projectile = ProjectileScene.instantiate()
			projectile.damage = data.damage
			projectile.velocity = _attack_dir * data.projectile_speed
			get_parent().add_child(projectile)
			projectile.global_position = global_position + Vector2(0, -16)
			_orbit_side *= -1.0
		"kamikaze":
			Fx.spawn(get_parent(), "explosion", global_position, 0.8)
			if dist <= data.attack_range * data.explosion_range_multiplier and _has_line_of_sight():
				target.take_damage(data.damage, data.display_name)
			_die()
		"charger":
			_state = State.CHARGE
			_timer = data.charge_duration
			_hit_this_charge = false
		_:
			var in_arc := to.is_zero_approx() or _attack_dir.dot(to.normalized()) >= cos(deg_to_rad(data.melee_arc_degrees * 0.5))
			if dist <= data.attack_range + data.melee_hit_padding and in_arc and _has_line_of_sight():
				target.take_damage(data.damage, data.display_name)
	queue_redraw()


func _recover() -> void:
	_state = State.RECOVER
	_timer = data.recovery
	velocity = Vector2.ZERO


## Separado do dano para permitir força e direção próprias de cada golpe.
func apply_impulse(direction: Vector2, strength := 1.0) -> void:
	if hp <= 0 or is_queued_for_deletion():
		return
	_impact_velocity = direction.normalized() * data.knockback_speed * maxf(0.0, strength)
	# Depois de armado, o pavio não é cancelado: é possível empurrar o barril para longe.
	if data.kind == "kamikaze" and _state == State.WINDUP:
		return
	_state = State.STAGGER
	_timer = data.stagger_time * sqrt(maxf(0.0, strength))
	velocity = Vector2.ZERO
	sprite.play(&"idle")
	queue_redraw()


func take_damage(amount: int, _source := "") -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = maxi(0, hp - amount)
	Fx.text(get_parent(), global_position, str(amount), Color(1, 0.9, 0.4))
	_flash_left = data.hit_flash_time
	if hp == 0:
		_die()
	queue_redraw()


func _die() -> void:
	if is_queued_for_deletion():
		return
	hp = 0
	died.emit(self)
	GameState.notify_kill(self)
	Fx.spawn(get_parent(), "dead", global_position, 0.7)
	queue_free()


func _draw() -> void:
	if data == null or hp <= 0:
		return
	if _state == State.WINDUP:
		var progress := 1.0 - clampf(_timer / maxf(data.windup, 0.001), 0.0, 1.0)
		var color := Color(1.0, 0.35, 0.2, 0.24 + progress * 0.28)
		var outline_color := Color(0.08, 0.04, 0.02, 0.95)
		var edge_color := Color(1.0, 0.8, 0.4, 0.9)
		match data.kind:
			"kamikaze":
				var radius := data.attack_range * data.explosion_range_multiplier
				draw_circle(Vector2.ZERO, radius, Color(color, 0.1 + progress * 0.12))
				draw_arc(Vector2.ZERO, radius, 0, TAU, 40, outline_color, 6.0, true)
				draw_arc(Vector2.ZERO, radius, 0, TAU, 40, edge_color, 2.5, true)
				draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 40, color, 2.0, true)
			"charger":
				var side := _attack_dir.orthogonal() * data.charge_hit_radius
				var end := _attack_dir * data.charge_speed * data.charge_duration
				draw_colored_polygon(PackedVector2Array([-side, side, end + side, end - side]), Color(color, 0.16))
				var border := PackedVector2Array([-side, side, end + side, end - side, -side])
				draw_polyline(border, outline_color, 6.0, true)
				draw_polyline(border, edge_color, 2.5, true)
				draw_line(Vector2.ZERO, end, color, 3.0, true)
			"ranged":
				var origin := Vector2(0, -16)
				draw_line(origin, origin + _attack_dir * data.attack_range, outline_color, 5.0, true)
				draw_line(origin, origin + _attack_dir * data.attack_range, edge_color, 2.5, true)
			_:
				var half_angle := deg_to_rad(data.melee_arc_degrees * 0.5)
				var radius := data.attack_range + data.melee_hit_padding
				var points := PackedVector2Array([Vector2.ZERO])
				for i in 13:
					points.append(_attack_dir.rotated(lerpf(-half_angle, half_angle, i / 12.0)) * radius)
				draw_colored_polygon(points, color)
				points.append(Vector2.ZERO)
				draw_polyline(points, outline_color, 5.0, true)
				draw_polyline(points, edge_color, 2.0, true)
	if hp < roundi(data.max_hp * hp_scale):
		var bar := Rect2(Vector2(-21, data.hurtbox_center.y - data.hurtbox_size.y * 0.5 - 10), Vector2(42, 4))
		draw_rect(bar.grow(1.0), Color(0.08, 0.1, 0.14, 0.9))
		bar.size.x *= clampf(float(hp) / maxf(1.0, data.max_hp * hp_scale), 0.0, 1.0)
		draw_rect(bar, Color(1.0, 0.35, 0.24))
