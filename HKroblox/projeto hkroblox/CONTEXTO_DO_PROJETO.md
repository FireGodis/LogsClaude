# Contexto do projeto

## Identificação

- Projeto confirmado pelo usuário: place Roblox Studio **Rollow Knife (WIP)**, place ID `114682255992027`.
- Repositório: [FireGodis/LogsClaude](https://github.com/FireGodis/LogsClaude), diretório `HKroblox/`.
- Engine e linguagem: Roblox Studio e Luau; scripts usam `--!strict`.
- Gênero/arquitetura: metroidvania 2.5D; personagem articulado por Motor6D; mapa físico em Workspace.
- As imagens fornecidas servem como referência de atmosfera e legibilidade. Nenhum personagem, texto, mapa ou asset protegido foi copiado.

## Estado do repositório

O GitHub inicialmente tinha somente `HKroblox/.gitkeep`. Nesta sessão, os 33 scripts encontrados em ReplicatedStorage, ServerScriptService e StarterPlayer foram exportados para `HKroblox/src/`, preservando o caminho do DataModel sob diretórios. Isso permite revisar e continuar o código fora do Studio, mas não reproduz o place físico.

As alterações foram feitas no editor de scripts do Studio. A captura da janela do Studio falhou duas vezes, então não foi possível confirmar o atalho de salvar do place; o espelho GitHub registra as fontes observadas depois das alterações.

## Evidência de arquitetura

- `ReplicatedStorage.Shared.WorldMap`: 14 salas em seis biomas, portas, seis bancos, spawns, itens, barreira e limites.
- `Workspace.Mundo`: geometria e plataformas materializadas; a tabela WorldMap não é uma fonte comprovada de construção das partes.
- Cliente: `StarterPlayer.StarterPlayerScripts.Client` e controladores em `Controllers`.
- Servidor: `ServerScriptService.Server` e módulos em `Systems`.
- `StarterGui` estava vazio em Edit; Menu, HUD e cenas criam suas próprias interfaces.
- A busca inicial não encontrou NPCs nem sistema de diálogo. Esta sessão passou a criar NPCs de história pelo WorldSystem em tempo de execução.

## Estilo e preservação

Preservar o fluxo modular, nomes já usados, a validação do servidor e a animação interpolada. Não reconstruir os segmentos de plataforma por suposição: confirmar alcance, colisão e rota no jogo antes de mover partes.

## Atualização de continuidade — 2026-11-02

- Nesta sessão foram ajustados bloqueio rígido em diálogos/cutscene, layout de diálogo, Double Jump/Wall Jump, proteção de bancos e aparência procedural dos NPCs. Veja o novo registro em `historico/log_correcao_movimento_dialogo_npc_2026-11-02.md`.
- O teste do lock e o dano no banco j2 passaram isoladamente. Wall/Double Jump e UI final precisam de validação manual em Play.
- Geração 3D do ForgeGUI foi bloqueada pelo plano da conta. Place não pôde ser salvo nesta sessão; o espelho Luau e documentos foram atualizados no GitHub.

## Continuidade de movimento — 2026-11-02

A referência visual recebida orienta asas luminosas em leque, feitas com geometria original do rig. Wall jump agora deve ser encadeável com dash e flap; a implementação renova ambos ao saltar da parede, aumenta o impulso vertical e solta o personagem sem habilidade `claw`. Alterações e testes detalhados: `historico/log_salto_alado_walljump_fluido_2026-11-02.md`.
