class_name Screens
## Telas modais montadas em código. Quem abre pausa o jogo e passa `on_close`.

const MARKET_NAMES := {"cct": "Lojinha do CCT", "atletica": "Mercado da Atlética Engrenagem",
	"run": "Mercado da sala"}


## Atalhos de teclado de uma tela (ação do Input Map -> Callable).
class Keys:
	extends Node
	var handlers := {}

	func _unhandled_input(event: InputEvent) -> void:
		for action in handlers:
			if event.is_action_pressed(action):
				get_viewport().set_input_as_handled()
				handlers[action].call()
				return


static func _keys(center: Control, handlers: Dictionary) -> void:
	var k := Keys.new()
	k.handlers = handlers
	center.add_child(k)


static func close(c: Node) -> void:
	while c and not c is CanvasLayer:
		c = c.get_parent()
	if c:
		c.queue_free()


static func pause(parent: Node, on_resume: Callable) -> void:
	var center := UI.overlay(parent)
	var col := UI.panel(center, "Pausado", 360)
	var resume := func() -> void:
		close(center)
		on_resume.call()
	UI.button(col, "Continuar", resume)
	var hint := "A run continua da sala atual." if GameState.has_run() else ""
	UI.button(col, "Salvar e sair para o menu", func() -> void:
		GameState.save_game()
		GameState.go(GameState.SCENE_MENU))
	if hint != "":
		UI.label(col, hint, 14)
	_keys(center, {&"pause": resume})


static func teaching_choice(parent: Node, offers: Array, on_pick: Callable) -> void:
	var center := UI.overlay(parent)
	var col := UI.panel(center, "Escolha um ensinamento", 900)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	col.add_child(row)
	var handlers := {}
	for i in offers.size():
		var t: TeachingData = offers[i]
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(270, 0)
		card.add_theme_constant_override(&"separation", 6)
		row.add_child(card)
		UI.icon(card, load(UI.AVATARS.get(t.professor, UI.AVATARS["Profa. Lógica"])), 72)
		UI.label(card, t.professor, 15).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.label(card, t.display_name, 22).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var desc := UI.label(card, t.description, 16)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.custom_minimum_size.y = 48
		var pick := func() -> void:
			close(center)
			on_pick.call(t)
		UI.button(card, "Escolher [%d]" % (i + 1), pick)
		handlers[StringName("item_%d" % (i + 1))] = pick
	_keys(center, handlers)


static func shop(parent: Node, market: String, on_close: Callable) -> void:
	var center := UI.overlay(parent)
	var col := UI.panel(center, MARKET_NAMES[market], 640)
	var wallet := UI.label(col, "", 18)
	if market == "atletica":
		UI.label(col, "Desconto pela reputação: %d%% (reputação %d)" % [
			roundi(GameState.discount() * 100), GameState.profile.reputation], 15)
	elif market == "run":
		UI.label(col, "Compras daqui só valem nesta run.", 15)
	else:
		UI.label(col, "Compras daqui vão para o seu estoque e ficam até você usar.", 15)
	var rows: Array[Callable] = []
	for it in GameState.ITEMS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		col.add_child(row)
		UI.icon(row, it.icon, 44)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		UI.label(info, it.display_name, 18)
		UI.label(info, it.description, 14)
		var owned := UI.label(row, "", 15)
		owned.custom_minimum_size.x = 70
		var cost := GameState.price(it, market)
		var b := UI.button(row, "%d Bits" % cost, func() -> void: pass)
		b.custom_minimum_size.x = 130
		b.pressed.connect(func() -> void:
			GameState.buy(it, market)
			for r in rows:
				r.call())
		rows.append(func() -> void:
			b.disabled = GameState.wallet() < cost
			owned.text = "tem %d" % GameState.item_count(String(it.id)))
	rows.append(func() -> void: wallet.text = "Seus Bits: %d" % GameState.wallet())
	for r in rows:
		r.call()
	var done := func() -> void:
		close(center)
		on_close.call()
	UI.button(col, "Sair [Esc]", done)
	_keys(center, {&"pause": done})


static func result(parent: Node, r: Dictionary) -> void:
	var center := UI.overlay(parent)
	var col := UI.panel(center, "CCT conquistado!" if r.victory else "Reprovado!", 520)
	if r.victory:
		UI.label(col, "Você derrotou o Prof. Mainframe e conquistou o Centro de Ciências Tecnológicas.")
		UI.label(col, "Bits guardados no banco: %d" % r.bits)
		if not r.unlocked.is_empty():
			UI.label(col, "Novas habilidades no pool dos professores: " + ", ".join(r.unlocked))
		UI.label(col, "Os outros reinos (CCS, CCG e CCJ) chegam nas próximas versões.", 15)
	else:
		UI.label(col, "Você chegou à sala %d de %d." % [r.room, GameState.ROOM_COUNT])
		UI.label(col, "Bits da run perdidos: %d" % r.bits)
		UI.label(col, "Relíquias, reputação e itens do estoque continuam com você.", 15)
	UI.label(col, "Inimigos derrotados: %d" % r.kills)
	UI.button(col, "Voltar ao campus", func() -> void: GameState.go(GameState.SCENE_CAMPUS))


static func relics(parent: Node, on_close: Callable) -> void:
	var center := UI.overlay(parent)
	var col := UI.panel(center, "Coleção de Relíquias", 640)
	UI.label(col, "%d de %d encontradas. Relíquias são permanentes e dão bônus em todas as runs." % [
		GameState.profile.relics.size(), GameState.RELICS.size()], 15)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 18)
	col.add_child(grid)
	for r in GameState.RELICS:
		var owned: bool = String(r.id) in GameState.profile.relics
		var row := HBoxContainer.new()
		row.custom_minimum_size.x = 270
		grid.add_child(row)
		var ic := UI.icon(row, r.icon, 44)
		ic.modulate = Color.WHITE if owned else Color(0, 0, 0, 0.5)
		var info := VBoxContainer.new()
		info.custom_minimum_size.x = 210
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		UI.label(info, r.display_name if owned else "???", 16)
		UI.label(info, r.description if owned else "Ainda não encontrada.", 13)
	var done := func() -> void:
		close(center)
		on_close.call()
	UI.button(col, "Fechar [Esc]", done)
	_keys(center, {&"pause": done})


static func customize(parent: Node, on_done: Callable, title := "Espelho: cor do uniforme") -> void:
	var center := UI.overlay(parent)
	var col := UI.panel(center, title, 620)
	UI.label(col, "Escolha a cor do seu uniforme. A cor vermelha é da atlética.", 15)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	col.add_child(row)
	for c in GameState.COLORS:
		var card := VBoxContainer.new()
		row.add_child(card)
		var preview := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = load(SheetFrames.warrior(c).idle[0])
		atlas.region = Rect2(48, 40, 96, 100)
		preview.texture = atlas
		preview.custom_minimum_size = Vector2(130, 120)
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.add_child(preview)
		var b := UI.button(card, GameState.COLOR_NAMES[c], func() -> void:
			close(center)
			on_done.call(c))
		b.custom_minimum_size.x = 130
		if c == GameState.profile.color:
			b.text += " ✓"


static func mission(parent: Node, on_close: Callable) -> void:
	var center := UI.overlay(parent)
	var col := UI.panel(center, GameState.ATLETICA_NAME, 560)
	var rep: int = GameState.profile.reputation
	UI.label(col, "Reputação: %d (%s)" % [rep, "aliada" if GameState.is_ally() else "neutra"])
	if GameState.is_ally():
		UI.label(col, "A atlética está do seu lado: sem emboscadas nas runs e %d%% de desconto no mercado dela." % roundi(GameState.discount() * 100), 15)
	else:
		UI.label(col, "Enquanto não for aliada (%d de reputação), a atlética pode te emboscar nas runs. Missões aumentam a reputação e pagam Bits." % GameState.ALLY_REP, 15)
	var m: Dictionary = GameState.accept_mission()
	UI.label(col, "Missão atual: %s" % m.text, 18)
	if m.has("enemy"):
		UI.label(col, "Progresso: %d/%d" % [m.progress, m.goal], 16)
	UI.label(col, "Recompensa: +%d de reputação e +%d Bits no banco." % [GameState.MISSION_REP, GameState.MISSION_BITS], 15)
	var done := func() -> void:
		close(center)
		on_close.call()
	UI.button(col, "Fechar [Esc]", done)
	_keys(center, {&"pause": done})
