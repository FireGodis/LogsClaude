--[[
	Collection — Index (discovery of species / sizes / mutations), collection rewards
	(milestones, per-biome sets, per-mythology sets) and achievements (+ optional Roblox badges).
	Rewards are persistent and can only be claimed once (claimed ids saved in the profile).
]]

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local NumberFormatter = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)

local Collection = {}
local S
local TOTAL = #Creatures.List

function Collection.init(sys)
	S = sys
end

local function notify(id: number, kind: string, title: string, text: string)
	local player = S.Actors.player(id)
	if player then
		Net.fire(player, "Notify", { kind = kind, title = title, text = text })
	end
end

function Collection.discoveredCount(profile): number
	local n = 0
	for species in profile.index do
		if Creatures.ById[species] then
			n += 1
		end
	end
	return n
end

local function mythologyComplete(profile, mythology: string): boolean
	for _, c in Creatures.List do
		if c.mythology == mythology and not profile.index[c.id] then
			return false
		end
	end
	return true
end

local function biomeComplete(profile, biome: number): boolean
	for slot = 1, 4 do
		if not profile.index[Creatures.ByBiome[biome][slot].id] then
			return false
		end
	end
	return true
end

-- Returns true if this species was never seen before.
function Collection.discover(id: number, pet): boolean
	local p = S.PlayerData.get(id)
	if not p then
		return false
	end
	local entry = p.index[pet.species]
	local isNew = entry == nil
	if not entry then
		entry = { s = {}, m = {}, n = 0 }
		p.index[pet.species] = entry
	end
	entry.n += 1
	entry.s[pet.size] = true
	entry.m[pet.mutation] = true
	p.stats.discovered = Collection.discoveredCount(p)
	p.stats.greekComplete = mythologyComplete(p, "Greek") and 1 or 0
	p.stats.norseComplete = mythologyComplete(p, "Norse") and 1 or 0
	p.stats.egyptianComplete = mythologyComplete(p, "Egyptian") and 1 or 0
	if isNew then
		local c = Creatures.ById[pet.species]
		notify(id, "Discovery", "NOVA CRIATURA DESCOBERTA!", (c and c.name or pet.species) .. " foi adicionada ao Index")
		S.Tutorial.progress(id, "Discover")
	end
	Collection.checkAchievements(id)
	S.PlayerData.dirty(id)
	return isNew
end

-- ===================== REWARDS =====================
function Collection.rewardList()
	local list = {}
	for _, m in GameConfig.IndexMilestones do
		table.insert(list, m)
	end
	for b = 1, 12 do
		table.insert(list, { id = "Biome_" .. b, biome = b, label = "Coleção completa: " .. Formulas.biome(b).name,
			reward = { type = "Gold", seconds = GameConfig.BiomeCompleteReward.seconds, minimum = GameConfig.BiomeCompleteReward.minimumPerBiome * (5 ^ (b - 1)), keys = (b % 4 == 0) and 1 or 0 } })
	end
	return list
end

local rewardById = {}
for _, r in Collection.rewardList() do
	rewardById[r.id] = r
end

function Collection.isReached(profile, r): boolean
	local count = Collection.discoveredCount(profile)
	if r.biome then
		return biomeComplete(profile, r.biome)
	elseif r.mythology then
		return mythologyComplete(profile, r.mythology)
	elseif r.count then
		return count >= r.count
	end
	return count / TOTAL * 100 >= r.percent
end

local function grant(id: number, reward): string
	local p = S.PlayerData.get(id)
	local parts = {}
	if reward.type == "Gold" then
		local amount = S.Economy.incomeSeconds(id, reward.seconds, reward.minimum)
		S.Economy.addGold(id, amount, "IndexReward")
		table.insert(parts, "+" .. NumberFormatter.format(amount) .. " GOLD")
	elseif reward.type == "Trail" then
		S.Trails.grant(id, reward.trail)
		table.insert(parts, "Trail " .. reward.trail)
	elseif reward.type == "SpecialEgg" then
		local ok = S.Eggs.grantEggToBase(id, S.Eggs.makeRecord(Formulas.unlockedBiome(p.speed), "special"))
		if ok then
			table.insert(parts, "Ovo Divino na sua base")
		else
			local amount = S.Economy.incomeSeconds(id, 1800, 10000)
			S.Economy.addGold(id, amount, "IndexRewardFallback")
			table.insert(parts, "+" .. NumberFormatter.format(amount) .. " GOLD (base cheia)")
		end
	end
	if reward.keys and reward.keys > 0 then
		p.keys += reward.keys
		table.insert(parts, "+" .. reward.keys .. " chave(s)")
	end
	if reward.title then
		p.title = reward.title
		S.Bases.updateSign(id)
		table.insert(parts, "Título: " .. reward.title)
	end
	return table.concat(parts, " • ")
end

function Collection.claim(id: number, rewardId: any): (boolean, string?)
	local p = S.PlayerData.get(id)
	local r = typeof(rewardId) == "string" and rewardById[rewardId]
	if not p or not r then
		return false, "Recompensa inválida"
	end
	if p.claimed[rewardId] then
		return false, "Já coletada"
	end
	if not Collection.isReached(p, r) then
		return false, "Ainda não alcançada"
	end
	p.claimed[rewardId] = true -- mark first: no double claims even if grant yields
	local text = grant(id, r.reward)
	S.PlayerData.dirty(id)
	return true, text
end

-- ===================== ACHIEVEMENTS =====================
local function statValue(p, stat: string): number
	if stat == "totalEarned" then
		return p.totalEarned
	end
	return p.stats[stat] or 0
end

function Collection.checkAchievements(id: number)
	local p = S.PlayerData.get(id)
	if not p then
		return
	end
	for _, a in GameConfig.Achievements do
		if not p.achievements[a.id] and statValue(p, a.stat) >= a.goal then
			p.achievements[a.id] = os.time()
			notify(id, "Achievement", "CONQUISTA: " .. a.name, a.desc)
			local player = S.Actors.player(id)
			if player and a.badgeId and a.badgeId > 0 then
				task.spawn(function()
					pcall(BadgeService.AwardBadge, BadgeService, player.UserId, a.badgeId)
				end)
			end
			S.PlayerData.dirty(id)
		end
	end
end

function Collection.start()
	S.Net.handle("ClaimIndexReward", function(player, payload)
		return Collection.claim(player.UserId, payload.id)
	end)
end

return Collection
