# Pendências para o próximo agente

## Estado de entrega

O código que foi analisado reside no place Roblox Studio **Rollow Knife (WIP)**, place ID `114682255992027`. O GitHub `FireGodis/LogsClaude` ainda contém somente o marcador `HKroblox/.gitkeep` fora desta documentação. Não assuma que editar o place atual atualiza os arquivos do repositório.

## Próxima sequência

1. Auditar e corrigir bloqueio de controles em Menu/Cutscene; testar pulo, dash, ataque, foco e câmera antes/durante/depois.
2. Mapear superfícies jogáveis e reachability com as velocidades/configurações atuais; investigar colisores e trechos citados pelo usuário antes de mover peças.
3. Conferir posição dos bancos, prompts, SpawnLocation, checkpoint salvo, restauração de máscaras/alma, respawn e DataStore.
4. Implementar Double Jump e Wall Jump com progressão segura e limites por salto/parede; integrar ao servidor e animação.
5. Adicionar animação de asas ao KnightSpec/KnightAnim ou estratégia compatível com rig atual; criar VFX/SFX autorais e validar desempenho.
6. Criar camada de diálogo para NPCs com nome, fades e condições narrativas sem duplicar HUD.
7. Adicionar habilidades regionais somente depois de combinar cada uma com uma porta ou rota.
8. Construir diálogos originais e progressivos para regiões existentes.
9. Exportar scripts e dados do place para arquivos versionados no diretório `HKroblox/`; documentar ferramenta e mapeamento.
10. Executar Playtest e inspeção de Output; atualizar todos os documentos e logs de fases.

## Riscos técnicos

- Alterar `WorldMap` sem sincronizar `Workspace.Mundo` pode deixar dados e geometria divergentes.
- O código de input usa `UserInputService` em mais de um ponto; mudanças devem respeitar os callbacks e botão de pular cutscene.
- `PlayerData` trata falha de DataStore em Studio como perfil temporário não salvo; testes em Studio não comprovam persistência live.
- `Ability` é validado no servidor pelo estado do perfil, mas movimento precisa de validação equivalente para impedir cliente fora da progressão.
- Nenhuma dublagem foi encontrada; reprodução sonora e licenciamento dos assets existentes precisam ser verificados.
