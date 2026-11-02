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