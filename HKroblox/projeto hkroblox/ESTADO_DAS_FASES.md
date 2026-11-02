# Estado das fases

Estados oficiais usados: **Concluída**, **Em andamento**, **Pendente** e **Bloqueada**. Uma fase só passa a concluída após validação registrada em `TESTES_E_VALIDACOES.md`.

| Fase | Escopo oficial | Estado | Evidência atual |
|---|---|---|---|
| 1 | Reestruturar o código e corrigir o save | Em andamento | Módulos separados e PlayerData com migração v1, sanitização, trava e autosave existem; falta validar DataStore/saída e registrar correções. |
| 2 | Cavaleiro com animação, corrida, salto, dash, ataques nas quatro direções e dano em máscaras | Em andamento | Corrida, pulo variável, dash, combate para frente/cima/baixo e máscaras existem. Ataque lateral não foi identificado; pulo duplo e wall jump são incompletos. |
| 3 | Inimigos variados e chefes | Em andamento | Tipos Crawler, Shield e Flier; BossAI e chefe Vigia estão presentes. Falta playtest e validação de reinício/combate. |
| 4 | Mapa conectado, biomas, bancos e portões por habilidade | Em andamento | WorldMap define 14 salas e biomas, bancos, portas e uma barreira; fluxo físico e compatibilidade de saltos ainda não foram comprovados. |
| 5 | Habilidades ligadas às regiões | Em andamento | `dash` e `pulse` são padrão. `wings` e `claw` aparecem no save e no handler de Ability, mas não há movimento correspondente completo confirmado. |
| 6 | História, NPCs e diálogos | Pendente | Há narração curta na cutscene e avisos do mundo; NPCs, conversas progressivas e interface de diálogo não foram encontrados. |
| 7 | Menu, HUD, mapa e inventário | Em andamento | Menu e HUD gerados por código estão presentes. Mapa e inventário funcionais não foram encontrados na análise inicial. |
| 8 | Áudio e dublagem | Em andamento | Sound objects e chamadas de Audio existem; dublagem não foi identificada e reprodução não foi testada. |
| 9 | Monetização, testes e revisão final | Pendente | Nenhuma implementação ou validação de monetização/revisão final observada. |

Não alterar os estados sem registrar evidência nova. Status é do place observado, não do espelho GitHub.
