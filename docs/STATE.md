# Session state

## Last updated

2026-10-27 by Claude / make-game + cerebro-loop

## Current phase

development

## Current milestone

[Milestone 02: Inimigos e vida](milestones/02-inimigos-e-vida.md), planejado e sem código ainda.

## Last action

- Milestone 01 fechado.
- No playtest, o ataque com mouse não funcionava. Causa: o `ColorRect` de fundo da arena (mouse_filter STOP) consumia os cliques antes do `_unhandled_input` do player. Correção em `06a4b89`: o fundo virou a clear color do projeto, a barra do especial ignora o mouse e há um teste de regressão (nenhum Control da arena bloqueia o mouse). Confirmado com clique simulado numa janela real: antes falhava, depois funciona.
- Planejamento: o usuário escolheu o M02 (Inimigos e vida). M03 (Run de salas) e M04 (Recompensas) estão em `docs/backlog.md`.

## Next step

Rodar o cerebro-loop do M02: T01, escrever os testes B1–B5 falhando.

## Blockers

none

## Notes for next session

- Em headless a GUI não faz picking de mouse. Para checar input de mouse de verdade, rode o script sem `--headless` (`root.push_input` numa janela real).
- Toda `Control` nova na arena precisa de `mouse_filter = IGNORE`, senão engole os cliques (o teste `test_no_control_in_arena_swallows_mouse` pega isso).
- O estado do cerebro-loop do M01 fica em `.specs/loop/m01-player-combate/STATE.json`. Para o M02, rode `orchestrator.mjs init m02-inimigos-vida large`.
- Skills obrigatórias: cerebro-kernel, ponytail, cerebro-loop, make-game e as skills de Godot em `G/.claude/skills/`.
- O autoload `GameState` com `state_to_text()` entra no M03.
- Se mexer em `project.godot` com o editor aberto, peça para usar *Projeto → Recarregar Projeto Atual*.
