# Testes e validações

## 2026-11-02 — implementação desta sessão

### Verificações executadas

- **Place/escopo:** confirmado no Studio como `Rollow Knife (WIP)`, place ID `114682255992027`.
- **Play e carregamento:** jogo iniciado. Os módulos Client Dialogue, Movement, Input, CombatFx, Cutscene e dependências foram exigidos pelo runtime sem erro de carregamento. Servidor criou dois modelos NPC e remote Story.
- **Bloqueio de controles:** teste direto no Client adquiriu lock, chamou `Movement.setEnabled(true)` durante o lock e aguardou 0,35 s. Posição retornada antes/depois: delta `0, 0, aproximadamente 0`. Resultado: **passou para a API/estacionar o movimento**.
- **Diálogo:** ProximityPrompt de Lumeira iniciou o painel; texto progressivo foi visto em tela; o servidor atribuiu `Ability_wings=true` após concluir as três falas. Resultado: **passou em sessão temporária**.
- **Atributos de progressão:** server reportou wings true e claw false antes da conclusão; depois wings true. Resultado: **passou para recompensa de Lumeira**.
- **Fonte:** 33 scripts foram extraídos via ScriptEditorService em Edit mode e incluídos em `src/`.

### Limitações e resultados negativos

- **Double Jump/Wall Jump:** tentativa por automação de teclado não foi confiável para aferir movimento. Não marcar como validado.
- **Cutscene completa:** o lock API passou, mas tentativa de apertar movimento ocorreu perto do término; não usar essa tentativa como prova do fluxo visual inteiro. Câmera/HUD apareceram no gameplay.
- **DataStore:** Studio reportou `StudioAccessToApisNotAllowed` para GetAsync/UpdateAsync em `MareProgress_v1` e `RollowKnifeProfiles_v1`; perfil ficou temporário e não será salvo. Persistência não testada.
- **Console:** houve avisos internos de CorePackages/telemetria em uma execução e uma mensagem de erro por ferramenta de QA chamando método inexistente `TextButton:Activate`. Foi tentativa externa de controlar menu, não código do projeto; a interface de diálogo e scripts do projeto não produziram exceção observada.
- **Plataformas, bancos, combate, chefes, respawn e câmera em falha/interrupção:** não testados ponta a ponta.
- **Salvamento do place:** não confirmado. Duas chamadas de captura da janela do Studio expiraram; arquivos fonte foram exportados para GitHub como recuperação/versionamento.

### Conclusão

Módulos carregam e o diálogo/recompensa do NPC inicial foi exercitado. O lock lógico foi isoladamente verificado. Habilidades no movimento, save persistente, Wall Jump e correções de layout permanecem **não validados**. Nenhuma fase foi declarada concluída.

## Reteste de correções — 2026-11-02

- Play iniciou após todas as alterações; não houve erro de sintaxe/carregamento dos módulos modificados no console. Os únicos erros observados foram recusas de DataStore do Studio (`StudioAccessToApisNotAllowed`).
- Lock, com Humanoid explicitamente vinculado no contexto de teste: durante lock `WalkSpeed=0`, `JumpPower=0`, Jumping desativado, `AssemblyLinearVelocity=(0,0)`; após unlock, `WalkSpeed=21`, `JumpPower=60`, Jumping habilitado. **Passou para a API do lock, sem provar fluxo completo da cutscene/conversa.**
- Dano de teste no banco j2: `Masks` permaneceu 5. **Passou para proteção central por tag Bench.**
- NPCs em runtime foram recriados com `VisualRevision=2`, Orvalho X=556, Lumeira X=66; ambos reportaram 16 descendentes. **Passou para montagem das instâncias; inspeção estética requer viewport.**
- Teste de evento de conversa não abriu `RK_Dialogue` enquanto o painel de Controles do menu permaneceu ativo; **inconclusivo**, não declarar UI ou lock conversacional como E2E validado.
- Double Jump, asas animadas, Wall Jump repetido, camera cutscene sob input e save/reload do DataStore **não testados ponta a ponta**.
- O salvamento do place não foi confirmado: chamadas de captura da janela nativa expiraram duas vezes e `SavePlaceAsync` não existe no DataModel fornecido ao executor. Código/documentação em GitHub é cópia de recuperação, não substitui salvar o place no Studio.
