# STEAL AN GOD

Simulador de roubo de ovos mitológicos para Roblox: corra por 12 biomas (Grécia, Nórdicos, Egito), roube ovos
protegidos por guardiões, leve-os para a sua base, choque criaturas divinas que geram GOLD e concedem
**habilidades únicas**, treine na esteira, compre Trails, expanda seu templo, coloque armadilhas e roube ovos das
bases dos outros — com até 5 participantes simulados quando o servidor está vazio.

Projeto refeito do zero (a versão anterior desta pasta foi apagada a pedido).

## Como colocar no Roblox Studio

**Opção A — substituir o place "UPD Steal An God" inteiro (recomendado):**
1. Abra `build/StealAnGod.rbxlx` no Studio (File → Open from File).
2. Pressione **Play**: o mapa inteiro é gerado no primeiro start do servidor.
   Para ver/salvar o mapa já no modo de edição: cole `tools/StudioWipeAndBuild.luau` no Command Bar com
   `DO_WIPE = false, DO_BUILD = true`.
3. File → **Publish to Roblox As…** → escolha a experiência existente "UPD Steal An God" → sobrescrever.
   Isso substitui todo o conteúdo antigo.

**Opção B — limpar o place aberto e sincronizar com Rojo:**
1. Com "UPD Steal An God" aberto, cole `tools/StudioWipeAndBuild.luau` no Command Bar (`DO_WIPE = true`) — apaga tudo.
2. `rojo serve default.project.json` e conecte o plugin do Rojo.
3. Rode o script de novo com `DO_WIPE = false, DO_BUILD = true` para gerar o mapa em modo de edição. Salve.

Depois: Game Settings → Security → **Enable Studio Access to API Services**, e siga
[`docs/CREATOR_DASHBOARD_SETUP.md`](docs/CREATOR_DASHBOARD_SETUP.md) para gamepasses, produtos, badges, ícone e thumbnail.

## Estrutura

```
default.project.json        Rojo (ReplicatedStorage.Shared / ServerScriptService.Server / StarterPlayerScripts.Client)
build/StealAnGod.rbxlx      place pronto para abrir (gerado por tools/build_rbxlx.py)
src/shared/Config/          Balance.json (toda a economia), Creatures.luau (52 criaturas + habilidades),
                            GameConfig.luau (mundo, eventos, conquistas, sons, bots), Monetization.luau (IDs)
src/shared/Util/            Formulas, NumberFormatter (K..Qa..Dc), Net (remotes + rate limit), WeightedRandom, Signal
src/shared/Factory/         ModelFactory: criaturas (12 arquétipos), ovos, guardiões, 10 esteiras, armadilhas, mutações
src/server/init.server.luau único Script do servidor (boot em duas fases: init → start)
src/server/World/           WorldBuilder (hub, 7 bases, avenida, 12 biomas, portões, ninhos) + BiomeDecor
src/server/Systems/         Actors, PlayerData, Economy, Bases, Biomes, Speed, Trails, Eggs, Theft, Hatch, Pets,
                            Guardians, Abilities, Traps, Events, Collection, Monetization, Tutorial, Leaderboard, Security
src/server/Bots/            BotPopulation, BotBrain, BotNavigator, BotAvatar
src/client/init.client.luau único LocalScript
src/client/Controllers/     Hud, Panels, Notifications, Effects, World, Input, Training, Tutorial, Sound
src/client/UI/              Kit + Shop/Trails, Inventory, Index, Upgrades, Rewards, Events, Settings, PetInfo
tools/                      check_luau.py, test_balance.py, simulate_economy.py, build_rbxlx.py,
                            StudioWipeAndBuild.luau, blender/generate_assets.py
art/                        logo, ícone e thumbnail (ForgeGUI)
docs/                       setup do Dashboard, catálogo de criaturas, simulação de economia, relatório de testes
```

## Sistemas (todos server-authoritative)

| Sistema | Resumo |
|---|---|
| Mapa | Avenida de ~3.200 studs: hub com spawn, 7 bases laterais, praça de lojas (Loja, Trails, Melhorias, Index, Recompensas, Ranking) e 12 biomas temáticos de 240 studs com portões por Speed (0 → 50B). |
| Ovos | 6 ninhos por bioma com respawn próprio; 8% de ovo dourado; tamanho (Pequeno→Colossal) e mutação visíveis no ovo; segurar E para roubar, ovo vai às costas, carga reduz a velocidade (10–42%), depósito automático na base. |
| Guardiões | 1–2 por bioma, IA central 5 Hz: Dormindo/Patrulhando/Observando/Detectando/Perseguindo/Atacando/Retornando; golpe = knockback + ovo cai (20 s para recuperar). Mais rápidos a cada bioma; +20% na Fúria dos Deuses. |
| Roubo de bases | Só ovos incubando; propriedade muda só no depósito; dono alcança o ladrão → ovo volta; alarme na base; proteção de novato (10 min), Base Shield e 3 min de proteção após 2 roubos em 5 min. |
| Armadilhas | 3 por jogador, 4 s de prisão só para quem carrega ovo, 8 s de imunidade, expiram em 5 min, proibidas em áreas seguras/bases alheias/portões/ninhos. Bots também usam. |
| Incubação/Chocagem | 15 s (bioma 1) a 15 min (bioma 12), ×tamanho, 2X Growth; contador e barra no ovo, tremor no fim; cinemática de revelação com cor de raridade; offline: choca ao voltar. |
| Pets/Renda | Renda = base × raridade × tamanho × mutação (retornos decrescentes acima de 10×) × modificadores globais (teto 6×); cofre na base + plataforma de coleta (Auto Collect paga). Venda de pets. |
| Habilidades | 52 habilidades em 16 categorias técnicas (Hermes acelera, Athena revela, Thor atordoa guardiões, Loki cria clone, Ra aumenta renda…); Q / botão / X do controle; recarga ≥25 s; nunca afetam outros jogadores. |
| Esteiras/Trails | 10 esteiras visualmente distintas (+2 → +40.000 por passo), 11 Trails (1.5× → 20×) que multiplicam só o treino; Speed vira velocidade real (log, teto 76). |
| Index | 52 criaturas por mitologia/bioma, silhuetas, %, tamanhos/mutações descobertos, recompensas de marco/bioma/mitologia resgatáveis uma única vez. |
| Bases | 8 níveis (4 → 22 incubadoras, 8 → 54 pets), cercas, pilares, estandartes, arcos, tochas, estátuas e aura mudam a cada nível. |
| Eventos | Ovo Divino a cada 5 min (contagem de 15 s, feixe de luz, seta na tela); 4 eventos mundiais rotativos de 4 min a cada 20 min com iluminação própria e ovos exclusivos. |
| Bots | bots = min(5, max(0, 6 − jogadores reais)); 5 personalidades; máquina de estados com utilidade; usam exatamente as mesmas regras/preços; saem de forma graciosa quando alguém entra. |
| Dados | DataStore com UpdateAsync, session lock, retry com backoff, autosave 90 s, BindToClose, versionamento/migração; offline 50% até 8 h. |
| Monetização | 6 gamepasses + 10 produtos configuráveis; ProcessReceipt idempotente; Relíquia com odds públicas e PolicyService. |
| Segurança | Remotes criados só no servidor, rate limit por jogador, validação de distância/estado/preço, detecção de movimento impossível (bloqueia ações, não bane). |

## Comandos úteis

```bash
python3 tools/check_luau.py src          # estrutura Luau, remotes declarados, requires e APIs entre sistemas
python3 tools/test_balance.py            # 242 invariantes de balanceamento/config
python3 tools/simulate_economy.py --hours 6 --runs 12 --md docs/ECONOMY_SIMULATION.md
python3 tools/build_rbxlx.py             # regera build/StealAnGod.rbxlx
```

Veja [`docs/TEST_REPORT.md`](docs/TEST_REPORT.md) para o estado real de testes e prontidão.
