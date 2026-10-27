# Tech stack

## Engine / runtime

- **Engine:** Godot 4.7 (instalado via Steam, 4.7.2.stable)
- **Language(s):** GDScript
- **Target platforms:** Windows (PC)

## Libraries / frameworks

| Library | Version | Purpose |
|---------|---------|---------|
| GUT (Godot Unit Test) | 9.7.1 | Testes automatizados da lógica (combos, dano, economia, reputação, save) |

Nenhuma outra dependência por enquanto.

## Tooling

- **Package manager:** nenhum (plugins vão em `addons/`)
- **Build:** preset "Windows Desktop" em `export_presets.cfg` → `builds/ReinosDaUnifor.exe` (templates 4.7.2 instalados)
- **Testing:** GUT (52 testes) + `tests/tools/autoplay.gd` (fluxo ponta a ponta); playtest manual para feel
- **Linting / formatting:** guia de estilo oficial do GDScript (gdtoolkit/gdformat é opcional)
- **Asset / binary storage:** Git LFS ainda não. Reavaliar quando houver muitos assets.

## Project layout

Raiz do projeto: `C:\Users\renpo\Downloads\Aplicacoes\G\uni-king-dooms` (é onde fica o `project.godot`).

Assets: `Tiny Swords/Tiny Swords (Update 010)/` e `Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/` na raiz (fora do git, pela licença). O lixo de macOS tem `.gdignore`.

```
docs/                 # design, milestones, ADRs, estado
addons/               # plugins (GUT)
assets/               # sprites, tiles, áudio, fontes (placeholders e packs gratuitos)
  <tipo>/<reino>/
data/                 # recursos .tres: itens, combos, ensinamentos, inimigos, facções
scenes/
  ui/main_menu        # cena principal
  campus/             # hub: Biblioteca, lojas, atlética, portão
  run/room            # sala da run (todas as 12 usam a mesma cena)
  actors/             # enemy, boss, projectile
  player/
  enemies/            # boneco de treino
scripts/
  autoload/game_state # único autoload: estado, economia, atlética, save, troca de cena
  anim/               # SheetFrames (animações a partir de spritesheets)
  combat/             # dados (Weapon/Combo/Enemy/Teaching/Item/Relic) e lógica pura
  ui/                 # tema, HUD, telas modais
  world/              # WorldController, MapBuilder, Interactable, Coin
tests/                # GUT (unit, integration) e tools/autoplay.gd
builds/               # export Windows (fora do git)
```

## Conventions

- **Code naming:** `snake_case` para arquivos, funções e variáveis; `PascalCase` para `class_name` e nós; `UPPER_SNAKE` para constantes (guia oficial do GDScript).
- **Onde ficam os scripts:** script de cena fica ao lado da `.tscn` (ex.: `scenes/player/player.gd`); lógica pura e classes de dados ficam em `scripts/` (ex.: `scripts/combat/`).
- **IA:** `enum` + `match` no script (inimigos e chefe). A state machine por nós fica para quando um caso exigir.
- **Data-driven:** itens, combos, ensinamentos, inimigos, moedas e facções são `Resource` (`.tres`) em `data/`. Adicionar conteúdo não deve exigir mexer em código.
- **Estado global:** só no autoload `GameState` (estado, economia, reputação, save e sinais globais `enemy_killed`, `bits_changed`, `items_changed`, `notice`). Não há autoloads separados até alguém precisar.
- **Constantes:** tuning em `scripts/constants.gd` (`class_name Constants`) ou nos `Resource`s de dados, nunca solto na lógica.
- **Input:** ações nomeadas no Input Map (`move_*`, `attack_basic`, `attack_heavy`, `special`, `dash`, `interact`), nunca teclas cruas.
- **Inspeção:** `GameState.state_to_text()` devolve um JSON do estado, para verificação por agente.
- **Asset naming:** `kebab-case`, prefixado por reino quando for específico (`cct-robot-idle.png`).

## Out-of-scope dependencies

- C#/.NET: GDScript basta e o usuário já conhece.
- Frameworks de rede: o jogo não tem multiplayer.
