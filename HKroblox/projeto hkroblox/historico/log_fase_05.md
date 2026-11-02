# Histórico — Fase 5: Habilidades por região

## Linha de base — 2026-11-02

- `Config.DefaultAbilities` inicia com `dash=true`, `pulse=true`.
- `PlayerData` reconhece habilidades `dash`, `pulse`, `wings`, `claw` e replica atributos para o cliente.
- `Combat.onAbility` aceita `Flap` com `wings` e `WallJump` com `claw`, escrevendo atributos de animação e FX para outros clientes.
- `Movement` não mostrou lógica correspondente para enviar essas habilidades ou alterar a velocidade/estado físico.
- `KnightAnim` consulta `FlapAt`, mas a configuração `KnightSpec` não contém grupos/partes Wing; o efeito não foi confirmado.
- `WorldMap` define um Jardim e um poço vertical, mas não associa desbloqueios a habilidades. Só há uma barreira definida; o requisito de progressão não foi validado.
- Testes: leitura estática; sem Playtest.
- Estado: **Em andamento**. Nenhuma nova habilidade implementada ainda.
