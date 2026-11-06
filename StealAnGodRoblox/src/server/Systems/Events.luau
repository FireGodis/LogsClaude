--[[
	Events — the global server clock for:
	  • SPECIAL EGG every 5 minutes: 15s countdown announcement, dramatic spawn, a beam marker
	    visible across the map; everybody races for it (no teleport).
	  • WORLD EVENTS (Eclipse Divino, Ragnarok, Ascensão Solar, Fúria dos Deuses): announcement,
	    timer, lighting/ambience change, waves of exclusive event eggs, end sequence.
	New events: add an entry to GameConfig.Events and (optionally) hooks to EVENT_HOOKS below.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local WeightedRandom = require(Shared.Util.WeightedRandom)
local Net = require(Shared.Util.Net)

local Events = {}
local S

Events.current = nil -- {id, name, endsAt}
Events.special = nil -- {eggId, position, biome, spawnedAt}
Events.nextSpecialAt = 0

local EVENT_HOOKS = {
	FuryOfGods = {
		onStart = function()
			S.Guardians.setFury(true)
		end,
		onEnd = function()
			S.Guardians.setFury(false)
		end,
	},
}

function Events.init(sys)
	S = sys
end

local function biomeFolder(b: number)
	return Workspace.Map:FindFirstChild("Biome_" .. b)
end

local function randomSpot(b: number): Vector3
	local f = biomeFolder(b)
	local spots = f and f:FindFirstChild("SpawnSpots")
	local children = spots and spots:GetChildren() or {}
	if #children > 0 then
		return children[math.random(1, #children)].Position
	end
	local z0, z1 = S.WorldBuilder.biomeZ(b)
	return Vector3.new(math.random(-30, 30), 1, math.random(z0 + 20, z1 - 20))
end

-- Biomes weighted by how many participants can reach them (so the race is fair for most).
local function chooseBiome(): number
	local weights = {}
	for b = 1, #Balance.biomes do
		weights[b] = b == 1 and 0.5 or 0
	end
	for id in S.Actors.all() do
		local p = S.PlayerData.get(id)
		if p then
			local u = Formulas.unlockedBiome(p.speed)
			for b = 1, u do
				weights[b] += (b == u) and 2 or 0.4
			end
		end
	end
	return WeightedRandom.index(weights)
end

-- ===================== SPECIAL EGG =====================
function Events.onSpecialTaken()
	Events.special = nil
end

function Events.onSpecialExpired()
	Events.special = nil
	Net.fireAll("Announce", { type = "SpecialEggGone" })
end

local function spawnSpecial()
	local b = chooseBiome()
	local pos = randomSpot(b)
	local record = S.Eggs.makeRecord(b, "special")
	local entry = S.Eggs.spawnWorldEgg(record, CFrame.new(pos + Vector3.new(0, 0.3, 0)), "special", { lifetime = Balance.specialEgg.lifetimeSeconds })
	-- vertical light beam marker
	local beam = Instance.new("Part")
	beam.Name = "SpecialBeam"
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 235, 140)
	beam.Transparency = 0.55
	beam.Size = Vector3.new(3, 300, 3)
	beam.CFrame = CFrame.new(pos + Vector3.new(0, 150, 0))
	beam.Parent = entry.model
	Events.special = { eggId = entry.id, position = pos, biome = b, spawnedAt = os.clock() }
	Net.fireAll("Announce", { type = "SpecialEggSpawned", position = pos, biome = b, biomeName = Formulas.biome(b).name, size = record.size, mutation = record.mutation })
	S.BotBrain.onSpecialEgg(Events.special)
end

-- ===================== WORLD EVENTS =====================
local eventIndex = 0

local function runWorldEvent()
	eventIndex = eventIndex % #GameConfig.Events + 1
	local def = GameConfig.Events[eventIndex]
	local cfg = Balance.worldEvents
	local endsAt = os.time() + cfg.durationSeconds
	Events.current = { id = def.id, name = def.name, endsAt = endsAt }
	Net.fireAll("WorldState", { event = def.id, endsAt = endsAt })
	Net.fireAll("Announce", { type = "EventStart", event = def.id, name = def.name, desc = def.desc, endsAt = endsAt })
	local hooks = EVENT_HOOKS[def.id]
	if hooks and hooks.onStart then
		hooks.onStart()
	end
	local waves = math.floor(cfg.durationSeconds / cfg.waveSeconds)
	for _ = 1, waves do
		for _ = 1, cfg.eventEggsPerWave do
			local b = chooseBiome()
			local record = S.Eggs.makeRecord(b, "event", { event = def.id, tier = b })
			S.Eggs.spawnWorldEgg(record, CFrame.new(randomSpot(b) + Vector3.new(math.random(-6, 6), 0.3, math.random(-6, 6))), "event", { lifetime = cfg.waveSeconds + 30 })
		end
		Net.fireAll("Announce", { type = "EventWave", event = def.id, name = def.name })
		task.wait(cfg.waveSeconds)
	end
	if hooks and hooks.onEnd then
		hooks.onEnd()
	end
	Events.current = nil
	Net.fireAll("WorldState", { event = nil })
	Net.fireAll("Announce", { type = "EventEnd", name = def.name })
end

function Events.start()
	-- late joiners receive the current world state
	S.PlayerData.Loaded:Connect(function(id)
		local player = S.Actors.player(id)
		if player then
			task.delay(3, function()
				local cur = Events.current
				Net.fire(player, "WorldState", { event = cur and cur.id or nil, endsAt = cur and cur.endsAt or nil, nextSpecialAt = Events.nextSpecialAt })
				if Events.special then
					Net.fire(player, "Announce", { type = "SpecialEggSpawned", position = Events.special.position, biome = Events.special.biome, biomeName = Formulas.biome(Events.special.biome).name, quiet = true })
				end
			end)
		end
	end)

	-- special egg loop
	task.spawn(function()
		local cfg = Balance.specialEgg
		while true do
			Events.nextSpecialAt = os.time() + cfg.intervalSeconds
			Net.fireAll("WorldState", { event = Events.current and Events.current.id or nil, endsAt = Events.current and Events.current.endsAt or nil, nextSpecialAt = Events.nextSpecialAt })
			task.wait(cfg.intervalSeconds - cfg.warningSeconds)
			Net.fireAll("Announce", { type = "SpecialEggSoon", seconds = cfg.warningSeconds })
			task.wait(cfg.warningSeconds)
			if Events.special then
				S.Eggs.removeWorldEgg(Events.special.eggId)
				Events.special = nil
			end
			local ok, err = pcall(spawnSpecial)
			if not ok then
				warn("[Events] special egg failed:", err)
			end
		end
	end)

	-- world event loop
	task.spawn(function()
		task.wait(Balance.worldEvents.firstDelaySeconds)
		while true do
			local ok, err = pcall(runWorldEvent)
			if not ok then
				warn("[Events] world event failed:", err)
				Events.current = nil
			end
			task.wait(Balance.worldEvents.intervalSeconds - Balance.worldEvents.durationSeconds)
		end
	end)
end

return Events
