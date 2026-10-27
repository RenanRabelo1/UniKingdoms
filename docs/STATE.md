# Session state

## Last updated

2026-10-27 by Claude / make-game + cerebro-loop

## Current phase

development

## Current milestone

[Milestone 01: Player e combate básico](milestones/01-player-e-combate.md). A1 a A7 estão feitos; falta A8 (playtest do usuário).

## Last action

Implementado o combate base:
- Input Map com 9 ações;
- `WeaponData` (`caneta.tres`) e `ComboData` (Assinatura: básico+básico+pesado ×1.5; Grifo Duplo: pesado+pesado ×1.3);
- `ComboTracker` e `SpecialMeter` (carrega por tempo e por dano);
- `Player` com movimento, mira no mouse, dash com invencibilidade, ataques por consulta de forma e especial em área;
- `TrainingDummy` e a arena de teste como cena principal, com HUD.

São 19 testes GUT passando, o boot headless não tem erros e o frame renderizado foi conferido.

## Next step

O usuário faz o playtest (F5) e dá feedback de feel. Ajustar os números em `scripts/constants.gd` e `data/weapons/caneta.tres` e fechar o milestone 01.

## Blockers

Aguardando o playtest do usuário (A8).

## Notes for next session

- O estado do cerebro-loop fica em `.specs/loop/m01-player-combate/STATE.json`. O spec e as tarefas do loop estão no próprio milestone (sem duplicar em `.specs/features`).
- Skills obrigatórias neste projeto: cerebro-kernel, ponytail, cerebro-loop, make-game e as skills de Godot em `G/.claude/skills/`.
- O autoload `GameState` com `state_to_text()` ainda não existe. Criar quando houver estado global (moedas/run).
- As ações do player chegam por `_unhandled_input` e são executadas no `_physics_process`, porque as consultas de colisão precisam rodar no passo de física.
- Se mexer em `project.godot` com o editor aberto, peça para usar *Projeto → Recarregar Projeto Atual*.
