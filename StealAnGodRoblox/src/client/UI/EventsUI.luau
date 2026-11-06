--[[
	EventsUI — current world event (timer + description), the next Divine Egg countdown and the
	list of all world events with what they bring.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local NF = require(Shared.Util.NumberFormatter)
local Kit = require(script.Parent.Kit)

local EventsUI = {}
local C
local T = Kit.Theme
local panel, header, specialLabel, body

function EventsUI.init(ctx)
	C = ctx
end

function EventsUI.render()
	for _, ch in body:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	for i, e in GameConfig.Events do
		local f = Kit.card(body, e.color, i)
		f.Size = UDim2.new(1, -10, 0, 96)
		local exclusive = Creatures.Events[e.id]
		Kit.label({ Text = "🎉 " .. e.name .. (C.State.World.event == e.id and "  (AGORA!)" or ""), Parent = f, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 4), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = e.color, MaxTextSize = 24 })
		Kit.label({ Text = e.desc, Parent = f, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 34), TextXAlignment = Enum.TextXAlignment.Left, Font = T.FontBody, MaxTextSize = 15 })
		Kit.label({ Text = "Criatura exclusiva: " .. (exclusive and (exclusive.name .. " (" .. exclusive.rarity .. ")") or "—"), Parent = f, Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 66), TextXAlignment = Enum.TextXAlignment.Left, Font = T.FontBody, TextColor3 = T.Gold, MaxTextSize = 15 })
	end
end

function EventsUI.start()
	panel = Kit.panel(C.Panels.screen, "🎉 EVENTOS", Color3.fromRGB(255, 90, 90))
	header = Kit.label({ Text = "", Parent = panel.content, Size = UDim2.new(1, 0, 0, 30), MaxTextSize = 24 })
	specialLabel = Kit.label({ Text = "", Parent = panel.content, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 26), Font = T.FontBody, MaxTextSize = 18, TextColor3 = Color3.fromRGB(255, 230, 120) })
	body = Kit.scroll(panel.content, { Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -66) })
	Kit.list(body, 8)
	Kit.padding(body, 4)
	C.Panels.register("Events", panel, EventsUI.render)
	RunService.Heartbeat:Connect(function()
		if not panel.frame.Visible then
			return
		end
		local w = C.State.World
		local now = C.State.now()
		if w.event and w.endsAt then
			local name = w.event
			for _, e in GameConfig.Events do
				if e.id == w.event then
					name = e.name
				end
			end
			header.Text = "Evento ativo: " .. name .. " — termina em " .. NF.time(w.endsAt - now)
		else
			header.Text = "Nenhum evento ativo no momento"
		end
		specialLabel.Text = w.nextSpecialAt and ("🥚 Próximo Ovo Divino em " .. NF.time(w.nextSpecialAt - now) .. " (a cada 5 minutos)") or ""
	end)
end

return EventsUI
