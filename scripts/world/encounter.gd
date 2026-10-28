class_name Encounter
extends Node2D
## Grupo de inimigos que aparece quando o player chega perto de uma área do campus.
## Vencer paga Bits no banco e o encontro só volta depois que uma run termina (GameState).

signal triggered(encounter: Encounter)
signal cleared(encounter: Encounter)

const EnemyScene := preload("res://scenes/actors/enemy.tscn")
const TRIGGER_RADIUS := 520.0
## Inimigos do campus só perseguem até esta distância (não atravessam o mapa atrás do player).
const AGGRO_RANGE := 700.0
const OFFSETS := [Vector2(-160, -70), Vector2(160, -70), Vector2(-90, 110), Vector2(100, 120),
	Vector2(0, -150)]

var id := ""
var message := ""
var enemy_ids: Array = []
var alive := 0
var started := false


func _physics_process(_delta: float) -> void:
	if started:
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player and player.global_position.distance_to(global_position) < TRIGGER_RADIUS:
		start()


func start() -> void:
	started = true
	for i in enemy_ids.size():
		var e: Enemy = EnemyScene.instantiate()
		e.data = load("res://data/enemies/%s.tres" % enemy_ids[i])
		e.aggro_range = AGGRO_RANGE
		e.died.connect(_on_enemy_died)
		get_parent().add_child(e)
		e.global_position = global_position + OFFSETS[i % OFFSETS.size()]
		Fx.spawn(get_parent(), "dust", e.global_position, 1.0)
	alive = enemy_ids.size()
	triggered.emit(self)


func _on_enemy_died(_enemy: Enemy) -> void:
	alive -= 1
	if alive == 0:
		cleared.emit(self)
