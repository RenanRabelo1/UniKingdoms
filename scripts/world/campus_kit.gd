class_name CampusKit
## Monta o campus com o Unifor-campus-kit (`res://assets/unifor/`): terreno com autotile de 8 vizinhos
## e objetos com colisão revisada, ordenação por Y e transparência quando o player passa por trás.

const ROOT := "res://assets/unifor/"
const TERRAIN := ROOT + "godot/unifor-terrain.tres"
## Material → source_id no TileSet do kit (catalog.json).
const MATERIALS := {"grama-tropical": 0, "grama-clara": 1, "piso-praca": 2, "concreto-claro": 3,
	"asfalto": 4, "terra": 5, "areia": 6, "deck-madeira": 7, "piso-biblioteca": 8, "pista-atletismo": 9,
	"quadra-azul": 10, "gramado-campo": 11, "agua-lagoa": 12, "agua-piscina": 13, "piso-ladrilho": 14,
	"ciclovia": 15}
## Máscara de vizinhos (N=1, E=2, S=4, W=8, NE=16, SE=32, SW=64, NW=128) → célula do atlas (masks.json).
## A diagonal só conta quando os dois lados vizinhos também são do material.
const MASKS := {
	0: Vector2i(3, 0), 1: Vector2i(4, 0), 2: Vector2i(5, 0), 3: Vector2i(6, 0), 4: Vector2i(7, 0),
	5: Vector2i(8, 0), 6: Vector2i(3, 1), 7: Vector2i(4, 1), 8: Vector2i(5, 1), 9: Vector2i(6, 1),
	10: Vector2i(7, 1), 11: Vector2i(8, 1), 12: Vector2i(3, 2), 13: Vector2i(4, 2),
	14: Vector2i(5, 2), 15: Vector2i(6, 2), 19: Vector2i(0, 2), 23: Vector2i(7, 2),
	27: Vector2i(8, 2), 31: Vector2i(0, 3), 38: Vector2i(0, 0), 39: Vector2i(1, 3),
	46: Vector2i(2, 3), 47: Vector2i(3, 3), 55: Vector2i(0, 1), 63: Vector2i(4, 3),
	76: Vector2i(2, 0), 77: Vector2i(5, 3), 78: Vector2i(6, 3), 79: Vector2i(7, 3),
	95: Vector2i(8, 3), 110: Vector2i(1, 0), 111: Vector2i(0, 4), 127: Vector2i(1, 4),
	137: Vector2i(2, 2), 139: Vector2i(2, 4), 141: Vector2i(3, 4), 143: Vector2i(4, 4),
	155: Vector2i(1, 2), 159: Vector2i(5, 4), 175: Vector2i(6, 4), 191: Vector2i(7, 4),
	205: Vector2i(2, 1), 207: Vector2i(8, 4), 223: Vector2i(0, 5), 239: Vector2i(1, 5),
	255: Vector2i(1, 1)
}
const NEIGHBORS := [[Vector2i(0, -1), 1], [Vector2i(1, 0), 2], [Vector2i(0, 1), 4], [Vector2i(-1, 0), 8]]
const DIAGONALS := [[Vector2i(1, -1), 16, 1, 2], [Vector2i(1, 1), 32, 4, 2], [Vector2i(-1, 1), 64, 4, 8],
	[Vector2i(-1, -1), 128, 1, 8]]

## Superfícies de chão: ficam sempre embaixo dos personagens e não bloqueiam.
const FLAT := ["estadio-atletismo", "campo-futebol-society", "quadra-tenis", "quadra-poliesportiva",
	"vitoria-regia", "canteiro-flores", "corredor-horizontal", "corredor-vertical", "corredor-canto",
	"corredor-cruzamento", "ponte-madeira", "rampa-acesso", "escada-frontal"]
const TREES := ["arvore-copa-larga", "arvore-copa-redonda", "arvore-alta", "arvore-florida-amarela",
	"palmeira-alta", "palmeira-jovem", "coqueiro", "palmeiras-duplas"]
## Sem colisão: quem passa por baixo ou por cima (o player fica transparente-visível pela oclusão).
const WALKABLE := ["centro-convivencia", "portaria-principal", "estacionamento-solar",
	"ponto-carrinho-eletrico", "arbusto-redondo", "capim-lagoa", "pedras-pequenas", "totem-orientacao",
	"bicicletario", "cobertura-solar", "carrinho-eletrico"]
## Tamanho da colisão como fração da largura/altura do sprite, para objetos que não são prédio nem árvore.
const PROP_BOX := {
	"piscina-olimpica": [0.86, 0.7], "arquibancada": [0.9, 0.55], "fonte-jardim": [0.7, 0.4],
	"banca-lanchonete": [0.8, 0.45], "quiosque-cafe": [0.8, 0.45], "guarda-sol-mesa": [0.5, 0.25],
	"mesa-piquenique": [0.8, 0.35], "carrinho-eletrico": [0.8, 0.3], "pedra-grande": [0.8, 0.35],
	"cerca-viva-horizontal": [0.92, 0.25], "cerca-viva-canto": [0.9, 0.6], "muro-baixo": [0.92, 0.4],
}
const OCCLUDE_ALPHA := 0.45

static var _tileset: TileSet


static func tileset() -> TileSet:
	if _tileset == null:
		_tileset = load(TERRAIN)
	return _tileset


## Camada de terreno com os encaixes calculados pelos vizinhos do mesmo material.
static func ground(parent: Node, material: String, cells: Dictionary) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = "Chao_" + material
	layer.tile_set = tileset()
	layer.z_index = -10
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var source: int = MATERIALS[material]
	for cell in cells:
		layer.set_cell(cell, source, MASKS.get(mask(cells, cell), Vector2i(1, 1)))
	parent.add_child(layer)
	return layer


static func mask(cells: Dictionary, cell: Vector2i) -> int:
	var m := 0
	for n in NEIGHBORS:
		if cells.has(cell + n[0]):
			m |= n[1]
	for d in DIAGONALS:
		if m & d[2] and m & d[3] and cells.has(cell + d[0]):
			m |= d[1]
	return m


## Células de um conjunto de retângulos (em tiles).
static func cells_of(rects: Array) -> Dictionary:
	var cells := {}
	for r: Rect2i in rects:
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				cells[Vector2i(x, y)] = true
	return cells


## Instancia o objeto do kit com a base em `pos` e troca a colisão aproximada do kit por uma por tipo.
static func place(parent: Node, id: String, pos: Vector2) -> Node2D:
	var node: Node2D = load(ROOT + "godot/prefabs/%s.tscn" % id).instantiate()
	var sprite: Sprite2D = node.get_node(^"Sprite2D")
	for c in node.get_children():
		if c is CollisionShape2D:
			node.remove_child(c)
			c.free()
	var box := collision_box(id, sprite)
	if box.has_area():
		var body: CollisionObject2D = node if node is StaticBody2D else StaticBody2D.new()
		if body != node:
			node.add_child(body)
		body.collision_layer = Constants.LAYER_WORLD
		body.collision_mask = 0
		MapBuilder.add_rect(body, box)
	if id in FLAT:
		node.z_index = -5
	else:
		node.add_to_group(&"occluder")
	node.set_meta(&"kit_id", id)
	parent.add_child(node)
	node.global_position = pos
	# Objetos do kit são estáticos: o retângulo do sprite é calculado uma vez (oclusão e mapa).
	node.set_meta(&"rect", sprite_rect(node))
	return node


## Retângulo de colisão (relativo à base) de cada tipo de objeto.
static func collision_box(id: String, sprite: Sprite2D) -> Rect2:
	var size := sprite.texture.get_size()
	var top := sprite.position.y - size.y / 2.0
	if id in FLAT or id in WALKABLE:
		return Rect2()
	if id in TREES:
		return Rect2(-16, -22, 32, 20)
	if sprite.texture.resource_path.contains("/buildings/"):
		# Prédio: a planta ocupa quase todo o sprite (vista de cima); só o topo do telhado fica livre
		# para o player passar por trás sem sumir.
		var y0 := top + size.y * 0.22
		return Rect2(-size.x * 0.42, y0, size.x * 0.84, -6.0 - y0)
	if PROP_BOX.has(id):
		var f: Array = PROP_BOX[id]
		var h: float = (-top) * f[1]
		return Rect2(-size.x * f[0] / 2.0, -h - 4.0, size.x * f[0], h)
	# Objetos pequenos (bancos, postes, lixeiras): só a base.
	return Rect2(-minf(size.x * 0.33, 40.0), -18, minf(size.x * 0.66, 80.0), 16)


## Retângulo do sprite em coordenadas globais (para oclusão e para o mapa).
static func sprite_rect(node: Node2D) -> Rect2:
	var sprite: Sprite2D = node.get_node(^"Sprite2D")
	var size := sprite.texture.get_size()
	return Rect2(node.global_position + sprite.position - size / 2.0, size)


## Deixa transparente o que está na frente do ponto (o player atrás de prédios e copas).
static func update_occlusion(tree: SceneTree, point: Vector2) -> void:
	for node: Node2D in tree.get_nodes_in_group(&"occluder"):
		var rect: Rect2 = node.get_meta(&"rect")
		var behind := point.y < node.global_position.y - 8.0 and rect.grow(-8).has_point(point)
		var target := OCCLUDE_ALPHA if behind else 1.0
		if node.modulate.a != target:
			node.modulate.a = move_toward(node.modulate.a, target, 0.08)
