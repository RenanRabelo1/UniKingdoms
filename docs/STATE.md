# Session state

## Last updated

2026-10-27 by Claude / cerebro-kernel + cerebro-loop + ponytail + skills de Godot

## Current phase

development, com a v1.1 (acerto no combate + campus da Unifor) entregue para os testes do usuário

## Current milestone

[Milestone 04: v1.1](milestones/04-v1.1-combate-campus.md). Critérios verificados por automação; falta o playtest do usuário.

## Last action

- Combate: `Hurtbox` separada da colisão de movimento, golpe em cápsula a partir do corpo, ativo por 0,2 s, um acerto por alvo; F3 mostra as áreas (só debug).
- Campus 100 × 75 tiles com o Unifor-campus-kit (`assets/unifor/`), layout a partir do mapa oficial, mapa (M/totens), carrinho elétrico, 6 encontros.
- Ações do Input Map normalizadas para `device -1`.

Verificado: 68 testes GUT, autoplay (com o campus), checagem de alcance (0 células presas), capturas, medição de quadro em janela, export e boot do `.exe`.

## Next step

O usuário testa combate e exploração seguindo a nota do Obsidian `02-Projetos/Ativos/Reinos da Unifor - Entrega v1.1.md`. Confirmar quais blocos reais são de cada centro (CCT/CCS/CCG/CCJ) e ajustar `scenes/campus/campus_layout.gd`.

## Blockers

Nenhum. Áudio e fonte continuam dependendo de assets do usuário.

## Notes for next session

- Antes do F5 no editor: *Projeto → Recarregar Projeto Atual* (o `project.godot` mudou: camada `hurtbox`, ações `campus_map`/`debug_combat`, `device -1`).
- Packs não usados na raiz têm `.gdignore`; tire o arquivo se for usar um deles.
- `tests/tools/shots.gd` precisa de janela (não use `--headless`). Use `--disable-vsync` para medir FPS real.
- `Performance.TIME_PROCESS` não serve como tempo por quadro aqui; meça com `Time.get_ticks_usec` entre quadros.
- O template de release ignora `-s`: o autoplay só roda no projeto, não no `.exe`.
- Scripts rodados com `-s` compilam antes dos autoloads: não use `class_name` que dependa do `GameState` neles.
- Em headless a GUI não faz picking de mouse; para checar cliques, rode com janela.
- Telas modais pausam a árvore. Testes que esperam durante a pausa precisam de `PROCESS_MODE_ALWAYS`.
