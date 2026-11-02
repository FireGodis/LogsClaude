# Arquitetura e sistemas

## Estrutura versionada

`src/` espelha 33 LuaSourceContainers do place como arquivos `.luau`. O caminho relativo depois de `src/` corresponde ao caminho no DataModel, por exemplo `src/StarterPlayer/StarterPlayerScripts/Client/Controllers/Movement.luau`. Isso não é um projeto Rojo e não inclui cenas, peças, tags, atributos ou assets não-script.

## Cliente

- `Input`: ações de teclado, mouse, controle e toque via UserInputService.
- `Movement`: PreSimulation, corrida, pulo variável, coyote/buffer, dash, combate, dano, Double Jump, Wall Jump e bloqueio de controle.
- `KnightAnim` + `KnightSpec`: rig por Motor6D. A especificação inclui grupos `wingA`/`wingB` e duas cunhas de asa autorais que aparecem durante flap.
- `CombatFx` e `Audio`: VFX procedural e sons existentes.
- `Dialogue`: UI runtime genérica, typewriter, fade de nome, avanço de fala, lock de controles e tecla/espaço/controle.
- `Cutscene`: anima câmera/personagem e agora segura um lock de controles até conclusão, destruição de personagem ou encerramento.
- `HUD`, `Menu`, `CameraRig`, `Zone`, `EnemyAnim`: apresentação e contexto de jogo.

## Servidor

- `PlayerData`: save versionado, sanitização, lock, retry, autosave e nova API `saveNow(player)`.
- `WorldSystem`: bancos, colecionáveis, pontes de eco e criação dos NPCs de história. Descansar persiste o checkpoint imediatamente quando o perfil é persistente.
- `Combat`: valida ataque, dash, habilidades, dano, máscaras, foco e respawn; Flap/WallJump têm rate limit e checagens de perfil/estado.
- `Net`: cria remotes com rate limit. O remote `Story` agora é compartilhado nos contratos C2S/S2C.
- `Enemies`, `EnemyTypes`, `EnemyRig`, `BossAI`: sistemas existentes não foram alterados nesta sessão.

## Dados narrativos e progressão

`WorldSystem` descreve os registros de NPC (id, nome, região, coordenada, habilidade, falas iniciais e repetidas), cria um modelo simples e um ProximityPrompt, e envia as falas ao cliente pelo evento Story. O cliente envia `Finish`; o servidor confere que a conversa estava pendente, a identidade do NPC e a distância. A habilidade é gravada no perfil, publicada em atributo e salva imediatamente. Para adicionar NPC, estenda `STORY_NPCS`; para criar novas mecânicas de habilidade, altere Config, Movement, servidor e animação compatíveis.

## Limites de integração

- O modelo físico do mapa está em Workspace; a sessão não reposicionou plataformas porque não obteve reprodução de um trecho preso.
- As asas e efeitos são peças/partículas originais geradas por código. Audio.play reaproveita os templates do jogo; não há efeito sonoro inédito para cada habilidade.
- O arquivo do place não foi confirmado como salvo pela interface; o código-fonte versionado está em `src/`.