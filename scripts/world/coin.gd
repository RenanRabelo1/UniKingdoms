class_name Coin
extends Node2D
## Bit no chão: é puxado pelo player quando ele chega perto.

const TEX := preload("res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Terrain/Resources/Gold/Gold Resource/Gold_Resource.png")
const MAGNET_RADIUS := 160.0
const MAGNET_SPEED := 560.0

var value := 1
## A sala aumenta isto quando é limpa, para as moedas voarem até o player.
var magnet_radius := MAGNET_RADIUS
var _player: Node2D
var _credited := false
var _gain := 0


func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = TEX
	s.scale = Vector2(0.3, 0.3)
	s.position.y = -8
	add_child(s)
	_player = get_tree().get_first_node_in_group(&"player")
	var scatter := Vector2.from_angle(randf() * TAU) * randf_range(10.0, 40.0)
	create_tween().tween_property(self, "position", position + scatter, 0.25)


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var d := global_position.distance_to(_player.global_position)
	if d < magnet_radius:
		global_position = global_position.move_toward(_player.global_position, MAGNET_SPEED * delta)
	if d < 20.0:
		credit()
		Fx.text(get_parent(), global_position, "+%d" % _gain, Color(1, 0.85, 0.2))
		queue_free()


## Credita uma vez, mas mantém a moeda para terminar o voo até o player.
func credit() -> int:
	if _credited:
		return 0
	_credited = true
	_gain = GameState.add_bits(value)
	return _gain


## Antes do checkpoint/portal, nenhuma moeda pode ficar para trás nem pagar duas vezes.
static func settle_all(parent: Node) -> int:
	var total := 0
	for child in parent.get_children():
		if child is Coin:
			total += child.credit()
			child.magnet_radius = 5000.0
	return total


## Espalha `total` Bits em algumas moedas a partir de `pos`.
static func drop(parent: Node, pos: Vector2, total: int) -> void:
	var count := clampi(total / 3, 1, 6)
	for i in count:
		var c := Coin.new()
		c.value = total / count + (1 if i < total % count else 0)
		c.position = parent.to_local(pos) if parent is Node2D else pos
		parent.add_child(c)
