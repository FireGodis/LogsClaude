# Bugs e problemas

## Confirmados por inspeção estática

1. **Cutscene pode não bloquear todos os controles.** `Movement.start` desativa os controles padrão em uma tarefa assíncrona; o menu/cutscene pode começar antes da desativação terminar. `Cutscene` apenas observa tecla/toque para pular e não adquire um bloqueio exclusivo de controles.
2. **Habilidades parciais.** O servidor aceita `Flap`/`WallJump` somente se `wings`/`claw` estiverem desbloqueadas e replica timestamps; o movimento local não mostrou execução dessas habilidades. `KnightAnim` prepara tratamento de `flapP`, mas `KnightSpec.Groups` não inclui `wingA`/`wingB` e a lista de peças não contém asas.
3. **Diálogo ausente.** Não foi localizado sistema de NPC/conversa. Notificações curtas e legendas não suportam diálogo progressivo.
4. **Mapa físico sem fonte localizada.** `WorldMap` declara layout lógico, mas os scripts ativos listados não incluem o construtor que criou as 204 peças de plataformas e 30 partes de geometria.

## Ainda precisam de reprodução

- Plataformas que prendem o personagem e conexões impossíveis entre trechos.
- Segurança e alcance de cada banco/checkpoint.
- Persistência de descanso, salvamento, morte e reaparecimento.
- Interrupção/erro da cutscene e câmera/pose após a liberação de controles.

## Não presumir causa sem reproduzir

A existência de muitos segmentos e oscilação de alturas não prova por si só que um salto é impossível. O alcance depende da gravidade, velocidade, paredes, colisores e habilidade liberada. Verificar a geometria e jogar o trecho antes de alterar posições.
