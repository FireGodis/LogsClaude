# Relatório de testes e prontidão — estado real

## Ambiente desta sessão (limitações)

Esta sessão rodou num **container na nuvem**, não no seu computador:

- **Roblox Studio MCP: não conectado.** Não houve acesso ao place aberto "UPD Steal An God"; nada foi apagado ou
  construído diretamente nele. Por isso o projeto inclui `tools/StudioWipeAndBuild.luau` e `build/StealAnGod.rbxlx`.
- **Blender: não instalado** (e executar binários baixados foi bloqueado). O kit de meshes está em
  `tools/blender/generate_assets.py`, pronto para rodar na sua máquina; até lá o jogo usa modelos procedurais
  do `ModelFactory`, que é substituído automaticamente por meshes em `ReplicatedStorage.Assets`.
- **luau-analyze / Lune: não executáveis** aqui. No lugar, foi escrito um verificador estrutural próprio.
- **ForgeGUI: disponível e usado** (logo, ícone, thumbnail; logo publicado na sua conta Roblox).

## Testes EXECUTADOS nesta sessão (passaram)

| Teste | Resultado |
|---|---|
| `tools/check_luau.py` — 56 arquivos Luau: blocos/parênteses balanceados, operadores inválidos, sintaxe de função inválida, todos os `require` resolvem, todos os nomes de remote/ação usados existem em `Net.luau`, **124 referências entre sistemas** (`S.X.fn` / `C.X.fn`) apontam para funções existentes | ✅ |
| `tools/test_balance.py` — 242 invariantes: tabela de bots (1→5 … 6→0, 7→0), curva de Speed da especificação, 12 biomas, crescimento de renda/guardiões, tempos de incubação nas faixas pedidas, lojas monotônicas, 52 criaturas únicas com 4 por bioma, 25 deuses obrigatórios, habilidades válidas com recarga ≥25 s, odds da relíquia = 100%, IDs de monetização = 0, offline 50%/8 h, ovo especial a cada 5 min, armadilhas | ✅ (1 falha real encontrada e corrigida: o empilhamento máximo dava 57× a renda base; retornos decrescentes ajustados para ~33×) |
| `tools/simulate_economy.py` — simulação de progressão (iniciante/intermediário/avançado/bot) | ✅ ver `ECONOMY_SIMULATION.md`: biomas novos a cada poucos minutos no início, Templo Solar como meta de longo prazo (>6 h); bots ficam entre iniciante e intermediário |
| `tools/build_rbxlx.py` — gera place XML válido (57 scripts) com árvore correta de serviços | ✅ |
| Revisão visual das artes geradas (logo legível "STEAL AN GOD", ícone e thumbnail no estilo definido) | ✅ |

## Testes que EXIGEM o Roblox Studio (não executados — faça com a lista abaixo)

Nenhum destes foi marcado como aprovado porque o Studio não estava acessível. Roteiro:

1. **Primeiro acesso** — Play: splash com logo, base atribuída, tutorial com feixe até um ovo; roubar (segurar E),
   voltar, depósito automático, contador, cinemática de chocagem, plataforma dourada credita GOLD.
2. **Progressão** — correr na esteira (números "+⚡"), comprar Basic Trail, chegar a 150 Speed: portão do Mar Egeu abre
   (fica sólido antes), comprar Wooden Treadmill na praça (o visual da esteira muda).
3. **Raridades** — o Command Bar do Studio cria uma instância separada dos módulos, então não altera o jogo em
   execução. Para forçar raridades/mutações/tamanhos, aumente temporariamente `rareEggChance` e os pesos em
   `Balance.json` (ou `speciesHatchWeights`), rode Play e confira cores, auras e multiplicadores no Inventário.
4. **Habilidades** — equipar Hermes/Thor/Athena/Loki, apertar Q: efeito por mitologia, recarga no botão, guardião
   atordoado/lento, clone distrai.
5. **Roubo entre jogadores** — Test → Clients and Servers com 2 jogadores (proteção de novato dura 10 min de jogo:
   para testar antes, reduza `protection.newPlayerSeconds`).
6. **Armadilhas** — T três vezes (4ª recusa), testar em área segura (recusa), ladrão carregando ovo fica preso 4 s.
7. **Bots** — 1 jogador: 5 participantes aparecem em ~10 s. Com 2–7 clientes locais confirme 4/3/2/1/0/0.
   Observe o atributo `BotState` nos modelos em `Workspace.Runtime.Bots` (Treinando, Roubando, Comprando…).
8. **Dados** — com API Services ligado: sair/entrar, conferir GOLD, pets, ovos, melhorias, recompensas e tela de ganhos offline.
9. **Monetização** — com IDs reais: comprar no modo de teste do Studio, verificar recibo idempotente e item "Indisponível" quando ID = 0.
10. **Dispositivos** — Device Emulator (celular/tablet/console): HUD escalado por `UIScale`, botões de toque, gamepad (X/Y/D-pad).

## Riscos conhecidos a observar no primeiro Play

- Código Luau nunca executado de fato: podem aparecer erros de runtime pontuais (nomes de propriedade, ordem de
  carregamento). Os loops críticos estão protegidos com `pcall` + `warn`, então um erro não derruba o servidor —
  verifique a janela Output e me envie o log.
- `Players:CreateHumanoidModelFromDescription` precisa de rede; se falhar, os bots usam um avatar estilizado alternativo.
- Pathfinding dos bots no Labirinto (paredes) pode exigir ajuste fino dos pontos de ninho.

## Prontidão para publicação

**Não publicado.** Código e conteúdo completos para um primeiro teste no Studio; pendências externas:
IDs de gamepass/produtos/badges, ícone/thumbnail no Dashboard, API Services, áudios próprios, execução do roteiro acima.
