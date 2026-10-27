# Session state

## Last updated

2026-10-27 by Claude / make-game + cerebro-loop + cerebro-kernel + ponytail

## Current phase

development, com a v1.0 entregue para os testes finais do usuário

## Current milestone

[Milestone 03: v1.0, reino do CCT completo](milestones/03-v1-mvp-cct.md). C1–C9 verificados; falta C10 (playtest do usuário).

## Last action

A v1.0 foi implementada inteira:
- menu, customização, campus/hub, run de 12 salas, 4 inimigos e chefe;
- ensinamentos, Bits, mercados, itens, relíquias, atlética e save/continuar;
- sprites e UI do Tiny Swords;
- export Windows em `builds/`.

Verificado com 52 testes GUT, autoplay ponta a ponta, capturas de tela, clique em janela real e boot do `.exe`.

## Next step

O usuário faz o playtest final seguindo o roteiro da nota do Obsidian `02-Projetos/Ativos/Reinos da Unifor - Entrega v1.md`. Ajustar o balanceamento (`data/`, `scripts/constants.gd`, `scenes/run/room.gd`) com o feedback.

## Blockers

Nenhum para a v1. Áudio e fonte dependem de assets do usuário (não bloqueiam).

## Notes for next session

- O editor do Godot estava aberto durante o desenvolvimento. Antes do F5, use *Projeto → Recarregar Projeto Atual*: o `project.godot` mudou (autoload, input, cena principal, clear color).
- Os packs `Tiny Swords/` e `Tiny Swords (Free Pack)/` ficam fora do git (licença), mas o jogo depende deles na raiz do projeto.
- Scripts rodados com `-s` compilam antes dos autoloads: não use `class_name` que dependa do `GameState` neles (veja `tests/tools/autoplay.gd`).
- Em headless a GUI não faz picking de mouse; para checar cliques, rode com janela.
- Telas modais pausam a árvore. Testes que esperam durante a pausa precisam de `PROCESS_MODE_ALWAYS` (veja `tests/integration/test_flow.gd`).
- O harness do cerebro-loop (`.specs/loop/v1-mvp-cct/STATE.json`) parou por orçamento de tempo (BUDGET_TIME_EXCEEDED). Os gates foram rodados manualmente (testes, autoplay, boot, capturas).
