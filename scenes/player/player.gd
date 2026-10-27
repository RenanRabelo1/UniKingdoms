class_name Player
extends CharacterBody2D
## Aluno controlado pelo jogador: anda, mira no mouse, dá dash, ataca, usa o especial e leva dano.

signal attacked(kind: StringName, combo: ComboData)
signal special_used
signal health_changed(hp: int, max_hp: int)
signal died

@export var weapon: WeaponData
@export var combos: Array[ComboData] = []

## Cor do uniforme (Warrior do Free Pack). Definida antes de entrar na árvore.
var color := "Blue"
var aim_direction := Vector2.RIGHT
var is_invincible := false
var is_dead := false
var max_hp := Constants.PLAYER_MAX_HP
var hp := Constants.PLAYER_MAX_HP
## Bônus somados de ensinamentos, relíquias e itens. Chaves em Constants.STAT_KEYS.
var stats := {}
var special_meter := SpecialMeter.new(
	Constants.SPECIAL_CHARGE_PER_SECOND, Constants.SPECIAL_CHARGE_PER_DAMAGE)

var _combo_tracker: ComboTracker
var _attack_ready_at := 0.0
var _dash_ready_at := 0.0
var _dash_time_left := 0.0
var _hurt_time_left := 0.0
var _mouse_seen := false
## Ações pedidas no input, executadas no próximo passo de física (consultas de colisão vivem lá).
var _pending: Array[StringName] = []

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group(&"player")
	_combo_tracker = ComboTracker.new(combos, Constants.COMBO_WINDOW)
	sprite.sprite_frames = SheetFrames.build(SheetFrames.warrior(color))
	sprite.play(&"idle")
	sprite.animation_finished.connect(func() -> void: sprite.play(&"idle"))
	GameState.enemy_killed.connect(_on_enemy_killed)


## Aplica bônus e vida inicial. hp < 0 significa vida cheia.
func setup(p_stats: Dictionary, p_hp := -1) -> void:
	stats = p_stats
	max_hp = Constants.PLAYER_MAX_HP + int(stat(&"max_hp"))
	hp = max_hp if p_hp < 0 else clampi(p_hp, 1, max_hp)
	var rate := 1.0 + stat(&"special_rate")
	special_meter.per_second = Constants.SPECIAL_CHARGE_PER_SECOND * rate
	special_meter.per_damage = Constants.SPECIAL_CHARGE_PER_DAMAGE * rate
	health_changed.emit(hp, max_hp)


func stat(key: StringName) -> float:
	return stats.get(key, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_seen = true
	for action in [&"attack_basic", &"attack_heavy", &"dash", &"special"]:
		if event.is_action_pressed(action):
			_pending.append(action)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	special_meter.tick(delta)
	_hurt_time_left = maxf(_hurt_time_left - delta, 0.0)
	if _mouse_seen:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 1.0:
			aim_direction = to_mouse.normalized()

	for action in _pending:
		match action:
			&"attack_basic": attack(&"basic")
			&"attack_heavy": attack(&"heavy")
			&"dash": dash()
			&"special": use_special()
	_pending.clear()

	if _dash_time_left > 0.0:
		_dash_time_left -= delta
		if _dash_time_left <= 0.0:
			is_invincible = false
			velocity = Vector2.ZERO
			sprite.modulate.a = 1.0
	else:
		velocity = _move_input() * Constants.PLAYER_SPEED * (1.0 + stat(&"speed"))
	move_and_slide()

	sprite.flip_h = aim_direction.x < 0.0
	if not sprite.animation.begins_with("attack"):
		sprite.play(&"run" if velocity.length() > 5.0 else &"idle")
	queue_redraw()


## Golpeia na direção da mira. `kind` é &"basic" ou &"heavy". Retorna false se em recarga.
func attack(kind: StringName) -> bool:
	var now := _now()
	if is_dead or now < _attack_ready_at:
		return false
	var heavy := kind == &"heavy"
	var cooldown := weapon.heavy_cooldown if heavy else weapon.basic_cooldown
	_attack_ready_at = now + cooldown * (1.0 - stat(&"attack_speed"))

	var combo := _combo_tracker.register(kind, now)
	var damage := float(weapon.heavy_damage if heavy else weapon.basic_damage)
	damage *= 1.0 + stat(&"dmg_heavy" if heavy else &"dmg_basic") + stat(&"dmg_all")
	if combo:
		damage *= combo.damage_multiplier + stat(&"combo_bonus")
	if randf() < stat(&"crit"):
		damage *= 2.0
	var reach := 1.0 + stat(&"reach")
	var center := global_position + aim_direction * weapon.reach * reach
	var dealt := _hit(center, weapon.hit_radius * reach, roundi(damage),
		combo.display_name if combo else weapon.display_name)
	special_meter.add_damage(dealt)

	sprite.play(&"attack2" if heavy else &"attack1")
	var color_fx := Color.GOLD if combo else (Color.ORANGE if heavy else Color.WHITE)
	_flash(center, weapon.hit_radius * reach, color_fx)
	attacked.emit(kind, combo)
	return true


func dash() -> bool:
	var now := _now()
	if is_dead or now < _dash_ready_at:
		return false
	var dir := _move_input()
	if dir == Vector2.ZERO:
		dir = aim_direction
	_dash_ready_at = now + Constants.DASH_COOLDOWN * (1.0 - stat(&"dash_cd"))
	_dash_time_left = Constants.DASH_DURATION
	is_invincible = true
	velocity = dir.normalized() * Constants.DASH_SPEED
	sprite.modulate.a = 0.5
	Fx.spawn(get_parent(), "dust", global_position, 1.0)
	return true


func use_special() -> bool:
	if is_dead or not special_meter.consume():
		return false
	_hit(global_position, Constants.SPECIAL_RADIUS, Constants.SPECIAL_DAMAGE, "Especial")
	_flash(global_position, Constants.SPECIAL_RADIUS, Color(0.4, 0.8, 1.0))
	Fx.spawn(get_parent(), "explosion", global_position, 1.2)
	special_used.emit()
	return true


## Recebe dano de inimigos. Ignora durante o dash e logo depois de outro golpe.
func take_damage(amount: int, _source := "") -> bool:
	if is_dead or is_invincible or _hurt_time_left > 0.0:
		return false
	hp = maxi(hp - amount, 0)
	_hurt_time_left = Constants.HURT_IFRAMES
	health_changed.emit(hp, max_hp)
	Fx.text(get_parent(), global_position, "-%d" % amount, Color(1, 0.35, 0.35))
	sprite.modulate = Color(1, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, Constants.HURT_IFRAMES)
	if hp == 0:
		is_dead = true
		velocity = Vector2.ZERO
		sprite.play(&"idle")
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.8)
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
	Fx.text(get_parent(), global_position, "+%d" % amount, Color(0.4, 1, 0.5))


func _on_enemy_killed(_enemy: Node) -> void:
	heal(int(stat(&"heal_on_kill")))


## Dá dano em tudo da camada de inimigos dentro do círculo. Retorna o dano total causado.
func _hit(center: Vector2, radius: float, damage: int, source: String) -> int:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collision_mask = Constants.LAYER_ENEMIES
	var total := 0
	for result in get_world_2d().direct_space_state.intersect_shape(query, 32):
		if result.collider.has_method(&"take_damage"):
			result.collider.take_damage(damage, source)
			total += damage
	return total


func _flash(center: Vector2, radius: float, color_fx: Color) -> void:
	var fx := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 24:
		points.append(Vector2.from_angle(TAU * i / 24.0) * radius)
	fx.polygon = points
	fx.color = Color(color_fx, 0.3)
	fx.top_level = true
	add_child(fx)
	fx.global_position = center
	create_tween().tween_property(fx, "modulate:a", 0.0, 0.15).finished.connect(fx.queue_free)


func _move_input() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _draw() -> void:
	# Indicador discreto da mira na altura do corpo.
	var c := Vector2(0, -20)
	draw_line(c + aim_direction * 34.0, c + aim_direction * 46.0, Color(1, 1, 1, 0.7), 3.0)
