# Estado das fases

Estados oficiais: **Concluída**, **Em andamento**, **Pendente** e **Bloqueada**. Nenhuma fase foi concluída nesta sessão; validação incompleta permanece explicitamente anotada.

| Fase | Escopo oficial | Estado | Evidência atual |
|---|---|---|---|
| 1 | Reestruturar o código e corrigir o save | Em andamento | PlayerData ganhou API de salvamento imediato e o banco a chama. Persistência real não pôde ser testada porque APIs de DataStore estão desabilitadas em Studio. |
| 2 | Cavaleiro com animação, corrida, salto, dash, ataques nas quatro direções e dano em máscaras | Em andamento | Movimento agora contém caminhos de double jump/wall jump e o rig ganha asas; o teclado automatizado não produziu uma validação confiável do impulso. Ataques existentes permanecem frente/cima/baixo. |
| 3 | Inimigos variados e chefes | Em andamento | Inimigos e chefe existentes não foram revalidados nesta sessão. |
| 4 | Mapa conectado, biomas, bancos e portões travados por habilidades | Em andamento | Auditoria estática dos seis bancos; nenhum reposicionamento das plataformas ou bancos sem reprodução confiável. Compatibilidade do mapa continua pendente. |
| 5 | Habilidades ligadas às regiões | Em andamento | Lumeira concede `wings` e Orvalho concede `claw`; mecânicas, efeitos e movimento foram implementados, mas o comportamento físico em Play não foi validado ponta a ponta. |
| 6 | História, NPCs e diálogos | Em andamento | Dois NPCs autorais, falas próprias e caixa de diálogo com nome/fade/typewriter foram exercitados; ramificação avançada e conteúdo por progressão ainda podem crescer. |
| 7 | Menu, HUD, mapa e inventário | Em andamento | Menu/HUD pré-existentes; diálogo runtime foi acrescentado. Mapa e inventário completos não foram encontrados. |
| 8 | Áudio e dublagem | Em andamento | Cues existentes foram reaproveitados para asas, parede e blips. Som único de habilidade e dublagem não foram produzidos. |
| 9 | Monetização, testes e revisão final | Pendente | Monetização e revisão final não implementadas. |

Atualize estados somente junto com evidência no arquivo de validação.