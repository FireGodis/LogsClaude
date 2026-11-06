--[[
	BotPopulation — keeps the world feeling alive.

	Target population = 6 participants; bots = min(5, max(0, 6 - realPlayers)):
	  1 real → 5 bots, 2 → 4, 3 → 3, 4 → 2, 5 → 1, 6 → 0, 7 → 0.

	• when a player joins: the target drops; a bot is asked to LEAVE gracefully (finishes carrying
	  its egg home, max 20s). If no base is free for the newcomer, a bot is removed immediately.
	• when a player leaves: new bots arrive gradually (8s apart) with a different personality and
	  a coherent starting progression (based on how far the real players are, never stronger).
	Simulated participants are NOT Players: they never appear in the Roblox player list/count.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local WeightedRandom = require(Shared.Util.WeightedRandom)

local BotPopulation = {}
local S

local bots = {} -- [id] = bot record
local nextId = -1
local nextSpawnAt = 0
local startedAt = os.clock()
local rng = Random.new()
local usedNames = {}
local PERSONALITIES = { "Beginner", "Collector", "Competitive", "Investor", "Explorer" }

function BotPopulation.init(sys)
	S = sys
end

function BotPopulation.count(includeLeaving: boolean?): number
	local n = 0
	for _, b in bots do
		if includeLeaving or not b.leaving then
			n += 1
		end
	end
	return n
end

function BotPopulation.list()
	return bots
end

local function pickName(): string
	for _ = 1, 30 do
		local base = GameConfig.BotNames[rng:NextInteger(1, #GameConfig.BotNames)]
		local name = rng:NextNumber() < 0.5 and base or (base .. rng:NextInteger(2, 99))
		if not usedNames[name] then
			usedNames[name] = true
			return name
		end
	end
	return "Player" .. rng:NextInteger(100, 999)
end

local function pickPersonality(): string
	local counts = {}
	for _, k in PERSONALITIES do
		counts[k] = 0
	end
	for _, b in bots do
		counts[b.personality] += 1
	end
	local options = {}
	local min = math.huge
	for _, k in PERSONALITIES do
		min = math.min(min, counts[k])
	end
	for _, k in PERSONALITIES do
		if counts[k] == min then
			table.insert(options, k)
		end
	end
	return options[rng:NextInteger(1, #options)]
end

-- Starting progression coherent with the humans in the server (never above the best human).
local function makeSeed()
	local maxUnlocked, sumUnlocked, n, playtime = 1, 0, 0, 0
	for _, player in Players:GetPlayers() do
		local p = S.PlayerData.get(player.UserId)
		if p then
			local u = Formulas.unlockedBiome(p.speed)
			maxUnlocked = math.max(maxUnlocked, u)
			sumUnlocked += u
			n += 1
			playtime += p.playtime
		end
	end
	local avg = n > 0 and sumUnlocked / n or 1
	local minutes = n > 0 and playtime / n / 60 or 0
	local biome = math.clamp(math.floor(avg + rng:NextNumber(-1, 0.3)), 1, maxUnlocked)
	local b = Balance.biomes[biome]
	local nextB = Balance.biomes[biome + 1]
	local speed = b.speedRequired + (nextB and (nextB.speedRequired - b.speedRequired) * rng:NextNumber(0, 0.5) or 0)
	if minutes < 3 then
		speed = rng:NextNumber(0, 90)
	end
	local baseLevel = math.clamp(math.ceil(biome * 0.6 + rng:NextNumber(-0.5, 0.5)), 1, 8)
	local trails = {}
	for i = 1, math.clamp(biome - 1 + rng:NextInteger(-1, 0), 0, #Balance.trails) do
		table.insert(trails, Balance.trails[i].id)
	end
	local petCount = minutes < 3 and rng:NextInteger(0, 2) or rng:NextInteger(2, math.min(Formulas.baseLevel(baseLevel).petSlots - 2, 3 + biome * 2))
	local pets = {}
	for _ = 1, petCount do
		local pb = rng:NextInteger(math.max(1, biome - 2), biome)
		local slot = WeightedRandom.index(Balance.speciesHatchWeights.normal, rng)
		local size = WeightedRandom.pick(Balance.sizes, function(s)
			return s.weight
		end, rng).name
		local mutation = WeightedRandom.pick(Balance.mutations, function(m)
			return m.weight
		end, rng).name
		table.insert(pets, { uid = S.PlayerData.newUid(), species = Creatures.ByBiome[pb][slot].id, size = size, mutation = mutation, at = os.time() })
	end
	return {
		speed = speed,
		treadmillTier = math.clamp(biome + rng:NextInteger(-1, 0), 1, #Balance.treadmills),
		trailsOwned = trails,
		equippedTrail = trails[#trails],
		baseLevel = baseLevel,
		pets = pets,
		gold = Balance.economy.startingGold,
		playtime = 99999,
	}, biome
end

local function placeCharacter(bot)
	local cf = S.Bases.spawnCFrame(bot.id) or CFrame.new(GameConfig.World.SpawnPosition)
	local model = S.BotAvatar.build(bot.id, bot.name, bot.seed)
	model:PivotTo(cf)
	model.Parent = Workspace.Runtime.Bots
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	local info = S.Actors.get(bot.id)
	if info then
		info.model = model
	end
	bot.model = model
	S.BotAvatar.setupAnimations(bot.id, model)
	S.Actors.CharacterAdded:Fire(bot.id, model)
end

function BotPopulation.spawn(): number?
	if S.Bases.freeCount() == 0 then
		return nil
	end
	local id = nextId
	nextId -= 1
	local name = pickName()
	local seed, biome = makeSeed()
	local profile = S.PlayerData.createBotProfile(id, seed)
	-- index for seeded pets
	for _, pet in profile.pets do
		local e = profile.index[pet.species] or { s = {}, m = {}, n = 0 }
		e.s[pet.size] = true
		e.m[pet.mutation] = true
		e.n += 1
		profile.index[pet.species] = e
	end
	local best = nil
	for _, pet in profile.pets do
		if not best or Formulas.petIncome(pet) > Formulas.petIncome(best) then
			best = pet
		end
	end
	profile.equippedPet = best and best.uid or nil
	S.Actors.register(id, { kind = "Bot", name = name })
	if not S.Bases.assign(id) then
		S.Actors.unregister(id)
		S.PlayerData.removeBotProfile(id)
		usedNames[name] = nil
		return nil
	end
	local bot = { id = id, name = name, personality = pickPersonality(), rng = Random.new(rng:NextInteger(1, 1e9)), seed = rng:NextInteger(1, 1e9) }
	bots[id] = bot
	placeCharacter(bot)
	-- a couple of eggs already incubating, like any player who has been around for a while
	for _ = 1, rng:NextInteger(0, 2) do
		local record = S.Eggs.makeRecord(math.max(1, biome - rng:NextInteger(0, 1)), "normal")
		S.Eggs.deposit(id, record, rng:NextInteger(10, Formulas.biome(record.biome).incubation))
	end
	S.BotBrain.add(bot)
	return id
end

function BotPopulation.despawn(id: number)
	local bot = bots[id]
	if not bot then
		return
	end
	bots[id] = nil
	usedNames[bot.name] = nil
	S.BotBrain.remove(id)
	S.BotAvatar.forget(id)
	S.Actors.unregister(id)
	S.PlayerData.removeBotProfile(id)
	if bot.model then
		bot.model:Destroy()
	end
end

-- Least disruptive bot to remove (not carrying, preferably idle/training).
local function chooseLeaver()
	local best, bestScore = nil, math.huge
	for id, b in bots do
		if not b.leaving then
			local st = S.Actors.state(id)
			local score = (st and st.carry) and 10 or 0
			if b.state == "Idle" or b.state == "Training" or b.state == "Thinking" then
				score -= 2
			end
			score += rng:NextNumber()
			if score < bestScore then
				best, bestScore = id, score
			end
		end
	end
	return best
end

local function reconcile()
	local real = #Players:GetPlayers()
	local target = Formulas.botCount(real)
	local now = os.clock()
	-- graceful leavers
	for id, b in bots do
		if b.leaving then
			local brain = S.BotBrain.get(id)
			if (brain and brain.readyToLeave) or now >= b.leaveDeadline then
				BotPopulation.despawn(id)
			end
		end
	end
	local active = BotPopulation.count(false)
	if active > target then
		for _ = 1, active - target do
			local id = chooseLeaver()
			if id then
				bots[id].leaving = true
				bots[id].leaveDeadline = now + Balance.bots.despawnGraceSeconds
				local brain = S.BotBrain.get(id)
				if brain then
					brain.leaving = true
				end
			end
		end
	elseif active < target and now >= nextSpawnAt and S.Bases.freeCount() > 0 then
		local warmup = now - startedAt < 45 -- first wave fills the world quickly
		nextSpawnAt = now + (warmup and 1.5 or Balance.bots.spawnDelaySeconds * rng:NextNumber(0.6, 1.4))
		BotPopulation.spawn()
	end
	-- respawn bots that fell out of the world
	for id, b in bots do
		local root = S.Actors.root(id)
		if (not root or root.Position.Y < -40 or not b.model or not b.model.Parent) and not b.respawning then
			b.respawning = true
			S.Eggs.dropCarry(id, "died")
			if b.model then
				b.model:Destroy()
			end
			S.BotAvatar.forget(id)
			task.delay(2, function()
				if bots[id] then
					placeCharacter(b)
					b.respawning = false
				end
			end)
		end
	end
end

function BotPopulation.start()
	Players.PlayerAdded:Connect(function()
		-- a real player always gets a base: free one immediately if needed
		if S.Bases.freeCount() == 0 then
			local id = nil
			for bid, b in bots do
				if b.leaving then
					id = bid
				end
			end
			id = id or chooseLeaver()
			if id then
				BotPopulation.despawn(id)
			end
		end
		task.defer(reconcile)
	end)
	Players.PlayerRemoving:Connect(function()
		nextSpawnAt = math.max(nextSpawnAt, os.clock() + Balance.bots.spawnDelaySeconds)
	end)
	-- first wave arrives quickly so the server never looks empty
	startedAt = os.clock()
	nextSpawnAt = os.clock() + 2
	task.spawn(function()
		while true do
			local ok, err = pcall(reconcile)
			if not ok then
				warn("[BotPopulation]", err)
			end
			task.wait(BotPopulation.count(true) < Formulas.botCount(#Players:GetPlayers()) and 1.5 or 2)
		end
	end)
end

return BotPopulation
