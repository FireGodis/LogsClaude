# Log de alterações

## 2026-11-02 — documentação inicial e auditoria estática

- **Sistema:** documentação e inventário do projeto.
- **Arquivos criados:** todos os documentos desta pasta, incluindo histórico das Fases 5 e 6.
- **Problema identificado:** o repositório GitHub tinha somente `HKroblox/.gitkeep`; o conteúdo real estava no place conectado do Roblox Studio.
- **Causa:** o place ainda não foi espelhado em arquivos-fonte neste repositório.
- **Funcionamento anterior:** não havia documentação nem código do jogo versionado no diretório solicitado.
- **Funcionamento esperado:** manter contexto, fases, arquitetura, bugs, validações e handoff legíveis para outro desenvolvedor.
- **Funcionamento após a alteração:** documentação inicial criada com fatos observados e lacunas marcadas; nenhuma fase foi declarada concluída.
- **Testes realizados:** leitura do metadado do repositório, árvore do place, busca/read de scripts, contagem e localização de objetos do Workspace.
- **Resultado:** análise estática concluída; não foi iniciado Play mode nem testada persistência real.
- **Problemas durante a implementação:** o conector GitHub não oferece uma listagem de árvore para esta tarefa; o estado inicial foi confirmado pelo conteúdo vazio e metadado do repositório. `StarterGui` está vazio porque interfaces são criadas via script.
- **Pendências:** exportar fontes/modelos do place para o repositório; validar comportamento em Play mode; completar Fases 5 e 6; testar os bugs reportados.
- **Relações:** Movement depende de Input, Config, Net, Audio e CombatFx; Cutscene depende de CameraRig e KnightAnim; mapa, bancos e checkpoints ligam WorldMap, WorldSystem, Combat e PlayerData.
