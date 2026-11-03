# Histórico — Fase 6: História, NPCs e diálogos

## 2026-11-02 — início do framework e dois encontros

- **Lumeira, Guardiã do Pavio — Vila das Lanternas:** guarda uma chama e ensina a Asa de Bruma (`wings`). Fala em frases breves, cuidadosas e contemplativas; após desbloqueio, retorna uma fala alternativa.
- **Orvalho, Tecelão de Raízes — Alameda de Musgo:** observa como as raízes encontram apoio na pedra e oferece Garra de Raiz (`claw`). Voz paciente e tátil; diálogo alternativo após desbloqueio.
- **Interface:** caixa escura com ornamento original, fonte Garamond, fade de nome antes da fala, typewriter, blips discretos e avanço por espaço/enter/E/controle. Input normal é mantido bloqueado durante conversa.
- **Estrutura expansível atual:** lista `STORY_NPCS` no WorldSystem contém id, nome, região, posição, habilidade, linhas iniciais e repetidas. Conclusão tem validação de pendência/distância no servidor.
- **Progresso do mundo:** perfil recebe habilidade e flag; PlayerData publica atributo e chama saveNow.
- **Teste observado:** conversa e recompensa wings funcionaram em Play de Studio. Orvalho/claw e save persistente ainda não testados.
- **Pendências:** ampliar variações narrativas por chefe, região e eventos; extrair dados para módulo se a lista crescer; acrescentar outros NPCs e testar acessibilidade/touch.
- **Estado:** **Em andamento**; há base funcional, não uma narrativa completa.

## 2026-11-02 — legibilidade e elenco

O diálogo agora esvazia a linha antes do typewriter, posiciona o painel no topo direito e exibe o nome em fonte 34 no canto inferior esquerdo (fade 0,7 s, hold 2,8 s, fade 0,75 s). Orvalho foi afastado do banco j2, e ambos os NPCs são montados em revisão visual procedural 2 com máscara, manto, antenas e brilho regional. O caminho visual após esta alteração não passou em teste Play final; geração de personagem 3D no ForgeGUI foi bloqueada pelo plano. Consulte o [registro detalhado](log_correcao_movimento_dialogo_npc_2026-11-02.md).
