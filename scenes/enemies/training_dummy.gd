class_name TrainingDummy
extends StaticBody2D
## Boneco de treino: mostra o dano recebido e regenera a vida depois de um tempo sem apanhar.

const MAX_HP := 200
const REGEN_DELAY := 2.0

var hp := MAX_HP
var hits := 0
var last_damage := 0
var last_source := ""

var _regen_timer := 0.0


func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = load("res://Tiny Swords/Tiny Swords (Update 010)/Deco/18.png")
	s.position.y = -40
	s.show_behind_parent = true
	add_child(s)


func take_damage(amount: int, source: String = "") -> void:
	hits += 1
	last_damage = amount
	last_source = source
	hp = maxi(hp - amount, 0)
	_regen_timer = REGEN_DELAY
	queue_redraw()


func _process(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
		if _regen_timer <= 0.0:
			hp = MAX_HP
			queue_redraw()


func _draw() -> void:
	var ratio := float(hp) / MAX_HP
	draw_rect(Rect2(-24, -96, 48, 6), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-24, -96, 48 * ratio, 6), Color(0.3, 0.9, 0.4))
	if hits > 0:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-40, 40), "%s %d" % [last_source, last_damage],
			HORIZONTAL_ALIGNMENT_CENTER, 80, 14)
