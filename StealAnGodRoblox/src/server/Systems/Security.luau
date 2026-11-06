--[[
	Security — server-side sanity layer.
	  • logs rate-limit violations coming from Net
	  • tracks impossible movement (speed hacks / teleports) and marks the actor as "suspect"
	    for a few seconds: suspect actors cannot pick up, steal or deposit eggs
	  • provides distance validation helpers used by every gameplay system
	Never bans on heuristics — it blocks the invalid operation and protects the economy.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Util.Net)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)

local Security = {}
local S

local strikes = {} -- [player] = count
local suspectUntil = {} -- [id] = os.clock()
local lastPos = {} -- [id] = {pos, t}
local log = {}

local function record(kind: string, who: string, detail: string)
	local entry = string.format("[%s] %s %s: %s", os.date("!%H:%M:%S"), kind, who, detail)
	table.insert(log, entry)
	if #log > 200 then
		table.remove(log, 1)
	end
	warn("[Security]", entry)
end

function Security.init(sys)
	S = sys
	Net.onRateLimited = function(player, name)
		strikes[player] = (strikes[player] or 0) + 1
		if strikes[player] % 20 == 1 then
			record("RateLimit", player.Name, name .. " x" .. strikes[player])
		end
	end
end

function Security.isSuspect(id: number): boolean
	return (suspectUntil[id] or 0) > os.clock()
end

function Security.flag(id: number, reason: string)
	suspectUntil[id] = os.clock() + 8
	record("Flag", S.Actors.name(id), reason)
end

-- Distance check with latency tolerance.
function Security.within(id: number, position: Vector3, maxDistance: number): boolean
	local pos = S.Actors.position(id)
	if not pos then
		return false
	end
	return (pos - position).Magnitude <= maxDistance + (S.Actors.isBot(id) and 0 or 4)
end

function Security.recentLog()
	return table.clone(log)
end

function Security.start()
	Players.PlayerRemoving:Connect(function(p)
		strikes[p] = nil
		suspectUntil[p.UserId] = nil
		lastPos[p.UserId] = nil
	end)
	-- movement sanity (players only; bots are server-driven)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local id = player.UserId
				local profile = S.PlayerData.get(id)
				local pos = S.Actors.position(id)
				if profile and pos then
					local prev = lastPos[id]
					if prev and now - prev.t > 0 then
						local horizontal = Vector3.new(pos.X - prev.pos.X, 0, pos.Z - prev.pos.Z).Magnitude
						local allowed = (Formulas.walkSpeed(profile.speed) * 1.6 + 60) * (now - prev.t)
						local st = S.Actors.state(id)
						local exempt = st and st.teleportGrace and st.teleportGrace > now
						if horizontal > allowed and not exempt then
							Security.flag(id, string.format("moved %.0f studs in %.2fs", horizontal, now - prev.t))
						end
					end
					lastPos[id] = { pos = pos, t = now }
				else
					lastPos[id] = nil
				end
			end
		end
	end)
end

return Security
