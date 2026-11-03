# Plano de desenvolvimento

## Feito nesta sessão (em andamento até validação completa)

1. Inspeção estática do lugar e criação da documentação inicial.
2. Adição de double jump com impulso e janela leve, asas animadas/VFX/SFX existente.
3. Adição de wall jump lateral, slide e recarga ao encostar em parede oposta/aterrar.
4. Bloqueio tokenizado para cutscene, com chamada de reativação ignorada enquanto o lock está ativo e liberação idempotente.
5. Salvamento de checkpoint ao usar banco.
6. Framework de diálogo e dois NPCs regionais com recompensa de habilidade.
7. Exportação de todo o código Luau observado para GitHub.

## Continuação na ordem da missão

1. Confirmar save do place no Studio e garantir que o projeto abre com as alterações.
2. Testar salto normal, Double Jump, limite de um flap por salto e Wall Jump em paredes reais; validar câmera/animação/FX e cooldown no servidor.
3. Auditar grafo de plataformas com alcance e colisores; reproduzir o local indicado pelo usuário e então fazer a menor correção física justificada.
4. Revalidar localização, prompt e segurança dos seis bancos, além de respawn/checkpoint/DataStore em ambiente com APIs habilitadas.
5. Testar controles da cutscene, incluindo ativação concorrente, skip, personagem destruído e saída normal.
6. Expandir diálogo com condições e variações por progresso, e validar nome/fades em dispositivos.
7. Associar habilidades a portas/rotas físicas sem bloquear progressão indevidamente.
8. Completar fases 5 e 6 com áudio autoral, narrativa regional e testes reais.
9. Revisar as demais fases, monetização, performance e release.

Não mover bancos ou plataformas sem conectar a mudança aos spawns, portas, habilidades e geometria física.

## Correções em 2026-11-02

1. Reforçar lock de controles e failsafe da cutscene — implementados; lock isolado passou, caminho completo ainda pendente.
2. Corrigir hierarquia visual e posição do diálogo — implementado; verificar em tela em Play.
3. Melhorar Double Jump e permitir repetição de Wall Jump na mesma parede — configurado/implementado; confirmar física manualmente.
4. Tornar o banco j2 seguro contra dano central e afastar Orvalho — implementado; teste de dano no assento passou.
5. Criar visuais originais procedurais; solicitar modelo 3D ForgeGUI quando recurso estiver liberado.

Priorizar validação manual e persistência do place antes de avançar conteúdo adicional.
