# Estado das fases

Estados oficiais: **Concluída**, **Em andamento**, **Pendente** e **Bloqueada**. Nenhuma fase foi concluída nesta sessão; validação incompleta permanece explicitamente anotada.

| Fase | Escopo oficial | Estado | Evidência atual |
|---|---|---|---|
| 1 | Reestruturar o código e corrigir o save | Em andamento | PlayerData ganhou API de salvamento imediato e o banco a chama. Persistência real não pôde ser testada porque APIs de DataStore estão desabilitadas em Studio. |
| 2 | Cavaleiro com animação, corrida, salto, dash, ataques nas quatro direções e dano em máscaras | Em andamento | Wall jump agora exige afastamento medido e novo contato; impulso de saída protegido por 0,18 s. Queda sem claw foi observada em teste local; parede com habilidade ainda requer cadeia manual. |
| 3 | Inimigos variados e chefes | Em andamento | Inimigos e chefe existentes não foram revalidados nesta sessão. |
| 4 | Mapa conectado, biomas, bancos e portões travados por habilidades | Em andamento | Auditoria estática dos seis bancos; nenhum reposicionamento das plataformas ou bancos sem reprodução confiável. Compatibilidade do mapa continua pendente. |
| 5 | Habilidades ligadas às regiões | Em andamento | claw usa wall slide lento e wall hop rearmado só após separação e retorno. Playtest de repetição e encadeamento ainda pendente. |
| 6 | História, NPCs e diálogos | Em andamento | NPCs procedurais revisão 2, Orvalho afastado do banco j2; nome agora fica maior no canto inferior esquerdo e painel no canto superior direito. Fluxo visual após essa revisão não foi validado em Play. |
| 7 | Menu, HUD, mapa e inventário | Em andamento | Interface de diálogo atualizada em runtime; teste com o menu do Studio permaneceu no painel Controles, sem validar a tela final. Mapa e inventário completos não foram encontrados. |
| 8 | Áudio e dublagem | Em andamento | Cues existentes foram reaproveitados para asas, parede e blips. Som único de habilidade e dublagem não foram produzidos. |
| 9 | Monetização, testes e revisão final | Pendente | Monetização e revisão final não implementadas. |

Atualize estados somente junto com evidência no arquivo de validação.