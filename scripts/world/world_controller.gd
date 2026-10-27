class_name WorldController
extends Node2D
## Base da sala da run e do campus: player, HUD, interação (E), itens (1/2/3) e pausa (Esc).

const PlayerScene := preload("res://scenes/player/player.tscn")
const INTERACT_RADIUS := 75.0

var player: Player
var hud: Hud
var modal_open := false


func spawn_player(pos: Vector2, hp := -1) -> void:
	player = PlayerScene.instantiate()
	player.color = GameState.profile.color
	add_child(player)
	player.global_position = pos
	player.setup(GameState.stats(), hp)
	hud = Hud.new()
	add_child(hud)
	hud.bind_player(player)
	player.died.connect(_on_player_died)


func _process(_delta: float) -> void:
	if player == null or modal_open:
		return
	var it := nearest_interactable()
	hud.set_prompt(("[E] " + it.prompt) if it else "")


func nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_d := INTERACT_RADIUS
	for n in get_tree().get_nodes_in_group(&"interactable"):
		var d: float = n.global_position.distance_to(player.global_position)
		if n.enabled and d < best_d:
			best = n
			best_d = d
	return best


func _unhandled_input(event: InputEvent) -> void:
	if modal_open or player == null:
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		open_modal()
		Screens.pause(self, close_modal)
	elif event.is_action_pressed(&"interact"):
		var it := nearest_interactable()
		if it and not player.is_dead:
			get_viewport().set_input_as_handled()
			it.used.emit()
	else:
		for i in GameState.USABLE_ITEMS.size():
			if event.is_action_pressed("item_%d" % (i + 1)):
				use_item(i)


func use_item(slot: int) -> void:
	var it := GameState.item(GameState.USABLE_ITEMS[slot])
	if player.is_dead:
		return
	if not GameState.has_run():
		hud.show_notice("Itens só podem ser usados durante a run.")
		return
	if it.effect == "teaching" and GameState.offer_teachings(1).is_empty():
		hud.show_notice("Você já aprendeu todos os ensinamentos disponíveis.")
		return
	if not GameState.consume_item(String(it.id)):
		hud.show_notice("Você não tem %s." % it.display_name)
		return
	match it.effect:
		"heal":
			player.heal(int(it.amount))
		"special":
			player.special_meter.add(it.amount)
		"teaching":
			var t: TeachingData = GameState.offer_teachings(1)[0]
			apply_teaching(t)
			hud.show_notice("%s ensinou: %s. %s" % [it.display_name, t.display_name, t.description])


func apply_teaching(t: TeachingData) -> void:
	GameState.take_teaching(t)
	player.setup(GameState.stats(), player.hp)
	player.heal(t.heal)
	hud.refresh()


func open_modal() -> void:
	modal_open = true
	get_tree().paused = true
	hud.set_prompt("")


func close_modal() -> void:
	modal_open = false
	get_tree().paused = false


func _on_player_died() -> void:
	pass
