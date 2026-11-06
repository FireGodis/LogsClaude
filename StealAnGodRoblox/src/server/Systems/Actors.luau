--[[
	Actors — one registry for everybody who plays: real Players (id = UserId) and simulated
	participants (bots, id = negative number). Every gameplay system works on actor ids, so bots
	go through the exact same rules, prices and validations as humans.

	Also holds per-actor RUNTIME state (never saved): carried egg, buffs, stuns, cooldowns.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local Actors = {}
Actors.Added = Signal.new()
Actors.Removed = Signal.new()
Actors.CharacterAdded = Signal.new() -- (id, character) for players AND bots

local registry = {} -- [id] = {id, kind, player?, name, model?}
local runtime = {} -- [id] = state table

function Actors.init(_S) end

function Actors.register(id: number, info)
	info.id = id
	registry[id] = info
	runtime[id] = {
		carry = nil,
		buffs = {}, -- [name] = {untilT = os.clock() + d, value = x}
		trappedUntil = 0,
		stunUntil = 0,
		trapImmuneUntil = 0,
		hitImmuneUntil = 0,
		cooldowns = {},
		lastTrainPing = 0,
		lastSafePosition = nil,
		currentBiome = 0,
	}
	Actors.Added:Fire(id, info)
end

function Actors.unregister(id: number)
	if registry[id] then
		local info = registry[id]
		Actors.Removed:Fire(id, info)
		registry[id] = nil
		runtime[id] = nil
	end
end

function Actors.get(id: number)
	return registry[id]
end

function Actors.exists(id: number): boolean
	return registry[id] ~= nil
end

function Actors.state(id: number)
	return runtime[id]
end

function Actors.all()
	return registry
end

function Actors.ids(): { number }
	local list = {}
	for id in registry do
		table.insert(list, id)
	end
	return list
end

function Actors.isBot(id: number): boolean
	local a = registry[id]
	return a ~= nil and a.kind == "Bot"
end

function Actors.player(id: number): Player?
	local a = registry[id]
	return a and a.player or nil
end

function Actors.name(id: number): string
	local a = registry[id]
	if not a then
		return "?"
	end
	if a.player then
		return a.player.DisplayName
	end
	return a.name
end

function Actors.character(id: number): Model?
	local a = registry[id]
	if not a then
		return nil
	end
	if a.player then
		return a.player.Character
	end
	return a.model
end

function Actors.root(id: number): BasePart?
	local c = Actors.character(id)
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart? or nil
end

function Actors.humanoid(id: number): Humanoid?
	local c = Actors.character(id)
	return c and c:FindFirstChildOfClass("Humanoid") or nil
end

function Actors.position(id: number): Vector3?
	local r = Actors.root(id)
	return r and r.Position or nil
end

function Actors.alive(id: number): boolean
	local h = Actors.humanoid(id)
	return h ~= nil and h.Health > 0 and Actors.root(id) ~= nil
end

function Actors.fromCharacter(model: Instance?): number?
	if not model then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(model)
	if player then
		return registry[player.UserId] and player.UserId or nil
	end
	local botId = model:GetAttribute("ActorId")
	if typeof(botId) == "number" and registry[botId] then
		return botId
	end
	return nil
end

-- ---------- buffs ----------
function Actors.addBuff(id: number, name: string, duration: number, value: any)
	local st = runtime[id]
	if st then
		st.buffs[name] = { untilT = os.clock() + duration, value = value }
	end
end

function Actors.buff(id: number, name: string)
	local st = runtime[id]
	local b = st and st.buffs[name]
	if b and b.untilT > os.clock() then
		return b.value or true
	end
	return nil
end

function Actors.clearBuff(id: number, name: string)
	local st = runtime[id]
	if st then
		st.buffs[name] = nil
	end
end

function Actors.isStuck(id: number): boolean
	local st = runtime[id]
	if not st then
		return false
	end
	local now = os.clock()
	return st.trappedUntil > now or st.stunUntil > now
end

return Actors
