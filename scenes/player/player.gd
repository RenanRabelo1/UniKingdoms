class_name Player
extends CharacterBody2D
## Aluno controlado pelo jogador: anda, mira no mouse, dá dash, ataca e usa o especial.

signal attacked(kind: StringName, combo: ComboData)
signal special_used

@export var weapon: WeaponData
@export var combos: Array[ComboData] = []

var aim_direction := Vector2.RIGHT
var is_invincible := false
var special_meter := SpecialMeter.new(
	Constants.SPECIAL_CHARGE_PER_SECOND, Constants.SPECIAL_CHARGE_PER_DAMAGE)

var _combo_tracker: ComboTracker
var _attack_ready_at := 0.0
var _dash_ready_at := 0.0
var _dash_time_left := 0.0
var _mouse_seen := false
## Ações pedidas no input, executadas no próximo passo de física (consultas de colisão vivem lá).
var _pending: Array[StringName] = []


func _ready() -> void:
	_combo_tracker = ComboTracker.new(combos, Constants.COMBO_WINDOW)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_seen = true
	for action in [&"attack_basic", &"attack_heavy", &"dash", &"special"]:
		if event.is_action_pressed(action):
			_pending.append(action)


func _physics_process(delta: float) -> void:
	special_meter.tick(delta)
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
	else:
		velocity = _move_input() * Constants.PLAYER_SPEED
	move_and_slide()
	queue_redraw()


## Golpeia na direção da mira. `kind` é &"basic" ou &"heavy". Retorna false se em recarga.
func attack(kind: StringName) -> bool:
	var now := _now()
	if now < _attack_ready_at:
		return false
	var heavy := kind == &"heavy"
	_attack_ready_at = now + (weapon.heavy_cooldown if heavy else weapon.basic_cooldown)

	var combo := _combo_tracker.register(kind, now)
	var damage := float(weapon.heavy_damage if heavy else weapon.basic_damage)
	if combo:
		damage *= combo.damage_multiplier
	var center := global_position + aim_direction * weapon.reach
	var dealt := _hit(center, weapon.hit_radius, roundi(damage),
		combo.display_name if combo else weapon.display_name)
	special_meter.add_damage(dealt)

	var color := Color.GOLD if combo else (Color.ORANGE if heavy else Color.WHITE)
	_flash(center, weapon.hit_radius, color)
	attacked.emit(kind, combo)
	return true


func dash() -> bool:
	var now := _now()
	if now < _dash_ready_at:
		return false
	var dir := _move_input()
	if dir == Vector2.ZERO:
		dir = aim_direction
	_dash_ready_at = now + Constants.DASH_COOLDOWN
	_dash_time_left = Constants.DASH_DURATION
	is_invincible = true
	velocity = dir.normalized() * Constants.DASH_SPEED
	return true


func use_special() -> bool:
	if not special_meter.consume():
		return false
	_hit(global_position, Constants.SPECIAL_RADIUS, Constants.SPECIAL_DAMAGE, "Especial")
	_flash(global_position, Constants.SPECIAL_RADIUS, Color(0.4, 0.8, 1.0))
	special_used.emit()
	return true


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


func _flash(center: Vector2, radius: float, color: Color) -> void:
	var fx := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 24:
		points.append(Vector2.from_angle(TAU * i / 24.0) * radius)
	fx.polygon = points
	fx.color = Color(color, 0.6)
	fx.top_level = true
	add_child(fx)
	fx.global_position = center
	create_tween().tween_property(fx, "modulate:a", 0.0, 0.15).finished.connect(fx.queue_free)


func _move_input() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _draw() -> void:
	# shortcut: placeholder geométrico, trocar por sprite animado quando houver arte
	var body := Color(0.3, 0.6, 1.0, 0.5 if is_invincible else 1.0)
	draw_circle(Vector2.ZERO, 14.0, body)
	draw_line(Vector2.ZERO, aim_direction * 28.0, Color.WHITE, 3.0)
