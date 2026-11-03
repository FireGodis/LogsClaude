# Log: wall jump com separação e recontato — 2026-11-02

## Solicitação e diagnóstico

O jogador conseguia manter-se colado à parede e ganhar altura pressionando pulo repetidamente. A causa foi o cooldown local de 0,16 s: expirava sem exigir que o raycast perdesse o contato. Além disso, a direção de Humanoid:Move() continuava apontando para a parede durante o impulso inicial, mesmo quando a velocidade calculada era para fora. Sem a habilidade, o controlador neutralizava o estado visual de parede, porém a entrada lateral ainda pressionava o personagem contra a colisão.

## Alterações

Arquivos:
- HKroblox/src/ReplicatedStorage/Shared/Config.luau
- HKroblox/src/StarterPlayer/StarterPlayerScripts/Client/Controllers/Movement.luau
- HKroblox/src/StarterPlayer/StarterPlayerScripts/Client/Controllers/KnightAnim.luau

Valores atuais:
- WallJumpVelocityX = 36, WallJumpVelocityY = 78.
- WallJumpLock = 0,18 s, período mínimo de separação WallJumpRegrabCooldown = 0,16 s.
- WallSlideSpeed = 9 studs/s com Ability_claw.
- UnskilledWallFallSpeed = 26 studs/s sem habilidade.

O estado wallJumpArmed começa habilitado, desabilita ao saltar e só volta a habilitar depois que a detecção não encontra parede por pelo menos 0,16 s. A contagem também observa a separação durante dash. O novo contato após esse intervalo é necessário para saltar de novo. No impulso inicial, a velocidade e o comando do Humanoid impedem movimento em direção à parede, mas ainda permitem continuar para fora. Com claw, o wall slide tem queda lenta e respiração sutil na pose. Sem claw, a entrada que empurra contra a parede é zerada, a pose de parede não aparece e a queda é acelerada.

## Referências pesquisadas

Foram consultadas descrições públicas de uma recriação comunitária de movimento em Godot e a página de fonte de um mod para Silksong. A recriação descreve estados separados de wall slide e wall jump, com impulso direcional para longe da parede. A página do mod não fornece uma referência confiável ao controlador original do jogador. Não foi copiado ou portado código descompilado; os ajustes acima são implementação original em Luau, baseada no comportamento solicitado. Ver [recriação comunitária em Godot](https://github.com/tbh272/HollowKnightGodot) e [página de fonte do mod](https://old.thunderstore.io/c/hollow-knight-silksong/p/jakobhellermann/SpeedrunGym/source/).

## Validação e resultado

- Studio Play iniciou; não apareceu erro Luau novo. Console manteve avisos já existentes de DataStore API desabilitada.
- Teste cliente isolado com parede temporária e Ability_claw=false: reposicionado em Y=20 ao lado da parede e segurando D por ~0,5 s, o personagem desceu até Y=3 no piso. Isto confirma a queda sem cling para esse cenário.
- Não foi possível concluir nesta sessão a sequência manual com claw=true, retorno à parede, dash e flap. Não registrar o encadeamento como validado.
- O teste usou parede criada em memória no Client, não editou geometria persistente do mapa.

## Funcionamento anterior / esperado / atual

- **Anterior:** cooldown reabilitava salto na parede sem separação; comando lateral podia anular o afastamento; sem habilidade a entrada continuava empurrando contra parede.
- **Esperado:** cada salto gera deslocamento para fora e para cima; o jogador precisa retornar à parede antes de saltar de novo; slide lento e idle apenas com claw; sem habilidade, queda livre sem agarrar.
- **Atual:** latch e bloqueio de entrada foram implementados; queda sem habilidade observada em teste local. Wall hop/recontato e animação ainda precisam de playtest manual.

## Pendências

1. Executar sequência em parede real com claw=true e confirmar apenas um salto por contato.
2. Verificar que o empurrão de 0,18 s cria espaço suficiente e não impede reaproximação com controle.
3. Encadear dash e flap; observar que reset de recursos não permite uso infinito sem recontato.
4. Verificar visualmente o wall idle e o limite de queda lenta.
5. Salvar o place no Studio e confirmar persistência ao reabrir.