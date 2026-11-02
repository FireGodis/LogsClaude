# Log de alterações

## 2026-11-02 — movimento, cutscene, descanso, narrativa e espelho fonte

### Double Jump e asas

- **Sistema/arquivos:** `Config`, `KnightSpec`, `Movement`, `CombatFx`, `Combat`, `KnightAnim` (espelho em `src/`).
- **Problema:** campos de flap/animação e handler de habilidade existiam parcialmente, mas o rig não tinha asas e Movement não executava esses movimentos.
- **Causa:** não havia peças/grupos Wing em KnightSpec nem gatilho de movimento no controlador.
- **Antes:** pulo principal, dash e placeholders/atributos Flap; sem impulso secundário integrado.
- **Solução:** parâmetros centralizados; impulso secundário único até aterrissar, disponível quando `Ability_wings`; VFX de partículas; cues de som existentes; WedgeParts de asa visíveis durante animação `flapP`; servidor limita pedido e confere perfil/ar.
- **Esperado/após:** personagem desbloqueado pode acionar um segundo impulso no ar e ver bater de asas. A habilidade foi desbloqueada na sessão de Play, mas o deslocamento físico do pulo não foi validado com teclado automatizado.
- **Relações:** PlayerData atributos, Combat remote Ability, Config, Movement, KnightSpec, KnightAnim, CombatFx, Audio.
- **Pendências:** testar em input local real; revisar dimensão/pivôs das asas; criar som original e validar asset ID se ForgeGUI publicar estiver disponível.

### Wall Jump

- **Sistema/arquivos:** `Config`, `Movement`, `Combat`, `CombatFx`, `KnightAnim` (fontes no espelho).
- **Problema:** `claw` era conhecida por save/servidor, sem movimento local funcional.
- **Solução:** raycasts horizontais laterais, slide limitado, impulso diagonal para longe da parede; uma ativação por parede até aterrissar ou tocar a face oposta; janela curta de direção; servidor confere desbloqueio, ar e proximidade de parede.
- **Esperado:** permitir escalar shafts alternando paredes, sem disparos repetidos no mesmo contato.
- **Após:** lógica implementada; não validada fisicamente no mapa real.
- **Pendências/relações:** conceder claw via NPC Orvalho e testar os shafts existentes; revisar VFX/pose remota e tolerâncias de raycast.

### Bloqueio de cutscene

- **Arquivos:** `Movement`, `Cutscene`.
- **Problema:** uma chamada `setEnabled(true)` concorrente podia religar input durante a cena; não havia limpeza de lock garantida na destruição do personagem.
- **Causa:** estado booleano único compartilhado sem tokens de exclusão.
- **Solução:** `acquireControlLock` com liberação idempotente; entrada fica inativa enquanto houver qualquer token, buffers são limpos e a velocidade é zerada. Cutscene libera no fim/destruição.
- **Antes/esperado/após:** antes, setEnabled concorrente sobrescrevia o estado. Esperado, controles e movimento bloqueados até unlock; após, teste direto manteve a posição idêntica por 0,35s apesar de setEnabled(true), e release concluiu.
- **Relações:** Movement, Input, Cutscene, CameraRig, KnightAnim e callback do menu.
- **Pendências:** testar todos os inputs por teclado/controle/toque durante a cutscene em uma sessão interativa completa.

### Bancos e salvamento

- **Arquivos:** `PlayerData`, `WorldSystem`.
- **Problema:** descanso atualizava checkpoint em memória e dependia do autosave de 60s.
- **Solução:** adicionar `PlayerData.saveNow` e chamar após definir checkpoint no prompt do banco; warn se falhar.
- **Funcionamento esperado/após:** persistir a decisão de descanso sem esperar o autosave quando o DataStore está disponível. Studio negou acesso, então não se pode declarar persistência validada.
- **Bancos:** os seis pontos existentes foram auditados estaticamente e parecem posicionados em salas de região/interseção; não foram movidos sem reproduzir risco/local perigoso.
- **Relações:** WorldMap, SpawnLocation, PlayerData, WorldSystem, Combat.restore e respawn.

### Diálogo e progressão narrativa

- **Arquivos:** novo `Dialogue`, `Client`, `Remotes`, `WorldSystem`, `PlayerData` (fontes espelhadas em `src/`).
- **Problema:** busca de código não encontrou NPCs nem sistema de conversa.
- **Solução:** UI original em Garamond com ornamento discreto, nome em fade in/out, typewriter, blips, avançar/skip de linha e lock de controles. WorldSystem cria Lumeira (Vila das Lanternas, wings) e Orvalho (Alameda de Musgo, claw), com falas próprias e alternativas após desbloqueio. Server valida fim, grava habilidade e profile flag; Story remote transporta conversa/recompensa.
- **Testes:** conversa de Lumeira abriu por prompt; falas avançaram; servidor passou `Ability_wings=true`.
- **Pendências:** testar Orvalho/claw, progressão repetida, animação/visibilidade em mobile e save real.
- **Funcionamento após:** fase narrativa tem base expansível, ainda não história completa com mudanças amplas do mundo.

### Exportação para GitHub e testes

- `HKroblox/src/` agora contém 33 scripts obtidos do editor em Edit mode; diretórios preservam os caminhos de serviços.
- Todos os documentos e histórico foram atualizados com estado e limites.
- Play no Studio iniciou scripts e exigiu os novos módulos no cliente; console não indicou erro dos módulos alterados. DataStore recusou API em Studio; avisos CorePackages e uma chamada de QA inválida não representam erro do jogo.
- **Place:** alterações editoriais estavam presentes antes de exportar. Não foi possível confirmar salvamento do place pela UI porque captura/recuperação da janela do Studio expirou; verificar/Salvar no Studio antes de publicar.

## Arquivos alterados no DataModel do Studio

- `ReplicatedStorage.Shared.Config`
- `ReplicatedStorage.Shared.KnightSpec`
- `ReplicatedStorage.Shared.Remotes`
- `StarterPlayer.StarterPlayerScripts.Client`
- `StarterPlayer.StarterPlayerScripts.Client.Controllers.Movement`
- `StarterPlayer.StarterPlayerScripts.Client.Controllers.Cutscene`
- `StarterPlayer.StarterPlayerScripts.Client.Controllers.CombatFx`
- `StarterPlayer.StarterPlayerScripts.Client.Controllers.Dialogue` (novo ModuleScript)
- `ServerScriptService.Server.Systems.Combat`
- `ServerScriptService.Server.Systems.PlayerData`
- `ServerScriptService.Server.Systems.WorldSystem`

O espelho versionado inclui os 33 LuaSourceContainers do place, não apenas os 11 scripts acima; consulte `HKroblox/src/README.md` e os caminhos sob `HKroblox/src/`. NPCs são criados em execução pela função de inicialização de WorldSystem, portanto não representam modelos salvos no DataModel de edição.