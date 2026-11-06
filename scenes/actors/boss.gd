class_name Boss
extends CharacterBody2D
## Prof. Mainframe, chefe do CCT. Fase 1: investidas com a lança (com aviso).
## Fase 2 (metade da vida): investidas mais rápidas, leque de dinamites e invoca Bugs.

signal died(boss: Boss)
signal hp_changed(hp: int)
signal summon_requested(count: int)

enum State { CHASE, TELEGRAPH, CHARGE, THROW, RECOVER }

const DISPLAY_NAME := "Prof. Mainframe"
const DATA := preload("res://data/enemies/mainframe.tres")
## Compatibilidade com HUD e testes que consultam Boss.MAX_HP.
static var MAX_HP: int = DATA.max_hp
const BASE := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Black Units/Lancer/"
const ANIMS := {
	"idle": [BASE + "Lancer_Idle.png", 320, 320, 0, 12, 10.0, true],
	"run": [BASE + "Lancer_Run.png", 320, 320, 0, 6, 10.0, true],
	"attack": [BASE + "Lancer_Right_Attack.png", 320, 320, 0, 3, 8.0, false],
}
const ProjectileScene := preload("res://scenes/actors/projectile.tscn")

@export var data: BossData = DATA
var hp: int = MAX_HP
var phase := 1
var target: Player

var _state := State.CHASE
var _timer := 0.0
var _summon_timer := 0.0
var _dir := Vector2.RIGHT
var _hit_this_charge := false
var _attack_index := 0
var _flash_left := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var telegraph: Line2D = $Telegraph


func _ready() -> void:
	hp = data.max_hp
	_timer = data.opening_delay
	_summon_timer = data.summon_every
	sprite.sprite_frames = SheetFrames.build(ANIMS)
	sprite.play(&"idle")
	telegraph.visible = false
	telegraph.width = data.contact_range * 2.0
	# Corpo visível do Lancer (escala 1.7): ~118 × 255 px contando a lança; o tronco é menor.
	Hurtbox.attach(self, Vector2(100, 190), Vector2(0, -95))
	target = get_tree().get_first_node_in_group(&"player")


func _physics_process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	sprite.modulate = Color(2.5, 2.5, 2.5) if _flash_left > 0.0 else Color.WHITE
	queue_redraw()
	if not is_instance_valid(target) or target.is_dead or hp <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to := target.global_position - global_position
	_timer -= delta
	if phase == 2:
		_summon_timer -= delta
		if _summon_timer <= 0.0:
			_summon_timer = data.summon_every
			summon_requested.emit(data.summon_count)
	match _state:
		State.CHASE:
			velocity = to.normalized() * data.speed
			sprite.play(&"run")
			if _timer <= 0.0:
				# Um padrão aprendível: na fase turbo, investida e leque se alternam.
				if phase == 2 and _attack_index % 2 == 1:
					_throw(to)
				else:
					_telegraph(to)
				_attack_index += 1
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				telegraph.visible = false
				_state = State.CHARGE
				_timer = data.charge_time
				_hit_this_charge = false
				sprite.play(&"attack")
		State.CHARGE:
			velocity = _dir * data.charge_speed
			if not _hit_this_charge and to.length() < data.contact_range and _has_line_of_sight():
				_hit_this_charge = target.take_damage(data.charge_damage, DISPLAY_NAME)
			if _timer <= 0.0:
				_recover(data.charge_recovery)
		State.THROW:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_release_fan()
				_recover(data.throw_recovery)
		State.RECOVER:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_state = State.CHASE
				_timer = data.chase_time if phase == 1 else data.turbo_chase_time
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	elif absf(to.x) > 4.0:
		sprite.flip_h = to.x < 0.0
	move_and_slide()
	if _state == State.CHARGE and get_slide_collision_count() > 0:
		_recover(data.charge_recovery)


func _telegraph(to: Vector2) -> void:
	_state = State.TELEGRAPH
	_timer = data.charge_warning if phase == 1 else data.turbo_charge_warning
	_dir = to.normalized()
	velocity = Vector2.ZERO
	sprite.play(&"idle")
	telegraph.visible = true
	telegraph.points = [Vector2.ZERO, _dir * data.charge_speed * data.charge_time]


func _has_line_of_sight() -> bool:
	var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, Constants.LAYER_WORLD)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _throw(to: Vector2) -> void:
	_state = State.THROW
	_timer = data.throw_warning
	_dir = to.normalized()
	velocity = Vector2.ZERO
	telegraph.visible = false
	sprite.play(&"idle")
	queue_redraw()


func _release_fan() -> void:
	sprite.play(&"attack")
	for i in data.fan_count:
		var p: Projectile = ProjectileScene.instantiate()
		p.damage = data.throw_damage
		var angle := (i - (data.fan_count - 1) * 0.5) * data.fan_step_degrees
		p.velocity = _dir.rotated(deg_to_rad(angle)) * data.projectile_speed
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(0, -30)


func _recover(time: float) -> void:
	_state = State.RECOVER
	_timer = time
	sprite.play(&"idle")
	telegraph.visible = false
	velocity = Vector2.ZERO
	queue_redraw()


## O professor resiste a empurrões; a reação visual mantém o golpe legível.
func apply_impulse(_direction: Vector2, _strength := 1.0) -> void:
	_flash_left = data.hit_flash_time


func take_damage(amount: int, _source := "") -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp)
	Fx.text(get_parent(), global_position + Vector2(0, -50), str(amount), Color(1, 0.9, 0.4))
	_flash_left = data.hit_flash_time
	if phase == 1 and hp <= data.max_hp / 2:
		phase = 2
		_summon_timer = data.first_summon_delay
		GameState.notice.emit("O Prof. Mainframe entrou em modo turbo!")
	if hp == 0:
		telegraph.visible = false
		Fx.spawn(get_parent(), "explosion", global_position, 2.0)
		died.emit(self)
		queue_free()


func _draw() -> void:
	if hp <= 0:
		return
	if _state == State.TELEGRAPH:
		var side := _dir.orthogonal() * data.contact_range
		var end := _dir * data.charge_speed * data.charge_time
		var outline := PackedVector2Array([-side, side, end + side, end - side, -side])
		draw_polyline(outline, Color(0.08, 0.04, 0.02, 0.95), 6.0, true)
		draw_polyline(outline, Color(1.0, 0.75, 0.36, 1.0), 2.5, true)
		return
	if _state != State.THROW:
		return
	var progress := 1.0 - clampf(_timer / maxf(data.throw_warning, 0.001), 0.0, 1.0)
	var color := Color(1.0, 0.82, 0.45, 0.85 + progress * 0.15)
	var origin := Vector2(0, -30)
	for i in data.fan_count:
		var angle := (i - (data.fan_count - 1) * 0.5) * data.fan_step_degrees
		var ray := _dir.rotated(deg_to_rad(angle)) * data.projectile_speed
		draw_line(origin, origin + ray, Color(0.08, 0.04, 0.02, 0.95), 6.0, true)
		draw_line(origin, origin + ray, color, 3.0, true)
