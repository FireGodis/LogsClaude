--[[
	UpgradesUI — base expansion and treadmill upgrades (GOLD), showing the next level benefits.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local Kit = require(script.Parent.Kit)

local UpgradesUI = {}
local C
local T = Kit.Theme
local panel, body

function UpgradesUI.init(ctx)
	C = ctx
end

local function card(order, title, lines, buttonText, enabled, color, onClick)
	local f = Kit.card(body, color, order)
	f.Size = UDim2.new(1, -10, 0, 150)
	Kit.label({ Text = title, Parent = f, Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color, MaxTextSize = 26 })
	Kit.label({ Text = table.concat(lines, "\n"), Parent = f, Size = UDim2.new(0.62, -10, 0, 96), Position = UDim2.fromOffset(10, 44), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = T.FontBody, MaxTextSize = 17 })
	local b = Kit.button({ Text = buttonText, color = color, Size = UDim2.new(0.34, 0, 0, 56), Position = UDim2.new(1, -10, 1, -12), AnchorPoint = Vector2.new(1, 1), Parent = f, MaxTextSize = 22, onClick = function()
		if enabled then
			onClick()
		end
	end })
	Kit.setButtonEnabled(b, enabled, color)
end

function UpgradesUI.render()
	local d = C.State.get()
	if not d or not panel.frame.Visible then
		return
	end
	for _, ch in body:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	local lvl = Formulas.baseLevel(d.baseLevel)
	local nextLvl = Balance.baseLevels[d.baseLevel + 1]
	local lines = {
		"Nível atual: " .. d.baseLevel .. "/" .. #Balance.baseLevels .. "  •  Incubadoras: " .. d.incubators .. "  •  Espaços de pets: " .. lvl.petSlots,
	}
	if nextLvl then
		table.insert(lines, "Próximo nível: +" .. (nextLvl.incubators - lvl.incubators) .. " incubadoras, +" .. (nextLvl.petSlots - lvl.petSlots) .. " espaços de pets")
		table.insert(lines, "Novo visual: cercas, pilares, estandartes, arcos, tochas e estátuas divinas")
	else
		table.insert(lines, "Sua base está no nível máximo — um verdadeiro templo!")
	end
	card(1, "🏛 EXPANDIR BASE", lines, nextLvl and (NF.format(nextLvl.price) .. " GOLD") or "MÁXIMO", nextLvl ~= nil and d.gold >= nextLvl.price, Color3.fromRGB(255, 150, 80), function()
		local ok, msg = Net.request("UpgradeBase", {})
		C.Notifications.toast(ok and "Reward" or "Warning", "Base", msg or "")
	end)
	local tm = Formulas.treadmill(d.treadmillTier)
	local nextTm = Balance.treadmills[d.treadmillTier + 1]
	local tl = { "Atual: " .. tm.name .. " (+" .. NF.format(tm.perStep) .. " Speed por passo)" }
	if nextTm then
		table.insert(tl, "Próxima: " .. nextTm.name .. " (+" .. NF.format(nextTm.perStep) .. " por passo)")
		table.insert(tl, "Ganho real/passo com seu Trail: " .. NF.format(Formulas.trainGain(d.treadmillTier + 1, d.equippedTrail, {})))
	else
		table.insert(tl, "Você tem a esteira mais poderosa do panteão!")
	end
	card(2, "🏃 ESTEIRA", tl, nextTm and (NF.format(nextTm.price) .. " GOLD") or "MÁXIMO", nextTm ~= nil and d.gold >= nextTm.price, T.Accent, function()
		local ok, msg = Net.request("BuyTreadmill", {})
		C.Notifications.toast(ok and "Reward" or "Warning", "Esteira", msg or "")
	end)
end

function UpgradesUI.start()
	panel = Kit.panel(C.Panels.screen, "🏛 MELHORIAS", Color3.fromRGB(255, 150, 80), UDim2.fromScale(0.55, 0.6))
	body = Kit.scroll(panel.content)
	Kit.list(body, 10)
	Kit.padding(body, 4)
	C.Panels.register("Upgrades", panel, UpgradesUI.render)
	C.State.Changed:Connect(function()
		UpgradesUI.render()
	end)
end

return UpgradesUI
