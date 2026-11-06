# Análise e refatoração v1.2 — 2026-11-06

## Diagnóstico e decisões

Análise do código, dos testes e das notas `Reinos da Unifor`, `Entrega v1` e `Entrega v1.1` do SegundoCérebro. O CCT já tinha fluxo completo; os principais problemas estavam na resposta das ações e na repetição do combate. A prioridade foi reformular esse ciclo mantendo a identidade e o progresso existentes.

| Sistema | Evidência encontrada | Alteração |
|---|---|---|
| Input | Cliques durante cooldown eram descartados no mesmo frame | Buffer de 180 ms, uma intenção ofensiva, dash prioritário |
| Mobilidade | Dash não cancelava a cápsula nem a recuperação anterior | Cancelamento e ataque de avanço com janela de 300 ms |
| Tempo | Cooldowns usavam relógio real e avançavam durante pausa | Relógio da simulação |
| Combos | Histórico podia crescer indefinidamente; sem orientação de sequência | Histórico limitado, próximo comando no HUD, finalizador destacado |
| Impacto | Inimigos apenas piscavam ao receber dano | Impulso, stagger local, efeito e som no acerto |
| Inimigos | Robôs parados no alcance; atlética semelhante ao Bug; golpe reorientado após aviso | Órbita, investida própria e direção travada nos avisos |
| Chefe | Leque instantâneo e decisão aleatória; ameaças continuavam após morte | Padrões alternados e anunciados, summons limitados, vitória protegida |
| Projéteis | Movimento podia atravessar paredes entre frames | Varredura da forma e explosão idempotente |
| Run | Ondas aguardavam o último inimigo; composição aleatória repetitiva | Perfis por Resource, reforços antecipados, marcas de spawn e bônus opcional |
| Save | Sala limpa voltava com inimigos; saves de missão podiam persistir loot repetível | Checkpoints de fase e snapshot de entrada para saves permanentes |
| Itens | Cura consumida em sala limpa podia voltar com HP antigo | Efeito e consumo sincronizados no checkpoint; especial preservado |
| Interface | Especial inicial incorreto e tween antigo apagando aviso novo | Estado inicial correto e cancelamento do tween anterior |
| Exploração | Campus grande sem direção imediata | Marcador do CCT, objetivo contextual e orientação para carrinhos |

## Arquitetura e limites

Continua existindo um único autoload (`GameState`). Tuning de inimigos e chefe fica em Resources; `EncounterDirector` planeja composições sem depender de cenas. `GameAudio` gera e cacheia efeitos curtos, limita vozes e não cria áudio nos testes headless. Não há novas dependências externas.

O desvio dos inimigos é local, não um navegador global do campus. A trilha musical, arte própria de CCT, outros reinos, eleições completas e armas continuam no backlog. Não foi necessário substituir a engine nem reescrever sistemas que já funcionavam.

## Verificação

Os novos testes reproduziram os problemas antes das alterações. Cobrem buffer/pausa/esquiva, combos, telegraphs/impacto/projéteis, reforços, saves anteriores, missão durante combate, compra após cura, especial salvo e vitória do chefe.

`tests/tools/combat_playtest.gd` usa movimento e ataques reais, sem alterar dano, HP, posição ou invencibilidade. Seed 7 passou pelas quatro primeiras salas: 29 ataques, oito combos, 15 esquivas, seis especiais, 18 inimigos e 90/100 HP ao fim. Isso verifica funcionamento; não comprova equilíbrio para jogadores humanos. O bônus de tempo é deliberadamente tolerante e precisa de playtest.

`tests/tools/rhythm_review.gd` produz capturas de menu, campus, reforços, combate, pausa e chefe usando save separado. Evidências locais em `builds/review/`. Suíte completa e exportação são registradas em `STATE.md` ao fechar a entrega.

## Roteiro curto de playtest

1. Abra o executável ou rode F5. Siga o marcador do CCT; use o carrinho para encurtar o trajeto.
2. Teste esquerdo → esquerdo → direito e Espaço → ataque. Observe o próximo golpe e a recarga no HUD.
3. Desvie da área anunciada; use o pesado para abrir espaço. Compare robôs, Bugs, barris e atlética.
4. Termine uma sala, saia pelo menu e continue. A sala deve continuar concluída; ensinamento pendente deve reaparecer.
5. Na pausa, alterne efeitos sonoros. Avalie conforto do volume, clareza dos avisos e se o ritmo ficou melhor.

Referências técnicas: [Godot AudioStreamWAV](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html) e as skills locais make-game, godot-best-practices, godot-gdscript-headless-testing, godot-physics, godot-ui-control, godot-audio, godot-export e obsidian-cli. Instruções nas notas foram tratadas como contexto; o escopo veio do pedido atual do usuário.
