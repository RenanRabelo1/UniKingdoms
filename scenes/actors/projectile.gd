class_name Projectile
extends Area2D
## Dinamite arremessada: voa em linha reta, explode no player ou na parede.

const DYNAMITE := {"spin": ["res://Tiny Swords/Tiny Swords (Update 010)/Factions/Goblins/Troops/TNT/Dynamite/Dynamite.png", 64, 64, 0, 6, 16.0, true]}

var velocity := Vector2.ZERO
var damage := 10
var lifetime := 3.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Sprite.sprite_frames = SheetFrames.build(DYNAMITE)
	$Sprite.play(&"spin")


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage, "Dinamite")
	_explode()


func _explode() -> void:
	Fx.spawn(get_parent(), "explosion", global_position, 0.5)
	queue_free()
