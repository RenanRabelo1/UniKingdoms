# Session state

## Last updated

2026-10-27 by Claude / make-game scaffold

## Current phase

development

## Current milestone

Nenhum ainda. O próximo passo é planejar o milestone 01 (movimento + combate básico do player numa sala de teste).

## Last action

Scaffold concluído:
- projeto Godot 4.7 em `uni-king-dooms/`, com `docs/` movido pra dentro;
- estrutura de pastas de `docs/tech.md`;
- cena principal `scenes/main.tscn` como placeholder;
- GUT 9.7.1 em `addons/gut` com `.gutconfig.json` e um teste de fumaça passando;
- boot headless sem erros;
- `AGENTS.md` e `CLAUDE.md` criados.

## Next step

Rodar milestone planning e escrever `docs/milestones/01-*.md`: player placeholder com WASD, mira no mouse, dash, ataque básico/pesado e Input Map configurado.

## Blockers

none

## Notes for next session

- O editor do Godot pode estar aberto enquanto você edita arquivos. Se mexer em `project.godot` (Input Map, autoloads), avise o usuário para usar *Projeto → Recarregar Projeto Atual*, senão o editor pode sobrescrever as mudanças.
- Repositório git local (branch `main`, sem remote). O commit inicial do scaffold é `ae5434b`.
- A pasta pai `G/` só contém este projeto.
