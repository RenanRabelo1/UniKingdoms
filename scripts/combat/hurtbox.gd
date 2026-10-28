class_name Hurtbox
extends Area2D
## Área que recebe golpes do player, separada da colisão de movimento do dono (o nó pai).
## O golpe procura esta camada; quem leva o dano é o pai (`take_damage`).

## Liga o desenho das áreas de combate (F3, só em build de debug).
static var debug_draw := false

var shape: CapsuleShape2D
var center: Vector2
var _drawn := false


## Cápsula vertical de largura `size.x` e altura `size.y`, com centro em `p_center` (relativo ao dono).
static func attach(owner_node: Node2D, size: Vector2, p_center: Vector2) -> Hurtbox:
	var hb := Hurtbox.new()
	hb.name = &"Hurtbox"
	hb.center = p_center
	hb.collision_layer = Constants.LAYER_HURTBOX
	hb.collision_mask = 0
	hb.monitoring = false
	hb.shape = CapsuleShape2D.new()
	hb.shape.radius = size.x / 2.0
	hb.shape.height = maxf(size.y, size.x)
	var cs := CollisionShape2D.new()
	cs.shape = hb.shape
	cs.position = p_center
	hb.add_child(cs)
	owner_node.add_child(hb)
	return hb


func _process(_delta: float) -> void:
	if debug_draw or _drawn:
		queue_redraw()
	_drawn = debug_draw


func _draw() -> void:
	if not debug_draw:
		return
	draw_set_transform(center)
	shape.draw(get_canvas_item(), Color(0.2, 1, 0.3, 0.45))
	draw_set_transform(Vector2.ZERO)
	# Colisão de movimento do dono, para comparar com a área de dano.
	var body := get_parent().get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if body and body.shape is CircleShape2D:
		draw_circle(body.position, body.shape.radius, Color(0.3, 0.6, 1, 0.9), false, 2.0)
