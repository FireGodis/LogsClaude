# Registro detalhado — correções de movimento, diálogo, NPC e banco (2026-11-02)

## Alvo e escopo
Place Roblox Studio **Rollow Knife (WIP)**, place ID `114682255992027`, confirmado pelo usuário como HKROBLOX. Fonte versionada no repositório `FireGodis/LogsClaude`, sob `HKroblox/`.

## Sistemas e arquivos Luau alterados
- `ReplicatedStorage.Shared.Config`: impulso de Double Jump elevado de 44 para 68; Wall Jump Lock ajustado para 0,18 s; raio horizontal de segurança do banco (15 studs) e tolerância vertical (8 studs).
- `StarterPlayer.StarterPlayerScripts.Client.Controllers.Movement`: lock agora desativa WalkSpeed, JumpPower, JumpHeight, auto-jump e estado Jumping, anula velocidade e tem prioridade sobre hit-stop; snapshot restaura as propriedades após o último token de lock. Wall jump rearmado por cooldown de 0,22 s após o impulso, removendo a trava que permitia só um salto no mesmo lado. Double Jump conserva o impulso por 0,14 s antes de aceitar corte pela soltura do botão.
- `StarterPlayer.StarterPlayerScripts.Client.Controllers.KnightAnim` e `ReplicatedStorage.Shared.KnightSpec`: asas aumentadas e separadas em X para formar silhueta visível na câmera lateral; flap segue animado durante 0,42 s.
- `StarterPlayer.StarterPlayerScripts.Client.Controllers.Dialogue`: `Line.Text` começa vazio; painel no canto superior direito; nome em fonte 34, no canto inferior esquerdo, com fade-in de 0,7 s, permanência de 2,8 s e fade-out de 0,75 s.
- `StarterPlayer.StarterPlayerScripts.Client.Controllers.Cutscene`: failsafe de 12 s chama a rotina idempotente de término, que libera lock, câmera e pose se o roteiro for interrompido.
- `ServerScriptService.Server.Systems.Combat`: dano bloqueado no raio seguro de bancos marcados `Bench`; cooldown de efeitos de Wall Jump reduzido para 0,18 s.
- `ServerScriptService.Server.Systems.WorldSystem`: Orvalho movido de X=504 para X=556 (46 studs do banco j2 em X=510); NPCs de revisão visual antiga são substituídos por modelos procedurais originais em camadas, com máscara, olhos, antenas, manto, ornamentos regionais e semente luminosa. Prompt afastado 44 px e alcance reduzido a 8 studs.

## Diagnóstico, causa e comportamento
- O fluxo de lock já limpava a entrada própria, mas o bloqueio podia ser preterido por hit-stop e não neutralizava diretamente o Humanoid padrão; por isso outras fontes de movimento ainda podiam atuar. O lock agora se aplica antes do hit-stop e mantém propriedades críticas zeradas durante a trava.
- O diálogo criava um TextLabel com valor padrão `Label`, que ficava visível durante a espera inicial. O texto agora é inicializado como string vazia antes da animação.
- O segundo impulso era baixo (44), podia ser encurtado pela lógica de pulo variável e as WedgeParts tinham espessura visual lateral reduzida. O impulso foi elevado a 68, ganhou uma janela curta de preservação e as asas foram ampliadas na dimensão projetada.
- O wall jump usava `wallJumpUsed` e só rearmava ao tocar outro lado/chão. Isso impedia subir repetindo saltos na mesma face. A nova regra permite novo salto após recontato e cooldown curto, ainda exigindo novo pressionamento de pulo.
- O banco j2 não anulava dano de contato; o fluxo central de dano não tinha noção de área segura. Agora o servidor verifica o raio do banco antes de aplicar dano.

## Antes, esperado e após
- **Antes:** controles de personagem podiam persistir durante interação/cena; texto padrão aparecia; nome pequeno e central; flap pouco perceptível; um único salto na mesma parede; Orvalho quase sobre o banco e mosca podia ferir o jogador em cima dele.
- **Esperado:** bloqueio que sobreviva a scripts padrão e interrupção; layout conforme pedido; dupla impulsão legível; wall hops repetíveis por input; personagem regional reconhecível e banco seguro.
- **Após:** lógica de lock, layout, rearmamento de parede, força/config de flap, segurança e geração procedural foram atualizados. O NPC recriado em Play reportou revisão 2 e 16 descendentes. O lock e a zona segura passaram nos testes isolados abaixo. A conversa visual completa, a animação/impulso durante jogo real e a subida repetida em parede física ainda não foram validados ponta a ponta.

## Testes realizados e resultado
- Jogo iniciou duas vezes em Play depois das alterações; console não mostrou erro de sintaxe/carregamento dos módulos alterados. DataStore em Studio emitiu `StudioAccessToApisNotAllowed` para GetAsync/UpdateAsync; persistência não foi testada.
- **Lock direto no Client, com bind explícito do Humanoid:** durante a trava observados WalkSpeed=0, JumpPower=0, Jumping desativado, velocidade X/Y=0; após liberar: WalkSpeed=21, JumpPower=60 e Jumping habilitado. Passou para a API do lock. A automação carregou uma cópia isolada do módulo, então isso não prova o fluxo inteiro do menu/cutscene.
- **Segurança do banco j2:** dano de teste via `Combat.damagePlayer` no ponto do assento manteve `Masks=5`. Passou para a verificação central do servidor.
- **NPCs:** no servidor, Lumeira (X=66) e Orvalho (X=556) foram criados com `VisualRevision=2`; os dois modelos tinham 16 descendentes. Passou para geração/reconstrução das instâncias; qualidade estética exige inspeção de tela.
- **Diálogo/cutscene:** tentativa de automação não saiu do painel de controles do menu; `RK_Dialogue` não foi encontrado nessa tentativa. Resultado inconclusivo, layout e fluxo inteiro requerem playtest manual.
- **Double Jump/Wall Jump:** não foi possível medir salto nem sequência física em parede em Play. Não marcado como validado.
- **Salvar place:** `game:SavePlaceAsync()` não existe nesta sessão e duas capturas da janela Studio expiraram. O place pode continuar com alterações em memória sem persistência confirmada; fontes e documentos foram sincronizados para GitHub.

## ForgeGUI e referências de movimento
- A chamada de geração de modelo 3D pelo ForgeGUI retornou `paid_generation_required / Generation locked` e link de upgrade. Nenhum modelo foi gerado ou publicado; chamadas pagas foram interrompidas. A conexão Roblox disponível também não lista escopo `publication:write`.
- Para deixar uma melhoria implementada no jogo, os NPCs foram aprimorados com composição procedural original no WorldSystem. Isso não substitui um asset 3D orgânico produzido pelo ForgeGUI; a execução da geração depende de habilitação do plano e publicação continua pendente.
- A referência pública consultada descreve repetir o salto enquanto se mantém direção contra a parede para ganhar altura, que orientou o requisito de recontato e saltos sucessivos. O código do jogo foi escrito originalmente para HKROBLOX; nenhum código descompilado ou asset dos jogos referenciados foi reutilizado. Referência: [Mantis Claw — Hollow Knight Wiki](https://hollowknight.wiki/w/Mantis_Claw).

## Problemas encontrados, dependências e pendências
- O Studio impede salvamento por API pública acessível ao executor e a captura de tela da janela nativa expirou duas vezes. Confirmar Ctrl+S manualmente antes de publicar o place.
- Ativar DataStore APIs em ambiente de teste e validar descanso, persistência e reaparecimento.
- Fazer playtest manual em teclado/controle: conversar, apertar WASD/Espaço durante diálogo/cutscene, verificar que câmera/pose continuam normais e que movimento volta ao fim.
- Medir altura do Double Jump; confirmar uso único por ciclo aéreo, asas e som; escalar uma parede com três ou mais recontatos; confirmar cooldown sem ativações involuntárias.
- Revisar visual procedural dos NPCs em viewport e substituir/expandir pelo asset 3D ForgeGUI quando geração/publicação estiver habilitada.
- Segurança usa `Combat.damagePlayer` central e tags `Bench`; validar se todos os marcadores relevantes de banco estão marcados e se a altura de 8 studs não protege trechos verticais indevidos.
- Relacionamento: Movement depende de Config/Input/Net/CombatFx/Audio e alimenta KnightAnim; Cutscene e Dialogue adquirem token do Movement; Combat resolve dano de Enemies e respeita tags Bench; WorldSystem cria NPCs e concede habilidades por progresso.

## Próximo agente
1. Abrir o place confirmado e salvar; fonte Luau no GitHub está espelhada sob `HKroblox/src/`.
2. Fazer playtest da conversa com movimento pressionado e da cutscene até skip/término.
3. Validar parede, segundo salto, asas/VFX/som, NPCs, safe zone e respawn.
4. Resolver ForgeGUI plano/publicação, importar modelo original se disponível.
5. Atualizar evidências e só então rever estados das fases.
