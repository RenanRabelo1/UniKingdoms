# Reinos da Unifor (título provisório)

## Pitch

Um roguelike de ação 2D top-down no estilo Hades que se passa na Unifor. Você é um aluno comum que precisa atravessar os quatro centros da universidade, transformados em "reinos" com moedas, mercados, atléticas rivais e um professor-chefe em cada um, até chegar ao Chanceler, no topo da Reitoria.

O diferencial: a **política do campus** faz parte do jogo. A reputação com as atléticas e as eleições do centro acadêmico mudam preços, aliados, inimigos e o final.

## Core gameplay loop

1. **Hub (Biblioteca):** customizar o personagem, ver a coleção de relíquias e sair para o campus.
2. **Campus (mundo aberto):** andar entre os reinos e escolher qual explorar. A ordem é livre.
3. **Área do reino:** explorar, comprar no mercado do reino ou no mercado das facções, pegar missões secundárias e lidar com as atléticas.
4. **Run:** entrar no portão do reino e atravessar uma sequência de salas de combate:
   - lutar (ataque básico, ataque pesado, especial, dash e combos);
   - ganhar recompensas por sala: moedas, ensinamentos de professores, armas, habilidades e, raramente, relíquias;
   - cumprir objetivos de missão que aparecem dentro da run;
   - enfrentar o **professor-chefe** do reino no final.
5. **Fim da run:**
   - **Morte:** volta para a Biblioteca. Perde o que era da run e mantém o que é permanente.
   - **Vitória:** o reino fica "conquistado" e as habilidades novas entram no pool de todas as runs.
6. Depois dos quatro reinos, a **Reitoria** é desbloqueada e o boss final é **O Chanceler**, um personagem fictício.

## Game rules

### Combate
- **Ataque básico:** rápido e de pouco dano.
- **Ataque pesado:** lento e de dano alto.
- **Especial:** usa uma barra que carrega devagar com o tempo e mais rápido com o dano causado. Só pode ser usado com a barra cheia.
- **Dash:** esquiva curta com invencibilidade breve e recarga.
- **Combos:** sequências simples aumentam o dano somado. Exemplo: `básico → básico → pesado` termina num golpe final com bônus. A lista de combos fica num arquivo de dados para ser fácil de ajustar.
- Sem magia por enquanto.

### Itens e armas (com exemplos)
| Item | Tipo | Função |
|------|------|--------|
| Caneta | Arma | Equivalente à espada, corpo a corpo e equilibrada |
| Jaleco | Equipável | Dá buffs passivos |
| Código Penal | Consumível (pergaminho) | Ao usar, ensina uma habilidade |

Cada reino tem uma especialidade no mercado:
- **CCT:** tecnologia e os itens principais (caneta, jaleco, código penal) no MVP.
- **CCJ:** cartas consumíveis que dão habilidades temporárias ou combos.
- **CCS e CCG:** a definir.

### Ensinamentos (as "bênçãos")
- Professores aparecem em algumas salas e oferecem **1 entre 3 ensinamentos** temporários, que valem só para aquela run.
- Cada professor tem um tema. Por exemplo, um professor de computação dá ensinamentos ligados a velocidade e crítico.

### Moedas
- Cada reino tem a sua moeda. Nomes provisórios: CCT = Bits, CCS = Doses, CCG = Cotas, CCJ = Honorários.
- A moeda só compra coisas no mercado daquele reino.

### O que é permanente e o que se perde
| Permanente (sobrevive à morte) | Só da run (perdido ao morrer) |
|---|---|
| **Relíquias**, que ficam expostas na sala de coleção da Biblioteca | Moedas |
| **Habilidades desbloqueadas** ao conquistar um reino, que passam a poder aparecer em qualquer reino | Upgrades da run |
| **Itens comprados fora da run que não foram usados** | Armas e habilidades pegas na run |
| Reputação com facções e progresso de missões e da história | Ensinamentos |

### Facções (atléticas) e política
- São **4 atléticas fictícias**, com níveis de hostilidade diferentes (umas piores que as outras).
- Às vezes elas atrapalham o jogador, tanto nas runs (emboscadas, salas sabotadas) quanto durante a exploração.
- **Reputação por facção:** missões secundárias e escolhas aumentam ou diminuem a reputação. Com amizade alta:
  - preços menores no **mercado da facção**;
  - inimigos dela passam a ser aliados ou neutros;
  - missões exclusivas aparecem.
- **Eleições do centro acadêmico:** cadeia de missões secundárias ligada à história.
- A política é **obrigatória**: a história principal exige se envolver com ela.
- **Finais diferentes** dependem das alianças e das eleições.

### Personagem
- Totalmente customizável na aparência.
- **Sem classes:** a build é montada a qualquer momento com armas, itens, habilidades e ensinamentos.
- **Protagonista silencioso.**

### Save
- Salva automaticamente **no meio da run**, a cada sala concluída, além do progresso permanente.

## Win / lose conditions

- **Run:** perde quando a vida chega a 0. Ganha quando derrota o professor-chefe do reino.
- **Jogo:** conquistar os 4 reinos, derrotar O Chanceler na Reitoria e chegar a um dos finais definidos pela política.

## Art style

- **2D top-down**, com visual inspirado em Hades: contornos fortes, cores saturadas e iluminação dramática.
- Cenários que **lembram a Unifor de verdade**: blocos dos centros, lago, áreas de convivência e Biblioteca.
- Identidade de cor por reino. Provisório: CCT em azul/ciano tech, CCS em verde/branco hospitalar, CCG em dourado/laranja corporativo, CCJ em vinho/bordô.
- **Assets:** placeholders (formas simples) e packs gratuitos (Kenney, itch.io, OpenGameArt) no começo. A arte final pode vir depois.

## Audio direction

- Efeitos e músicas de **packs gratuitos** como placeholder.
- Música mais intensa nas runs e no boss, mais calma no hub.

## Player goals

- **Curto prazo (uma run):** montar uma build forte com ensinamentos e itens e derrotar o professor-chefe. Uma run dura **15 a 20 minutos**, com mais ou menos 10 a 14 salas.
- **Longo prazo:** completar a coleção de relíquias, conquistar os 4 reinos, construir alianças, ganhar as eleições, derrotar O Chanceler e ver os finais.

## Controles

- **Teclado + mouse:** WASD para andar e mira no mouse. Mapeamento provisório: botão esquerdo = básico, botão direito = pesado, Q = especial, Espaço = dash, E = interagir/usar item.
- Suporte a controle fica para depois.

## Escopo do MVP (v1) — entregue em 2026-10-27

Um reino completo, o **CCT**. O detalhe está em `docs/milestones/03-v1-mvp-cct.md`.

- **Fluxo:** menu (Novo jogo com cor do uniforme / Continuar / Sair) → campus → Portão do CCT → 12 salas → chefe → tela de resultado → campus.
- **Campus (hub):**
  - Biblioteca com vitrine de relíquias, espelho (cor) e espantalho de treino;
  - Lojinha do CCT;
  - sede e mercado da Atlética Engrenagem;
  - CCS, CCG, CCJ e Reitoria trancados.
- **Run:** 12 salas; ensinamento na 1ª e em mais 2 sorteadas; mercado nas salas 5 e 9; Prof. Mainframe na 12ª.
- **Inimigos:** Bug (corpo a corpo), Robô (dinamite), Barril (explode), membro da atlética (emboscadas). 3 + n por sala, vida +8% por sala, ondas de até 6.
- **Economia:** Bits da run (perdidos na morte, guardados na vitória) e Bits do banco (lojas do campus, começa com 50). Missões pagam no banco.
- **Itens:** Marmita do RU (cura 40), Power Bank (+50% especial), Código Penal (ensinamento aleatório), Jaleco (+25 vida máx na run). Comprados no campus vão para o estoque e persistem; comprados na run valem só na run.
- **Ensinamentos:** 9 de 3 professores + 2 que entram no pool depois de conquistar o CCT.
- **Relíquias:** 6 permanentes com bônus pequenos (8% de chance por sala de combate, garantida no chefe).
- **Atlética:**
  - reputação 0 → aliada com 50 (2 missões);
  - aliada não embosca;
  - o mercado dela dá 0,4% de desconto por ponto de reputação.
- **Save:** automático ao entrar em cada sala, comprar e mudar o perfil.

## Anti-goals

- Sem multiplayer.
- Sem diálogos longos: a história é conceitual, contada por ambiente, ícones e eventos.
- Sem sistema de classes.
- Sem versão para celular ou navegador (só PC).
- Não é 3D.
- Sem pessoas reais como personagens: professores, atléticas e O Chanceler são fictícios.

## References

- **Hades:** combate, estrutura de run, bênçãos e hub entre runs.
- **Enter the Gungeon / The Binding of Isaac:** relíquias permanentes e coleção.
- **Fable / Mass Effect (de leve):** reputação com facções mudando o final.

## Open questions

- Título definitivo.
- Nomes e identidade das 4 atléticas, e quais são as mais hostis.
- Nomes e mecânicas dos 4 professores-chefes. Do CCT para o MVP: tema de computação/robótica, com fases do boss a definir.
- Mercados do CCS e do CCG: o que vendem.
- Quantos finais existem e o que define cada um.
- Nomes finais das moedas.
