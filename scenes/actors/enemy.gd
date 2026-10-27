class_name Enemy
extends CharacterBody2D
## Inimigo genérico guiado por EnemyData: persegue, atira de longe ou explode.

signal died(enemy: Enemy)

enum State { MOVE, WINDUP, RECOVER }

const ProjectileScene := preload("res://scenes/actors/projectile.tscn")

@export var data: EnemyData
## Multiplicador de vida aplicado pela sala (dificuldade por profundidade).
var hp_scale := 1.0
var hp: int
var target: Node2D

var _state := State.MOVE
var _timer := 0.0
var _cooldown := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	hp = roundi(data.max_hp * hp_scale)
	var shape := CircleShape2D.new()
	shape.radius = data.body_radius
	$CollisionShape2D.shape = shape
	sprite.sprite_frames = SheetFrames.build(data.animations)
	sprite.scale = Vector2.ONE * data.sprite_scale
	sprite.position = data.sprite_offset
	sprite.play(&"idle")
	_cooldown = randf_range(0.2, 0.8)
	if target == null:
		target = get_tree().get_first_node_in_group(&"player")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_dead:
		velocity = Vector2.ZERO
		sprite.play(&"idle")
		move_and_slide()
		return
	_cooldown -= delta
	var to := target.global_position - global_position
	var dist := to.length()
	match _state:
		State.MOVE:
			velocity = _desired_velocity(to, dist)
			if dist <= data.attack_range and _cooldown <= 0.0:
				_start_windup()
		State.WINDUP:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_strike(to, dist)
		State.RECOVER:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_state = State.MOVE
	if _state == State.MOVE:
		sprite.play(&"run" if velocity.length() > 5.0 else &"idle")
	if absf(to.x) > 4.0:
		sprite.flip_h = to.x < 0.0
	move_and_slide()


func _desired_velocity(to: Vector2, dist: float) -> Vector2:
	var dir := to.normalized()
	if data.kind == "ranged":
		if dist > data.attack_range * 0.9:
			return dir * data.speed
		if dist < data.attack_range * 0.5:
			return -dir * data.speed
		return Vector2.ZERO
	return dir * data.speed if dist > data.body_radius + 10.0 else Vector2.ZERO


func _start_windup() -> void:
	_state = State.WINDUP
	_timer = data.windup
	sprite.play(&"attack")
	if data.kind == "kamikaze":
		var tween := create_tween().set_loops(4)
		tween.tween_property(sprite, "modulate", Color(2, 0.6, 0.6), data.windup / 8.0)
		tween.tween_property(sprite, "modulate", Color.WHITE, data.windup / 8.0)


func _strike(to: Vector2, dist: float) -> void:
	_cooldown = data.attack_cooldown
	_state = State.RECOVER
	_timer = 0.3
	match data.kind:
		"ranged":
			var p: Projectile = ProjectileScene.instantiate()
			p.damage = data.damage
			p.velocity = to.normalized() * data.projectile_speed
			get_parent().add_child(p)
			p.global_position = global_position + Vector2(0, -16)
		"kamikaze":
			Fx.spawn(get_parent(), "explosion", global_position, 0.8)
			if dist <= data.attack_range * 1.6:
				target.take_damage(data.damage, data.display_name)
			_die()
		_:
			if dist <= data.attack_range + 14.0:
				target.take_damage(data.damage, data.display_name)


func take_damage(amount: int, _source := "") -> void:
	if hp <= 0:
		return
	hp -= amount
	Fx.text(get_parent(), global_position, str(amount), Color(1, 0.9, 0.4))
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		_die()


func _die() -> void:
	hp = 0
	died.emit(self)
	GameState.notify_kill(self)
	Fx.spawn(get_parent(), "dead", global_position, 0.7)
	queue_free()
