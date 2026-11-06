--[[
	ShopUI — "Loja Divina" (tabs: Gamepasses, Produtos, Speed, Trails, Boosts, Ovos Especiais) and
	the standalone Trails panel (kiosk/HUD). Robux items open the official Roblox purchase prompt;
	items whose id is not configured show as "Indisponível" (never a fake button).
	The Divine Reliquary shows every reward and its exact chance BEFORE purchase, and is hidden
	for players whose policy restricts paid random items (they can open it with free keys).
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Monetization = require(Shared.Config.Monetization)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local Kit = require(script.Parent.Kit)

local ShopUI = {}
local C
local T = Kit.Theme
local player = Players.LocalPlayer
local shop, trailsPanel
local body
local currentTab = "Gamepasses"

local PASS_ICON = { Crown = "👑", Coins = "💰", Egg = "🥚", Magnet = "🧲", Nest = "🪺", Bolt = "⚡" }

function ShopUI.init(ctx)
	C = ctx
end

local function clear(container)
	for _, ch in container:GetChildren() do
		if not ch:IsA("UIGridLayout") and not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
			ch:Destroy()
		end
	end
end

-- Generic item card
local function itemCard(parent, order, data)
	local card = Kit.card(parent, data.color or T.Gold, order)
	Kit.label({ Text = data.icon or "✦", Parent = card, Size = UDim2.new(0, 64, 0, 64), Position = UDim2.fromOffset(10, 10), stroke = false })
	Kit.label({ Text = data.name, Parent = card, Size = UDim2.new(1, -90, 0, 30), Position = UDim2.fromOffset(80, 8), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 24, TextColor3 = data.color or T.Gold })
	Kit.label({ Text = data.desc or "", Parent = card, Size = UDim2.new(1, -90, 0, 52), Position = UDim2.fromOffset(80, 38), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = T.FontBody, MaxTextSize = 15 })
	local btn, label = Kit.button({ Text = data.buttonText, color = data.enabled and (data.buttonColor or T.Good) or Color3.fromRGB(90, 90, 110), Size = UDim2.new(1, -20, 0, 42), Position = UDim2.new(0, 10, 1, -50), Parent = card, MaxTextSize = 20, onClick = function()
		if data.enabled and data.onBuy then
			data.onBuy()
		end
	end })
	Kit.setButtonEnabled(btn, data.enabled, data.buttonColor or T.Good)
	return card, btn, label
end

local function request(action, payload)
	local ok, msg = Net.request(action, payload)
	C.Notifications.toast(ok and "Purchase" or "Warning", ok and "Sucesso!" or "Ops!", msg or "")
	return ok
end

-- ===================== TABS =====================
local Tabs = {}

function Tabs.Gamepasses(container)
	local d = C.State.get()
	local order = 0
	for key, pass in Monetization.Gamepasses do
		order += 1
		local owned = d and d.passes and table.find(d.passes, key) ~= nil
		local registered = Monetization.isRegistered(pass)
		itemCard(container, order, {
			icon = PASS_ICON[pass.icon] or "💎", name = pass.name, desc = pass.desc, color = T.Gold,
			buttonText = owned and "ADQUIRIDO ✓" or (registered and ("R$ " .. pass.price) or "Indisponível"),
			enabled = registered and not owned,
			onBuy = function()
				MarketplaceService:PromptGamePassPurchase(player, pass.id)
			end,
		})
	end
end

local function productCards(container, kinds)
	local order = 0
	local d = C.State.get()
	local income = d and d.income or 0
	for key, product in Monetization.Products do
		if kinds[product.kind] and key ~= "DivineReliquary" then
			order += 1
			local registered = Monetization.isRegistered(product)
			local desc = product.desc
			if product.kind == "Gold" then
				desc = "+" .. NF.format(math.max(product.minimum, income * product.seconds)) .. " GOLD agora • " .. product.desc
			end
			local active = product.boost and d and d.boosts and d.boosts[product.boost]
			if active then
				desc = desc .. "\nAtivo por mais " .. NF.time(active - C.State.now())
			end
			itemCard(container, order, {
				icon = (product.kind == "Gold" and "💰") or (product.boost == "shield" and "🛡") or (product.kind == "HatchInstant" and "🐣") or "⚡",
				name = product.name, desc = desc, color = Color3.fromRGB(110, 200, 255),
				buttonText = registered and ("R$ " .. product.price) or "Indisponível", enabled = registered,
				onBuy = function()
					MarketplaceService:PromptProductPurchase(player, product.id)
				end,
			})
		end
	end
end

function Tabs.Produtos(container)
	productCards(container, { Gold = true })
end

function Tabs.Boosts(container)
	productCards(container, { Boost = true, HatchInstant = true })
end

function Tabs.Speed(container)
	local d = C.State.get()
	if not d then
		return
	end
	local current = Formulas.treadmill(d.treadmillTier)
	local nextT = Balance.treadmills[d.treadmillTier + 1]
	itemCard(container, 1, {
		icon = "🏃", name = "Sua esteira: " .. current.name, desc = "+" .. NF.format(current.perStep) .. " Speed por passo (antes de Trail e bônus).", color = T.Accent,
		buttonText = "EQUIPADA", enabled = false,
	})
	if nextT then
		itemCard(container, 2, {
			icon = "⬆", name = nextT.name, desc = "+" .. NF.format(nextT.perStep) .. " Speed por passo. Visual exclusivo e efeitos próprios.", color = T.Gold,
			buttonText = NF.format(nextT.price) .. " GOLD", enabled = d.gold >= nextT.price, buttonColor = T.Gold,
			onBuy = function()
				request("BuyTreadmill", {})
				task.wait(0.3)
				ShopUI.render()
			end,
		})
	end
	productCards(container, { Boost = true })
	for _, ch in container:GetChildren() do
		if ch:IsA("Frame") and ch.LayoutOrder > 0 and ch.LayoutOrder < 10 then
			ch.LayoutOrder += 10
		end
	end
end

local function trailsList(container)
	local d = C.State.get()
	if not d then
		return
	end
	local all = table.clone(Balance.trails)
	for _, t in Balance.rewardTrails do
		table.insert(all, t)
	end
	for i, t in all do
		local owned = table.find(d.trailsOwned, t.id) ~= nil
		local equipped = d.equippedTrail == t.id
		local color = Color3.fromRGB(t.c1[1], t.c1[2], t.c1[3])
		local card = itemCard(container, i, {
			icon = "✨", name = t.name .. "  (" .. t.mult .. "x)", color = color,
			desc = "Raridade: " .. t.rarity .. "\nMultiplica a Speed ganha na esteira por " .. t.mult .. "x." .. (t.price < 0 and "\nRecompensa do Index (75%)." or ""),
			buttonText = equipped and "EQUIPADO" or (owned and "EQUIPAR" or (t.price < 0 and "Recompensa" or (NF.format(t.price) .. " GOLD"))),
			enabled = (owned and not equipped) or (not owned and t.price >= 0 and d.gold >= t.price),
			buttonColor = owned and T.Accent or T.Gold,
			onBuy = function()
				if owned then
					request("EquipTrail", { id = t.id })
				else
					request("BuyTrail", { id = t.id })
				end
				task.wait(0.3)
				ShopUI.render()
				ShopUI.renderTrails()
			end,
		})
		local swatch = Kit.new("Frame", { BackgroundColor3 = color, Size = UDim2.fromOffset(60, 8), Position = UDim2.fromOffset(12, 76), Parent = card })
		Kit.corner(swatch, 4)
		Kit.gradient(swatch, color, Color3.fromRGB(t.c2[1], t.c2[2], t.c2[3]), 0)
	end
end

function Tabs.Trails(container)
	trailsList(container)
end

Tabs["Ovos Especiais"] = function(container)
	local d = C.State.get()
	local ok, info = Net.request("GetReliquaryInfo", {})
	if not ok or not info then
		return
	end
	local product = Monetization.Products.DivineReliquary
	local canBuyPaid = info.registered and not info.restricted
	itemCard(container, 1, {
		icon = "🏺", name = "Divine Reliquary", color = Color3.fromRGB(255, 140, 220),
		desc = "Uma relíquia mitológica aleatória. Probabilidades exatas listadas abaixo (somam 100%).",
		buttonText = info.restricted and "Indisponível na sua região" or (info.registered and ("R$ " .. product.price) or "Indisponível"),
		enabled = canBuyPaid,
		onBuy = function()
			MarketplaceService:PromptProductPurchase(player, product.id)
		end,
	})
	for i, row in info.odds do
		itemCard(container, 10 + i, {
			icon = "🎲", name = string.format("%.1f%%", row.chance), color = Color3.fromRGB(255, 140, 220),
			desc = row.label, buttonText = "Probabilidade real", enabled = false,
		})
	end
	itemCard(container, 2, {
		icon = "🗝", name = "Abrir com Chave (grátis)", color = T.Good,
		desc = "Você tem " .. (d and d.keys or 0) .. " chave(s). Chaves são ganhas no login diário, no Index e com VIP. Mesmas probabilidades.",
		buttonText = "ABRIR (1 chave)", enabled = (d and d.keys or 0) > 0,
		onBuy = function()
			local success, res = Net.request("OpenReliquaryKey", {})
			if success then
				C.Notifications.toast("Rare", "Relíquia aberta!", res.text)
			else
				C.Notifications.toast("Warning", "Relíquia", res)
			end
			task.wait(0.3)
			ShopUI.render()
		end,
	})
end

function ShopUI.render()
	if not body then
		return
	end
	clear(body)
	local fn = Tabs[currentTab]
	if fn then
		fn(body)
	end
end

function ShopUI.renderTrails()
	if trailsPanel and trailsPanel.frame.Visible then
		clear(trailsPanel.body)
		trailsList(trailsPanel.body)
	end
end

function ShopUI.start()
	shop = Kit.panel(C.Panels.screen, "🛒 LOJA DIVINA", T.Gold)
	local setTab = Kit.tabs(shop.content, { "Gamepasses", "Produtos", "Speed", "Trails", "Boosts", "Ovos Especiais" }, function(name)
		currentTab = name
		ShopUI.render()
	end)
	body = Kit.scroll(shop.content, { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50) })
	Kit.grid(body, UDim2.fromOffset(300, 150), 10)
	Kit.padding(body, 4)
	C.Panels.register("Shop", shop, function()
		setTab(currentTab)
	end)

	trailsPanel = Kit.panel(C.Panels.screen, "✨ TRAILS", Color3.fromRGB(170, 120, 255))
	trailsPanel.body = Kit.scroll(trailsPanel.content)
	Kit.grid(trailsPanel.body, UDim2.fromOffset(300, 150), 10)
	Kit.padding(trailsPanel.body, 4)
	C.Panels.register("Trails", trailsPanel, function()
		clear(trailsPanel.body)
		trailsList(trailsPanel.body)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function()
		task.wait(1)
		ShopUI.render()
	end)
	C.State.Changed:Connect(function(_, partial)
		if not partial and shop.frame.Visible and currentTab ~= "Ovos Especiais" then
			ShopUI.render()
		end
	end)
end

return ShopUI
