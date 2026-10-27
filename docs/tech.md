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
- **Build:** export do Godot para Windows
- **Testing:** GUT para lógica; playtest manual para feel e visual
- **Linting / formatting:** guia de estilo oficial do GDScript (gdtoolkit/gdformat é opcional)
- **Asset / binary storage:** Git LFS ainda não. Reavaliar quando houver muitos assets.

## Project layout

Raiz do projeto: `C:\Users\renpo\Downloads\Aplicacoes\G\uni-king-dooms` (é onde fica o `project.godot`).

```
docs/                 # design, milestones, ADRs, estado
addons/               # plugins (GUT)
assets/               # sprites, tiles, áudio, fontes (placeholders e packs gratuitos)
  <tipo>/<reino>/
data/                 # recursos .tres: itens, combos, ensinamentos, inimigos, facções
scenes/
  hub/                # Biblioteca, coleção de relíquias
  campus/             # mundo aberto
  realms/cct/         # área do reino e salas da run
  player/
  enemies/
  ui/
scripts/
  autoload/           # singletons: GameState, SaveManager, Economy, Reputation
  combat/
  run/                # geração e sequência de salas, recompensas
tests/                # testes GUT
```

## Conventions

- **Code naming:** `snake_case` para arquivos, funções e variáveis; `PascalCase` para `class_name` e nós; `UPPER_SNAKE` para constantes (guia oficial do GDScript).
- **State machines:** state machine por nós para player, inimigos e bosses.
- **Data-driven:** itens, combos, ensinamentos, inimigos, moedas e facções são `Resource` (`.tres`) em `data/`. Adicionar conteúdo não deve exigir mexer em código.
- **Estado global:** apenas em autoloads (`GameState`, `SaveManager`, `Economy`, `Reputation`), criados quando um milestone precisar. Comunicação entre sistemas por sinais ou pelo autoload `Events` (sinais `dominio_acao`).
- **Constantes:** tuning em `scripts/constants.gd` (`class_name Constants`) ou nos `Resource`s de dados, nunca solto na lógica.
- **Input:** ações nomeadas no Input Map (`move_*`, `attack_basic`, `attack_heavy`, `special`, `dash`, `interact`), nunca teclas cruas.
- **Inspeção:** `GameState.state_to_text()` devolve um JSON do estado, para verificação por agente.
- **Asset naming:** `kebab-case`, prefixado por reino quando for específico (`cct-robot-idle.png`).

## Out-of-scope dependencies

- C#/.NET: GDScript basta e o usuário já conhece.
- Frameworks de rede: o jogo não tem multiplayer.
