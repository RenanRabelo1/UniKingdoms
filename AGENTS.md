# AGENTS.md

> Arquivo de regras para qualquer agente de IA que trabalhe neste repositório. Leia **primeiro**, em toda sessão, antes de qualquer outra ação. Usuários do Claude: `CLAUDE.md` aponta para cá.

Este projeto segue o pipeline [`make-game`](https://github.com/OpusGameLabs/game-creator). Não improvise o processo: siga as regras abaixo.

## Project overview

- **Title:** Reinos da Unifor (título provisório; nome do projeto Godot: UniKingDooms)
- **Pitch:** Roguelike de ação 2D top-down no estilo Hades na Unifor. Um aluno comum atravessa os quatro centros, transformados em reinos, até enfrentar O Chanceler na Reitoria. A política do campus (atléticas e eleições) muda preços, aliados e o final.
- **Genre / type:** roguelike de ação top-down com hub e mundo aberto entre reinos
- **Engine:** Godot 4.7 (instalado via Steam, 4.7.2.stable)
- **Language:** GDScript
- **Target platform:** Windows (PC)

## Hard gate: no code before plan

Se `docs/gameplan.md` não existir neste repositório, você está na **fase de ideia**. Não crie código. Rode o checklist da fase de ideia do `make-game`.

## Mandatory: run the make-game skill

Toda sessão neste diretório **deve** rodar o sub-pipeline session-start do skill `make-game` antes de qualquer outro trabalho.

Se o skill não estiver instalado:

```
npx skills add opusgamelabs/game-creator --skill make-game -p -y
```

## Source-of-truth files

Leia no início da sessão. **Não** edite sem confirmação do usuário.

- `docs/STATE.md`: handoff da última sessão. Leia primeiro.
- `docs/gameplan.md`: definição do jogo.
- `docs/tech.md`: stack, ferramentas, convenções.
- `docs/milestones/`: trabalho dividido com critérios de aceite.
- `docs/architectural-decisions/`: decisões travadas.
- `docs/backlog.md`: tudo que foi adiado.

**Espelho no Obsidian:** o vault `SegundoCérebro` tem a nota de projeto `02-Projetos/Ativos/Reinos da Unifor.md`. Ao fim de cada sessão com progresso, atualize "Estado atual", "Critérios de sucesso" e "Registro de trabalho" dessa nota (CLI `obsidian`). O repositório continua sendo a fonte de verdade técnica.

## Architecture rules

- **Autoloads só para estado global e eventos.** `Events` (barramento de sinais, nomes `dominio_acao`) e singletons de estado (`GameState`, `SaveManager`, `Economy`, `Reputation`), criados conforme os milestones precisarem. Nós de gameplay não se referenciam diretamente entre sistemas: usam sinais ou `Events`.
- **Conteúdo é dado.** Itens, combos, ensinamentos, inimigos, moedas e facções são `Resource`s (`.tres`) em `data/`. Adicionar conteúdo não exige mudar código.
- **Constantes centralizadas.** Números de tuning (velocidades, tempos, dano base) vão em `scripts/constants.gd` (`class_name Constants`) ou nos `Resource`s de dados, nunca soltos na lógica.
- **State machine por nós** para player, inimigos e bosses.
- **Input:** ações nomeadas no Input Map (`move_*`, `attack_basic`, `attack_heavy`, `special`, `dash`, `interact`). Gameplay lê ações em `_unhandled_input`/`Input`, nunca teclas cruas.
- **Inspeção por agente:** o `GameState` expõe `state_to_text() -> String` com um JSON do estado atual, para verificação sem screenshot.
- **Testes:** toda lógica pura (combos, dano, economia, reputação, save) tem teste GUT em `tests/` escrito antes da implementação.

## Stack-specific commands

Execute a partir da raiz do projeto (`uni-king-dooms/`). `GODOT` = `"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"`.

- **Rodar o jogo:** F5 no editor, ou `GODOT --path .`
- **Smoke de boot (headless):** `GODOT --headless --path . --quit-after 60`
- **Importar assets (headless):** `GODOT --headless --path . --import`
- **Tests:** `GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`
- **Build:** export Windows pelo editor (preset a criar)
- **Lint / format:** n/a

## Live iterate (after every code change)

1. Rode os testes GUT, que devem passar.
2. Rode o smoke de boot headless. A saída não pode ter `ERROR`/`SCRIPT ERROR`.
3. Verifique `GameState.state_to_text()` quando a mudança afetar estado.
4. Para mudança visual ou de feel, peça playtest ao usuário (F5) com uma pergunta focada.
5. Uma mudança **não está pronta** até passar por esse loop.

## Append vs spawn a new milestone

- **Append:** refinamento dentro do escopo do milestone atual.
- **Spawn:** fora do escopo mas relacionado; use `Depends on:`.
- **Inline:** correções triviais.

## Minimum-viable doc mode

Se o usuário reclamar da documentação: milestone de uma linha é aceitável, mas `docs/STATE.md` continua obrigatório e ADRs de stack não podem ser pulados.

## What to do if `make-game` isn't loaded

1. Pare. Não comece a codar.
2. Leia este arquivo, depois `docs/STATE.md`, `docs/gameplan.md` e `docs/tech.md`.
3. Identifique a fase e o milestone aberto.
4. Avise o usuário que o skill não está carregado.
5. Se seguir sem ele, aplique estas regras manualmente e atualize `docs/STATE.md` no fim.

## Last regenerated

2026-10-27 by Claude / make-game scaffold
