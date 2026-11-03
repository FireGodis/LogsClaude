# Desenho da economia

## Estado

A economia completa continua indefinida. O slice inicial possui preços, renda e upgrade provisórios, centralizados e testados no Roblox Studio; eles não são balanceamento final aprovado. Probabilidades, custos de progressão longa e IDs de produtos continuam sem definição.

## Moedas planejadas

| Moeda | Papel indicado | Fontes planejadas | Usos planejados | Decisões pendentes |
|---|---|---|---|---|
| Coins | Moeda principal de progressão | Produção dos deuses e recompensas de jogo | Ovos, upgrades, bases e progressão | Taxas, preços, ritmo e limites |
| Gems | Moeda premium ou secundária | Compras e fontes de jogo ainda a definir | Produtos, conveniência ou itens elegíveis | Ganhos gratuitos, conversão e usos |
| Divine Shards | Recurso de progressão | A definir | A definir | Obtenção, raridade e função |

Não misture automaticamente moeda comprada com moeda obtida jogando. Defina os tipos e as regras de gasto antes de implementar transações ou compras aleatórias.

## Produção e evolução

Cada deus tem renda base e multiplicador configuráveis. A fórmula final deve esclarecer como upgrades, eventos e gamepasses afetam a produção. O servidor calcula saldos e recompensas; o cliente apenas solicita ações e apresenta os valores recebidos do servidor.

Custos de ovos e upgrades devem ser ajustados por uma curva documentada e testados como jogador gratuito. Não há preços de referência aprovados neste momento.

## Ovos, raridades e odds

Ovos configuráveis: Greek, Norse, Egyptian, Ancient, Celestial e Divine. Raridades planejadas: Common, Uncommon, Rare, Epic, Legendary, Mythic e Divine. Cada tabela deve ser orientada por dados, definir resultados finais e odds sem duplicar a lógica em scripts e somar 100% antes de qualquer arredondamento de exibição.

Antes de implementar uma recompensa aleatória paga:

- Consultar a regra oficial vigente e usar PolicyService:GetPolicyInfoForPlayerAsync() para obter ArePaidRandomItemsRestricted para o jogador.
- Bloquear o acesso ao gerador pago para jogadores restritos e planejar uma alternativa elegível, como caminho gratuito ou oferta direta e garantida, conforme o desenho aprovado.
- Mostrar todos os resultados possíveis e as probabilidades individuais efetivas antes da compra.
- Recalcular a divulgação quando um modificador de sorte estiver ativo.
- Verificar regras de troca de itens pagos com IsPaidItemTradingAllowed caso exista troca entre jogadores.
- Nunca confiar no cliente para determinar o resultado ou conceder o item.

A diretriz atual da Roblox descreve divulgação de resultados e odds, regras por jogador e a restrição ArePaidRandomItemsRestricted. Revise-a novamente durante a implementação: [Diretrizes de itens aleatórios pagos](https://create.roblox.com/docs/production/monetization/paid-random-items) e [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService).

## Monetização

Gamepasses propostos: VIP, 2x Coins, 2x Luck, slots extra, hatch rápido, velocidade, coleta automática, base premium, equip extra e acesso Divine. Produtos de desenvolvedor propostos: pacotes de moedas/gemas, hatch instantâneo, boosts temporários, proteção, defesa, velocidade, tokens de rebirth e cosméticos.

Bundles devem indicar exatamente seus itens. Starter Pack deve mostrar preço, recompensas e estado de compra. Não usar contagem regressiva, escassez falsa ou descrições ambíguas. Nenhum ID real de produto ou passe deve ser inventado; IDs permanecem configuráveis até serem fornecidos.

ProcessReceipt deve ser seguro, idempotente e recuperável em repetição. Verificar a propriedade de passes e a concessão no servidor. A loja não pode conceder itens apenas porque o cliente enviou um evento.

## Próximas decisões de balanceamento

1. Definir fonte e uso de Gems e Divine Shards.
2. Selecionar o primeiro ovo e o primeiro deus do loop inicial.
3. Fixar custo, renda, tempo de hatch e ritmo de upgrade com playtests.
4. Formalizar o que ocorre com itens adquiridos ao desconectar ou sofrer roubo.
5. Determinar produtos reais somente após aprovação e configuração no Roblox.

## Slice inicial testado no Studio — valores provisórios

A primeira versão executável centraliza estes valores em SAG_Config. São parâmetros do protótipo, testados no Studio, ainda sem aprovação de balanceamento de longo prazo:

| Parâmetro | Valor atual | Efeito |
|---|---:|---|
| Coins iniciais | 150 | Perfil novo e Ares |
| Greek Egg | 100 Coins | Compra no altar do hub |
| Renda de Zeus | 4 Coins/s | Saldo pendente no nível de base 1 |
| Upgrade de base | 100 Coins | Nível 1→2 |
| Bônus do nível 2 | +25% | Produção arredondada para 5 Coins/s |
| Nível máximo nesta fatia | 2 | Limite de escopo |

O servidor decide transações e publica atributos para o HUD. O playtest confirmou compra, hatch, produção, coleta e upgrade. Ares usa estado simulado próprio com os mesmos custos e renda; não recebe moedas arbitrárias depois do valor inicial.

Esses valores não definem a curva completa, custo de civilizações futuras, odds, Gems, Shards ou monetização. Nenhuma compra com Robux ou ovo de recompensa paga existe nesta fatia.
