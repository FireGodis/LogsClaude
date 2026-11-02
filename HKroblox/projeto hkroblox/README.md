# Projeto HKROBLOX

Esta pasta registra o estado técnico e narrativo do jogo tratado neste ciclo como HKROBLOX. O projeto executado está aberto no Roblox Studio como **Rollow Knife (WIP)**, place ID `114682255992027`. O repositório GitHub fornecido continha apenas `HKroblox/.gitkeep`; por isso, o código observado nesta análise ainda vive no place do Studio e não está espelhado aqui.

## Documentos

- [Contexto do projeto](CONTEXTO_DO_PROJETO.md)
- [Estado das fases](ESTADO_DAS_FASES.md)
- [Arquitetura e sistemas](ARQUITETURA_E_SISTEMAS.md)
- [Plano de desenvolvimento](PLANO_DE_DESENVOLVIMENTO.md)
- [Log de alterações](LOG_DE_ALTERACOES.md)
- [Bugs e problemas](BUGS_E_PROBLEMAS.md)
- [Testes e validações](TESTES_E_VALIDACOES.md)
- [Pendências para próximo agente](PENDENCIAS_PARA_PROXIMO_AGENTE.md)
- [Histórico da Fase 5](historico/log_fase_05.md)
- [Histórico da Fase 6](historico/log_fase_06.md)

## Estado desta revisão

Análise estática inicial concluída. O place já possui movimentação e combate 2.5D, mapa de 14 salas, seis bancos, inimigos, chefe, HUD e cutscene de abertura. A análise não encontrou um sistema de diálogos com NPCs. As habilidades `wings` e `claw` aparecem no esquema de save e em handlers parciais, mas o fluxo completo de desbloqueio, movimento, animação e validação ainda não foi confirmado.

Nenhuma fase é considerada concluída sem validação comportamental no Studio.
