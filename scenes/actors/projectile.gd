class_name Projectile
extends Area2D
## Dinamite arremessada: voa em linha reta, explode no player ou na parede.

const DYNAMITE := {"spin": ["res://Tiny Swords/Tiny Swords (Update 010)/Factions/Goblins/Troops/TNT/Dynamite/Dynamite.png", 64, 64, 0, 6, 16.0, true]}

var velocity := Vector2.ZERO
var damage := 10
var lifetime := 3.0
var _exploded := false

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Sprite.sprite_frames = SheetFrames.build(DYNAMITE)
	$Sprite.play(&"spin")


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	# Varrer o volume da dinamite impede atravessar paredes e o jogador entre quadros.
	var motion := velocity * delta
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape.shape
	query.transform = _shape.global_transform
	query.collision_mask = collision_mask
	var space := get_world_2d().direct_space_state
	var overlaps := space.intersect_shape(query, 1)
	if not overlaps.is_empty():
		_on_body_entered(overlaps[0].collider)
		return
	query.motion = motion
	var fractions := space.cast_motion(query)
	if fractions[0] < 1.0:
		global_position += motion * fractions[1]
		query.transform = _shape.global_transform
		query.motion = Vector2.ZERO
		query.margin = 0.1
		overlaps = space.intersect_shape(query, 1)
		if not overlaps.is_empty():
			_on_body_entered(overlaps[0].collider)
		else:
			_explode()
		return
	global_position += motion
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()


func _on_body_entered(body: Node) -> void:
	if _exploded:
		return
	if body is Player:
		body.take_damage(damage, "Dinamite")
	_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	Fx.spawn(get_parent(), "explosion", global_position, 0.5)
	queue_free()
