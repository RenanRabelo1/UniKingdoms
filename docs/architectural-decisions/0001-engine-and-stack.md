# ADR 0001: Engine, linguagem e estilo de arte

## Status

accepted

## Date

2026-10-27

## Context

Roguelike de ação 2D top-down (estilo Hades), projeto de hobby, sem prazo, só para PC e sem multiplayer. O usuário já programou jogos em Godot e prefere dar direção, mexendo no código só quando precisar. A arte começa com placeholders e assets gratuitos.

## Decision

O jogo usa **Godot 4.x (estável mais recente) com GDScript**, exportado para **Windows**. Os testes de lógica usam **GUT**. O visual é **2D top-down inspirado em Hades**, com placeholders e packs gratuitos até existir arte própria. O conteúdo (itens, combos, ensinamentos, inimigos, facções) é definido em `Resource`s de dados.

## Consequences

### Positive

- O usuário já conhece a engine e consegue ler e ajustar o código.
- O Godot tem ótimas ferramentas 2D (TileMap, AnimationPlayer, física 2D) e é gratuito.
- Definir conteúdo por dados permite adicionar reinos, itens e professores sem reescrever sistemas.

### Negative

- Testes automatizados de gameplay em tempo real são mais limitados que em navegador (Playwright). O feel do combate é validado por playtest.
- Assets gratuitos de fontes diferentes podem ficar visualmente inconsistentes até a arte final.

## Alternatives considered

- **Phaser (JS):** bom para web, mas o alvo é PC e o usuário já conhece Godot.
- **Unity:** mais pesado para 2D e o usuário não tem experiência.
- **Godot com C#:** sem ganho real neste escopo e adiciona dependência do .NET.

## Related

- `docs/gameplan.md`
- `docs/tech.md`
