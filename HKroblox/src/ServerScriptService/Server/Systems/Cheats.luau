--!strict
-- Atalhos de teste. SÓ existem no Studio: em servidor real o remote nem é criado.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(script.Parent.Net)
local PlayerData = require(script.Parent.PlayerData)

local Cheats = {}

function Cheats.start(deps: { restore: (Player) -> (), hurtBoss: (Player, number) -> () })
	if not RunService:IsStudio() then
		return
	end
	Net.on("Cheat", 4, 4, function(player: Player, action: unknown)
		if typeof(action) ~= "string" then
			return
		end
		if action == "restore" then
			deps.restore(player)
		elseif action == "cacos" then
			local profile = PlayerData.get(player)
			if profile then
				profile.cacos = math.min(9999999, profile.cacos + 100)
				PlayerData.publish(player)
			end
		elseif action == "unlock" then
			local profile = PlayerData.get(player)
			if profile then
				profile.abilities.wings = true
				profile.abilities.claw = true
				PlayerData.publish(player)
			end
		elseif action == "god" then
			local character = player.Character
			if character then
				character:SetAttribute("InvulnUntil", workspace:GetServerTimeNow() + 900)
			end
		elseif action == "hurtboss" then
			deps.hurtBoss(player, 6)
		elseif action == "soul" then
			player:SetAttribute("Soul", Config.Soul.Max)
		end
	end)
end

return Cheats
