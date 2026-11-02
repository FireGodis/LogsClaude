--!strict
-- Música e efeitos. Reaproveita os sons existentes em SoundService.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Audio = {}

local cueSource: { [string]: string } = {
	jump = "Mare_Jump",
	land = "Mare_Jump",
	dash = "Mare_Dash",
	swing = "Mare_Swing",
	hit = "Mare_Impact",
	hurt = "Mare_Impact",
	pulse = "Mare_Pulse",
	heal = "Mare_Pulse",
	hover = "Mare_Jump",
	click = "Mare_Pulse",
	thud = "Mare_Impact",
	flap = "Mare_Swing",
	flap2 = "Mare_Jump",
	wall = "Mare_Impact",
	blip = "Mare_Jump",
	relic = "Mare_Pulse",
	spike = "Mare_Impact",
}
local cueVolume: { [string]: number } = {
	jump = 0.12, land = 0.05, dash = 0.2, swing = 0.22, hit = 0.3, hurt = 0.35, pulse = 0.28, heal = 0.2,
	hover = 0.05, click = 0.22, thud = 0.5,
	flap = 0.32, flap2 = 0.16, wall = 0.16, blip = 0.035, relic = 0.55, spike = 0.3,
}
local cuePitch: { [string]: number } = { land = 0.6, hurt = 0.7, heal = 1.5, hover = 2.1, click = 1.15, thud = 0.45, flap = 1.7, flap2 = 2.0, wall = 1.9, blip = 2.6, relic = 0.7, spike = 2.2 }

local folder = Instance.new("Folder")
folder.Name = "RK_Audio"
folder.Parent = SoundService

local menuMusic: Sound? = nil
local ambience: Sound? = nil

local function loop(templateName: string, volume: number, name: string): Sound?
	local template = SoundService:FindFirstChild(templateName)
	if not template or not template:IsA("Sound") then
		return nil
	end
	local sound = template:Clone()
	sound.Name = name
	sound.Volume = volume
	sound.Looped = true
	sound.Parent = folder
	sound:Play()
	return sound
end

function Audio.play(cue: string)
	local source = cueSource[cue]
	local template = if source then SoundService:FindFirstChild(source) else nil
	if not template or not template:IsA("Sound") then
		return
	end
	local sound = template:Clone()
	sound.Volume = cueVolume[cue] or 0.2
	sound.Looped = false
	sound.PlaybackSpeed = (cuePitch[cue] or 1) * (0.95 + math.random() * 0.1)
	sound.Parent = folder
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	Debris:AddItem(sound, 12)
end

-- Toca um som com tom/volume ajustados (voz dos NPCs, por exemplo).
function Audio.playWith(cue: string, pitchScale: number, volumeScale: number)
	local source = cueSource[cue]
	local template = if source then SoundService:FindFirstChild(source) else nil
	if not template or not template:IsA("Sound") then
		return
	end
	local sound = template:Clone()
	sound.Volume = (cueVolume[cue] or 0.2) * volumeScale
	sound.Looped = false
	sound.PlaybackSpeed = (cuePitch[cue] or 1) * pitchScale * (0.96 + math.random() * 0.08)
	sound.Parent = folder
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	Debris:AddItem(sound, 6)
end

function Audio.startMenu()
	if not menuMusic then
		menuMusic = loop("Mare_MenuMusic", 0.15, "MusicaDoMenu")
	end
end

function Audio.startGame()
	if not ambience then
		ambience = loop("Mare_GameAmbience", 0.055, "Ambiencia")
	end
	if menuMusic then
		TweenService:Create(menuMusic, TweenInfo.new(1.6), { Volume = 0.18 }):Play()
	end
end

return Audio
