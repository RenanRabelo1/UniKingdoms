class_name CampusWaypoint
extends Control
## Marcador de direção para o CCT: acompanha a câmera e fica dentro das bordas úteis da tela.

var player: Node2D
var destination := Vector2.ZERO
var _point := Vector2.ZERO
var _direction := Vector2.DOWN
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UI.hud_label(self, "CCT", 14)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override(&"font_color", Color("ffd47c"))
	_label.size = Vector2(140, 24)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var screen := get_viewport_rect().size
	var projected := player.get_viewport_transform() * destination
	var center := screen * 0.5
	_point = projected.clamp(Vector2(60, 150), screen - Vector2(60, 150))
	_direction = (projected - center).normalized() if _point.distance_to(projected) > 2.0 else Vector2.DOWN
	_label.position = _point + Vector2(-70, 19)
	queue_redraw()


func _draw() -> void:
	draw_circle(_point, 17.0, Color(0.02, 0.06, 0.08, 0.9))
	draw_arc(_point, 17.0, 0.0, TAU, 24, Color("ffd47c"), 2.0, true)
	var side := _direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		_point + _direction * 10.0, _point - _direction * 7.0 + side * 7.0,
		_point - _direction * 3.0, _point - _direction * 7.0 - side * 7.0,
	]), Color("ffd47c"))
