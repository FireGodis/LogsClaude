# STEAL A GOD — documentação do projeto

Esta pasta reúne a especificação do jogo, documentos de planejamento, referências de ferramentas, coordenação entre agentes e o índice de backups do projeto Roblox **STEAL A GOD**.

## Estado atual

A documentação inicial foi organizada em 3 de novembro de 2026 a partir do documento mestre fornecido pelo usuário. O documento original foi preservado em [MASTER_GAME_DESIGN.md](MASTER_GAME_DESIGN.md).

O projeto Roblox, o place no Studio, scripts, modelos e configurações ainda não foram inspecionados nesta etapa. Nenhum sistema do jogo foi implementado ou validado por este commit. O próximo passo é a Fase 0: inspecionar o ambiente real antes de propor alterações.

## Documentos

| Documento | Conteúdo |
|---|---|
| [MASTER_GAME_DESIGN.md](MASTER_GAME_DESIGN.md) | Cópia integral do GDD e da especificação de desenvolvimento fornecidos pelo usuário |
| [PROJECT_SPEC.md](PROJECT_SPEC.md) | Visão do produto, princípios, arquitetura sugerida, fases e critérios de aceite |
| [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) | Estado documentado, alterações realizadas e próximos passos |
| [ASSET_MANIFEST.md](ASSET_MANIFEST.md) | Convenções propostas e inventário inicial de assets, ainda não verificados |
| [ECONOMY_DESIGN.md](ECONOMY_DESIGN.md) | Moedas, fontes e usos planejados, monetização e regras de odds |
| [BOT_AI_DESIGN.md](BOT_AI_DESIGN.md) | Arquitetura e comportamento planejados dos rivais controlados por IA |
| [TEST_PLAN.md](TEST_PLAN.md) | Cenários de validação e critérios de aceite; os testes ainda não foram executados |
| [SKILLS_AND_WORKFLOW.md](SKILLS_AND_WORKFLOW.md) | Skills de Roblox e Blender indicadas pelo usuário e quando consultá-las |
| [AGENT_HANDOFF.md](AGENT_HANDOFF.md) | Protocolo para registrar progresso, evidências, pendências e passagem entre agentes |
| [BACKUP_INDEX.md](BACKUP_INDEX.md) | Índice e convenção para futuras cópias de segurança |

## Referências de desenvolvimento

- [Roblox Game Skill](https://github.com/brockmartin/roblox-game-skill/tree/main) — referência para trabalho em Luau, Roblox Studio, arquitetura, segurança, desempenho e fluxos de desenvolvimento.
- [Blender SuperSkill](https://github.com/powerhouse90/Blender-Superskill) — referência para criação, inspeção e validação iterativa de assets no Blender.

As skills permanecem nos repositórios de origem; esta pasta guarda links e orientações de uso, não uma cópia das instruções de terceiros. Consulte [SKILLS_AND_WORKFLOW.md](SKILLS_AND_WORKFLOW.md).

## Uso da pasta como histórico e coordenação

Os commits deste repositório mantêm o histórico versionado dos documentos. Para o estado compartilhado entre agentes, atualize [AGENT_HANDOFF.md](AGENT_HANDOFF.md) com resumo, arquivos, evidências e próximos passos. Para backups futuros de scripts ou assets, registre origem, data e escopo em [BACKUP_INDEX.md](BACKUP_INDEX.md). Esta primeira organização não inclui uma cópia do place, scripts ou modelos Roblox.
