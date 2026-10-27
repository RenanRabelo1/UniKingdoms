# Backlog

Tudo que foi mencionado e adiado. Itens promovidos a milestone ganham ✔ e o link; itens rejeitados ficam riscados com o motivo.

## Próximos milestones (ordem combinada em 2026-10-27)

- [ ] **M03: Run de salas.** Limpar a sala abre a porta e leva à próxima, a run termina e reinicia. Cria o autoload `GameState` com `state_to_text()`. *Depends on: M02.*
- [ ] **M04: Recompensas da sala.** Ao limpar a sala, escolher 1 de 3 ensinamentos de um professor, ou ganhar Bits (moeda do CCT). *Depends on: M03.*

## MVP do CCT (ainda sem milestone)

- [ ] Mercado do CCT (caneta, jaleco, código penal, tecnologia), com moeda Bits.
- [ ] Boss: professor-chefe do CCT, com state machine por nós e fases.
- [ ] Relíquias permanentes + sala de coleção na Biblioteca.
- [ ] Save no meio da run (por sala concluída) e progresso permanente.
- [ ] Hub mínimo (Biblioteca) e trecho do campus com os reinos trancados.
- [ ] Reputação com 1 atlética ativa no CCT e o mercado da facção.
- [ ] Customização básica de aparência.
- [ ] Mais 1 ou 2 inimigos do CCT para completar 3 ou 4 tipos.

## Polish & juice

- [ ] Knockback nos inimigos.
- [ ] Sprites e animações reais no lugar dos placeholders. O plugin SpriteCook (catálogo) gera sprites e tem fluxo para Godot.
- [ ] Sons (packs gratuitos).
- [ ] Barra do especial com tema visível (o tema padrão é escuro demais).

## Open questions

- Título definitivo.
- Nomes e identidade das 4 atléticas, e quais são as mais hostis.
- Professor-chefe do CCT: nome e fases.
- Mercados do CCS e do CCG, nomes finais das moedas e quantidade de finais.

## Riscos técnicos

- As ações do Input Map foram escritas sem `"device": -1` (o editor usa -1). O teclado funcionou no playtest e o clique de mouse foi verificado com evento simulado numa janela real. Se algum dispositivo não responder, comece por aqui.
