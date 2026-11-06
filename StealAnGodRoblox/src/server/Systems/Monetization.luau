--[[
	Monetization — Gamepasses, Developer Products (idempotent ProcessReceipt), VIP daily reward
	and the Divine Reliquary (paid random item with published odds + PolicyService compliance).

	Nothing is ever granted from a client event. Products only exist when their id is filled in
	Config/Monetization.luau; unregistered products are hidden/disabled in the shop.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Monetization)
local Balance = require(Shared.Config.Balance)
local Formulas = require(Shared.Util.Formulas)
local WeightedRandom = require(Shared.Util.WeightedRandom)
local Net = require(Shared.Util.Net)

local Monetization = {}
local S

local owned = {} -- [id] = {[passKey] = true}
local randomRestricted = {} -- [userId] = bool
local passById = {}
local productById = {}

for key, pass in Config.Gamepasses do
	if Config.isRegistered(pass) then
		passById[pass.id] = key
	end
end
for key, product in Config.Products do
	if Config.isRegistered(product) then
		productById[product.id] = key
	end
end

-- Validate odds table once (must total 100%).
do
	local total = 0
	for _, row in Config.ReliquaryTable do
		total += row.chance
	end
	assert(math.abs(total - 100) < 1e-6, "ReliquaryTable odds must sum to 100, got " .. total)
end

function Monetization.init(sys)
	S = sys
end

function Monetization.has(id: number, key: string): boolean
	local o = owned[id]
	return o ~= nil and o[key] == true
end

function Monetization.ownedList(id: number)
	local list = {}
	for k, v in owned[id] or {} do
		if v then
			table.insert(list, k)
		end
	end
	return list
end

function Monetization.isRandomRestricted(id: number): boolean
	return randomRestricted[id] == true
end

local function notify(id: number, title: string, text: string, kind: string?)
	local player = S.Actors.player(id)
	if player then
		Net.fire(player, "Notify", { kind = kind or "Purchase", title = title, text = text })
	end
end

local function applyPass(id: number, key: string)
	owned[id] = owned[id] or {}
	if owned[id][key] then
		return
	end
	owned[id][key] = true
	if key == "VIP" then
		S.Bases.refreshVisuals(id)
		local player = S.Actors.player(id)
		if player and player.Character then
			S.Trails.applyVipAura(id, player.Character)
		end
	elseif key == "ExtraBase" then
		S.Bases.refreshVisuals(id)
	end
	S.PlayerData.dirty(id)
end

local function refreshOwnership(player: Player)
	local id = player.UserId
	owned[id] = owned[id] or {}
	for key, pass in Config.Gamepasses do
		if Config.isRegistered(pass) then
			local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, id, pass.id)
			if ok and result then
				applyPass(id, key)
			end
		end
	end
	local ok, policy = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
	if ok and policy then
		randomRestricted[id] = policy.ArePaidRandomItemsRestricted == true
	else
		randomRestricted[id] = true -- fail closed: hide paid random items when policy is unknown
	end
	S.PlayerData.dirty(id)
end

-- ===================== REWARD HELPERS =====================
local function addBoost(id: number, boost: string, seconds: number)
	local p = S.PlayerData.get(id)
	local now = os.time()
	p.boosts[boost] = math.max(now, p.boosts[boost] or 0) + seconds
	S.PlayerData.dirty(id)
end
Monetization.addBoost = addBoost

-- Rolls and grants a reliquary result. Odds are EXACTLY the published table.
function Monetization.openReliquary(id: number)
	local row = WeightedRandom.pick(Config.ReliquaryTable, function(r)
		return r.chance
	end)
	local p = S.PlayerData.get(id)
	local text = row.label
	if row.reward == "GoldHour" then
		local amount = S.Economy.incomeSeconds(id, 3600, 25000)
		S.Economy.addGold(id, amount, "Reliquary")
		text = "+" .. amount .. " GOLD"
	elseif row.reward == "MoneyBoost30" then
		addBoost(id, "money", 1800)
	elseif row.reward == "TrainingBoost30" then
		addBoost(id, "training", 1800)
	elseif row.reward == "SpecialEgg" then
		local biome = Formulas.unlockedBiome(p.speed)
		local ok = S.Eggs.grantEggToBase(id, S.Eggs.makeRecord(biome, "special"))
		if not ok then
			local amount = S.Economy.incomeSeconds(id, 3600, 25000)
			S.Economy.addGold(id, amount, "ReliquaryFallback")
			text = "Base cheia — convertido em " .. amount .. " GOLD"
		end
	elseif row.reward == "CollectorTrail" then
		if table.find(p.trailsOwned, "Collector") then
			local amount = S.Economy.incomeSeconds(id, 10800, 100000)
			S.Economy.addGold(id, amount, "ReliquaryDupe")
			text = "Collector Trail repetido — +" .. amount .. " GOLD"
		else
			S.Trails.grant(id, "Collector")
		end
	end
	S.PlayerData.dirty(id)
	return row.reward, text
end

local function grantProduct(id: number, key: string): boolean
	local product = Config.Products[key]
	local p = S.PlayerData.get(id)
	if not product or not p then
		return false
	end
	if product.kind == "Gold" then
		local amount = S.Economy.incomeSeconds(id, product.seconds, product.minimum)
		S.Economy.addGold(id, amount, "Product")
		notify(id, "Compra concluída!", "+" .. amount .. " GOLD")
	elseif product.kind == "Boost" then
		addBoost(id, product.boost, product.seconds)
		notify(id, "Boost ativado!", product.name)
		if product.boost == "shield" then
			S.Bases.refreshVisuals(id)
		end
	elseif product.kind == "HatchInstant" then
		if not S.Hatch.hatchInstant(id) then
			addBoost(id, "money", 900)
			notify(id, "Nenhum ovo incubando", "Você recebeu 15 min de 2X Money no lugar.")
		end
	elseif product.kind == "Reliquary" then
		local _, text = Monetization.openReliquary(id)
		notify(id, "Divine Reliquary", text, "Rare")
	end
	return true
end

-- ===================== RECEIPTS =====================
local function processReceipt(receipt)
	local id = receipt.PlayerId
	local key = productById[receipt.ProductId]
	if not key then
		warn("[Monetization] Unknown product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local p = S.PlayerData.get(id)
	if not p then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- player not loaded / left: retried later
	end
	if table.find(p.purchases, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted (idempotent)
	end
	local ok, err = pcall(grantProduct, id, key)
	if not ok then
		warn("[Monetization] grant failed", err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(p.purchases, receipt.PurchaseId)
	while #p.purchases > 80 do
		table.remove(p.purchases, 1)
	end
	if not S.PlayerData.saveNow(id) then
		-- Purchase id is recorded in memory, so a re-delivery in this session is idempotent;
		-- if the server dies before saving, Roblox re-delivers and the grant is (correctly) redone.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization.start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and passById[passId] then
			applyPass(player.UserId, passById[passId])
			notify(player.UserId, "Gamepass adquirido!", Config.Gamepasses[passById[passId]].name)
		end
	end)

	S.PlayerData.Loaded:Connect(function(id)
		local player = S.Actors.player(id)
		if player then
			task.spawn(refreshOwnership, player)
		end
	end)
	S.Actors.Removed:Connect(function(id)
		owned[id] = nil
		randomRestricted[id] = nil
	end)

	S.Net.handle("GetReliquaryInfo", function(player)
		local p = S.PlayerData.get(player.UserId)
		return true, {
			odds = Config.ReliquaryTable,
			restricted = randomRestricted[player.UserId] ~= false,
			registered = Config.isRegistered(Config.Products.DivineReliquary),
			keys = p and p.keys or 0,
		}
	end)

	S.Net.handle("OpenReliquaryKey", function(player)
		local id = player.UserId
		local p = S.PlayerData.get(id)
		if not p or p.keys < 1 then
			return false, "Você não tem chaves de relíquia."
		end
		p.keys -= 1
		local reward, text = Monetization.openReliquary(id)
		return true, { reward = reward, text = text }
	end)

	S.Net.handle("ClaimVipDaily", function(player)
		local id = player.UserId
		local p = S.PlayerData.get(id)
		if not p or not Monetization.has(id, "VIP") then
			return false, "Exclusivo VIP"
		end
		if os.time() - p.lastVipDaily < 20 * 3600 then
			return false, "Disponível em " .. math.ceil((20 * 3600 - (os.time() - p.lastVipDaily)) / 3600) .. "h"
		end
		p.lastVipDaily = os.time()
		local e = Balance.economy
		local amount = S.Economy.incomeSeconds(id, e.vipDailyGoldSecondsOfIncome, e.vipDailyGoldMinimum)
		S.Economy.addGold(id, amount, "VipDaily")
		p.keys += 1
		S.PlayerData.dirty(id)
		return true, "+" .. amount .. " GOLD e 1 chave de relíquia!"
	end)

	-- Daily login key (free alternative to the paid reliquary, available to everyone).
	S.PlayerData.Loaded:Connect(function(id, profile)
		local day = os.time() // 86400
		if profile.lastDaily ~= day then
			profile.lastDaily = day
			profile.keys += 1
			task.delay(8, function()
				notify(id, "Recompensa diária", "+1 Chave de Relíquia Divina (abra na Loja > Ovos Especiais)", "Reward")
			end)
		end
	end)
end

return Monetization
