# Contexto do projeto

## Identificação

- Nome exibido no projeto aberto: **Rollow Knife (WIP)**.
- Place ID visível na conexão do Roblox Studio: `114682255992027`.
- Repositório principal fornecido: [FireGodis/LogsClaude](https://github.com/FireGodis/LogsClaude).
- Diretório de jogo solicitado: `HKroblox/`.
- Engine e linguagem: Roblox Studio e Luau; scripts usam `--!strict`.
- Identidade: metroidvania 2.5D com cenário em profundidade fixa, personagem montado por peças e mundo original em português.

## Limite entre place e repositório

Na análise inicial, o repositório tinha somente o arquivo vazio `HKroblox/.gitkeep`. O place aberto contém os scripts e modelos observados abaixo. A documentação é gravada em `HKroblox/projeto hkroblox/`; alterações nos scripts do place precisam ser exportadas para o repositório para manter cópia reproduzível do código.

O usuário confirmou que o place **Rollow Knife (WIP)** é o projeto HKROBLOX pretendido. Essa confirmação autoriza tratar esse place como alvo da implementação desta sessão.

## Evidência inicial

- `ReplicatedStorage.Shared.WorldMap` define 14 salas em seis biomas, 13 aberturas, seis bancos, spawns e itens.
- `Workspace.Mundo` possui pastas de geometria, plataformas, spawns, bancos, colecionáveis, barreiras, inimigos e cenário.
- `Workspace.Mundo.Plataformas` contém 204 peças: 102 plataformas sólidas e 102 detalhes de brilho.
- `StarterPlayer.StarterPlayerScripts.Client.Controllers` contém Input, Movement, KnightAnim, HUD, Menu, Cutscene, Zone, Audio, CameraRig, CombatFx e animação de inimigos.
- `ServerScriptService.Server.Systems` contém PlayerData, KnightRig, Enemies, WorldSystem, Combat, BossAI e auxiliares de rede.
- `StarterGui` estava vazio no modo Edit; várias interfaces são criadas por código.
- A lista de scripts não revelou controlador de diálogos/NPCs. O texto narrativo existente está na cutscene e em notificações.
- O mapa físico atual existe no Workspace, mas não foi encontrado um construtor ativo de mapa entre os scripts do place.

## Preservação e estilo

Manter os módulos existentes, seus nomes em português e inglês já adotados, a validação de combate no servidor e a animação interpolada em `KnightAnim`. As imagens anexadas orientam clima, silhueta e legibilidade; não são autorização para copiar personagens, textos, mapas ou assets de Hollow Knight/Silksong.
