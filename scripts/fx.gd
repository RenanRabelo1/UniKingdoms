class_name Fx
## Efeitos visuais de uso único (explosão, poeira, caveira) e números flutuantes.

const FREE := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/"
const OLD := "res://Tiny Swords/Tiny Swords (Update 010)/"
const SPECS := {
	"explosion": [FREE + "Particle FX/Explosion_01.png", 192, 192, 0, 8, 16.0, false],
	"dust": [FREE + "Particle FX/Dust_01.png", 64, 64, 0, 8, 18.0, false],
	"dead": [OLD + "Factions/Knights/Troops/Dead/Dead.png", 128, 128, 0, 7, 14.0, false],
}


static func spawn(parent: Node, kind: String, pos: Vector2, size := 1.0) -> void:
	if not is_instance_valid(parent):
		return
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SheetFrames.build({kind: SPECS[kind]})
	s.scale = Vector2.ONE * size
	parent.add_child(s)
	s.global_position = pos
	s.play(kind)
	s.animation_finished.connect(s.queue_free)


static func text(parent: Node, pos: Vector2, value: String, color := Color.WHITE) -> void:
	if not is_instance_valid(parent):
		return
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", 4)
	label.add_theme_font_size_override(&"font_size", 18)
	label.z_index = 50
	parent.add_child(label)
	label.global_position = pos + Vector2(-12, -60)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 28, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.finished.connect(label.queue_free)


## Uma marca curta de impacto reforça o momento em que a hurtbox realmente recebeu dano.
static func impact(parent: Node, pos: Vector2, strength := 1.0) -> void:
	var ring := Line2D.new()
	ring.width = 2.5
	ring.default_color = Color(1.0, 0.85, 0.45, 0.8)
	ring.z_index = 45
	for i in 17:
		ring.add_point(Vector2.from_angle(TAU * i / 16.0) * 9.0 * strength)
	parent.add_child(ring)
	ring.global_position = pos
	var tween := ring.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector2.ONE * 2.0, 0.12)
	tween.tween_property(ring, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(ring.queue_free)


static func afterimage(parent: Node, source: AnimatedSprite2D) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	ghost.flip_h = source.flip_h
	ghost.modulate = Color(0.35, 0.85, 1.0, 0.5)
	ghost.z_index = source.z_index - 1
	parent.add_child(ghost)
	ghost.global_transform = source.global_transform
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.tween_callback(ghost.queue_free)
