# Plano de testes e critérios de validação

## Estado

O primeiro playtest do slice foi executado no Roblox Studio em 2026-11-03. O status de cada caso abaixo reflete apenas o alcance efetivamente observado; pendências de persistência, multiplayer, justiça, mobile, compras e desempenho continuam sem validação.

## Casos de teste

| ID | Área | Cenário | Resultado esperado | Estado |
|---|---|---|---|---|
| ENV-01 | Ambiente | Abrir/inventariar projeto e ferramentas disponíveis | Registrar formato, Studio, Rojo/sincronização, packages, cenas e estado encontrado | Parcial |
| CORE-01 | Início | Humano entra e recebe base disponível | Uma base exclusiva atribuída; sem colisão com outros jogadores | Parcial |
| CORE-02 | Economia | Gerar, coletar e gastar Coins | Saldo validado pelo servidor e UI sincronizada | Aprovado |
| CORE-03 | Hatch | Comprar ovo e executar hatch válido | Ovo sai do inventário uma vez; resultado é escolhido pelo servidor e deus entra uma vez | Aprovado |
| CORE-04 | Produção | Posicionar um deus e aguardar renda | Renda baseada na configuração e creditada pelo servidor | Aprovado |
| CORE-05 | Progressão | Atualizar base/deus e testar rebirth | Custos, desbloqueios e reset correspondem à regra definida | Parcial |
| SAVE-01 | Persistência | Sair/reentrar, falha ou repetição de save | Dados íntegros, versionados e recuperáveis conforme a arquitetura selecionada | Pendente |
| BOT-01 | IA | Um rival progride sem scripts aleatórios de movimento | Compra, hatch, coleção e upgrade guiados por objetivos independentes | Aprovado |
| BOT-02 | População | Validar com 1–7+ humanos | Alvo de 6, 5, 4, 3, 2, 1 e 0 rivais para 1–7+ humanos conforme configuração inicial | Pendente |
| BOT-03 | Navegação | Navegar, falhar em destino e recalcular | Movimento por PathfindingService; sem teleporte para fingir atividade | Parcial |
| BOT-04 | Justiça | Verificar conhecimento oculto e proteção do jogador | Sem visão de inventário/ovos ocultos, ataques repetidos ou roubo inelegível | Pendente |
| STEAL-01 | Roubo | Iniciar roubo válido e inválido | Servidor verifica dono, alcance, cooldown, elegibilidade, conclusão e retorno à base | Pendente |
| STEAL-02 | Anti-duplicação | Desconectar durante roubo / repetir evento | Item transferido uma vez ou recuperado sem duplicação | Pendente |
| DEF-01 | Defesa | Receber alerta e usar defesa/ability | Defesa é válida no servidor e avisa o proprietário a tempo | Pendente |
| PAY-01 | Gamepass | Testar propriedade, concessão e falha | Benefício concedido conforme ownership real, sem confiar no cliente | Pendente |
| PAY-02 | Developer Product | Repetir ProcessReceipt e falhar concessão | Recebimento idempotente, sem item duplicado, com recuperação segura | Pendente |
| PAY-03 | Random pago | Restringido e elegível; odds e modificadores | Respeitar PolicyService, divulgar resultados/odds efetivas e bloquear gerador quando restrito | Pendente |
| SEC-01 | Remotes | Payload inválido, spam, item/currency forjado | Requisição recusada ou limitada; nenhum estado crítico decidido pelo cliente | Pendente |
| UI-01 | Dispositivos | Revisar HUD, hatch, loja e base em desktop, tablet e mobile | Interface legível, operável e sem corte de conteúdo crítico | Pendente |
| PERF-01 | Servidor | Medir IA, física, remotes e efeitos com população alvo | Sem atualização por frame desnecessária ou crescimento ilimitado de trabalho | Pendente |

## Registro de cada execução

Para cada caso, anotar data, versão/commit ou place, pré-condições, passos, esperado, observado, evidência, resultado e limitações. Separar teste estático de playtest, Studio e validação em cliente real. Descrever avisos preexistentes separadamente de regressões novas.

## Gate de lançamento inicial

Não declarar a versão inicial completa até validar o loop central, persistência, multiplayer, bots, roubo/defesa, compras, segurança, UI móvel e desempenho previstos no GDD. O checklist detalhado está em [PROJECT_SPEC.md](PROJECT_SPEC.md). Publicar exige autorização explícita.

## Playtest no Studio — 2026-11-03

Place: [☀️UPD] Steal An God (129275930788382), Roblox Studio Play. Foi executada uma sessão com um cliente humano e Ares.

### Passou

- Spawn e atribuição de base exclusiva para o cliente.
- Compra de Greek Egg: 150→50 Coins e inventário +1.
- Hatch: ovo consumido, Zeus atribuído uma vez, estátua criada e produção +4 Coins/s.
- Geração em saldo pendente e coleta para Coins.
- Upgrade humano nível 1→2: custo 100, atributo de base atualizado e trilho visual criado; renda nível 2 passa a +5 Coins/s.
- Ares: base 7 marcada OwnerKind=AI, deslocamento por caminho, compra, hatch, coleta e upgrade para nível 2.
- HUD atualizou saldos, inventário, status e nível da base.

### Limites deste teste

Studio usou StudioMemoryOnly=true; o console mostrou o aviso esperado e não houve leitura/escrita de DataStore online. Não foram verificados rejoin, lock entre servidores, múltiplos clientes, caminho bloqueado, mobile, desempenho de população, roubo, defesa, recibos ou publicação. Upgrade cobre nível 1→2, não rebirth.
