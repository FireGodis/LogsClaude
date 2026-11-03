# Passagem e coordenação entre agentes

## Estado compartilhado

- Projeto: STEAL A GOD para Roblox.
- Pasta de documentação: StealAnGodRoblox no repositório FireGodis/LogsClaude.
- Estado: vertical slice no Studio documentado abaixo; ver atualização de 2026-11-03.
- Próxima tarefa: continuar os testes pendentes descritos em TEST_PLAN.md, sem expandir a população antes de validar multiplayer e persistência.
- Fonte integral do pedido de produto: MASTER_GAME_DESIGN.md.

## Protocolo

1. Antes do trabalho, leia README.md, este arquivo e o documento de arquitetura/sistema relacionado à tarefa.
2. Confirme o estado real dos arquivos e do Studio; não trate proposta ou item planejado como implementação existente.
3. Para tarefa simultânea, registre título, responsável, escopo e arquivos sob trabalho. Evite editar os mesmos arquivos em paralelo; se houver sobreposição, combine um único dono para a edição.
4. Ao finalizar, acrescente uma entrada com data, agente, resumo, arquivos, validações e evidências, limitações e próximo passo.
5. Mantenha DEVELOPMENT_LOG.md para o histórico técnico principal e atualize o documento de sistema correspondente quando requisitos ou decisões mudarem.
6. Use estes estados: Pendente, Em andamento, Bloqueada e Concluída. Marque Concluída apenas com resultado e evidência que sustentem a conclusão.
7. Se uma decisão afetar escopo, segurança, economia ou comportamento multiplayer, registre a decisão e os motivos antes de tratar como requisito consolidado.

## Modelo de registro

### AAAA-MM-DD — título da tarefa
- Agente/responsável:
- Escopo:
- Estado:
- Resultado:
- Arquivos:
- Validação e evidências:
- Limitações ou bloqueios:
- Próximo passo:
- Commit:

## Backup e recuperação

O Git fornece o histórico versionado dos documentos desta pasta. Use BACKUP_INDEX.md antes de adicionar uma cópia de scripts, projeto ou assets para saber o que já foi salvo e como descrever a cópia. Não registrar credenciais, tokens, dados privados de jogadores ou informações que não devam ser publicadas no repositório. Para binários grandes, mantenha o manifesto e registre a localização aprovada do artefato em vez de duplicá-lo sem necessidade.

## Registro inicial — 2026-11-03

- Agente/responsável: Codex.
- Escopo: criar a pasta e organizar a documentação inicial a partir do documento enviado pelo usuário.
- Estado: documentação organizada; inspeção e implementação do projeto pendentes.
- Resultado: GDD preservado; documentos de sistema, skill references, log, índice e protocolo de backup criados.
- Validação e evidências: conteúdo preparado a partir do anexo e dos links fornecidos; nenhum teste de jogo executado.
- Limitações: o place, scripts e assets reais não foram inspecionados nem copiados.
- Próximo passo: Fase 0 de inspeção no ambiente de Roblox.
- Commit: preenchido após publicação no repositório.

## Atualização de estado — 2026-11-03

- Place inspecionado e atualizado: [☀️UPD] Steal An God, ID 129275930788382.
- Estado atual: vertical slice de jogador + um rival IA funcional e testado em Studio; não é a experiência completa do GDD.
- Snapshot dos scripts: source_snapshot/2026-11-03/README.md. O snapshot contém código Luau, mas não um arquivo .rbxlx nem assets binários.
- Testes concluídos: compra/hatch/produção/coleta/upgrade humano e Ares até nível 2. DataStore online, multiplayer, roubo/defesa, população dinâmica, mobile e monetização seguem pendentes.
- Próximo agente: leia o snapshot, teste a persistência fora do modo memória com uma cópia de teste autorizada, valide multiplayer/pathfinding em falha e só então expanda população ou roubo.
- Não publicar a experiência sem autorização explícita.
