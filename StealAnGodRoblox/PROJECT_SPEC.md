# STEAL A GOD — especificação do projeto

## Visão

STEAL A GOD é um simulador multiplayer Roblox de coleção, progressão, bases e incursões. Jogadores compram e chocam ovos divinos, coletam deuses mitológicos, posicionam-nos em bases para gerar recursos, evoluem sua coleção e podem invadir bases rivais para roubar itens elegíveis. Rivais NPC transparentemente identificados como IA mantêm o mundo ativo em servidores com poucos jogadores humanos.

A especificação completa fornecida pelo usuário está em [MASTER_GAME_DESIGN.md](MASTER_GAME_DESIGN.md). Este documento organiza os requisitos para planejamento; ele não confirma que o projeto de jogo já exista ou que qualquer requisito esteja implementado.

## Plataforma e direção

- Plataforma e engine: Roblox.
- Linguagem: Luau.
- Arte 3D: Blender; ForgeGUI somente para fluxos cuja disponibilidade e capacidades forem verificadas.
- Gênero: simulador multiplayer de coleção, roubo, tycoon e progressão.
- Civilizações iniciais: grega (Olympus), nórdica (Asgard) e egípcia (Egyptian Kingdom).
- Hub compacto: loja de ovos, loja premium, rebirth, quests, recompensas diárias, eventos, museu, placares e guias NPC.
- Direção de arte: estilizada, colorida, legível, com silhuetas distintas e desempenho adequado a dispositivos móveis.

## Pilares de experiência

1. Objetivo principal compreensível em até 30 segundos.
2. Sempre existir uma meta útil de progressão.
3. Competição significativa por coleta, invasão, defesa e interação.
4. População de rivais NPC reduzir gradualmente à medida que entram humanos.
5. Monetização clara e sustentável, sem escassez falsa, jogadores falsos ou urgência enganosa.

## Sistemas principais

### Coleção e ovos

O catálogo de deuses deve ser orientado por dados, com identificador, nome, civilização, raridade, modelo, ícone, renda, multiplicador de evolução, habilidade, cooldown, descrição e referências visuais e sonoras. As listas iniciais incluem oito deuses por civilização, mas a primeira implementação deve usar um grupo representativo menor até o loop central estar estável.

Tipos de ovos planejados: Greek, Norse, Egyptian, Ancient, Celestial e Divine. Raridades planejadas: Common, Uncommon, Rare, Epic, Legendary, Mythic e Divine. Custos, tempos e probabilidades permanecem por definir e devem ser configuráveis, sem lógica de odds espalhada em scripts.

### Bases, economia e progressão

Cada jogador deve receber uma base individual, com slots de deuses, armazenamento, coleta de moedas, estações de evolução, defesa e personalização. As moedas propostas são Coins, Gems e Divine Shards. Produção, capacidade, upgrades, quests, achievements, coleção, recompensas diárias e rebirth devem avançar em marcos graduais.

### Invasões e segurança

Roubo de ovos ou deuses elegíveis usa autoridade do servidor, validação de dono, distância, linha de visão quando aplicável, cooldowns, limite de solicitações, prevenção de duplicação e tratamento de desconexão. O dono recebe aviso e oportunidade de defesa. Colecionáveis comprados diretamente com Robux não podem ser roubados sem um desenho explícito, transparente e compatível com as regras aplicáveis.

### Rivais NPC

NPCs são concorrentes do jogo, nunca contas ou jogadores Roblox falsos. Devem seguir as regras aplicáveis aos humanos, manter uma identidade clara e não conhecer conteúdo oculto ou atravessar paredes. O sistema combina Utility AI, máquina de estados hierárquica, objetivos, memória curta, personalidade e avaliação de risco. A primeira etapa é validar um rival antes de aumentar a população.

### Monetização e conformidade

Gamepasses, Developer Products, bundles, cosméticos e produtos futuros devem usar identificadores configuráveis. Nenhum ID real deve ser inventado. ProcessReceipt deve ser idempotente e a validação de compras deve ocorrer no servidor.

Ovos ou outras recompensas aleatórias pagas exigem revisão do fluxo oficial da Roblox, divulgação dos resultados e odds efetivas e tratamento por jogador conforme PolicyService. Veja [ECONOMY_DESIGN.md](ECONOMY_DESIGN.md) e [TEST_PLAN.md](TEST_PLAN.md).

## Arquitetura sugerida

A sugestão inicial separa configuração e módulos compartilhados, remotes, serviços do servidor, controladores do cliente, interfaces, mapa, bases, spawners e NPCs. Serviços mencionados no GDD incluem PlayerData, Economy, God, Egg, Base, Steal, Ability, Upgrade, Rebirth, Quest, Event, Monetization, Receipt, AntiExploit, BotPopulation, BotSimulation, BotNavigation, BotEvent e WorldFeed.

A estrutura final deve ser adaptada ao formato encontrado na Fase 0. Não criar serviços duplicados nem presumir que Rojo, ForgeGUI ou qualquer integração esteja instalada.

## Fases planejadas

| Fase | Resultado esperado |
|---|---|
| 0 — Inspeção | Inventariar o projeto, ferramentas, Studio, Rojo, sincronização e estado atual; registrar especificação, log, assets, economia, IA e plano de testes |
| 1 — Fundação | Estrutura modular, configurações, inicialização de cliente/servidor, remotes, dados, HUD e atribuição de base |
| 2 — Primeiro loop | Moedas, compra de um ovo, inventário, hatch, um deus, posicionamento, renda e upgrade básico |
| 3 — Primeiro rival | Um NPC progride, compra, choca, coleta e evolui de forma independente |
| 4 — População de IA | Perfis adicionais, navegação, interação entre bots, população dinâmica e aposentadoria gradual |
| 5 — Roubo | Invasão, transporte, conclusão na base do ladrão, alertas, defesa, cooldowns e regras server-side |
| 6 — Habilidades | Deuses representativos com habilidades, efeitos, cooldowns e validação no servidor |
| 7 — Progressão | Upgrades, rebirth, quests, achievements, coleção, recompensas e eventos |
| 8 — Monetização | Gamepasses, produtos, recibos, bundles, cosméticos e política de itens aleatórios pagos |
| 9 — Arte | Integrar e revisar assets Blender, importação, escala, pivôs, colisões, materiais e desempenho |
| 10 — QA | Validar persistência, multiplayer, IA, roubo, defesa, compras, segurança, UI móvel e desempenho |
| 11 — Lançamento | Preparar ícone, thumbnails, descrição, onboarding, analytics, ajuste de economia e checklist; publicação exige autorização explícita |

## Critérios de aceite

A primeira versão jogável deve permitir entrar, receber base, ganhar moedas, comprar e chocar ovos, coletar e posicionar deuses, gerar renda, melhorar a base, fazer rebirth, roubar itens elegíveis e defender-se. IA, monetização, segurança e desempenho devem satisfazer os cenários listados em [TEST_PLAN.md](TEST_PLAN.md).

## Estado inicial

- Estado: documentação organizada; inspeção técnica do jogo pendente.
- Escopo implementado nesta etapa: documentação baseada no GDD fornecido.
- Testes de jogo: não executados.
- Próximo passo: Fase 0 — inspeção do ambiente e do projeto real, antes de modificar scripts ou assets.
