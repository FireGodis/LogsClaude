--[[
	SettingsUI — music, SFX, visual-effects quality (High/Low particle budget) and camera shake.
	Saved in the profile through the validated SaveSettings action.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Util.Net)
local Kit = require(script.Parent.Kit)

local SettingsUI = {}
local C
local T = Kit.Theme
local panel, body
local settings = { music = true, sfx = true, vfx = "High", shake = true }

function SettingsUI.init(ctx)
	C = ctx
end

local function apply()
	C.Sound.setEnabled(settings.sfx, settings.music)
	C.Effects.setQuality(settings.vfx)
	C.Effects.setShake(settings.shake)
end

local function save()
	apply()
	Net.request("SaveSettings", { music = settings.music, sfx = settings.sfx, vfx = settings.vfx, shake = settings.shake })
	SettingsUI.render()
end

function SettingsUI.render()
	for _, ch in body:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	local rows = {
		{ "🎵 Música", settings.music and "LIGADA" or "DESLIGADA", settings.music, function()
			settings.music = not settings.music
			save()
		end },
		{ "🔊 Efeitos sonoros", settings.sfx and "LIGADOS" or "DESLIGADOS", settings.sfx, function()
			settings.sfx = not settings.sfx
			save()
		end },
		{ "✨ Qualidade de efeitos", settings.vfx == "High" and "ALTA" or "BAIXA (dispositivos fracos)", settings.vfx == "High", function()
			settings.vfx = settings.vfx == "High" and "Low" or "High"
			save()
		end },
		{ "📳 Tremor de câmera", settings.shake and "LIGADO" or "DESLIGADO", settings.shake, function()
			settings.shake = not settings.shake
			save()
		end },
	}
	for i, r in rows do
		local f = Kit.card(body, T.Accent, i)
		f.Size = UDim2.new(1, -10, 0, 64)
		Kit.label({ Text = r[1], Parent = f, Size = UDim2.new(0.55, 0, 1, -10), Position = UDim2.fromOffset(14, 5), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 22 })
		Kit.button({ Text = r[2], color = r[3] and T.Good or T.Bad, Size = UDim2.new(0.4, 0, 0, 46), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = f, MaxTextSize = 18, onClick = r[4] })
	end
	local d = C.State.get()
	if d and not d.saveable then
		Kit.label({ Text = "⚠ Progresso temporário: o DataStore não está disponível neste servidor.", Parent = body, Size = UDim2.new(1, -10, 0, 40), TextColor3 = T.Bad, MaxTextSize = 16, LayoutOrder = 99, Font = T.FontBody })
	end
end

function SettingsUI.start()
	panel = Kit.panel(C.Panels.screen, "⚙ CONFIGURAÇÕES", Color3.fromRGB(160, 160, 190), UDim2.fromScale(0.45, 0.55))
	body = Kit.scroll(panel.content)
	Kit.list(body, 8)
	Kit.padding(body, 4)
	C.Panels.register("Settings", panel, SettingsUI.render)
	local loaded = false
	C.State.Changed:Connect(function(d, partial)
		if not partial and d.settings and not loaded then
			loaded = true
			settings.music = d.settings.music ~= false
			settings.sfx = d.settings.sfx ~= false
			settings.vfx = d.settings.vfx == "Low" and "Low" or "High"
			settings.shake = d.settings.shake ~= false
			apply()
		end
	end)
end

return SettingsUI
