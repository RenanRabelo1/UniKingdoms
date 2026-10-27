# Backlog

Tudo que foi mencionado e adiado. Itens promovidos ganham ✔ e o link; itens rejeitados ficam riscados com o motivo.

## Promovidos

- [x] ✔ M03 Run de salas, M04 Recompensas, mercado, relíquias, save, chefe, hub, atlética, customização e mais 2 inimigos → [Milestone 03 (v1)](milestones/03-v1-mvp-cct.md).

## Próximas versões (fora da v1)

- [ ] Reinos CCS, CCG e CCJ (inimigos, professor-chefe, mercado e moeda de cada um).
- [ ] Reitoria e O Chanceler (chefe final depois dos 4 reinos).
- [ ] Eleições do centro acadêmico (missões em cadeia) e finais diferentes.
- [ ] As outras 3 atléticas ativas; reputação negativa (hostil) e aliados que lutam junto.
- [ ] Outras armas da run (só a Caneta na v1).
- [ ] Customização além da cor (cabelo, acessórios).
- [ ] Suporte a controle.

## Polish & juice

- [ ] Áudio: músicas e efeitos (precisa dos assets).
- [ ] Fonte com identidade do jogo (precisa do arquivo).
- [ ] Knockback e hit-stop nos inimigos.
- [ ] Inimigos contornam árvores e pedras (hoje só deslizam).
- [ ] Sprites próprios de professores, chefe e inimigos "de CCT" (hoje: monges, Lancer e goblins do Tiny Swords).
- [ ] Ícone do executável.

## Balanceamento (depende do playtest)

- [ ] Uma vitória rende ~380 Bits e os itens custam 20–40; talvez seja generoso demais.
- [ ] Dano/vida dos inimigos por sala (`hp_scale` +8%/sala, 3 + n inimigos) e vida do chefe (900).

## Open questions (decisões do usuário)

- Título definitivo (hoje "Reinos da Unifor").
- Nomes da atlética do CCT ("Atlética Engrenagem" é provisório) e das outras 3.
- Nomes dos professores (Profa. Lógica, Prof. Circuito, Profa. Prancheta) e do chefe (Prof. Mainframe), todos provisórios.
- Nomes das moedas dos outros reinos e quantidade de finais.

## Riscos técnicos

- As ações do Input Map foram escritas sem `"device": -1`. Teclado e mouse foram verificados; se um dispositivo não responder, comece por aqui.
