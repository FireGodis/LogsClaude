--[[
	Biomes — authoritative region access. Clients make locked gates solid locally; the server
	verifies every 0.3s that nobody (player or bot) is inside a biome above their Speed and pushes
	intruders back to the gate. Also tracks the current biome of each actor.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Formulas = require(Shared.Util.Formulas)
local NumberFormatter = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)

local Biomes = {}
local S

function Biomes.init(sys)
	S = sys
end

function Biomes.biomeOf(id: number): number
	local pos = S.Actors.position(id)
	return pos and S.WorldBuilder.biomeAt(pos.Z) or 0
end

function Biomes.unlocked(id: number): number
	local p = S.PlayerData.get(id)
	return p and Formulas.unlockedBiome(p.speed) or 1
end

function Biomes.canEnter(id: number, biomeId: number): boolean
	return biomeId <= Biomes.unlocked(id)
end

function Biomes.start()
	task.spawn(function()
		while true do
			task.wait(0.3)
			for id in S.Actors.all() do
				local root = S.Actors.root(id)
				local st = S.Actors.state(id)
				if root and st then
					local b = S.WorldBuilder.biomeAt(root.Position.Z)
					if b > 0 and not Biomes.canEnter(id, b) then
						local z0 = S.WorldBuilder.biomeZ(b)
						st.teleportGrace = os.clock() + 2
						local char = S.Actors.character(id)
						if char then
							char:PivotTo(CFrame.new(root.Position.X * 0.3, root.Position.Y + 1, z0 - 8))
						end
						local player = S.Actors.player(id)
						if player then
							Net.fire(player, "Notify", { kind = "Warning", title = "Região bloqueada", text = "Requer " .. NumberFormatter.format(Formulas.biome(b).speedRequired) .. " Speed. Treine na esteira!" })
						end
					elseif b ~= st.currentBiome then
						st.currentBiome = b
					end
					if root.Position.Y > -10 then
						st.lastSafePosition = root.Position
					end
				end
			end
		end
	end)
end

return Biomes
