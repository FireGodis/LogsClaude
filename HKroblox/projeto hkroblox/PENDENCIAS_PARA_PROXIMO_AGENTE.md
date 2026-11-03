# Pendências para o próximo agente

## Alvo e fonte

- Roblox Studio: **Rollow Knife (WIP)**, place ID `114682255992027`; usuário confirmou ser HKROBLOX.
- Repositório: `FireGodis/LogsClaude`; código Luau espelhado em `HKroblox/src/` e documentação em `HKroblox/projeto hkroblox/`.
- O espelho inclui 33 scripts e não contém mapa, modelos, tags ou configurações do DataModel.
- **Verificar o Studio e salvar o place**: a UI do Studio expirou durante a tentativa de confirmar Ctrl+S. Não publicar até confirmar o estado salvo.

## Próxima execução recomendada

1. Abrir o place e salvar os scripts atuais; comparar Movement/Cutscene/WorldSystem com `src/`.
2. Em Play, testar andando/pulo normal, duplo impulso, uma ativação por salto, asas e VFX, Wall Jump, slide e troca de parede. Registrar valores e regiões.
3. Revisar estado de input no callback Menu → Cutscene → Movement. Input automatizado nesta sessão não confirmou o controle normal, apesar do lock API isolado passar.
4. Testar NPC Lumeira no começo e Orvalho perto da Alameda de Musgo; confirmar desbloqueios wings/claw no servidor e repetição de diálogo.
5. Validar com DataStore habilitado em ambiente de teste: banco, saveNow, saída, reaparecimento e reload. Em Studio atual houve perfil temporário.
6. Reproduzir local exato onde plataformas prendem o jogador; medir gap/altura/colisor e modificar a geometria física mínima. Não alterar somente WorldMap.
7. Visitar seis bancos, confirmar alcance e segurança, spawn/checkpoint e retorno entre regiões.
8. Testar câmera/pose e desbloqueio de controles ao terminar/skip/destruir personagem durante cutscene.
9. Rodar análise Luau e testes de jogo disponíveis; preencher resultado, não inferir sucesso a partir da presença de scripts.
10. Atualizar estados das nove fases.

## Questões de arquitetura abertas

- A tabela `STORY_NPCS` está em WorldSystem. Para escalar narrativa, considerar mover dados para módulo compartilhado e separar narrativa de construção dos modelos.
- As habilidades têm pré-requisitos de perfil e cooldown server-side; validar chegada do remote no mesmo frame de salto e comportamento com lag.
- Som `flap` e `wall` reaproveitam os sons existentes. Assets únicos ainda não foram publicados.
- WorldSystem gera NPCs em runtime; validar aparência no place publicado e persistência do modelo de progresso.

## Continuidade acrescentada — 2026-11-02

- **Salvar no Studio:** lugar está aberto como Rollow Knife (WIP), place 114682255992027. Alterações foram feitas em memória; Ctrl+S precisa ser confirmado manualmente. O executor não expõe SavePlaceAsync e a captura Windows expirou. Espelho das 33 fontes está em GitHub; esta sessão atualizou sete scripts desse espelho.
- **Playtest do lock:** conversar com NPC e pressionar mover/pular/ataque/habilidade; repetir durante cutscene, skip, conclusão e destruição de personagem. Confirmar camera/pose e restauração sem erro.
- **UI:** confirmar que “Label” sumiu, painel está no alto à direita e speaker de 34 px fica no canto inferior esquerdo; validar fade/tempo em desktop e telas pequenas.
- **Movimento:** medir altura de flap, validar uma utilização até aterrissar e aparência/som; fazer pelo menos três wall hops recontatando a mesma parede, depois testar outra parede e cooldown.
- **Bancos:** revisar todos os tags Bench, aplicar dano fora/dentro da área, testar ataques de chefe/hazards e tolerância vertical.
- **NPC:** inspecionar composição procedural em viewport. O pedido ForgeGUI foi bloqueado pelo plano; geração/publicação de modelo 3D segue pendente.
- **Dados:** em ambiente autorizado para DataStore, validar save, reload e respawn. Nenhuma fase deve ser marcada como concluída ainda.

## Próxima sessão — revisão de movimento 2026-11-02

1. Salvar o place aberto “Rollow Knife (WIP)” (114682255992027) no Roblox Studio e conferir persistência no reopen. O código GitHub é espelho dos scripts, não salva o place.
2. Em Play, testar numa parede vertical: três ou mais wall jumps recontatando a mesma parede; encadear dash, mudar direção e usar flap; comprovar altura suficiente e controle durante o voo.
3. Sem `Ability_claw`, encostar e pressionar A/D; personagem deve cair sem pose/slide de agarrar.
4. Conferir visual em tela: leque largo branco/ciano, halo sem ofuscar gameplay, animação sincronizada e som.
5. Se a escalada ficar excessiva, ajustar apenas `Config.Move` (`WallJumpVelocityY=78`, `WallJumpVelocityX=32`, `WallJumpRegrabCooldown=0.16`, `WallSlideSpeed=15`, `UnskilledWallFallSpeed=18`) após teste comparativo.

## Parede: validação que falta após 2026-11-02

Em Play com Ability_claw=true, use parede vertical e execute: encostar → saltar uma vez → segurar pulo enquanto ainda encosta (não deve subir de novo) → confirmar afastamento → retornar à parede → saltar novamente. Repetir com dash e flap no meio. Observar a pose wall idle e a descida lenta. Com claw=false, repetir D/A junto à parede e confirmar queda sem cling. A configuração atual é X=36, Y=78, lock=0,18 s, separação mínima=0,16 s, slide=9 e queda sem habilidade=26 studs/s.
