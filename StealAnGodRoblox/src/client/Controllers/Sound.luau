--[[
	Sound — SFX and per-mythology ambient music with volume control and toggles.
	Sound ids come from GameConfig.Sounds (empty = silent). Never invent asset ids.
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Sound = {}
local C
local sfxOn, musicOn = true, true
local musicSound: Sound? = nil
local currentMusic = nil
local cache = {}

function Sound.init(ctx)
	C = ctx
end

function Sound.play(name: string, position: Vector3?)
	if not sfxOn then
		return
	end
	local id = GameConfig.Sounds[name]
	if not id or id == "" then
		return
	end
	if position then
		local a = Instance.new("Attachment")
		a.WorldPosition = position
		a.Parent = workspace.Terrain
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = 0.6
		s.RollOffMaxDistance = 120
		s.Parent = a
		s:Play()
		s.Ended:Connect(function()
			a:Destroy()
		end)
		task.delay(6, function()
			if a.Parent then
				a:Destroy()
			end
		end)
		return
	end
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = 0.5
		s.Parent = SoundService
		cache[name] = s
	end
	s:Play()
end

function Sound.music(mythology: string)
	currentMusic = mythology
	local id = GameConfig.Sounds["Music" .. mythology] or ""
	if not musicSound then
		musicSound = Instance.new("Sound")
		musicSound.Name = "SAG_Music"
		musicSound.Looped = true
		musicSound.Volume = 0.25
		musicSound.Parent = SoundService
	end
	local m = musicSound :: Sound
	if m.SoundId ~= id then
		m:Stop()
		m.SoundId = id
	end
	if musicOn and id ~= "" and not m.IsPlaying then
		m:Play()
	end
end

function Sound.setEnabled(sfx: boolean, music: boolean)
	sfxOn = sfx
	musicOn = music
	local KitModule = require(script.Parent.Parent.UI.Kit)
	KitModule.sfxEnabled = sfx
	if musicSound then
		if music then
			Sound.music(currentMusic or "Hub")
		else
			musicSound:Stop()
		end
	end
end

function Sound.start()
	C.State.Changed:Connect(function(d, partial)
		if not partial and d.settings then
			Sound.setEnabled(d.settings.sfx ~= false, d.settings.music ~= false)
		end
	end)
end

return Sound
