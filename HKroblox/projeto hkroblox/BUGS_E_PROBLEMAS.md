# Bugs e problemas

## Corrigidos nesta sessão (pendente validação ampliada)

1. **Cutscene reativava controles:** adicionado lock exclusivo e idempotente em Movement; passo de controle trava velocidade durante lock. Teste direto de 0,35 s passou. Jogabilidade completa dentro da cena ainda pendente.
2. **Asas ausentes no rig:** KnightSpec agora contém duas WedgeParts e grupos de animação. O servidor já aceitava Flap, mas agora o Movement também solicita e aplica impulso. VFX usa partículas procedurais; som reutiliza templates existentes.
3. **Wall jump sem movimento:** acrescentados raycasts, impulso, slide e limite de reuso no mesmo lado. Não validado em paredes físicas.
4. **Diálogo ausente:** novo UI e dois NPCs/progressões. Conversa de Lumeira validada em Play; Orvalho e dispositivo móvel pendentes.
5. **Checkpoint dependia do autosave:** adicionada chamada saveNow no banco. DataStore Studio indisponível, portanto falha live não foi reproduzida.

## Ainda abertos

- **Plataformas que prendem/rotas impossíveis:** sem telemetria de ponto exato e sem reprodução confiável do local; não reposicionadas. A geometria é física em Workspace e não tem gerador ativo encontrado.
- **Distribuição de bancos:** posições não alteradas; auditoria estática manteve os seis bancos por estarem em salas de região e aparentemente seguras. Validar a segurança jogando todas as rotas.
- **Double Jump e Wall Jump:** código implementado, porém velocidade física e sincronização ainda precisam playtest de usuário/dispositivo confiável.
- **Save de descanso/respawn:** saveNow codificado, mas APIs do DataStore foram negadas pelo Studio; testar em ambiente com acesso e verificar reaparecimento.
- **Diálogos por progresso:** atualmente cada NPC tem fala inicial e repetida; não há ainda condições narrativas amplas por eventos de chefe/região.

## Risco/limite

O assistente só confirma salvamento em GitHub. A janela do Roblox Studio expirou durante captura, então o place pode manter alterações não salvas; abrir o place e salvar antes de publicar ou encerrar o trabalho de edição.