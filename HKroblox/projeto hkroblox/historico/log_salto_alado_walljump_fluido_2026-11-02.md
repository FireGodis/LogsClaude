# Log: salto alado e Wall Jump fluido — 2026-11-02

## Objetivo e contexto

A solicitação desta revisão foi aproximar o visual do Double Jump da referência anexada (asas claras, largas e abertas como leque) e tornar a mobilidade de parede encadeável. O jogador deve poder saltar da parede, usar dash ou flap, voltar e continuar escalando. Sem a habilidade regional `claw`, tocar uma parede não deve prendê-lo.

## Sistemas e arquivos alterados

- `HKroblox/src/ReplicatedStorage/Shared/Config.luau`
- `HKroblox/src/ReplicatedStorage/Shared/KnightSpec.luau`
- `HKroblox/src/StarterPlayer/StarterPlayerScripts/Client/Controllers/Movement.luau`
- `HKroblox/src/StarterPlayer/StarterPlayerScripts/Client/Controllers/KnightAnim.luau`
- `HKroblox/src/StarterPlayer/StarterPlayerScripts/Client/Controllers/CombatFx.luau`
- `HKroblox/src/ServerScriptService/Server/Systems/Combat.luau`

## Problema, causa e funcionamento anterior

O flap anterior tinha asas pouco legíveis e efeito pequeno, e o impulso vertical parecia fraco. A pose utilizava poucas peças de asa sem silhueta ampla. No movimento de parede, a trava direcional e a falta de renovação de dash/double jump interrompiam combinações; força vertical baixa dificultava subir. O contato com parede era confundido com estado de wall slide mesmo sem a habilidade.

## Solução implementada

- Configuração de flap visual: duração `0.52 s`; asas base ampliadas e quatro penas em leque adicionadas ao rig.
- Animação de asa mais ampla, com elevação adicional do corpo. O brilho do corpo fica ciano/branco durante o flap.
- VFX do flap: rajada de partículas brancas/cianas, halo expansivo e PointLight temporário.
- Wall Jump: `WallJumpVelocityY=78`, `WallJumpVelocityX=32`, lock inicial `0.08 s`, cooldown de recontato `0.16 s`, slide `15` e queda sem habilidade limitada a `-18`.
- Ao saltar da parede, dash e double jump são renovados, permitindo encadear ações durante a subida.
- Contato físico de raycast é separado do estado habilitado de parede; apenas `Ability_claw == true` habilita pose e slide de parede.
- Cooldown do evento visual no servidor ajustado para acompanhar hops mais próximos.

## Funcionamento esperado e resultado observado

Esperado: asas abertas e claramente visíveis durante o flap; impulso mais forte; wall hops sucessivos com direção corrigível, dash e flap disponíveis no ar; personagem sem `claw` segue caindo ao encostar em parede.

Observado: scripts iniciaram em Play sem erro Luau aparente; rig reportou 18 filhos; chamada de VFX criou o halo e a luz. Esses resultados confirmam a montagem estrutural, não o feeling físico nem a leitura visual em tela. A experiência do usuário em sequência real ainda deve ser testada.

## Testes e validações

- Play no Roblox Studio: inicialização dos módulos sem erro de sintaxe/carregamento observado.
- Inspeção do rig no servidor: 18 peças-filhas, incluindo as penas novas.
- Smoke test do `CombatFx.flap`: `ring=true`, `light=true`; configuração reportada `FlapDuration=0.52`, `WallJumpVelocityY=78`.
- Console mostrou avisos de APIs DataStore bloqueadas no Studio (`StudioAccessToApisNotAllowed` nos stores `MareProgress_v1` e `RollowKnifeProfiles_v1`), sem relação confirmada com esta alteração.
- Não houve teste físico ponta a ponta de parede, dash, flap, recontato ou queda sem habilidade; não declarar esses comportamentos como validados.
- O place não foi salvo/confirmado na nuvem durante esta sessão. Os fontes atualizados são versionados no GitHub.

## Problemas durante implementação e pendências

Não foi possível observar a composição visual final numa captura confiável de tela nem executar uma sequência de teclado reproduzível. Os valores são uma primeira calibração e podem exigir ajuste com o controle real. Confirmar que o reset de dash no wall hop não permite uso ilimitado em áreas sem paredes e que o cooldown evita disparos repetidos pela mesma janela de contato.

## Relação com outros sistemas

`Config.Move` fornece parâmetros a `Movement` e `KnightAnim`; `KnightSpec` cria as partes consumidas pela animação; `CombatFx` fornece o feedback de flap e wall jump; servidor controla cooldown dos eventos visuais. A progressão existente (`Ability_claw`) continua sendo a condição de acesso à mecânica de parede.

## Próximas ações

1. Salvar o place no Roblox Studio e reabri-lo para confirmar persistência.
2. Em Play, validar 3+ wall hops, dash, retorno à parede e flap no meio da cadeia.
3. Desabilitar `Ability_claw` para provar queda normal sem cling.
4. Ajustar forças após observar alturas/distâncias reais e inspecionar o VFX na câmera de jogo.
5. Registrar o resultado do playtest antes de alterar o estado das fases.
