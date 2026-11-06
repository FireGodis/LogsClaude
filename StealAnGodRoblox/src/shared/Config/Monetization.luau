--[[
	Monetization.luau — central place for every Gamepass / Developer Product.

	IDs are created in the Roblox Creator Dashboard (Monetization > Passes / Developer Products).
	An id of 0 means "not registered yet": the shop shows the item as unavailable and the server
	never grants it. Fill the ids after creating them — see docs/CREATOR_DASHBOARD_SETUP.md.
]]

local Monetization = {}

Monetization.Gamepasses = {
	VIP = { id = 0, price = 299, name = "VIP", icon = "Crown",
		desc = "Tag VIP, aura dourada, +15% de GOLD, recompensa diária exclusiva e decoração VIP na base." },
	DoubleMoney = { id = 0, price = 299, name = "2X MONEY", icon = "Coins",
		desc = "Dobra permanentemente a renda de todos os seus pets." },
	DoubleGrowth = { id = 0, price = 199, name = "2X GROWTH SPEED", icon = "Egg",
		desc = "Reduz pela metade o tempo de incubação de todos os ovos." },
	AutoCollect = { id = 0, price = 149, name = "AUTO COLLECT", icon = "Magnet",
		desc = "O GOLD dos seus pets vai direto para o seu saldo, sem precisar coletar." },
	ExtraBase = { id = 0, price = 199, name = "EXTRA BASE", icon = "Nest",
		desc = "+4 espaços de incubação extras na sua base." },
	DoubleTraining = { id = 0, price = 249, name = "2X SPEED TRAINING", icon = "Bolt",
		desc = "Dobra a Speed recebida na esteira." },
}

-- kind decides how MonetizationService grants the product.
Monetization.Products = {
	GoldSmall   = { id = 0, price = 49,  name = "Bolsa de GOLD",     kind = "Gold", seconds = 600,   minimum = 1000,     desc = "10 minutos da sua renda atual (mín. 1K)." },
	GoldMedium  = { id = 0, price = 149, name = "Baú de GOLD",       kind = "Gold", seconds = 2400,  minimum = 10000,    desc = "40 minutos da sua renda atual (mín. 10K)." },
	GoldLarge   = { id = 0, price = 399, name = "Tesouro de GOLD",   kind = "Gold", seconds = 8000,  minimum = 100000,   desc = "~2h13 da sua renda atual (mín. 100K)." },
	GoldMega    = { id = 0, price = 999, name = "Cofre dos Deuses",  kind = "Gold", seconds = 24000, minimum = 1000000,  desc = "~6h40 da sua renda atual (mín. 1M)." },
	MoneyBoost  = { id = 0, price = 99,  name = "2X Money Boost",    kind = "Boost", boost = "money",    seconds = 900, desc = "Dobra a renda dos pets por 15 minutos (acumula tempo)." },
	SpeedBoost  = { id = 0, price = 79,  name = "Speed Boost",       kind = "Boost", boost = "training", seconds = 900, desc = "Dobra os ganhos de treinamento por 15 minutos." },
	EventBoost  = { id = 0, price = 79,  name = "Event Boost",       kind = "Boost", boost = "event",    seconds = 900, desc = "Ovos de evento: dobra a chance de tamanho/mutação melhores por 15 min." },
	BaseShield  = { id = 0, price = 59,  name = "Base Shield",       kind = "Boost", boost = "shield",   seconds = 600, desc = "Ninguém pode roubar ovos da sua base por 10 minutos." },
	HatchInstant= { id = 0, price = 29,  name = "Hatch Instantly",   kind = "HatchInstant", desc = "Choca imediatamente o ovo com mais tempo restante." },
	DivineReliquary = { id = 0, price = 199, name = "Divine Reliquary", kind = "Reliquary",
		desc = "Uma relíquia mitológica aleatória. Todas as probabilidades são exibidas antes da compra." },
}

-- Exact odds for the Divine Reliquary. Must sum to 100. Shown in the shop BEFORE purchase.
-- Rewards never depend on luck modifiers, so the displayed odds are always the real odds.
Monetization.ReliquaryTable = {
	{ reward = "GoldHour",      label = "1 hora de renda em GOLD (mín. 25K)",          chance = 40 },
	{ reward = "MoneyBoost30",  label = "2X Money Boost por 30 minutos",               chance = 25 },
	{ reward = "TrainingBoost30", label = "Speed Boost por 30 minutos",               chance = 20 },
	{ reward = "SpecialEgg",    label = "Ovo Divino do seu bioma mais alto (no slot livre)", chance = 12 },
	{ reward = "CollectorTrail",label = "Collector Trail (6x) — ou 3h de renda se já possuir", chance = 3 },
}

-- Free alternative for players whose policy restricts paid random items:
-- Reliquary Keys are earned from Index milestones and the daily login; one key opens one reliquary.
Monetization.FreeReliquaryKeyDailyChance = 1 -- one key every daily login

function Monetization.isRegistered(entry)
	return entry ~= nil and typeof(entry.id) == "number" and entry.id > 0
end

return Monetization
