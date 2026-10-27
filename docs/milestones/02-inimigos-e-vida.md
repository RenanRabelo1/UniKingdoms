# Milestone 02: Inimigos e vida

**Status:** concluído na v1 (2026-10-27). B5/B6 (arena com inimigos) foram absorvidos pelo M03: os inimigos agora aparecem nas salas da run, não numa arena.
**Depends on:** [01: Player e combate básico](01-player-e-combate.md)
**Blocks:** 03 (run de salas), 04 (recompensas da sala)

## Objective

Dar desafio ao combate: o aluno ganha vida e pode ser reprovado (morrer), e o CCT ganha seus dois primeiros inimigos com IA simples. O **Bug** corre até o player e causa dano por contato. O **Robô** mantém distância e atira projéteis. Os inimigos levam dano dos ataques que já existem e somem ao morrer.

## Scope

- **Vida do player:** 100 HP (em `Constants`).
  - Leva dano de contato e de projéteis.
  - Fica invencível por um tempo curto depois de levar dano.
  - O dash continua dando invencibilidade.
  - A 0 HP, emite `died` e a arena mostra "Reprovado — R para tentar de novo".
- **`EnemyData` (Resource):** vida, velocidade, dano, alcance, recarga e cor do placeholder. Dados: `data/enemies/bug.tres` e `data/enemies/robo.tres`.
- **Inimigo base** (`CharacterBody2D` na camada `enemies`):
  - `take_damage(amount, source)`, flash ao levar dano, sinal `died` e `queue_free` ao morrer.
  - Sem knockback.
- **Bug:** persegue o player e causa dano por contato, com recarga.
- **Robô:** se aproxima até o alcance, para e atira um projétil na direção do player a cada recarga. O projétil some ao bater em parede ou no player.
- **Arena:** os bonecos de treino saem e entram 3 Bugs e 2 Robôs. O HUD ganha uma barra de vida. R reinicia a cena quando o player está morto.

**Fora do escopo:** ondas e salas (M03), recompensas e drops (M04), knockback, animações, som, boss.

**Sprites (v1):** Bug = Goblin Torch roxo, Robô = Goblin TNT roxo com dinamite, Barril = Goblin Barrel roxo (kamikaze, novo), membro da atlética = Warrior vermelho (novo). Player = Warrior do Free Pack.

**Decisão:** a IA dos inimigos usa um estado simples (`enum` + `match`) dentro do script. A state machine por nós (convenção do `tech.md`) fica para o boss, que tem fases. Dois inimigos de 2 a 3 estados não justificam um nó por estado.

## Acceptance Criteria

- [x] B1. O player leva dano, não passa de 0, fica invencível por `HURT_IFRAMES` depois do golpe, ignora dano durante o dash e emite `died` a 0 HP. *(teste)*
- [x] B2. O inimigo perde vida pelos ataques do player, emite `died` e sai da árvore a 0 HP. *(teste)*
- [x] B3. O Bug se move em direção ao player e causa o dano do `bug.tres` por contato, respeitando a recarga. *(teste de cena)*
- [x] B4. O Robô para dentro do alcance e dispara um projétil que causa o dano do `robo.tres` ao atingir o player. *(teste de cena)*
- [ ] B5. A arena tem os 5 inimigos, barra de vida no HUD e tela de "Reprovado" com R para reiniciar. *(teste de cena)*
- [ ] B6. O jogo abre sem erros e o clique de mouse chega no player com janela real. *(boot + checagem de input)*
- [ ] B7. A dificuldade e o feel dos dois inimigos estão bons. *(verificado por playtest do usuário)*

## Exit Condition

O usuário aperta F5 e enfrenta 3 Bugs e 2 Robôs. Consegue matar todos usando ataques, combos, dash e especial. Ao levar dano demais, vê a tela de Reprovado e volta com R.

## Tasks

| ID | Tarefa | Gate |
|----|--------|------|
| T01 | Testes B1–B5 escritos e falhando | Falham por falta das classes |
| T02 | Vida do player + i-frames + `died` | B1 passa |
| T03 | `EnemyData`, inimigo base, `bug.tres`, `robo.tres` | B2 passa |
| T04 | IA do Bug (perseguir + contato) | B3 passa |
| T05 | IA do Robô + projétil | B4 passa |
| T06 | Arena com inimigos, HUD de vida, Reprovado/R | B5 e B6 passam |
| T07 | Playtest do usuário | B7 |
