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

## Atualização — 2026-11-02

- `Movement.acquireControlLock()` continua sendo o contrato de exclusão mútua usado por diálogo e cutscene. Sob qualquer token ativo, WalkSpeed, JumpPower, JumpHeight e estado Jumping são suspensos e a velocidade física é anulada; um snapshot restaura as configurações quando o último token é liberado. A checagem ocorre antes de hit-stop.
- `Config.Move` define o impulso de flap; `KnightSpec` descreve asas maiores em dois grupos, e `KnightAnim` anima e torna os membros visíveis por 0,42 s.
- Wall Jump detecta parede via raycast e usa cooldown local curto para permitir saltos sucessivos no mesmo plano após recontato. O cooldown do evento visual é limitado no servidor.
- `Combat.damagePlayer` consulta tags `Bench` e aplica o raio/tolerância de altura de `Config.World`; `WorldSystem` continua dono dos bancos, NPCs e progressão.
- Os NPCs agora são modelos procedurais compostos de BaseParts para manter o runtime independente de asset externo. Não são rigs animados nem o modelo 3D do ForgeGUI; cada revisão visual substitui a instância antiga.

## Movimento aéreo — revisão 2026-11-02

- `Config.Move` concentra `FlapDuration`, impulso, força de wall jump, slide e cooldown de recontato.
- `Movement` determina contato físico por raycast, mas só publica estado de escalada quando `Ability_claw` está ativa. Wall hop restaura dash e flap e usa direção controlável.
- `KnightSpec` define duas asas principais e quatro penas WedgePart; `KnightAnim` articula as seis partes no flap.
- `CombatFx.flap` cria partículas, halo de expansão e luz. Isso é VFX procedural; não depende de assets de terceiros.

## Regras de contato do Wall Jump — 2026-11-02

- Movement mantém um latch wallJumpArmed; disparar salto desarma até o raycast observar ausência de parede por WallJumpRegrabCooldown, seguido de novo contato. A contagem da separação também roda durante dash.
- Durante WallJumpLock, a velocidade e Humanoid:Move() bloqueiam simultaneamente a entrada contra a parede; direção para longe continua disponível. Assim o personagem deve separar-se fisicamente antes de retornar.
- Com Ability_claw, contato no ar aplica slide limitado a 9 studs/s e a pose wallSide usa uma animação de repouso sutil. Sem a habilidade, wallSide é zero, input contra a parede é neutralizado e a queda é acelerada.
- A revisão consultou [uma recriação comunitária de movimento HK em Godot](https://github.com/tbh272/HollowKnightGodot), cuja descrição separa wall slide/jump e usa impulso direcional, e a página de código de um mod para Silksong; não foi localizada ali a implementação original do controlador do jogador. Nenhum código decompilado foi incorporado.
