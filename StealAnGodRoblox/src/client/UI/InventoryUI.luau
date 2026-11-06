--[[
	InventoryUI — your creatures: 3D cards (ViewportFrame) sorted by income, with rarity border,
	size, mutation, income/s; selecting one shows its ability and lets you EQUIP it as the active
	divine companion or SELL it. Capacity is shown (pets / pet slots).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Creatures = require(Shared.Config.Creatures)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Kit = require(script.Parent.Kit)

local InventoryUI = {}
local C
local T = Kit.Theme
local panel, grid, details, capLabel
local selected = nil

function InventoryUI.init(ctx)
	C = ctx
end

local function petTitle(pet)
	local c = Creatures.ById[pet.species]
	return (pet.mutation ~= "None" and (pet.mutation .. " ") or "") .. (pet.size ~= "Normal" and (pet.size .. " ") or "") .. (c and c.name or pet.species)
end

local function showDetails(pet)
	selected = pet and pet.uid
	for _, ch in details:GetChildren() do
		if not ch:IsA("UIListLayout") then
			ch:Destroy()
		end
	end
	if not pet then
		Kit.label({ Text = "Selecione um pet", Parent = details, Size = UDim2.new(1, 0, 0, 40), MaxTextSize = 22 })
		return
	end
	local d = C.State.get()
	local c = Creatures.ById[pet.species]
	local rc = Kit.rarityColor(c and c.rarity)
	local vpHolder = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 150), LayoutOrder = 1, Parent = details })
	Kit.viewport(vpHolder, ModelFactory.creature(pet.species, pet.size, pet.mutation))
	Kit.label({ Text = petTitle(pet), Parent = details, Size = UDim2.new(1, 0, 0, 30), MaxTextSize = 24, LayoutOrder = 2 })
	Kit.label({ Text = (c and c.rarity or "?") .. " • " .. (c and c.mythology or ""), Parent = details, Size = UDim2.new(1, 0, 0, 22), TextColor3 = rc, MaxTextSize = 18, LayoutOrder = 3 })
	Kit.label({ Text = "💰 " .. NF.format(pet.income) .. "/s   •   Tamanho x" .. Formulas.size(pet.size).mult .. "   •   Mutação x" .. Formulas.mutation(pet.mutation).mult, Parent = details, Size = UDim2.new(1, 0, 0, 22), Font = T.FontBody, MaxTextSize = 15, LayoutOrder = 4 })
	if c then
		Kit.label({ Text = "✦ " .. c.ab.name .. " (recarga " .. c.ab.cd .. "s)\n" .. c.ab.desc, Parent = details, Size = UDim2.new(1, 0, 0, 52), Font = T.FontBody, TextColor3 = Kit.mythColor(c.mythology), MaxTextSize = 15, LayoutOrder = 5 })
		Kit.label({ Text = c.desc, Parent = details, Size = UDim2.new(1, 0, 0, 36), Font = T.FontBody, TextColor3 = T.TextDim, MaxTextSize = 14, LayoutOrder = 6 })
	end
	local equipped = d and d.equippedPet == pet.uid
	local row = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = 7, Parent = details })
	Kit.list(row, 8, true)
	local eb = Kit.button({ Text = equipped and "EQUIPADO" or "EQUIPAR", color = T.Accent, Size = UDim2.new(0.5, -4, 1, 0), Parent = row, LayoutOrder = 1, onClick = function()
		local ok, msg = Net.request("EquipPet", { uid = pet.uid })
		if not ok then
			C.Notifications.toast("Warning", "Pet", msg or "")
		end
	end })
	Kit.setButtonEnabled(eb, not equipped, T.Accent)
	Kit.button({ Text = "VENDER " .. NF.format(Formulas.sellValue(pet)), color = T.Bad, Size = UDim2.new(0.5, -4, 1, 0), Parent = row, LayoutOrder = 2, MaxTextSize = 18, onClick = function()
		local ok, msg = Net.request("SellPet", { uid = pet.uid })
		C.Notifications.toast(ok and "Reward" or "Warning", "Venda", msg or "")
		showDetails(nil)
	end })
end

function InventoryUI.render()
	local d = C.State.get()
	if not d or not panel.frame.Visible then
		return
	end
	for _, ch in grid:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	capLabel.Text = "Pets: " .. #d.pets .. " / " .. (d.petSlots or 0) .. "   •   Renda total: " .. NF.format(d.income) .. "/s"
	local pets = table.clone(d.pets)
	table.sort(pets, function(a, b)
		return a.income > b.income
	end)
	local found = nil
	for i, pet in pets do
		local c = Creatures.ById[pet.species]
		local rc = Kit.rarityColor(c and c.rarity)
		local cell = Kit.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = T.PanelLight, LayoutOrder = i, Parent = grid })
		Kit.corner(cell, 12)
		Kit.stroke(cell, rc, d.equippedPet == pet.uid and 4 or 2)
		Kit.gradient(cell, rc:Lerp(T.PanelLight, 0.7), T.Panel)
		if i <= 40 then -- cap viewport count for performance
			local vpHolder = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.66, 0), Parent = cell })
			Kit.viewport(vpHolder, ModelFactory.creature(pet.species, pet.size, pet.mutation))
		end
		Kit.label({ Text = c and c.name or pet.species, Parent = cell, Size = UDim2.new(1, -6, 0.17, 0), Position = UDim2.new(0, 3, 0.64, 0), MaxTextSize = 15 })
		Kit.label({ Text = NF.format(pet.income) .. "/s", Parent = cell, Size = UDim2.new(1, -6, 0.16, 0), Position = UDim2.new(0, 3, 0.82, 0), TextColor3 = T.Gold, Font = T.FontBody, MaxTextSize = 13 })
		if d.equippedPet == pet.uid then
			Kit.label({ Text = "★", Parent = cell, Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(4, 2), TextColor3 = T.Gold, stroke = false })
		end
		if pet.mutation ~= "None" then
			Kit.label({ Text = pet.mutation, Parent = cell, Size = UDim2.new(0.6, 0, 0, 16), Position = UDim2.new(0.4, -4, 0, 4), TextColor3 = Color3.fromRGB(255, 220, 120), Font = T.FontBody, MaxTextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })
		end
		cell.Activated:Connect(function()
			Kit.playClick()
			showDetails(pet)
		end)
		if pet.uid == selected then
			found = pet
		end
	end
	showDetails(found)
end

function InventoryUI.start()
	panel = Kit.panel(C.Panels.screen, "🐉 SEUS PETS", Color3.fromRGB(110, 200, 255))
	capLabel = Kit.label({ Text = "", Parent = panel.content, Size = UDim2.new(0.62, 0, 0, 28), MaxTextSize = 20, TextXAlignment = Enum.TextXAlignment.Left })
	grid = Kit.scroll(panel.content, { Position = UDim2.fromOffset(0, 34), Size = UDim2.new(0.62, -8, 1, -34) })
	Kit.grid(grid, UDim2.fromOffset(110, 130), 8)
	Kit.padding(grid, 4)
	details = Kit.new("Frame", { BackgroundColor3 = T.Panel, Position = UDim2.new(0.62, 4, 0, 0), Size = UDim2.new(0.38, -4, 1, 0), Parent = panel.content })
	Kit.corner(details, 14)
	Kit.stroke(details, T.Accent, 2)
	Kit.padding(details, 10)
	Kit.list(details, 6)
	C.Panels.register("Inventory", panel, InventoryUI.render)
	C.State.Changed:Connect(function(_, partial)
		if not partial then
			InventoryUI.render()
		end
	end)
end

return InventoryUI
