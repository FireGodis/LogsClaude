--[[
	State — client-side mirror of the player's profile snapshot (read-only; the server is the
	authority). Merges partial money/speed updates and fires Changed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Util.Net)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local State = {}
State.data = nil
State.Changed = Signal.new() -- (data, isPartial)
State.World = { event = nil, endsAt = nil, nextSpecialAt = nil }
State.WorldChanged = Signal.new()

function State.start()
	Net.listen("State", function(snap)
		if snap.partial then
			if State.data then
				for k, v in snap do
					if k ~= "partial" then
						State.data[k] = v
					end
				end
				State.Changed:Fire(State.data, true)
			end
		else
			State.data = snap
			State.Changed:Fire(State.data, false)
		end
	end)
	Net.listen("WorldState", function(ws)
		State.World.event = ws.event
		State.World.endsAt = ws.endsAt
		if ws.nextSpecialAt then
			State.World.nextSpecialAt = ws.nextSpecialAt
		end
		State.WorldChanged:Fire(State.World)
	end)
end

function State.get()
	return State.data
end

function State.now(): number
	return workspace:GetServerTimeNow()
end

function State.hasPass(key: string): boolean
	local d = State.data
	return d ~= nil and d.passes ~= nil and table.find(d.passes, key) ~= nil
end

return State
