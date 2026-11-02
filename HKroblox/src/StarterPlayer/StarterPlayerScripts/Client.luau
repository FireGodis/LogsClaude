--!strict
-- Ponto de entrada do cliente: só conecta os controladores.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Controllers = script:WaitForChild("Controllers")
local Net = require(Controllers.Net)
local Input = require(Controllers.Input)
local Audio = require(Controllers.Audio)
local CameraRig = require(Controllers.CameraRig)
local CombatFx = require(Controllers.CombatFx)
local Movement = require(Controllers.Movement)
local KnightAnim = require(Controllers.KnightAnim)
local HUD = require(Controllers.HUD)
local Menu = require(Controllers.Menu)
local Cutscene = require(Controllers.Cutscene)
local EnemyAnim = require(Controllers.EnemyAnim)
local Zone = require(Controllers.Zone)
local Dialogue = require(Controllers.Dialogue)

local player = Players.LocalPlayer

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

CameraRig.setFacingProvider(function()
	return Movement.getInfo().facing
end)
CameraRig.start()
CombatFx.hooks.hitStop = Movement.hitStop
CombatFx.start()
Movement.start()
KnightAnim.start()
EnemyAnim.start()
Zone.start()
HUD.start()
Dialogue.start()
Input.buildTouchControls()

player.CharacterAdded:Connect(function(character: Model)
	Movement.bind(character)
end)
if player.Character then
	task.spawn(Movement.bind, player.Character)
end

Menu.show(function()
	Audio.startGame()
	Cutscene.play(function()
		HUD.setVisible(true)
		Zone.announceCurrent()
		Movement.setEnabled(true)
		Net.send("Ready")
	end)
end)

-- Atalhos de teste: só no Studio (o servidor também só aceita no Studio).
if RunService:IsStudio() and Net.exists("Cheat") then
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftBracket then
			Net.send("Cheat", "restore")
		elseif input.KeyCode == Enum.KeyCode.RightBracket then
			Net.send("Cheat", "cacos")
		elseif input.KeyCode == Enum.KeyCode.BackSlash then
			Net.send("Cheat", "soul")
		end
	end)
end
