# Backlog

Tudo que foi mencionado e adiado. Itens promovidos ganham ✔ e o link; itens rejeitados ficam riscados com o motivo.

## Promovidos

- [x] ✔ M03 Run de salas, M04 Recompensas, mercado, relíquias, save, chefe, hub, atlética, customização e mais 2 inimigos → [Milestone 03 (v1)](milestones/03-v1-mvp-cct.md).
- [x] ✔ Acerto do combate (hurtbox) e campus com o Unifor-campus-kit → [Milestone 04 (v1.1)](milestones/04-v1.1-combate-campus.md).

## Próximas versões (fora da v1)

- [ ] Reinos CCS, CCG e CCJ (inimigos, professor-chefe, mercado e moeda de cada um).
- [ ] Reitoria e O Chanceler (chefe final depois dos 4 reinos).
- [ ] Eleições do centro acadêmico (missões em cadeia) e finais diferentes.
- [ ] As outras 3 atléticas ativas; reputação negativa (hostil) e aliados que lutam junto.
- [ ] Outras armas da run (só a Caneta na v1).
- [ ] Customização além da cor (cabelo, acessórios).
- [ ] Suporte a controle.

## Polish & juice

- [x] Efeitos sonoros de combate/recursos sintetizados, com opção de desligar → [Milestone 05](milestones/05-v1.2-ritmo-de-combate.md).
- [ ] Trilha musical e revisão artística do áudio.
- [ ] Fonte com identidade do jogo (precisa do arquivo).
- [x] Knockback e interrupção local nos inimigos → [Milestone 05](milestones/05-v1.2-ritmo-de-combate.md). Sem congelar o input global.
- [ ] Navegação global ao redor de prédios grandes. M05 adicionou desvio local de obstáculos pequenos; alcance de perseguição no campus continua 700 px.
- [ ] Usar as peças de arquitetura do kit (corredores cobertos, paredes, rampas, ponte, muro, portão) e os 8 terrenos ainda não usados (quadra, pista, terra, areia, piso da biblioteca, ladrilho, piscina, gramado).
- [ ] Salas da run com cenário do CCT (hoje: ilhas Tiny Swords).
- [ ] Animação de ataque para cima/baixo (o Warrior só tem golpe lateral; o golpe vale em 8 direções e o flash mostra a área).
- [ ] Sprites próprios de professores, chefe e inimigos "de CCT" (hoje: monges, Lancer e goblins do Tiny Swords).
- [ ] Ícone do executável.

## Balanceamento (depende do playtest)

- [ ] Uma vitória rende ~380 Bits e os itens custam 20–40; talvez seja generoso demais.
- [ ] Dano/vida dos inimigos por sala (`hp_scale` +8%/sala, 3 + n inimigos) e vida do chefe (900).

## Open questions (decisões do usuário)

- ~~Quais blocos reais são do CCT, CCS, CCG e CCJ~~: mantido CCT no N, CCS no D, CCG no L, CCJ no C (decisão do usuário, 2026-10-27; revisar depois do playtest).
- Posição real do Espaço Cultural (não está no mapa oficial; hoje ao lado da Pós-Unifor).

- Título definitivo (hoje "Reinos da Unifor").
- Nomes da atlética do CCT ("Atlética Engrenagem" é provisório) e das outras 3.
- Nomes dos professores (Profa. Lógica, Prof. Circuito, Profa. Prancheta) e do chefe (Prof. Mainframe), todos provisórios.
- Nomes das moedas dos outros reinos e quantidade de finais.

## Riscos técnicos

- As ações do Input Map foram escritas sem `"device": -1`. Teclado e mouse foram verificados; se um dispositivo não responder, comece por aqui.
