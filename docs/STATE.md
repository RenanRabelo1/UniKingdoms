# Session state

## Last updated

2026-11-06 — Codex. Skills: make-game, Godot (boas práticas, física, testes, UI, áudio, exportação), obsidian-cli. Análises paralelas de combate, inimigos e progressão.

## Current phase

development — v1.2 implementada, validada e exportada; avaliação humana do feel pendente.

## Current milestone

[Milestone 05: ritmo de combate](milestones/05-v1.2-ritmo-de-combate.md). Diagnóstico e roteiro de teste em [analise-v1.2.md](analise-v1.2.md).

## Last action

- Input buffer de 180 ms, relógio de simulação, dash cancel e ataque de avanço, combos limitados e orientação no HUD.
- Knockback/stagger, telegraphs contrastantes, robôs móveis, investida da atlética, boss com padrões e summons limitados; projéteis com varredura.
- Três perfis de encontro, reforços anunciados, bônus opcional e menor crescimento de HP por sala.
- Checkpoints para sala limpa/ensino, coleta de moedas idempotente, cura/especial salvos e snapshot de entrada para evitar farm via missão.
- HUD responsivo, marcador do CCT, efeitos sonoros sintetizados e opção de desativá-los na pausa.
- Executável novo: `builds/ReinosDaUnifor-v1.2.exe` (a build anterior foi mantida).

## Validation

- GUT: **119/119 testes, 1.364 asserts**, 16 scripts; saída 0. Há um aviso no fixture antigo `test_enemies.gd` sobre seis filhos de efeitos ainda vivos ao encerrar o teste; sem erro de script.
- Autoplay ponta a ponta: **OK**, vitória nas 12 salas, campus, morte e continuar sem farm.
- Bot com input real: seed 42, três salas; seed 7, quatro salas, 18 inimigos, 29 ataques, oito combos e 90/100 HP final. Sem teleporte, dano alterado ou invencibilidade.
- Capturas em janela: menu, campus, marcas de reforço, combate, pausa, Mainframe; execução final sem erros.
- Export Windows e smoke headless do executável: saída 0, sem erros.
- Campus: 25.768/25.768 células acessíveis, nenhuma presa na verificação existente.

Logs e capturas locais em `builds/`; resultados red/green em `builds/validation-history/`. Sem commit ou publicação remota nesta sessão.

## Next step

Playtest do usuário: testar `esq → esq → dir`, `Espaço → ataque`, leitura dos avisos e retomada de sala concluída. Ajustar dificuldade, janela do bônus e volume a partir da experiência real; não expandir antes desse retorno.

## Blockers

Nenhum para executar a v1.2. Navegação global do campus, trilha final, arte própria e outros reinos continuam no backlog.

## Notes for next session

- Novos scripts `class_name` exigem importar/recarregar o projeto no editor.
- Godot GUI no Windows: use pipe ou Start-Process -Wait para aguardar e capturar exit code. Processos auxiliares em janela oculta.
- `user://` pode ser bloqueado no sandbox; use save isolado nos testes e caminho absoluto para `--log-file`.
- GUT `-gtest` acrescenta scripts; `-gselect` filtra. Não rodar suítes concorrentes que usem o mesmo save temporário.
- Scripts `-s` compilam antes dos autoloads; runners usam load em runtime e evitam tipos que dependem de GameState.
