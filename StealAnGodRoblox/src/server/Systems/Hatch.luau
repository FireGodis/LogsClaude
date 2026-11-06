--[[
	Hatch — turns finished eggs into creatures (online and offline).

	Species is rolled at hatch time from the egg's biome table (normal/rare/special weights) or is
	the event creature for event eggs. Size and mutation were rolled when the egg spawned (they are
	visible on the egg). Offline: on join, every egg whose hatchAt passed is hatched server-side.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Creatures = require(Shared.Config.Creatures)
local Formulas = require(Shared.Util.Formulas)
local WeightedRandom = require(Shared.Util.WeightedRandom)
local Net = require(Shared.Util.Net)

local Hatch = {}
local S
local readyWarned = {}

function Hatch.init(sys)
	S = sys
end

function Hatch.rollSpecies(record): string
	if record.variant == "event" and record.event then
		local c = Creatures.Events[record.event]
		if c then
			return c.id
		end
	end
	local weights = Balance.speciesHatchWeights[record.variant] or Balance.speciesHatchWeights.normal
	local slot = WeightedRandom.index(weights)
	return Creatures.ByBiome[record.biome][slot].id
end

-- Event Boost: event eggs get a second mutation roll, keeping the better one.
local function improveMutation(id: number, record): string
	local p = S.PlayerData.get(id)
	if record.variant == "event" and p and S.Economy.boostActive(p, "event") then
		local other = S.Eggs.rollMutation(false)
		if Formulas.mutation(other).mult > Formulas.mutation(record.mutation).mult then
			return other
		end
	end
	return record.mutation
end

-- Hatches one slot. Returns the pet or nil (capacity full).
function Hatch.hatchSlot(id: number, slotKey: string, silent: boolean?)
	local p = S.PlayerData.get(id)
	local record = p and p.eggs[slotKey]
	if not record or S.Theft.isBeingStolen(id, slotKey) then
		return nil
	end
	if #p.pets >= S.Pets.capacity(id) then
		if not record.ready then
			record.ready = true
			S.Eggs.renderBaseEggs(id)
			S.PlayerData.dirty(id)
		end
		if not silent and (not readyWarned[id] or os.clock() - readyWarned[id] > 20) then
			readyWarned[id] = os.clock()
			local player = S.Actors.player(id)
			if player then
				Net.fire(player, "Notify", { kind = "Warning", title = "Ovo pronto, mas sem espaço!", text = "Venda um pet ou melhore a base para liberar espaço." })
			end
		end
		return nil
	end
	local species = Hatch.rollSpecies(record)
	local pet = {
		uid = S.PlayerData.newUid(),
		species = species,
		size = record.size,
		mutation = improveMutation(id, record),
		tier = (record.variant == "event") and (record.tier or record.biome) or nil,
		at = os.time(),
	}
	p.eggs[slotKey] = nil
	local isNew = S.Pets.add(id, pet)
	p.stats.hatched += 1
	local c = Creatures.ById[species]
	if c and c.rarity == "Divine" then
		p.stats.divinePets += 1
	end
	S.Eggs.renderBaseEggs(id)
	S.PlayerData.dirty(id)
	S.Collection.checkAchievements(id)
	S.Tutorial.progress(id, "Hatch")
	if not silent then
		local cf = S.Bases.slotCFrame(id, tonumber(slotKey) :: number)
		Net.fireAll("Effect", { kind = "HatchBurst", position = cf and cf.Position, rarity = c and c.rarity, mythology = c and c.mythology, owner = id })
		local player = S.Actors.player(id)
		if player then
			Net.fire(player, "HatchReveal", {
				species = species, size = pet.size, mutation = pet.mutation, tier = pet.tier,
				income = Formulas.petIncome(pet), isNew = isNew, rarity = c and c.rarity,
			})
		end
	end
	return pet
end

function Hatch.reduceAll(id: number, seconds: number): number
	local p = S.PlayerData.get(id)
	if not p then
		return 0
	end
	local now = os.time()
	local n = 0
	for slotKey, record in p.eggs do
		if record.hatchAt and record.hatchAt > now and not S.Theft.isBeingStolen(id, slotKey) then
			local remaining = record.hatchAt - now
			local cut = math.min(seconds, math.floor(remaining * 0.5) + 1) -- never more than half at once
			record.hatchAt -= cut
			n += 1
		end
	end
	S.Eggs.renderBaseEggs(id)
	S.PlayerData.dirty(id)
	return n
end

function Hatch.hatchInstant(id: number): boolean
	local p = S.PlayerData.get(id)
	if not p then
		return false
	end
	local bestKey, bestLeft = nil, -1
	local now = os.time()
	for slotKey, record in p.eggs do
		local left = (record.hatchAt or now) - now
		if left > bestLeft and not S.Theft.isBeingStolen(id, slotKey) then
			bestKey, bestLeft = slotKey, left
		end
	end
	if not bestKey then
		return false
	end
	p.eggs[bestKey].hatchAt = now
	return Hatch.hatchSlot(id, bestKey) ~= nil or p.eggs[bestKey] ~= nil
end

-- Offline processing at join: hatch everything whose timer ran out while away.
function Hatch.processOffline(id: number)
	local p = S.PlayerData.get(id)
	local hatched = {}
	if not p then
		return hatched
	end
	local now = os.time()
	local keys = {}
	for slotKey, record in p.eggs do
		if record.hatchAt and record.hatchAt <= now then
			table.insert(keys, slotKey)
		end
	end
	table.sort(keys, function(a, b)
		return (p.eggs[a].hatchAt or 0) < (p.eggs[b].hatchAt or 0)
	end)
	for _, k in keys do
		local pet = Hatch.hatchSlot(id, k, true)
		if pet then
			table.insert(hatched, { species = pet.species, size = pet.size, mutation = pet.mutation })
		end
	end
	return hatched
end

function Hatch.start()
	S.PlayerData.Loaded:Connect(function(id, _profile, info)
		local hatched = Hatch.processOffline(id)
		local gold = S.Economy.applyOffline(id, info.secondsAway)
		if (info.secondsAway >= 60 and (gold > 0 or #hatched > 0)) then
			local player = S.Actors.player(id)
			if player then
				task.delay(2.5, function()
					Net.fire(player, "OfflineSummary", { seconds = math.min(info.secondsAway, Balance.economy.offlineCapSeconds), rawSeconds = info.secondsAway, gold = gold, hatched = hatched })
				end)
			end
		end
		S.PlayerData.dirty(id)
	end)
	S.Actors.Removed:Connect(function(id)
		readyWarned[id] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for id in S.Actors.all() do
				local p = S.PlayerData.get(id)
				if p then
					for slotKey, record in p.eggs do
						if record.hatchAt and record.hatchAt <= now then
							Hatch.hatchSlot(id, slotKey)
						end
					end
				end
			end
		end
	end)
end

return Hatch
