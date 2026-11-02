--!strict
-- Ponto de entrada do servidor: só conecta os sistemas, sem lógica de jogo aqui.

local Players = game:GetService("Players")

local Systems = script:WaitForChild("Systems")
local Net = require(Systems.Net)
local PlayerData = require(Systems.PlayerData)
local WorldSystem = require(Systems.WorldSystem)
local Enemies = require(Systems.Enemies)
local Combat = require(Systems.Combat)
local Cheats = require(Systems.Cheats)

-- O personagem só nasce DEPOIS do perfil carregar (nada de jogar com dados padrão).
Players.CharacterAutoLoads = false

Net.makeAll()
Enemies.setPlayerDamage(Combat.damagePlayer)

PlayerData.onLoaded(function(player: Player, profile)
	if profile.flags["boss_vigia"] then
		Enemies.silenceBoss()
	end
	player.RespawnLocation = WorldSystem.spawnFor(profile)
	Combat.registerPlayer(player)
	player.CharacterAdded:Connect(function(character: Model)
		Combat.onCharacter(player, character)
	end)
	player:LoadCharacter()
end)

WorldSystem.start({ restore = Combat.restore, respawnEnemies = Enemies.respawnAll })
Enemies.start()
Combat.start()
Cheats.start({
	restore = Combat.restore,
	hurtBoss = function(player: Player, amount: number)
		Enemies.cheatDamageBoss(player, amount)
	end,
})
PlayerData.start() -- por último: callbacks já registrados
