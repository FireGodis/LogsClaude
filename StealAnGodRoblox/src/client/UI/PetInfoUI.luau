--[[
	PetInfoUI — card shown when inspecting a pet displayed in a base (ProximityPrompt "Ver"):
	income/s, rarity, size, mutation, ability, description; owners can equip it from here.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Creatures = require(Shared.Config.Creatures)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Kit = require(script.Parent.Kit)

local PetInfoUI = {}
local C
local T = Kit.Theme
local panel

function PetInfoUI.init(ctx)
	C = ctx
end

function PetInfoUI.show(model: Model)
	local species = model:GetAttribute("Species")
	local c = species and Creatures.ById[species]
	if not c then
		return
	end
	local content = panel.content
	for _, ch in content:GetChildren() do
		if not ch:IsA("UIListLayout") then
			ch:Destroy()
		end
	end
	local size = model:GetAttribute("Size") or "Normal"
	local mutation = model:GetAttribute("Mutation") or "None"
	local mine = model:GetAttribute("Owner") == Players.LocalPlayer.UserId
	panel.title.Text = (mutation ~= "None" and (mutation .. " ") or "") .. (size ~= "Normal" and (size .. " ") or "") .. c.name
	local vp = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 160), LayoutOrder = 1, Parent = content })
	Kit.viewport(vp, ModelFactory.creature(species, size, mutation))
	Kit.label({ Text = c.rarity .. " • " .. c.mythology, Parent = content, Size = UDim2.new(1, 0, 0, 26), TextColor3 = Kit.rarityColor(c.rarity), MaxTextSize = 22, LayoutOrder = 2 })
	Kit.label({ Text = "💰 " .. NF.format(model:GetAttribute("Income") or 0) .. "/s   •   Tamanho " .. size .. " (x" .. Formulas.size(size).mult .. ")   •   " .. mutation .. " (x" .. Formulas.mutation(mutation).mult .. ")", Parent = content, Size = UDim2.new(1, 0, 0, 24), Font = T.FontBody, MaxTextSize = 17, LayoutOrder = 3 })
	Kit.label({ Text = "✦ " .. c.ab.name .. " — " .. c.ab.desc, Parent = content, Size = UDim2.new(1, 0, 0, 44), Font = T.FontBody, TextColor3 = Kit.mythColor(c.mythology), MaxTextSize = 16, LayoutOrder = 4 })
	Kit.label({ Text = c.desc, Parent = content, Size = UDim2.new(1, 0, 0, 36), Font = T.FontBody, TextColor3 = T.TextDim, MaxTextSize = 15, LayoutOrder = 5 })
	if mine then
		Kit.button({ Text = "EQUIPAR COMO COMPANHEIRO", color = T.Accent, Size = UDim2.new(0.8, 0, 0, 48), Parent = content, LayoutOrder = 6, MaxTextSize = 20, onClick = function()
			local ok, msg = Net.request("EquipPet", { uid = model:GetAttribute("Uid") })
			C.Notifications.toast(ok and "Reward" or "Warning", "Companheiro", ok and (c.name .. " equipado!") or (msg or ""))
		end })
	end
	C.Panels.open("PetInfo")
end

function PetInfoUI.start()
	panel = Kit.panel(C.Panels.screen, "PET", T.Accent, UDim2.fromScale(0.4, 0.62))
	Kit.list(panel.content, 6)
	C.Panels.register("PetInfo", panel)
end

return PetInfoUI
