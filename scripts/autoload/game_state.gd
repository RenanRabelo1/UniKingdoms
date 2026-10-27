extends Node
## Estado global do jogo. Cresce a cada milestone (run, economia, save).

signal enemy_killed(enemy: Node)


func notify_kill(enemy: Node) -> void:
	enemy_killed.emit(enemy)
