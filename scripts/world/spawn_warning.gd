class_name SpawnWarning
extends Node2D
## Marca breve, sem colisão, que anuncia onde o próximo inimigo vai aparecer.

var tint := Color("69d8e8")
var duration := 0.65
var elapsed := 0.0


func _ready() -> void:
	add_to_group(&"spawn_warning")
	z_index = -1


func _process(delta: float) -> void:
	elapsed = minf(elapsed + delta, duration)
	queue_redraw()


func _draw() -> void:
	var progress := clampf(elapsed / maxf(duration, 0.01), 0.0, 1.0)
	draw_circle(Vector2.ZERO, 29.0, Color(tint, 0.15))
	draw_arc(Vector2.ZERO, 29.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 36, tint, 3.0)
	draw_line(Vector2(-10, 0), Vector2(10, 0), Color(tint, 0.8), 2.0)
	draw_line(Vector2(0, -10), Vector2(0, 10), Color(tint, 0.8), 2.0)
