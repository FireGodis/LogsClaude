# Plano de desenvolvimento

A sequência mantém a ordem solicitada. Cada item precisa de evidência e registro antes de ser marcado como feito.

1. Analisar o place, localizar logs anteriores e preservar alterações pré-existentes.
2. Manter esta documentação inicial atualizada.
3. Auditar grafo de plataformas, medidas de salto, colisores, pontos de transição e retorno antes de reposicionar geometria.
4. Auditar segurança, respawns e pontos de interseção dos seis bancos antes de mudar posição.
5. Integrar pulo duplo com animação de asas, efeito e som original; limitar uso por ciclo aéreo e habilidade desbloqueada.
6. Integrar wall jump com raycasts laterais, direção, cooldown/reativação após se afastar e sincronização visual.
7. Corrigir sistema de diálogo depois de localizar os assets e fluxo de NPC; criar arquitetura expansível.
8. Tornar bloqueio de controles durante cutscene exclusivo e garantido mesmo diante de chamadas concorrentes; liberar em caminho de erro.
9. Avançar Fase 5 apenas com habilidades que mudem a navegação e tenham região/portão compatível.
10. Avançar Fase 6 com NPCs originais, condições de progresso e conteúdo versionável.
11. Rodar verificações de sintaxe, dependências e playtest disponível.
12. Atualizar status, log e handoff.

Decisões de movimentação e alcance devem ser confrontadas com `Config.Move`, dimensões do personagem e geometria real. Não reduzir dificuldade por ajustes amplos; corrigir conexões impossíveis ou colisões que retêm o personagem.
