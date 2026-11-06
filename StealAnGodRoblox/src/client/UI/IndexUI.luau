--[[
	IndexUI — the collection book. Tabs per mythology (+ Eventos); each biome is a row of 4
	creatures. Discovered creatures show in 3D with their rarity color; unknown ones are dark
	silhouettes. Shows completion %, per mythology/biome counts, discovered sizes & mutations,
	description, ability and base income. Collection rewards are claimed in the Rewards panel.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Creatures = require(Shared.Config.Creatures)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Kit = require(script.Parent.Kit)

local IndexUI = {}
local C
local T = Kit.Theme
local panel, body, summary, detail
local tab = "Greek"

function IndexUI.init(ctx)
	C = ctx
end

local function countDiscovered(index, filter)
	local n, total = 0, 0
	for _, c in Creatures.List do
		if filter(c) then
			total += 1
			if index[c.id] then
				n += 1
			end
		end
	end
	return n, total
end

local function showDetail(c, entry)
	detail.Visible = true
	for _, ch in detail:GetChildren() do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") and not ch:IsA("UICorner") and not ch:IsA("UIStroke") then
			ch:Destroy()
		end
	end
	local known = entry ~= nil
	local vp = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 140), LayoutOrder = 1, Parent = detail })
	Kit.viewport(vp, ModelFactory.creature(c.id, "Normal", "None"), { silhouette = not known })
	Kit.label({ Text = known and c.name or "???", Parent = detail, Size = UDim2.new(1, 0, 0, 28), MaxTextSize = 24, LayoutOrder = 2 })
	Kit.label({ Text = c.rarity .. " • " .. (c.biome > 0 and Formulas.biome(c.biome).name or "Evento"), Parent = detail, Size = UDim2.new(1, 0, 0, 20), TextColor3 = Kit.rarityColor(c.rarity), MaxTextSize = 16, LayoutOrder = 3 })
	Kit.label({ Text = known and c.desc or "Ainda não descoberta. Choque um ovo deste bioma para encontrá-la!", Parent = detail, Size = UDim2.new(1, 0, 0, 40), Font = T.FontBody, MaxTextSize = 14, LayoutOrder = 4 })
	Kit.label({ Text = "✦ " .. c.ab.name .. ": " .. c.ab.desc, Parent = detail, Size = UDim2.new(1, 0, 0, 40), Font = T.FontBody, TextColor3 = Kit.mythColor(c.mythology), MaxTextSize = 14, LayoutOrder = 5 })
	local base = Formulas.speciesBaseIncome(c.id, 1)
	Kit.label({ Text = "Renda base: " .. NF.format(base) .. "/s" .. (c.biome == 0 and " (escala com o bioma do evento)" or ""), Parent = detail, Size = UDim2.new(1, 0, 0, 20), Font = T.FontBody, TextColor3 = T.Gold, MaxTextSize = 14, LayoutOrder = 6 })
	if known then
		local sizes, muts = {}, {}
		for _, s in Balance.sizes do
			table.insert(sizes, (entry.s[s.name] and "✔" or "✖") .. s.name)
		end
		for _, m in Balance.mutations do
			if m.name ~= "None" then
				table.insert(muts, (entry.m[m.name] and "✔" or "✖") .. m.name)
			end
		end
		Kit.label({ Text = "Tamanhos: " .. table.concat(sizes, " ") .. "\nMutações: " .. table.concat(muts, " ") .. "\nObtidos: " .. entry.n, Parent = detail, Size = UDim2.new(1, 0, 0, 66), Font = T.FontBody, MaxTextSize = 13, LayoutOrder = 7 })
	end
end

function IndexUI.render()
	local d = C.State.get()
	if not d or not panel.frame.Visible then
		return
	end
	local index = d.index or {}
	for _, ch in body:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	local all, total = countDiscovered(index, function()
		return true
	end)
	local parts = { string.format("📖 %d / %d  (%.0f%%)", all, total, all / total * 100) }
	for _, m in { "Greek", "Norse", "Egyptian", "Event" } do
		local n, t = countDiscovered(index, function(c)
			return c.mythology == m
		end)
		table.insert(parts, ({ Greek = "Gregos", Norse = "Nórdicos", Egyptian = "Egípcios", Event = "Eventos" })[m] .. " " .. n .. "/" .. t)
	end
	summary.Text = table.concat(parts, "   •   ")

	local order = 0
	local function section(title: string, list)
		order += 1
		local n = 0
		for _, c in list do
			if index[c.id] then
				n += 1
			end
		end
		Kit.label({ Text = title .. "  (" .. n .. "/" .. #list .. ")", Parent = body, Size = UDim2.new(1, -10, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 22, LayoutOrder = order })
		order += 1
		local row = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 130), LayoutOrder = order, Parent = body })
		Kit.list(row, 8, true)
		for i, c in list do
			local entry = index[c.id]
			local rc = Kit.rarityColor(c.rarity)
			local cell = Kit.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = T.PanelLight, Size = UDim2.fromOffset(120, 128), LayoutOrder = i, Parent = row })
			Kit.corner(cell, 12)
			Kit.stroke(cell, entry and rc or Color3.fromRGB(70, 70, 90), 2.5)
			local vpHolder = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.72, 0), Parent = cell })
			Kit.viewport(vpHolder, ModelFactory.creature(c.id, "Normal", "None"), { silhouette = entry == nil })
			Kit.label({ Text = entry and c.name or "???", Parent = cell, Size = UDim2.new(1, -6, 0.15, 0), Position = UDim2.new(0, 3, 0.7, 0), MaxTextSize = 14 })
			Kit.label({ Text = c.rarity, Parent = cell, Size = UDim2.new(1, -6, 0.13, 0), Position = UDim2.new(0, 3, 0.85, 0), Font = T.FontBody, TextColor3 = rc, MaxTextSize = 12 })
			cell.Activated:Connect(function()
				Kit.playClick()
				showDetail(c, entry)
			end)
		end
	end
	if tab == "Event" then
		local list = {}
		for _, c in Creatures.List do
			if c.biome == 0 then
				table.insert(list, c)
			end
		end
		section("🎉 Criaturas de Evento", list)
	else
		for b = 1, 12 do
			local biome = Formulas.biome(b)
			if biome.mythology == tab then
				local list = {}
				for slot = 1, 4 do
					table.insert(list, Creatures.ByBiome[b][slot])
				end
				section("🗺 " .. biome.name, list)
			end
		end
	end
end

function IndexUI.start()
	panel = Kit.panel(C.Panels.screen, "📖 INDEX DO PANTEÃO", Color3.fromRGB(90, 220, 140))
	summary = Kit.label({ Text = "", Parent = panel.content, Size = UDim2.new(1, 0, 0, 24), MaxTextSize = 18, Font = T.FontBody })
	local tabHolder = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(0.66, 0, 0, 40), Parent = panel.content })
	local setTab = Kit.tabs(tabHolder, { "Gregos", "Nórdicos", "Egípcios", "Eventos" }, function(name)
		tab = ({ Gregos = "Greek", ["Nórdicos"] = "Norse", ["Egípcios"] = "Egyptian", Eventos = "Event" })[name]
		IndexUI.render()
	end, Color3.fromRGB(90, 220, 140))
	body = Kit.scroll(panel.content, { Position = UDim2.fromOffset(0, 76), Size = UDim2.new(0.66, -8, 1, -76) })
	Kit.list(body, 6)
	detail = Kit.new("Frame", { BackgroundColor3 = T.Panel, Position = UDim2.new(0.66, 4, 0, 30), Size = UDim2.new(0.34, -4, 1, -30), Visible = false, Parent = panel.content })
	Kit.corner(detail, 14)
	Kit.stroke(detail, Color3.fromRGB(90, 220, 140), 2)
	Kit.padding(detail, 8)
	Kit.list(detail, 4)
	C.Panels.register("Index", panel, function()
		setTab(({ Greek = "Gregos", Norse = "Nórdicos", Egyptian = "Egípcios", Event = "Eventos" })[tab])
		C.Tutorial.markIndexOpened()
	end)
	C.State.Changed:Connect(function(_, partial)
		if not partial then
			IndexUI.render()
		end
	end)
end

return IndexUI
