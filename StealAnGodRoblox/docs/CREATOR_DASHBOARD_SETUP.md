# Configurações externas (Creator Dashboard) — o que depende de você

Nada abaixo pode ser feito por código: os IDs são gerados pela Roblox. Enquanto um ID estiver `0`,
o item aparece na loja como **"Indisponível"** e o servidor **nunca** o concede.

Depois de criar cada item, copie o ID para `src/shared/Config/Monetization.luau` (ou `GameConfig.luau`
para badges/sons) e rode `python3 tools/build_rbxlx.py` (ou sincronize com Rojo).

## 1. Configurações da experiência

| Onde | O que fazer |
|---|---|
| Studio → Game Settings → Security | Ativar **Enable Studio Access to API Services** (DataStore funciona no Studio). Sem isso o jogo roda com "progresso temporário" e avisa o jogador. |
| Game Settings → Basic Info | Nome: **STEAL AN GOD**; Gênero: Adventure/Simulator; Max players: **7** (o servidor foi projetado para 7). |
| Creator Dashboard → Places → Configure → Server Fill | Recomendado: "Roblox optimizes" com 7 jogadores máximos. |
| Ícone da experiência | Enviar `art/icon_0.png` (1024×1024). Alternativa: `art/icon_1.png`. |
| Thumbnails | Enviar `art/thumbnail_0.png` (16:9). Alternativa: `art/thumbnail_1.png`. |
| Logo no jogo | Já publicado na sua conta via ForgeGUI (ver `GameConfig.Images.Logo`). Se a moderação recusar, publique `art/logo_0.png` como Decal/Image e coloque o ID lá. |

**Descrição sugerida:**
> ROUBE OVOS DOS DEUSES! 🥚⚡ Corra por 12 biomas mitológicos — Grécia, Nórdicos e Egito —, fuja dos guardiões, leve ovos para a sua base e choque criaturas divinas como Zeus, Thor, Anubis e Rá. Cada criatura gera GOLD e concede uma HABILIDADE única! Treine na esteira, compre Trails, expanda seu templo, coloque armadilhas e roube ovos das bases dos outros jogadores. Novo Ovo Divino a cada 5 minutos e eventos: Eclipse Divino, Ragnarok, Ascensão Solar e Fúria dos Deuses!

## 2. Gamepasses (Monetization → Passes)

| Chave no config | Nome | Preço sugerido | Ícone sugerido | Benefício implementado |
|---|---|---:|---|---|
| `VIP` | VIP | 299 | coroa dourada | tag 👑 VIP + aura, +15% GOLD, recompensa diária (10 min de renda + 1 chave), decoração VIP na base |
| `DoubleMoney` | 2X MONEY | 299 | moedas | renda dos pets ×2 |
| `DoubleGrowth` | 2X GROWTH SPEED | 199 | ovo | incubação ×0.5 |
| `AutoCollect` | AUTO COLLECT | 149 | ímã | renda vai direto ao saldo |
| `ExtraBase` | EXTRA BASE | 199 | ninho | +4 incubadoras |
| `DoubleTraining` | 2X SPEED TRAINING | 249 | raio | Speed da esteira ×2 |

Campos a preencher no Dashboard: Name, Description (use o texto do config), Image (512×512 — pode gerar com ForgeGUI tipo `roblox_gamepass`), Price, "On Sale".

## 3. Developer Products (Monetization → Developer Products)

| Chave | Nome | Preço sugerido | Tipo | Efeito |
|---|---|---:|---|---|
| `GoldSmall` | Bolsa de GOLD | 49 | Gold | 10 min de renda (mín. 1K) |
| `GoldMedium` | Baú de GOLD | 149 | Gold | 40 min de renda (mín. 10K) |
| `GoldLarge` | Tesouro de GOLD | 399 | Gold | ~2h13 de renda (mín. 100K) |
| `GoldMega` | Cofre dos Deuses | 999 | Gold | ~6h40 de renda (mín. 1M) |
| `MoneyBoost` | 2X Money Boost | 99 | Boost | 15 min (acumula) |
| `SpeedBoost` | Speed Boost | 79 | Boost | treino ×2 por 15 min |
| `EventBoost` | Event Boost | 79 | Boost | ovos de evento rolam mutação 2× (fica a melhor) por 15 min |
| `BaseShield` | Base Shield | 59 | Boost | base imune a roubos por 10 min |
| `HatchInstant` | Hatch Instantly | 29 | HatchInstant | choca o ovo com mais tempo restante (sem ovo: 15 min de 2X Money) |
| `DivineReliquary` | Divine Reliquary | 199 | Reliquary | recompensa aleatória com probabilidades exibidas (tabela abaixo) |

**Divine Reliquary — probabilidades exatas (exibidas antes da compra):** 40% 1h de renda · 25% 2X Money 30 min ·
20% Speed Boost 30 min · 12% Ovo Divino · 3% Collector Trail (ou 3h de renda se já possuir) = **100%**.
Jogadores com `PolicyService.ArePaidRandomItemsRestricted` não veem o botão pago (falha fechada se a política não puder
ser lida) e abrem a relíquia com **chaves gratuitas** (1 por login diário, Index, VIP).

Recibos: `ProcessReceipt` idempotente (PurchaseId salvo no perfil, últimos 80), nenhum produto é concedido por evento
do cliente, `NotProcessedYet` quando o perfil não carregou ou o salvamento falhou.

## 4. Badges (opcional)

Crie em Engagement → Badges e preencha `badgeId` em `GameConfig.Achievements`:
First Egg, First Hatch, First Divine Pet, First Million, First Billion, First Raid, First Successful Defense,
First Biome Unlocked, Collector, Master Collector, God Hunter, All Greek Gods, All Norse Gods, All Egyptian Gods.
(Ícones 512×512 podem ser gerados no ForgeGUI com o tipo `roblox_badge` usando o estilo "Steal An God — Mythic Heist".)

## 5. Áudio

`GameConfig.Sounds` usa apenas sons internos do motor (`rbxasset://sounds/...`) por padrão — nenhum ID inventado.
Para música por mitologia (`MusicGreek`, `MusicNorse`, `MusicEgyptian`, `MusicHub`) e SFX extras (`Coins`, `EventStart`):
envie áudios que você tenha direito de usar (ou gere no ForgeGUI `generation_music`/`generation_sound_effect` e publique)
e cole `rbxassetid://<id>`.

## 6. Roupas dos participantes simulados

`src/server/Bots/BotAvatar.luau` → tabela `OUTFITS`: adicione IDs de Shirt/Pants que você tenha permissão de usar.
Sem IDs, os avatares usam cores de corpo variadas + acessórios procedurais.
