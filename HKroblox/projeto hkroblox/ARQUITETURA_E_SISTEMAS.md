# Arquitetura e sistemas

## Cliente

Entrada em `StarterPlayer.StarterPlayerScripts.Client` conecta controladores sob `Controllers`.

- `Input`: combina teclado, mouse, controle e botões de toque em ações lógicas. Usa UserInputService.
- `Movement`: deslocamento 2.5D em PreSimulation; coyote time, buffer e corte de pulo, dash, ataques, pogo, foco, stagger e eventos remotos.
- `KnightAnim`: monta animação de peças com Motor6D; lê estado local e atributos replicados para outros jogadores.
- `CameraRig`: câmera de gameplay e override de cutscene.
- `CombatFx` e `Audio`: efeitos visuais e sons acionados pelos controladores.
- `HUD`, `Menu`, `Cutscene`, `Zone`, `EnemyAnim`: interface e apresentação criadas por código.

## Servidor

`ServerScriptService.Server` inicia remotos, sistemas e carregamento do perfil; personagens só são carregados após PlayerData.

- `PlayerData`: DataStore `RollowKnifeProfiles_v1`, migração de `MareProgress_v1`, validação de checkpoint/habilidades, retry, lock, autosave e BindToClose.
- `Combat`: valida ações remotas, dano, máscaras, cura, foco, respawn e queda.
- `WorldSystem`: bancos via CollectionService `Bench`, coleta e pontes `EchoBridge`.
- `Enemies`, `EnemyTypes`, `EnemyRig`, `BossAI`: IA, inimigos e chefe.
- `Net`: nomes e limites de requisição.

## Dados compartilhados

- `Config`: números de movimento, combate, inimigos, câmera, máscaras e habilidades iniciais.
- `WorldMap`: salas, biomas, portas, bancos, spawns, colecionáveis, barreira, chefe e limites.
- `KnightSpec`: especificação da montagem por peças.
- `Types`, `MaskMath`, `EnemySpec`, `Remotes`: tipos, matemática e contratos.

## Limites identificados

O mapa físico está materializado em `Workspace.Mundo`; não foi localizado script ativo que o gere a partir de `WorldMap`. Uma mudança apenas na tabela de salas não necessariamente altera a geometria existente. Mudanças de navegação precisam considerar partes físicas, spawns, colisões, portas e os limites do movimento.

As interfaces são construídas em runtime; editar `StarterGui` sem examinar os controladores pode criar interfaces duplicadas. Não foi encontrada uma camada de diálogo ou definição de NPC.
