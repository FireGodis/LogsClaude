--[[
	Formulas — pure balance math shared by server (authoritative) and client (display only).
	Every number comes from Config/Balance.json so designers tune one file.
]]

local Config = script.Parent.Parent:WaitForChild("Config")
local Balance = require(Config:WaitForChild("Balance"))
local Creatures = require(Config:WaitForChild("Creatures"))

local Formulas = {}

local sizeByName = {}
for i, s in ipairs(Balance.sizes) do
	s.index = i
	sizeByName[s.name] = s
end
local mutationByName = {}
for i, m in ipairs(Balance.mutations) do
	m.index = i
	mutationByName[m.name] = m
end
local rarityByName = {}
for i, r in ipairs(Balance.rarities) do
	r.index = i
	rarityByName[r.name] = r
end
local trailById = {}
for _, t in ipairs(Balance.trails) do
	trailById[t.id] = t
end
for _, t in ipairs(Balance.rewardTrails) do
	trailById[t.id] = t
end

Formulas.Balance = Balance

function Formulas.size(name: string?)
	return sizeByName[name or "Normal"] or sizeByName.Normal
end
function Formulas.mutation(name: string?)
	return mutationByName[name or "None"] or mutationByName.None
end
function Formulas.rarity(name: string?)
	return rarityByName[name or "Common"] or rarityByName.Common
end
function Formulas.trail(id: string?)
	if id == nil then
		return nil
	end
	return trailById[id]
end
function Formulas.biome(id: number)
	return Balance.biomes[math.clamp(id, 1, #Balance.biomes)]
end
function Formulas.treadmill(tier: number)
	return Balance.treadmills[math.clamp(tier, 1, #Balance.treadmills)]
end
function Formulas.baseLevel(level: number)
	return Balance.baseLevels[math.clamp(level, 1, #Balance.baseLevels)]
end

-- Highest biome unlocked by a Speed value.
function Formulas.unlockedBiome(speed: number): number
	local unlocked = 1
	for _, b in ipairs(Balance.biomes) do
		if speed >= b.speedRequired then
			unlocked = b.id
		end
	end
	return unlocked
end

-- Movement speed derived from training Speed (log scaled + capped) and carry penalty.
function Formulas.walkSpeed(speed: number, carrySize: string?, penaltyReduction: number?, mult: number?): number
	local cfg = Balance.speed
	local ws = cfg.baseWalkSpeed + cfg.walkLogFactor * math.log10(1 + math.max(0, speed))
	ws = math.min(ws, cfg.maxWalkSpeed)
	if carrySize then
		local penalty = cfg.carryPenaltyBySize[carrySize] or 0.2
		penalty *= 1 - math.clamp(penaltyReduction or 0, 0, 0.9)
		ws *= 1 - penalty
	end
	ws *= mult or 1
	return math.min(ws, cfg.maxWalkSpeed * 1.4)
end

-- Base income of a species (before size/mutation). Event creatures scale with stored tier.
function Formulas.speciesBaseIncome(speciesId: string, tier: number?): number
	local c = Creatures.ById[speciesId]
	if not c then
		return 0
	end
	if c.biome == 0 then
		local b = Formulas.biome(tier or 1)
		return b.baseIncome * Balance.worldEvents.eventIncomeBiomeBonus
	end
	return Formulas.biome(c.biome).baseIncome * Balance.speciesIncomeMultiplier[c.slot]
end

-- Income/s of a single pet record {species, size, mutation, tier}.
function Formulas.petIncome(pet): number
	local c = Creatures.ById[pet.species]
	if not c then
		return 0
	end
	local base = Formulas.speciesBaseIncome(pet.species, pet.tier)
	local mult = Formulas.rarity(c.rarity).mult * Formulas.size(pet.size).mult * Formulas.mutation(pet.mutation).mult
	local dr = Balance.diminishingReturns
	if mult > dr.threshold then
		mult = dr.threshold + (mult - dr.threshold) ^ dr.exponent
	end
	return base * mult
end

-- Sum of global modifiers, capped so stacking never breaks the economy.
function Formulas.globalIncomeMultiplier(mods): number
	local e = Balance.economy
	local m = 1
	if mods.vip then
		m *= e.vipMultiplier
	end
	if mods.moneyPass then
		m *= e.moneyPassMultiplier
	end
	if mods.moneyBoost then
		m *= e.moneyBoostMultiplier
	end
	if mods.abilityMult then
		m *= mods.abilityMult
	end
	return math.min(m, Balance.globalModifierCap)
end

function Formulas.totalIncome(pets, mods): number
	local sum = 0
	for _, pet in pets do
		sum += Formulas.petIncome(pet)
	end
	return sum * Formulas.globalIncomeMultiplier(mods or {})
end

-- Speed gained per treadmill step.
function Formulas.trainGain(treadmillTier: number, trailId: string?, mods): number
	local per = Formulas.treadmill(treadmillTier).perStep
	local trail = Formulas.trail(trailId)
	local m = trail and trail.mult or 1
	local e = Balance.economy
	if mods then
		if mods.trainingPass then
			m *= e.trainingPassMultiplier
		end
		if mods.trainingBoost then
			m *= e.trainingBoostMultiplier
		end
		if mods.abilityMult then
			m *= mods.abilityMult
		end
	end
	return per * m
end

function Formulas.incubationSeconds(biomeId: number, sizeName: string, growthPass: boolean, special: boolean?): number
	local base = special and Balance.specialEgg.incubation or Formulas.biome(biomeId).incubation
	local t = base * Formulas.size(sizeName).incubationMult
	if growthPass then
		t *= Balance.economy.growthPassMultiplier
	end
	return math.max(5, math.floor(t))
end

function Formulas.offlineEarnings(incomePerSecond: number, secondsAway: number): number
	local e = Balance.economy
	local secs = math.clamp(secondsAway, 0, e.offlineCapSeconds)
	return math.floor(incomePerSecond * secs * e.offlineRate)
end

function Formulas.sellValue(pet): number
	return math.floor(Formulas.petIncome(pet) * Balance.economy.sellSecondsOfIncome)
end

-- Dynamic bot population: min(maxBots, max(0, target - realPlayers)).
function Formulas.botCount(realPlayers: number): number
	local b = Balance.bots
	return math.min(b.maxBots, math.max(0, b.targetPopulation - realPlayers))
end

function Formulas.incubatorCount(baseLevel: number, extraBasePass: boolean): number
	local n = Formulas.baseLevel(baseLevel).incubators
	if extraBasePass then
		n += Balance.economy.extraBaseIncubators
	end
	return n
end

return Formulas
