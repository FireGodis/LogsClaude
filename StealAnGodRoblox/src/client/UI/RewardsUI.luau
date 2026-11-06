--[[
	RewardsUI — collection rewards (Index milestones, biome sets, mythology sets) with claim
	buttons, achievements, VIP daily reward and the server ranking.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local Kit = require(script.Parent.Kit)

local RewardsUI = {}
local C
local T = Kit.Theme
local panel, body
local tab = "Coleção"

function RewardsUI.init(ctx)
	C = ctx
end

local function discovered(index)
	local n = 0
	for id in index do
		if Creatures.ById[id] then
			n += 1
		end
	end
	return n
end

local function reached(d, r)
	local idx = d.index or {}
	if r.biome then
		for slot = 1, 4 do
			if not idx[Creatures.ByBiome[r.biome][slot].id] then
				return false
			end
		end
		return true
	elseif r.mythology then
		for _, c in Creatures.List do
			if c.mythology == r.mythology and not idx[c.id] then
				return false
			end
		end
		return true
	elseif r.count then
		return discovered(idx) >= r.count
	end
	return discovered(idx) / #Creatures.List * 100 >= r.percent
end

local function rewardText(rw)
	local t = {}
	if rw.type == "Gold" then
		table.insert(t, "GOLD (" .. NF.time(rw.seconds) .. " de renda, mín. " .. NF.format(rw.minimum or rw.minimumPerBiome or 0) .. ")")
	elseif rw.type == "Trail" then
		table.insert(t, "Trail " .. rw.trail)
	elseif rw.type == "SpecialEgg" then
		table.insert(t, "Ovo Divino")
	end
	if rw.keys and rw.keys > 0 then
		table.insert(t, rw.keys .. " chave(s)")
	end
	if rw.title then
		table.insert(t, "Título \"" .. rw.title .. "\"")
	end
	return table.concat(t, " + ")
end

local function row(order, title, sub, buttonText, enabled, color, onClick)
	local f = Kit.card(body, color, order)
	f.Size = UDim2.new(1, -10, 0, 64)
	Kit.label({ Text = title, Parent = f, Size = UDim2.new(0.68, 0, 0, 28), Position = UDim2.fromOffset(12, 4), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 20, TextColor3 = color })
	Kit.label({ Text = sub, Parent = f, Size = UDim2.new(0.68, 0, 0, 26), Position = UDim2.fromOffset(12, 32), TextXAlignment = Enum.TextXAlignment.Left, Font = T.FontBody, MaxTextSize = 14 })
	if buttonText then
		local b = Kit.button({ Text = buttonText, color = color, Size = UDim2.new(0.28, 0, 0, 44), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Parent = f, MaxTextSize = 18, onClick = function()
			if enabled then
				onClick()
			end
		end })
		Kit.setButtonEnabled(b, enabled, color)
	end
end

local function collectionRewards()
	local list = {}
	for _, m in GameConfig.IndexMilestones do
		table.insert(list, m)
	end
	for b = 1, 12 do
		table.insert(list, { id = "Biome_" .. b, biome = b, label = "Coleção completa: " .. Formulas.biome(b).name, reward = { type = "Gold", seconds = GameConfig.BiomeCompleteReward.seconds, minimum = GameConfig.BiomeCompleteReward.minimumPerBiome * (5 ^ (b - 1)), keys = (b % 4 == 0) and 1 or 0 } })
	end
	return list
end

function RewardsUI.render()
	local d = C.State.get()
	if not d or not panel.frame.Visible then
		return
	end
	for _, ch in body:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	if tab == "Coleção" then
		for i, r in collectionRewards() do
			local claimed = d.claimed and d.claimed[r.id]
			local ok = reached(d, r)
			row(i, r.label, rewardText(r.reward), claimed and "COLETADO ✓" or (ok and "COLETAR" or "Bloqueado"), ok and not claimed, ok and T.Good or Color3.fromRGB(150, 150, 170), function()
				local success, msg = Net.request("ClaimIndexReward", { id = r.id })
				C.Notifications.toast(success and "Reward" or "Warning", r.label, msg or "")
			end)
		end
	elseif tab == "Conquistas" then
		for i, a in GameConfig.Achievements do
			local got = d.achievements and d.achievements[a.id]
			row(i, (a.icon or "🏆") .. " " .. a.name, a.desc, got and "CONQUISTADO ✓" or nil, false, got and T.Gold or Color3.fromRGB(150, 150, 170), function() end)
		end
	elseif tab == "Diário" then
		local vip = C.State.hasPass("VIP")
		row(1, "👑 Recompensa diária VIP", "10 min de renda em GOLD + 1 chave de relíquia (a cada 20h)", vip and "COLETAR" or "Exclusivo VIP", vip, T.Gold, function()
			local success, msg = Net.request("ClaimVipDaily", {})
			C.Notifications.toast(success and "Reward" or "Warning", "VIP", msg or "")
		end)
		row(2, "🗝 Chaves de Relíquia: " .. (d.keys or 0), "Ganhe 1 chave por dia ao entrar. Abra na Loja > Ovos Especiais.", "ABRIR LOJA", true, T.Accent, function()
			C.Panels.open("Shop")
		end)
		if d.title then
			row(3, "🏷 Seu título: " .. d.title, "Exibido na placa da sua base", nil, false, T.Gold, function() end)
		end
	elseif tab == "Ranking" then
		local ok, rows = Net.request("GetLeaderboard", {})
		if ok and rows then
			for i, r in rows do
				row(i, "#" .. i .. "  " .. r.name .. (r.title and ("  [" .. r.title .. "]") or ""), "💰 " .. NF.format(r.income) .. "/s   •   ⚡ " .. NF.format(r.speed) .. " Speed   •   🐉 " .. r.pets .. " pets", nil, false, i == 1 and T.Gold or T.Accent, function() end)
			end
		end
	end
end

function RewardsUI.start()
	panel = Kit.panel(C.Panels.screen, "🎁 RECOMPENSAS", Color3.fromRGB(255, 110, 160))
	Kit.tabs(panel.content, { "Coleção", "Conquistas", "Diário", "Ranking" }, function(name)
		tab = name
		RewardsUI.render()
	end, Color3.fromRGB(255, 110, 160))
	body = Kit.scroll(panel.content, { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50) })
	Kit.list(body, 8)
	Kit.padding(body, 4)
	C.Panels.register("Rewards", panel, RewardsUI.render)
	C.State.Changed:Connect(function(_, partial)
		if not partial and tab ~= "Ranking" then
			RewardsUI.render()
		end
	end)
end

return RewardsUI
