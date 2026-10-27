# Milestone 03: v1.0, reino do CCT completo (M03–M06 do plano)

**Status:** implementado e verificado por automação em 2026-10-27. Falta o playtest final do usuário.
**Depends on:** [01](01-player-e-combate.md), [02](02-inimigos-e-vida.md)
**Commits:** `6559be5`, `6caa560`

## Objective

Entregar o fluxo completo do jogo com um reino: menu → novo jogo/customização → campus (hub) → run de 12 salas do CCT → chefe → resultado → campus, com economia, ensinamentos, relíquias permanentes, atlética, save e assets Tiny Swords.

## Scope (o que foi feito)

- **M03, Run e save:**
  - `GameState` (autoload único): perfil, run, plano de 12 salas, save binário em `user://save.dat`;
  - sala com ilha Tiny Swords, ondas por profundidade (3 + n inimigos, vida +8% por sala), emboscada da atlética (25% enquanto não aliada), ponte de saída;
  - HUD, pausa, telas de Reprovado e vitória.
- **M04, Recompensas:**
  - 11 ensinamentos de 3 professores (2 bloqueados até vencer o CCT), Bits que caem dos inimigos e da sala;
  - sala de mercado, itens nas teclas 1/2/3, Jaleco passivo;
  - 6 relíquias (8% por sala de combate, garantida no chefe).
- **M05, Chefe:** Prof. Mainframe (Lancer preto, 900 de vida):
  - investida com aviso em linha vermelha;
  - na fase 2 (metade da vida), investidas mais rápidas, leque de 5 dinamites e invocação de 2 Bugs a cada 9 s.
- **M06, Hub e política:**
  - campus com Biblioteca, vitrine de relíquias, espelho (cor), espantalho de treino, Lojinha do CCT, Atlética Engrenagem (missões, reputação, mercado com desconto) e portão da run;
  - CCS, CCG, CCJ e Reitoria trancados;
  - menu principal com Continuar e intro curta.

## Acceptance Criteria

- [x] C1. O plano de salas tem 12 salas, chefe na última, 2 mercados (salas 5 e 9) e 3 ensinamentos. *(teste)*
- [x] C2. A morte perde os Bits da run e mantém relíquias, banco e estoque. A vitória guarda os Bits, conquista o CCT e desbloqueia 2 ensinamentos. *(teste + autoplay)*
- [x] C3. Compras do campus vão para o estoque e persistem; compras na run valem só na run; o desconto da atlética cresce com a reputação. *(teste)*
- [x] C4. Missões dão +25 de reputação e +60 Bits; com 50 de reputação as emboscadas param. *(teste)*
- [x] C5. O save mantém tipos e "Continuar" retoma a sala salva com a vida salva. *(teste + autoplay)*
- [x] C6. A sala de combate abre a ponte ao limpar; a de ensinamento só depois da escolha; a de mercado abre de cara. *(teste + autoplay)*
- [x] C7. O chefe muda de fase, machuca com a investida e a vitória leva ao campus. *(teste + autoplay)*
- [x] C8. Nenhum `Control` do mundo bloqueia o mouse; um clique real numa janela chega ao player na sala. *(teste + checagem em janela)*
- [x] C9. O jogo e o `.exe` exportado abrem sem erros. *(boot headless)*
- [ ] C10. Feel, dificuldade e economia aprovados. *(playtest do usuário)*

## Exit Condition

O usuário cria um jogo novo, joga uma run inteira do CCT até derrotar o Prof. Mainframe (ou ser reprovado), volta ao campus, compra itens, fala com a atlética e vê as relíquias na Biblioteca. Tudo sem travar.

## Verificação executada

- 52 testes GUT (unidade + integração com as cenas reais).
- `tests/tools/autoplay.gd`: 42 checagens ponta a ponta com trocas de cena reais.
- Capturas de tela de menu, campus, sala, ensinamento, mercado, missão, chefe e relíquias.
- Clique de mouse real numa janela dentro da sala.
- Boot headless do projeto e do `.exe` exportado.
