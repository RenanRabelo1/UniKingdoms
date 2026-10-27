extends Node2D
## Menu principal: novo jogo (com customização), continuar e sair.

const CASTLE := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Castle.png"
const INTRO := [
	"Semestre 1. A Unifor acordou dividida em quatro reinos.",
	"Cada centro tem seu professor-chefe, sua moeda e suas atléticas.",
	"Você é só um aluno comum. Comece pelo CCT e não seja reprovado.",
]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	MapBuilder.island(self, Rect2i(3, 3, 12, 6))
	MapBuilder.building(self, CASTLE, Vector2(576, 420))
	for p in [Vector2(300, 300), Vector2(860, 320), Vector2(330, 500), Vector2(820, 500)]:
		MapBuilder.decor(self, "tree", p, rng)

	var layer := CanvasLayer.new()
	add_child(layer)
	var title := UI.hud_label(layer, "Reinos da Unifor", 56)
	title.position = Vector2(0, 40)
	title.size.x = 1152
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := UI.hud_label(layer, "Um roguelike no campus · v1.0 — Reino do CCT", 18)
	sub.position = Vector2(0, 112)
	sub.size.x = 1152
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var col := VBoxContainer.new()
	col.position = Vector2(456, 450)
	col.add_theme_constant_override(&"separation", 8)
	layer.add_child(col)
	if GameState.has_save():
		var b := UI.button(col, "Continuar", GameState.continue_game)
		b.custom_minimum_size.x = 240
		b.grab_focus.call_deferred()
	UI.button(col, "Novo jogo", _on_new_game).custom_minimum_size.x = 240
	UI.button(col, "Sair", get_tree().quit).custom_minimum_size.x = 240
	var hint := UI.hud_label(layer, "WASD andar · Mouse mirar · Esq/Dir atacar · Espaço dash · Q especial · E interagir · 1/2/3 itens · Esc pausa", 14)
	hint.position = Vector2(0, 618)
	hint.size.x = 1152
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _on_new_game() -> void:
	if not GameState.has_save():
		_customize()
		return
	var center := UI.overlay(self)
	var col := UI.panel(center, "Começar do zero?", 460)
	UI.label(col, "Isso apaga o progresso salvo: relíquias, reputação, Bits e a run em andamento.")
	UI.button(col, "Sim, novo jogo", func() -> void:
		Screens.close(center)
		_customize())
	UI.button(col, "Cancelar", func() -> void: Screens.close(center))


func _customize() -> void:
	Screens.customize(self, func(color: String) -> void:
		GameState.new_game(color)
		_intro(), "Seu personagem: cor do uniforme")


func _intro() -> void:
	var center := UI.overlay(self)
	var col := UI.panel(center, "", 620)
	for line in INTRO:
		UI.label(col, line, 20).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.button(col, "Ir para o campus", func() -> void: GameState.go(GameState.SCENE_CAMPUS))
