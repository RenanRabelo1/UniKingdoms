class_name CampusLayout
## Planta do campus. Posições relativas tiradas do mapa geral oficial da Unifor (2026):
## Av. Washington Soares a leste, Av. Dr. Valmir Pontes ao norte (NAMI e Fórum do outro lado),
## Pós-Unifor/Reitoria/Biblioteca a leste, Centro de Convivência no meio, blocos N–R e Teatro ao sul,
## ginásio/academia/piscina/campo/DCE a noroeste do centro, estádio e quadras a oeste, lagoa a sudoeste.
## Adaptação: o mapa não diz quais blocos são de cada centro (CCT/CCS/CCG/CCJ); a escolha é do jogo.
## Tudo em pixels (base dos objetos) ou tiles de 64 px (chão). Mundo: 100 × 75 tiles.

const WORLD := Vector2i(100, 75)
const SPAWN := Vector2(5120, 3260)

## Chão por material, na ordem de desenho (cada material numa camada; as bordas mostram a de baixo).
const GROUND := [
	["grama-tropical", [Rect2i(0, 0, 100, 75)]],
	["grama-clara", [Rect2i(1, 1, 19, 12), Rect2i(0, 50, 20, 22), Rect2i(76, 53, 20, 18), Rect2i(24, 1, 26, 11)]],
	["asfalto", [Rect2i(22, 13, 78, 2), Rect2i(97, 0, 3, 75), Rect2i(0, 72, 100, 3), Rect2i(23, 53, 21, 12)]],
	["ciclovia", [Rect2i(22, 15, 75, 1)]],
	["concreto-claro", [
		Rect2i(0, 30, 97, 2), Rect2i(18, 50, 79, 2), Rect2i(0, 22, 20, 2), Rect2i(50, 11, 47, 2),
		Rect2i(20, 16, 2, 56), Rect2i(46, 16, 2, 56), Rect2i(72, 0, 2, 72),
	]],
	["piso-praca", [Rect2i(61, 34, 11, 12), Rect2i(74, 46, 23, 4), Rect2i(37, 40, 9, 4), Rect2i(49, 58, 12, 3),
		Rect2i(84, 56, 10, 10)]],
	["agua-lagoa", [Rect2i(0, 54, 15, 17), Rect2i(15, 57, 3, 10), Rect2i(2, 52, 9, 2)]],
	["deck-madeira", [Rect2i(12, 61, 8, 2)]],
]
## Linhas (em tiles) das calçadas horizontais: os acessos dos prédios descem até a primeira abaixo.
const WALK_ROWS := [11, 13, 30, 50, 72]

## [id do kit, base, placa, papel]. Placa vazia = sem placa. Papel liga o prédio a uma interação.
const BUILDINGS := [
	["fachada-bloco-repetivel", Vector2(3550, 640), "Bloco F", ""],
	["nami", Vector2(5150, 690), "NAMI", ""],
	["forum", Vector2(5880, 690), "Fórum", ""],
	["quadra-tenis", Vector2(560, 860), "Quadras de tênis", ""],
	["quadra-tenis", Vector2(980, 860), "", ""],
	["quadra-poliesportiva", Vector2(980, 1820), "Quadra poliesportiva", ""],
	["fachada-bloco-repetivel", Vector2(330, 1820), "Bloco Z", ""],
	["academia", Vector2(1700, 1380), "Academia", ""],
	["piscina-olimpica", Vector2(1700, 1860), "Piscina", ""],
	["fachada-bloco-repetivel", Vector2(2560, 1260), "Bloco O", ""],
	["ginasio-poliesportivo", Vector2(2560, 1880), "Ginásio poliesportivo", ""],
	["ccg-bloco-gestao", Vector2(3420, 1420), "CCG — Comunicação e Gestão", "ccg"],
	["prefeitura-campus", Vector2(4050, 1380), "Prefeitura do campus", ""],
	["fachada-bloco-repetivel", Vector2(3800, 1860), "Bloco I", ""],
	["fachada-bloco-repetivel", Vector2(4300, 1860), "Bloco J", ""],
	["ccs-bloco-saude", Vector2(5100, 1480), "CCS — Ciências da Saúde", "ccs"],
	["pos-graduacao", Vector2(5800, 1480), "Pós-Unifor (blocos A, B e E)", ""],
	["espaco-cultural", Vector2(5800, 1900), "Espaço Cultural", ""],
	["estadio-atletismo", Vector2(660, 2700), "Estádio de atletismo", ""],
	["arquibancada", Vector2(660, 3120), "", ""],
	["campo-futebol-society", Vector2(1900, 2600), "Campo society", ""],
	["dce-atletica", Vector2(2620, 2560), "DCE", "atletica"],
	["tec-unifor", Vector2(3400, 2560), "TEC Unifor", ""],
	["fachada-bloco-repetivel", Vector2(3950, 2300), "Bloco K", ""],
	["centro-convivencia", Vector2(4300, 2780), "Centro de Convivência", ""],
	["fachada-bloco-repetivel", Vector2(3500, 3080), "Bloco M", ""],
	["ccj-bloco-direito", Vector2(5100, 2440), "CCJ — Ciências Jurídicas", "ccj"],
	["reitoria", Vector2(5800, 2560), "Reitoria — O Chanceler", "reitoria"],
	["biblioteca-central", Vector2(5120, 3120), "Biblioteca", "biblioteca"],
	["estacionamento-solar", Vector2(1800, 3720), "Estacionamento", ""],
	["estacionamento-solar", Vector2(2400, 3720), "", ""],
	["estacionamento-solar", Vector2(1800, 4120), "", ""],
	["estacionamento-solar", Vector2(2400, 4120), "", ""],
	["centro-eventos", Vector2(1700, 4560), "Centro de Eventos", ""],
	["portaria-principal", Vector2(2600, 4600), "Portaria (acesso A2)", ""],
	["cct-bloco-tecnologia", Vector2(3500, 3720), "CCT — Ciências Tecnológicas", "cct"],
	["fachada-bloco-repetivel", Vector2(3350, 4100), "Bloco P", ""],
	["fachada-bloco-repetivel", Vector2(3650, 4100), "Bloco Q", ""],
	["fachada-bloco-repetivel", Vector2(3500, 4460), "Bloco R", ""],
	["quiosque-cafe", Vector2(4050, 3640), "Lojinha do CCT", "shop"],
	["teatro-celina-queiroz", Vector2(4300, 4440), "Teatro Celina Queiroz", ""],
	["fachada-bloco-repetivel", Vector2(5000, 3700), "Bloco G", ""],
	["fachada-bloco-repetivel", Vector2(5000, 4100), "Bloco H", ""],
	["fonte-jardim", Vector2(5700, 3800), "", ""],
	["escultura-campus", Vector2(5700, 4250), "", ""],
]

## Reinos trancados: papel do prédio → texto.
const LOCKED := {
	"ccs": "CCS — Ciências da Saúde",
	"ccg": "CCG — Comunicação e Gestão",
	"ccj": "CCJ — Ciências Jurídicas",
	"reitoria": "Reitoria — O Chanceler",
}

## Paradas do carrinho elétrico (viagem rápida), como no mapa oficial.
const STOPS := [
	["Biblioteca", Vector2(4860, 3500)],
	["Centro de Convivência", Vector2(4500, 2010)],
	["Ginásio / DCE", Vector2(3220, 2010)],
	["Estádio", Vector2(1180, 2260)],
	["Lagoa", Vector2(1180, 3480)],
	["CCT / Estacionamento", Vector2(3170, 3470)],
	["NAMI", Vector2(4500, 780)],
]

## Totens de orientação: abrem o mapa do campus.
const TOTEMS := [Vector2(5320, 3290), Vector2(4560, 2650), Vector2(2840, 2700), Vector2(2900, 4380)]

## Encontros: [id, aviso, centro, inimigos]. Voltam a aparecer só depois que uma run termina.
const ENCOUNTERS := [
	["estadio", "Membros de uma atlética rival estão treinando na pista do estádio!", Vector2(660, 2460),
		["atletica", "atletica", "bug", "bug"]],
	["lagoa", "Barris à deriva perto da lagoa!", Vector2(1340, 3760), ["barril", "barril", "bug", "barril"]],
	["estacionamento", "Bugs soltos no estacionamento!", Vector2(2100, 3900), ["bug", "bug", "bug", "robo", "bug"]],
	["nami", "Robôs bloqueando a Av. Valmir Pontes!", Vector2(4300, 900), ["robo", "robo", "bug", "bug"]],
	["quadras", "Bugs invadiram as quadras de tênis!", Vector2(760, 820), ["bug", "bug", "bug", "barril"]],
	["corredor", "Patrulha de robôs entre os blocos K e M!", Vector2(3850, 2650), ["robo", "bug", "robo", "bug"]],
]
