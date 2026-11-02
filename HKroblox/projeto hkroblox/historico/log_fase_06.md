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