# Roblox Studio source snapshot — 2026-11-03

Origem: Roblox Studio place **[☀️UPD] Steal An God**, place ID `129275930788382`.
Este snapshot foi lido dos scripts em modo Edit depois do playtest de novembro de 2026.

## Conteúdo

Os arquivos espelham classes do DataModel e preservam nomes de instância:

- `ServerStorage/SAG_Config.lua` — configuração de economia, mundo e rival.
- `ServerScriptService/SAG_Services/PlayerDataService.lua` — perfil, moedas, ovos, Zeus, nível de base e save.
- `ServerScriptService/SAG_Services/WorldBuilder.lua` — mapa grego procedural, sete bases, caminhos, altar de upgrade e estátua placeholder.
- `ServerScriptService/SAG_Services/GameService.lua` — interação server-side, produção, save e ligação da IA.
- `ServerScriptService/SAG_Services/BotAIService.lua` — Ares, navegação por PathfindingService e progresso econômico isolado.
- `ServerScriptService/SAG_Bootstrap.server.lua` — inicialização do servidor.
- `ReplicatedStorage/SAG_Shared/UIConfig.lua` — tema compartilhado do HUD.
- `StarterPlayer/StarterPlayerScripts/SAG_HUD.client.lua` — HUD de leitura de atributos.

## Restauração

Crie cada instância no serviço/caminho indicado com sua classe correspondente (ModuleScript, Script ou LocalScript) e copie o conteúdo. O bootstrap chama `WorldBuilder.Build()`, que gera o mundo se `Workspace.SAG_GameWorld` não existir. O projeto atual não usa Rojo.

## O que este snapshot cobre

- Compra server-side de Greek Egg, hatch de Zeus, geração/coleta de Coins e upgrade de base nível 1→2.
- Rival Ares identificado como IA: compra, hatch, coleta, upgrade e estados próprios.
- Mapa grego montado com Parts e materiais Roblox; a estátua de Zeus e o rig de Ares são placeholders/procedurais.
- A baseplate e o SpawnLocation originais foram preservados.

## Limitações do backup

Este snapshot guarda código fonte, mas não é um arquivo `.rbxlx`/place completo: não contém o estado binário do Studio nem assets externos. O salvamento/exportação de uma cópia local não foi concluído. A persistência de DataStore foi mantida desligada nos playtests via modo de memória do Studio; dados online não foram validados. Nenhum script concede Robux ou implementa compras.

## Evidência de teste

Playtest no Roblox Studio: compra e hatch do jogador; renda e coleta; upgrade do jogador para nível 2; Ares percorreu o caminho, comprou ovo, chocou Zeus, acumulou/coletou moedas e chegou ao nível 2. Console de jogo mostrou somente o aviso esperado de DataStore em modo memória.
