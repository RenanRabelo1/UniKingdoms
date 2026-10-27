class_name MapBuilder
## Monta ilhas de grama (tileset Tiny Swords), paredes invisíveis, decoração e construções.

const TILE := 64
const FREE := "res://Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/"
const TREES := [["Tree1.png", 256], ["Tree2.png", 256], ["Tree3.png", 192], ["Tree4.png", 192]]

static var _tileset: TileSet


static func tileset() -> TileSet:
	if _tileset:
		return _tileset
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = load(FREE + "Terrain/Tileset/Tilemap_color1.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	for x in 3:
		for y in 3:
			src.create_tile(Vector2i(x, y))
	_tileset.add_source(src, 0)
	return _tileset


## Ilha retangular em tiles, com bordas e cantos do tileset.
static func island(parent: Node, rect: Rect2i) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = tileset()
	layer.z_index = -10
	parent.add_child(layer)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var ax := 0 if x == rect.position.x else (2 if x == rect.end.x - 1 else 1)
			var ay := 0 if y == rect.position.y else (2 if y == rect.end.y - 1 else 1)
			layer.set_cell(Vector2i(x, y), 0, Vector2i(ax, ay))
	return layer


## Corpo estático com retângulos de colisão (em pixels).
static func walls(parent: Node, rects: Array) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_mask = 0
	parent.add_child(body)
	for r in rects:
		add_rect(body, r)
	return body


static func add_rect(body: StaticBody2D, r: Rect2) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = r.get_center()
	body.add_child(cs)
	return cs


## Paredes por fora de um retângulo jogável.
static func border(parent: Node, area: Rect2, t := 40.0) -> StaticBody2D:
	return walls(parent, [
		Rect2(area.position.x - t, area.position.y - t, area.size.x + 2 * t, t),
		Rect2(area.position.x - t, area.end.y, area.size.x + 2 * t, t),
		Rect2(area.position.x - t, area.position.y, t, area.size.y),
		Rect2(area.end.x, area.position.y, t, area.size.y),
	])


## Decoração: "tree" e "rock" bloqueiam passagem; "bush" não.
static func decor(parent: Node, kind: String, pos: Vector2, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D
	var radius := 0.0
	match kind:
		"tree":
			var t: Array = TREES[rng.randi() % TREES.size()]
			var s := AnimatedSprite2D.new()
			s.sprite_frames = SheetFrames.build({"sway": [FREE + "Terrain/Resources/Wood/Trees/" + t[0], 192, t[1], 0, 8, 8.0, true]})
			s.autoplay = "sway"
			s.position.y = -t[1] / 2.0 + 36
			root = StaticBody2D.new()
			root.add_child(s)
			radius = 18.0
		"rock":
			var s := Sprite2D.new()
			s.texture = load(FREE + "Terrain/Decorations/Rocks/Rock%d.png" % (rng.randi() % 4 + 1))
			s.position.y = -16
			root = StaticBody2D.new()
			root.add_child(s)
			radius = 16.0
		_:
			var s := AnimatedSprite2D.new()
			s.sprite_frames = SheetFrames.build({"sway": [FREE + "Terrain/Decorations/Bushes/Bushe%d.png" % (rng.randi() % 4 + 1), 128, 128, 0, 8, 8.0, true]})
			s.autoplay = "sway"
			s.position.y = -30
			root = Node2D.new()
			root.add_child(s)
	if root is StaticBody2D:
		root.collision_mask = 0
		var shape := CircleShape2D.new()
		shape.radius = radius
		var cs := CollisionShape2D.new()
		cs.shape = shape
		root.add_child(cs)
	parent.add_child(root)
	root.global_position = pos
	return root


## Construção com a base no ponto `pos` e colisão na parte de baixo.
static func building(parent: Node, path: String, pos: Vector2) -> StaticBody2D:
	var tex: Texture2D = load(path)
	var body := StaticBody2D.new()
	body.collision_mask = 0
	var s := Sprite2D.new()
	s.texture = tex
	s.position.y = -tex.get_height() / 2.0 + 24
	body.add_child(s)
	var w := tex.get_width() * 0.75
	add_rect(body, Rect2(-w / 2.0, -60, w, 70))
	parent.add_child(body)
	body.global_position = pos
	return body


## Faixa com texto (ribbon do Tiny Swords) para placas no mapa.
static func sign_label(parent: Node, text: String, pos: Vector2, color := "Yellow") -> void:
	var p := PanelContainer.new()
	var sb := UI._box("res://Tiny Swords/Tiny Swords (Update 010)/UI/Ribbons/Ribbon_%s_3Slides.png" % color,
		44, 16, 44, 22, 40, 6, 40, 16)
	p.add_theme_stylebox_override(&"panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.z_index = 40
	var l := UI.label(p, text, 16, Color(0.2, 0.12, 0.05))
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.ignore_mouse(p)
	parent.add_child(p)
	p.reset_size()
	p.global_position = pos - Vector2(p.size.x / 2.0, 0)
