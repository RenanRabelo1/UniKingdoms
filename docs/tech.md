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
- **Testing:** GUT (119 testes) + `tests/tools/autoplay.gd` (vitória/morte/continuar) + `tests/tools/combat_playtest.gd` (movimento e ataques reais sem invencibilidade) + `tests/tools/rhythm_review.gd` (capturas em janela). `tests/tools/shots.gd` mantém as capturas amplas e medição de quadro do campus. Playtest humano avalia feel e equilíbrio.
- **Linting / formatting:** guia de estilo oficial do GDScript (gdtoolkit/gdformat é opcional)
- **Asset / binary storage:** Git LFS ainda não. Reavaliar quando houver muitos assets.

## Project layout

Raiz do projeto: `C:\Users\renpo\Downloads\Aplicacoes\G\uni-king-dooms` (é onde fica o `project.godot`).

Assets:
- `Tiny Swords/Tiny Swords (Update 010)/` e `Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/` na raiz (fora do git, pela licença). O lixo de macOS tem `.gdignore`.
- `assets/unifor/`: cópia do `unifor-campus-kit` (no git). A pasta original `unifor-campus-kit/` fica como referência, com `.gdignore` e fora do git.
- Packs na raiz que o jogo **não usa** (Raven Fantasy Icons, FreeEnvironment, Modern Interiors, Tiny RPG 01/02) têm `.gdignore` (o Godot não importa) e ficam fora do git.
- `docs/referencias/unifor-mapa-geral-2026.pdf`: mapa oficial usado como referência do campus (fora do git).

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
- **Input:** ações nomeadas no Input Map (`move_*`, `attack_basic`, `attack_heavy`, `special`, `dash`, `interact`, `campus_map` (M), `debug_combat` (F3)), nunca teclas cruas. Todas com `"device": -1` (qualquer teclado/mouse).
- **Camadas de física:** 1 mundo, 2 player, 3 inimigos (colisão de movimento), 4 hurtbox (área que recebe golpes, `Hurtbox`). O golpe do player procura só a camada 4.
- **Campus:** planta por dados em `scenes/campus/campus_layout.gd`, montada por `scripts/world/campus_kit.gd` (autotile de 8 vizinhos a partir de `masks.json` do kit, colisão por tipo de objeto, superfícies planas com `z_index -5`, oclusão por transparência).
- **Inspeção:** `GameState.state_to_text()` devolve um JSON do estado, para verificação por agente.
- **Asset naming:** `kebab-case`, prefixado por reino quando for específico (`cct-robot-idle.png`).

## Sistemas da v1.2

- `scripts/world/encounter_director.gd` + `encounter_data.gd` e `data/encounters/`: composição, limite de inimigos, aviso e bônus de ritmo por dados.
- `scripts/combat/boss_data.gd` + `data/enemies/mainframe.tres`: tuning do chefe.
- `Player.combat_status()`: esquiva, janela de avanço e próximo passo do combo para o HUD; sinais `dashed` e `combat_hit` para áudio/efeitos.
- `GameState.room_phase()`, `checkpoint_room()` e `sync_room_player()`: fase/vida/especial, compatibilidade v1 e snapshot de entrada preservado nos saves de progresso permanente durante combate.
- `scripts/audio/game_audio.gd`: sons originais sintetizados e cacheados; preferência de efeitos em `user://audio.cfg`; máximo de 12 vozes. Sem novo autoload.
- `scripts/ui/campus_waypoint.gd`: direção do CCT no CanvasLayer. HUD em anchors/containers; viewport base explícito de 1152×648.
- `builds/ReinosDaUnifor-v1.2.exe`: entrega separada da build anterior. Evidências de testes e capturas em `builds/` (fora do Git).

## Out-of-scope dependencies (mantidas)

- C#/.NET: GDScript basta e o usuário já conhece.
- Frameworks de rede: o jogo não tem multiplayer.
