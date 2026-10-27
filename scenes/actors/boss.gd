class_name Boss
extends CharacterBody2D
## Prof. Mainframe, chefe do CCT. Fase 1: investidas com a lança (com aviso).
## Fase 2 (metade da vida): investidas mais rápidas, leque de dinamites e invoca Bugs.

signal died(boss: Boss)
signal hp_changed(hp: int)
signal summon_requested(count: int)

enum State { CHASE, TELEGRAPH, CHARGE, THROW, RECOVER }

const DISPLAY_NAME := "Prof. Mainframe"
const MAX_HP := 900
const SPEED := 90.0
const CHARGE_SPEED := 640.0
const CHARGE_TIME := 0.45
const CHARGE_DAMAGE := 22
const CONTACT_RANGE := 52.0
const THROW_DAMAGE := 12
const SUMMON_EVERY := 9.0
const BASE := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Black Units/Lancer/"
const ANIMS := {
	"idle": [BASE + "Lancer_Idle.png", 320, 320, 0, 12, 10.0, true],
	"run": [BASE + "Lancer_Run.png", 320, 320, 0, 6, 10.0, true],
	"attack": [BASE + "Lancer_Right_Attack.png", 320, 320, 0, 3, 8.0, false],
}
const ProjectileScene := preload("res://scenes/actors/projectile.tscn")

var hp := MAX_HP
var phase := 1
var target: Player

var _state := State.CHASE
var _timer := 1.5
var _summon_timer := SUMMON_EVERY
var _dir := Vector2.RIGHT
var _hit_this_charge := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var telegraph: Line2D = $Telegraph


func _ready() -> void:
	sprite.sprite_frames = SheetFrames.build(ANIMS)
	sprite.play(&"idle")
	telegraph.visible = false
	target = get_tree().get_first_node_in_group(&"player")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_dead or hp <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to := target.global_position - global_position
	_timer -= delta
	if phase == 2:
		_summon_timer -= delta
		if _summon_timer <= 0.0:
			_summon_timer = SUMMON_EVERY
			summon_requested.emit(2)
	match _state:
		State.CHASE:
			velocity = to.normalized() * SPEED
			sprite.play(&"run")
			if _timer <= 0.0:
				if phase == 2 and randf() < 0.4:
					_throw(to)
				else:
					_telegraph(to)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				telegraph.visible = false
				_state = State.CHARGE
				_timer = CHARGE_TIME
				_hit_this_charge = false
				sprite.play(&"attack")
		State.CHARGE:
			velocity = _dir * CHARGE_SPEED
			if not _hit_this_charge and to.length() < CONTACT_RANGE:
				_hit_this_charge = target.take_damage(CHARGE_DAMAGE, DISPLAY_NAME)
			if _timer <= 0.0:
				_recover(0.7)
		State.THROW, State.RECOVER:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_state = State.CHASE
				_timer = 1.6 if phase == 1 else 1.0
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	elif absf(to.x) > 4.0:
		sprite.flip_h = to.x < 0.0
	move_and_slide()


func _telegraph(to: Vector2) -> void:
	_state = State.TELEGRAPH
	_timer = 0.75 if phase == 1 else 0.5
	_dir = to.normalized()
	velocity = Vector2.ZERO
	sprite.play(&"idle")
	telegraph.visible = true
	telegraph.points = [Vector2.ZERO, _dir * CHARGE_SPEED * CHARGE_TIME]


func _throw(to: Vector2) -> void:
	_state = State.THROW
	_timer = 0.8
	sprite.play(&"attack")
	for i in 5:
		var p: Projectile = ProjectileScene.instantiate()
		p.damage = THROW_DAMAGE
		p.velocity = to.normalized().rotated(deg_to_rad(-30 + i * 15)) * 300.0
		get_parent().add_child(p)
		p.global_position = global_position + Vector2(0, -30)


func _recover(time: float) -> void:
	_state = State.RECOVER
	_timer = time
	sprite.play(&"idle")


func take_damage(amount: int, _source := "") -> void:
	if hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp)
	Fx.text(get_parent(), global_position + Vector2(0, -50), str(amount), Color(1, 0.9, 0.4))
	sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if phase == 1 and hp <= MAX_HP / 2:
		phase = 2
		_summon_timer = 2.0
		GameState.notice.emit("O Prof. Mainframe entrou em modo turbo!")
	if hp == 0:
		telegraph.visible = false
		Fx.spawn(get_parent(), "explosion", global_position, 2.0)
		died.emit(self)
		queue_free()
