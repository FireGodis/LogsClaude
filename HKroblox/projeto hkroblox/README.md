# Projeto HKROBLOX

O jogo está aberto no Roblox Studio como **Rollow Knife (WIP)**, place ID `114682255992027`. O usuário confirmou que este é o projeto HKROBLOX. Esta pasta documenta a implementação e o estado real do place.

A pasta [src](../src/README.md) contém um espelho de 33 scripts Luau extraídos do place nesta sessão. É um espelho de código-fonte, não um arquivo de place Roblox; geometria, modelos e configurações do DataModel continuam dentro do place.

## Documentos

- [Contexto](CONTEXTO_DO_PROJETO.md)
- [Estado das fases](ESTADO_DAS_FASES.md)
- [Arquitetura e sistemas](ARQUITETURA_E_SISTEMAS.md)
- [Plano de desenvolvimento](PLANO_DE_DESENVOLVIMENTO.md)
- [Log de alterações](LOG_DE_ALTERACOES.md)
- [Bugs e problemas](BUGS_E_PROBLEMAS.md)
- [Testes e validações](TESTES_E_VALIDACOES.md)
- [Pendências para o próximo agente](PENDENCIAS_PARA_PROXIMO_AGENTE.md)
- [Histórico da Fase 5](historico/log_fase_05.md)
- [Histórico da Fase 6](historico/log_fase_06.md)

## Estado desta sessão

Foram adicionados movimento de pulo duplo e wall jump condicionados às habilidades, peças originais de asas e VFX, bloqueio por token durante cutscene, salvamento imediato ao descansar, e um sistema de diálogo com dois NPCs originais. Lumeira, na Vila das Lanternas, concede `wings`; Orvalho, na Alameda de Musgo, concede `claw`.

O fluxo de diálogo e a concessão de `wings` foram exercitados no Studio. O movimento efetivo das novas habilidades, wall jump, geometria de plataformas, persistência real e salvamento do place ainda precisam de validação. Nenhuma fase foi marcada como concluída.

## Última sessão (2026-11-02)

Foram corrigidos os estados de lock de controles, diálogo, flap, wall jump, proteção do banco j2 e visuais procedurais dos dois NPCs. A geração paga do ForgeGUI está bloqueada no plano atual e o place ainda precisa ser salvo manualmente no Studio. Consulte o [registro detalhado](historico/log_correcao_movimento_dialogo_npc_2026-11-02.md) e a [validação](TESTES_E_VALIDACOES.md).

## Revisão de movimento — 2026-11-02

A iteração mais recente amplia o flap do Double Jump com seis segmentos de asa e halo ciano, e torna o Wall Jump mais alto e encadeável com dash e flap. Consulte `historico/log_salto_alado_walljump_fluido_2026-11-02.md` para evidência e limitações. O código espelhado está em `../src/`; o place no Studio ainda não foi confirmado como salvo.
