# Desenho da IA dos rivais

## Princípio

Os rivais são NPCs pertencentes à experiência, identificados como IA. Não são contas Roblox falsas. Devem criar competição sem enganar o jogador, ignorar regras ou esconder mecânicas.

## Perfis iniciais

| Rival | Personalidade | Prioridades descritas |
|---|---|---|
| ARES | Agressivo | Explorar bases, buscar ovos raros, aceitar mais risco e investir no ataque |
| ATHENA | Estratégica | Melhorar produção, estudar rivais e selecionar incursões calculadas |
| LOKI | Imprevisível | Alternar coleta e incursão, usar iscas e trocar de alvo |
| ANUBIS | Defensivo | Investir em segurança, deuses defensivos e evitar agressão desnecessária |
| HERMES | Oportunista | Procurar alvos desprotegidos, mover-se rápido e preferir incursões curtas |
| THOR | Competitivo | Buscar deuses fortes, desafiar rivais e avançar marcos |

Os perfis são configuração de pesos e preferências; não devem exigir uma arquitetura de decisão distinta por NPC.

## Arquitetura proposta

- Utility AI para pontuar ações possíveis conforme recompensa, risco, distância/tempo, estado do rival e personalidade.
- Máquina de estados hierárquica para executar a ação escolhida: Idle, Collecting, Scouting, Purchasing, Hatching, Upgrading, Defending, PreparingRaid, Infiltrating, Stealing, Escaping, Recovering, ParticipatingInEvent, ReturningHome ou Retiring.
- Objetivos de progressão e memória curta para evitar decisões sem contexto.
- Navegação com PathfindingService e Humanoid, incluindo detecção de destino inalcançável e recálculo de caminho.
- Atualização em intervalos controlados; não avaliar todos os NPCs a cada frame.

O primeiro marco valida apenas um rival funcional, incluindo economia simulada, compra de ovo, hatch, coleta e upgrade. Depois disso, ampliar perfis e população.

## Estado isolado por rival

Estado simulado: moedas, inventário, deuses, ovos, base, upgrades, habilidade, objetivo atual, perfil, dificuldade e memória curta. Por padrão, bots existem no escopo do servidor e não usam DataStore de jogadores. Bots não recebem Robux nem realizam compras reais.

## População dinâmica

Configuração inicial do GDD:

- TargetActivePopulation = 7
- MaxBots = 6
- MinimumBots = 0
- BotTarget = min(MaxBots, max(0, TargetActivePopulation - HumanPlayerCount))

| Jogadores humanos | Rivais IA alvo |
|---:|---:|
| 1 | 6 |
| 2 | 5 |
| 3 | 4 |
| 4 | 3 |
| 5 | 2 |
| 6 | 1 |
| 7 ou mais | 0 |

Esses valores são configuráveis. A contagem humana usa Players:GetPlayers(); NPCs não devem ser contados como Players.

Ao reduzir a população, interromper novos objetivos dos bots excedentes, concluir interações seguras, retornar ao templo, executar animação de aposentadoria e só então remover modelos e liberar recursos. Ao aumentar, criar NPCs gradualmente.

## Justiça e interação com humanos

- Não conhecer o conteúdo de ovos ocultos, ver através de paredes ou consultar inventário privado sem observação legítima.
- Respeitar distância, cooldowns, ownership, defesas, proteção de novos jogadores e limites de roubo.
- Não roubar itens comprados diretamente com Robux.
- Não repetir ataques ao mesmo jogador; priorizar bot contra bot quando a população humana for baixa.
- Exibir alertas de incursão, oportunidades defensivas e recuperação depois de um roubo.
- Feed de atividade deve identificar as ações como realizadas por NPCs/IA.

## Pendências

Validar a primeira política de utilidade, os limites de frequência e o custo de navegação no projeto real. Balanceamento de dificuldade só deve acompanhar a progressão de forma compreensível; não deve manipular resultados para forçar compras.

## Primeiro rival implementado — Ares (2026-11-03)

A implementação atual está em BotAIService no snapshot de código. O servidor reserva a base 7, cria um NPC R15 próprio, identifica-o como ARES • IA e mantém estado econômico independente de Players e DataStore.

- Personalidade configurada: Aggressive; pesos utilitários pontuam compra, hatch, coleta e upgrade.
- Estados observáveis: Purchasing, Hatching, Collecting, Upgrading, SavingCoins/Defending e Recovering.
- Usa 150 Coins iniciais, paga 100 por ovo, gera renda de Zeus em saldo pendente e coleta para o saldo do bot. Compra, hatch, coleta e upgrade checam inventário e moedas no servidor.
- Para deslocamento, calcula rotas com PathfindingService e move o Humanoid por waypoints. Caminhos bloqueados ou sem sucesso são tentados novamente até o limite configurado.
- Upgrade nível 2 usa o mesmo custo e multiplicador configurados para jogadores; o estado do bot existe apenas no ciclo do servidor.
- No playtest, Ares chegou ao hub, comprou o ovo, voltou à base, chocou Zeus, coletou e alcançou nível 2. Não houve teleporte de progresso.

### Escopo ainda pendente

A implementação valida um rival, não a população de seis. Ares ainda não rouba, invade, defende contra invasões, participa de eventos ou usa feed. Apenas uma personalidade e o nível 2 foram exercitados; caminho inalcançável, múltiplos jogadores, aposentadoria e fairness ainda exigem testes.
