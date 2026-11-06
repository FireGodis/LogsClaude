--[[
	STEAL AN GOD — the single server entry point.

	Two-phase boot (roblox-dev architecture skill):
	  1. build the world (if not already saved in the place)
	  2. require every system, call init(S) on all of them (wiring only, no yielding loops)
	  3. call start() on all of them (loops, connections that depend on other systems)
	Systems talk through the shared registry S (S.Economy, S.Eggs, ...) — no _G, no require cycles.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script
local Net = require(ReplicatedStorage.Shared.Util.Net)
local WorldBuilder = require(Server.World.WorldBuilder)

-- 1. World
local t0 = os.clock()
WorldBuilder.build(false)
WorldBuilder.ensureRuntime()
print(string.format("[SAG] World ready in %.2fs", os.clock() - t0))

-- 2. Remotes
Net.serverInit()

-- 3. Systems (explicit order = deterministic init/start)
local ORDER = {
	"Security", "Actors", "PlayerData", "Monetization", "Economy", "Bases", "Biomes", "Speed", "Trails",
	"Eggs", "Theft", "Hatch", "Pets", "Guardians", "Abilities", "Traps", "Events", "Collection",
	"Tutorial", "Leaderboard",
}
local BOT_ORDER = { "BotNavigator", "BotAvatar", "BotBrain", "BotPopulation" }

local S = {}
S.WorldBuilder = WorldBuilder
S.Net = Net

for _, name in ORDER do
	S[name] = require(Server.Systems:FindFirstChild(name))
end
for _, name in BOT_ORDER do
	S[name] = require(Server.Bots:FindFirstChild(name))
end

local function each(list, method)
	for _, name in list do
		local sys = S[name]
		if typeof(sys[method]) == "function" then
			if method == "init" then
				sys.init(S)
			else
				task.spawn(sys.start)
			end
		end
	end
end

each(ORDER, "init")
each(BOT_ORDER, "init")
each(ORDER, "start")
each(BOT_ORDER, "start")

ServerScriptService:SetAttribute("SAG_Ready", true)
print("[SAG] STEAL AN GOD server started")
