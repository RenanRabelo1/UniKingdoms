class_name Constants
## Tuning global. Valores por arma ficam em WeaponData; aqui só o que é do player e do especial.

const PLAYER_SPEED := 260.0
const PLAYER_MAX_HP := 100
## Invencibilidade depois de levar um golpe.
const HURT_IFRAMES := 0.6

const DASH_SPEED := 900.0
const DASH_DURATION := 0.15
const DASH_COOLDOWN := 0.6

const COMBO_WINDOW := 0.8

## Porcentagem da barra por segundo e por ponto de dano causado.
const SPECIAL_CHARGE_PER_SECOND := 4.0
const SPECIAL_CHARGE_PER_DAMAGE := 1.0
const SPECIAL_DAMAGE := 40
const SPECIAL_RADIUS := 140.0

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMIES := 4

## Bônus aceitos em Player.stats (somados de ensinamentos, relíquias e itens).
## Frações (0.2 = +20%), exceto max_hp e heal_on_kill (pontos).
const STAT_KEYS := [&"dmg_basic", &"dmg_heavy", &"dmg_all", &"attack_speed", &"reach", &"speed",
	&"dash_cd", &"special_rate", &"combo_bonus", &"crit", &"heal_on_kill", &"max_hp", &"bits_gain"]
