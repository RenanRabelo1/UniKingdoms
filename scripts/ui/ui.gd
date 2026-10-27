class_name UI
## Tema com as peças 9-slice do Tiny Swords e atalhos para montar telas em código.

const OLD_UI := "res://Tiny Swords/Tiny Swords (Update 010)/UI/"
const FREE_UI := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/UI Elements/UI Elements/"
const INK := Color(0.22, 0.15, 0.1)
const AVATARS := {
	"Profa. Lógica": FREE_UI + "Human Avatars/Avatars_05.png",
	"Prof. Circuito": FREE_UI + "Human Avatars/Avatars_02.png",
	"Profa. Prancheta": FREE_UI + "Human Avatars/Avatars_12.png",
}

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font_size = 18
	var btn := _box(OLD_UI + "Buttons/Button_Blue_3Slides.png", 22, 14, 22, 20, 18, 8, 18, 14)
	_theme.set_stylebox(&"normal", &"Button", btn)
	_theme.set_stylebox(&"focus", &"Button", StyleBoxEmpty.new())
	_theme.set_stylebox(&"hover", &"Button", _box(OLD_UI + "Buttons/Button_Hover_3Slides.png", 22, 14, 22, 20, 18, 8, 18, 14))
	_theme.set_stylebox(&"pressed", &"Button", _box(OLD_UI + "Buttons/Button_Blue_3Slides_Pressed.png", 22, 14, 22, 20, 18, 10, 18, 12))
	_theme.set_stylebox(&"disabled", &"Button", _box(OLD_UI + "Buttons/Button_Disable_3Slides.png", 22, 14, 22, 20, 18, 8, 18, 14))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		_theme.set_color(c, &"Button", INK)
	_theme.set_color(&"font_disabled_color", &"Button", Color(0.35, 0.35, 0.35))
	_theme.set_stylebox(&"panel", &"PanelContainer", _box(OLD_UI + "Banners/Carved_9Slides.png", 26, 26, 26, 26, 26, 22, 26, 24))
	_theme.set_color(&"font_color", &"Label", INK)
	_theme.set_color(&"default_color", &"RichTextLabel", INK)
	return _theme


static func _box(path: String, ml: int, mt: int, mr: int, mb: int, cl: int, ct: int, cr: int, cb: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(path)
	s.texture_margin_left = ml
	s.texture_margin_top = mt
	s.texture_margin_right = mr
	s.texture_margin_bottom = mb
	s.content_margin_left = cl
	s.content_margin_top = ct
	s.content_margin_right = cr
	s.content_margin_bottom = cb
	return s


## Fundo escurecido que cobre a tela e bloqueia cliques no mundo.
static func overlay(parent: Node) -> Control:
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	return center


## Painel de pergaminho com título; devolve a coluna onde vai o conteúdo.
static func panel(parent: Control, title: String, min_width := 420) -> VBoxContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = min_width
	parent.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 10)
	p.add_child(col)
	if title != "":
		var t := label(col, title, 28)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return col


static func label(parent: Node, text: String, size := 18, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


## Texto branco com contorno, para HUD sobre o mapa.
static func hud_label(parent: Node, text: String, size := 18) -> Label:
	var l := label(parent, text, size, Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_color_override(&"font_outline_color", Color.BLACK)
	l.add_theme_constant_override(&"outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 46)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


static func icon(parent: Node, tex: Texture2D, size := 40) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


static func bar(parent: Node, fill: Color, width := 220, height := 18) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(width, height)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.1, 0.1, 0.85)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.1, 0.05, 0.02)
	bg.set_corner_radius_all(4)
	var fg := bg.duplicate()
	fg.bg_color = fill
	b.add_theme_stylebox_override(&"background", bg)
	b.add_theme_stylebox_override(&"fill", fg)
	parent.add_child(b)
	return b


## Garante que nada do HUD/mapa engula cliques do mouse (bug do M01).
static func ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		ignore_mouse(c)
