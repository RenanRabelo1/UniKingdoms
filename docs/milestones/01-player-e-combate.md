# Milestone 01: Player e combate básico

**Status:** aguardando playtest (A8)
**Depends on:** scaffold
**Loop:** `.specs/loop/m01-player-combate/STATE.json` (cerebro-loop, escopo large)

## Objective

O aluno (placeholder geométrico) se move numa arena de teste, mira com o mouse, dá dash, faz ataque básico e pesado com a Caneta, encadeia combos definidos por dados e solta o especial quando a barra enche. Bonecos de treino mostram o dano recebido. É a base de todo o combate do jogo.

## Scope

- Input Map com ações nomeadas: `move_left/right/up/down` (WASD e setas), `attack_basic` (botão esquerdo), `attack_heavy` (botão direito), `special` (Q), `dash` (Espaço), `interact` (E).
- `Player` (`CharacterBody2D`, top-down): movimento, mira no mouse, dash com invencibilidade e recarga, ataques em hitbox `Area2D` na direção da mira.
- Dados:
  - `WeaponData` (Resource) com `caneta.tres`: dano e recarga do básico e do pesado, alcance.
  - `ComboData` (Resource) com 2 combos iniciais: `básico → básico → pesado` (×1.5) e `pesado → pesado` (×1.3).
- Lógica pura e testável:
  - `ComboTracker`: reconhece a sequência dentro de uma janela de tempo e devolve o combo.
  - `SpecialMeter`: carrega devagar com o tempo e mais rápido com dano causado; só dispara cheio.
- Especial: explosão em área ao redor do player.
- `TrainingDummy`: recebe dano, mostra vida e o último golpe/combo, e se regenera.
- HUD mínimo: barra do especial.
- A arena de teste vira a cena principal.

**Fora do escopo:** inimigos com IA, animações e sprites reais, vida e morte do player, outras armas, som, `GameState`/save. Ficam para milestones seguintes.

**Decisão tomada aqui:** a barra do especial carrega **pelos dois** (tempo e dano), com as taxas em `Constants`. Isso fecha a pergunta em aberto do gameplan.

## Acceptance Criteria

- [x] A1. O Input Map tem as 9 ações com os binds acima. *(teste)*
- [x] A2. O `ComboTracker` reconhece `básico, básico, pesado` e `pesado, pesado`, reseta a sequência quando passa a janela de tempo e não dispara combo com uma sequência errada. *(teste)*
- [x] A3. O `SpecialMeter` carrega pelo tempo e pelo dano, não passa de 100%, só pode ser consumido cheio e zera ao consumir. *(teste)*
- [x] A4. O ataque básico e o pesado causam o dano do `caneta.tres` num alvo dentro do alcance na direção da mira, e o finalizador de combo aplica o multiplicador. *(teste de cena)*
- [x] A5. O dash move o player rápido na direção do movimento (ou da mira, se parado), deixa ele invencível durante o dash e respeita a recarga. *(teste de cena)*
- [x] A6. O especial causa dano em área e esvazia a barra. *(teste de cena)*
- [x] A7. O jogo abre na arena sem erros no boot headless.
- [ ] A8. O feel (velocidade, dash, ritmo dos ataques) está bom. *(verificado por playtest do usuário)*

## Exit Condition

O usuário aperta F5, anda com WASD, mira com o mouse, dá dash no Espaço, bate nos bonecos com os dois botões do mouse, vê o nome do combo aparecer ao fazer `básico, básico, pesado` e solta o especial com Q quando a barra enche.

## Tasks

| ID | Tarefa | Gate |
|----|--------|------|
| T01 | Testes (A1–A6) escritos e falhando | GUT roda e os testes novos falham pelo motivo certo |
| T02 | Input Map no `project.godot` | A1 passa |
| T03 | `Constants`, `WeaponData`, `ComboData`, `caneta.tres`, combos `.tres` | Os recursos carregam |
| T04 | `ComboTracker` e `SpecialMeter` | A2 e A3 passam |
| T05 | `Player` + `TrainingDummy` + especial | A4, A5 e A6 passam |
| T06 | Arena como cena principal + HUD | A7 passa e o smoke test é atualizado |
| T07 | Playtest do usuário | A8 |
