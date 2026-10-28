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
## Golpe em andamento: fica ativo por SWING_ACTIVE_TIME e acerta cada alvo uma vez só.
var _swing := {}

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
		var to_mouse := get_global_mouse_position() - body_center()
		if to_mouse.length() > 1.0:
			aim_direction = to_mouse.normalized()

	for action in _pending:
		match action:
			&"attack_basic": attack(&"basic")
			&"attack_heavy": attack(&"heavy")
			&"dash": dash()
			&"special": use_special()
	_pending.clear()
	if not _swing.is_empty():
		_swing.time_left -= delta
		if _swing.time_left <= 0.0:
			_swing.clear()
		else:
			_swing_step()

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
	var size := (1.0 + stat(&"reach")) * (weapon.heavy_size if heavy else 1.0)
	_swing = {
		"dir": aim_direction, "reach": weapon.reach * size, "radius": weapon.hit_radius * size,
		"damage": roundi(damage), "source": combo.display_name if combo else weapon.display_name,
		"time_left": Constants.SWING_ACTIVE_TIME, "hit": {},
	}
	_swing_step()

	sprite.play(&"attack2" if heavy else &"attack1")
	var color_fx := Color.GOLD if combo else (Color.ORANGE if heavy else Color.WHITE)
	_flash_swing(color_fx)
	attacked.emit(kind, combo)
	return true


func body_center() -> Vector2:
	return global_position + Constants.PLAYER_BODY_CENTER


## Cápsula do golpe atual, do corpo até o alcance, na direção da mira travada no clique.
func swing_shape() -> Array:
	# Começa no corpo e não passa dele para trás: quem está atrás do player não é atingido.
	var a: Vector2 = body_center() + _swing.dir * _swing.radius
	var b: Vector2 = body_center() + _swing.dir * _swing.reach
	return [a, b, _swing.radius]


## Aplica o golpe em quem está na cápsula agora e ainda não foi atingido por ele.
func _swing_step() -> void:
	var cap := swing_shape()
	var shape := CapsuleShape2D.new()
	shape.radius = cap[2]
	shape.height = (cap[1] - cap[0]).length() + 2.0 * cap[2]
	var xf := Transform2D((cap[1] - cap[0]).angle() - PI / 2.0, (cap[0] + cap[1]) / 2.0)
	var dealt := 0
	for target in _targets_in(shape, xf):
		var id := target.get_instance_id()
		if not _swing.hit.has(id):
			_swing.hit[id] = true
			target.take_damage(_swing.damage, _swing.source)
			dealt += _swing.damage
	special_meter.add_damage(dealt)


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
	var shape := CircleShape2D.new()
	shape.radius = Constants.SPECIAL_RADIUS
	for target in _targets_in(shape, Transform2D(0.0, body_center())):
		target.take_damage(Constants.SPECIAL_DAMAGE, "Especial")
	_flash(_circle(Constants.SPECIAL_RADIUS, Vector2.ZERO), body_center(), Color(0.4, 0.8, 1.0))
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


## Donos das hurtboxes que tocam a forma (cada dono uma vez).
func _targets_in(shape: Shape2D, xf: Transform2D) -> Array[Node]:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = xf
	query.collision_mask = Constants.LAYER_HURTBOX
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var found: Array[Node] = []
	for result in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var target: Node = result.collider.get_parent()
		if target.has_method(&"take_damage") and not found.has(target):
			found.append(target)
	return found


## Mostra exatamente a área do golpe (a mesma cápsula usada na detecção).
func _flash_swing(color_fx: Color) -> void:
	var cap := swing_shape()
	var dir: Vector2 = _swing.dir
	var points := PackedVector2Array()
	for i in 13:
		points.append(cap[1] - body_center() + dir.rotated(-PI / 2.0 + PI * i / 12.0) * cap[2])
	for i in 13:
		points.append(cap[0] - body_center() + dir.rotated(PI / 2.0 + PI * i / 12.0) * cap[2])
	_flash(points, body_center(), color_fx)


func _circle(radius: float, offset: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 24:
		points.append(offset + Vector2.from_angle(TAU * i / 24.0) * radius)
	return points


func _flash(points: PackedVector2Array, at: Vector2, color_fx: Color) -> void:
	var fx := Polygon2D.new()
	fx.polygon = points
	fx.color = Color(color_fx, 0.3)
	fx.top_level = true
	add_child(fx)
	fx.global_position = at
	create_tween().tween_property(fx, "modulate:a", 0.0, 0.15).finished.connect(fx.queue_free)


func _move_input() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _draw() -> void:
	# Indicador discreto da mira na altura do corpo.
	var c := Constants.PLAYER_BODY_CENTER
	draw_line(c + aim_direction * 34.0, c + aim_direction * 46.0, Color(1, 1, 1, 0.7), 3.0)
	if Hurtbox.debug_draw:
		draw_circle(Vector2.ZERO, $CollisionShape2D.shape.radius, Color(0.3, 0.6, 1, 0.9), false, 2.0)
		if not _swing.is_empty():
			var cap := swing_shape()
			var r: float = cap[2]
			draw_line(cap[0] - global_position, cap[1] - global_position, Color(1, 0.2, 0.2, 0.35), r * 2.0)
			draw_circle(cap[0] - global_position, r, Color(1, 0.2, 0.2, 0.35))
			draw_circle(cap[1] - global_position, r, Color(1, 0.2, 0.2, 0.35))
