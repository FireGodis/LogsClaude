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

## Atualização — 2026-11-02

- **Movimento durante diálogos/cutscene:** implementação endurecida; lock põe propriedades do Humanoid em zero, cancela velocidade antes do hit-stop e restaura snapshot no último unlock. Lock API passou isoladamente; conversa/cutscene completas ainda sem validação final.
- **Texto “Label” e layout:** texto inicia vazio; painel foi para o alto à direita; nome grande (34 px) fadeia no canto inferior esquerdo. A tela final ainda requer inspeção manual.
- **Double Jump:** impulso configurado em 68 (era 44), janela inicial protegida contra jump-cut e asas mais largas. Físico e leitura visual ainda não foram medidos no jogo.
- **Wall Jump:** antiga trava por lado removida; novo cooldown de 0,22 s permite nova ação depois de recontato. Sequência de escalada em parede física pendente.
- **Banco j2 inseguro e Orvalho adjacente:** área segura no servidor (raio 15, tolerância vertical 8), teste de dano não reduziu máscaras; Orvalho deslocado 46 studs. Validar outras fontes de dano e os outros bancos.
- **Visual ForgeGUI:** modelo 3D foi solicitado, mas o ForgeGUI respondeu que geração exige upgrade; modelos procedurais originais substituem provisoriamente os blocos simples.
