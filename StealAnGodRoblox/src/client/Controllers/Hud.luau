--[[
	Hud — main heads-up display:
	  money + income/s, Speed, biome progress bar (current → next), side menu, ability button with
	  cooldown sweep, trap button (x/3), drop-egg button, carry indicator, protection badge,
	  event/special-egg timer and equipped trail. Works with mouse, touch and gamepad.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local Kit = require(script.Parent.Parent.UI.Kit)

local Hud = {}
local C
local T = Kit.Theme
local ui = {}
local cooldownEnd = 0
local cooldownTotal = 1
local displayedGold = 0

function Hud.init(ctx)
	C = ctx
end

local function pill(parent, icon: string, color: Color3, pos: UDim2, size: UDim2)
	local f = Kit.new("Frame", { BackgroundColor3 = T.Panel, Position = pos, Size = size, Parent = parent })
	Kit.corner(f, 20)
	Kit.stroke(f, color, 3)
	Kit.gradient(f, T.PanelLight, T.Panel)
	local ic = Kit.new("Frame", { BackgroundColor3 = color, Size = UDim2.new(0, 46, 0, 46), Position = UDim2.new(0, -6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = f })
	Kit.corner(ic, 23)
	Kit.stroke(ic, color:Lerp(Color3.new(0, 0, 0), 0.5), 2)
	Kit.label({ Text = icon, Parent = ic, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), stroke = false })
	local value = Kit.label({ Text = "0", Parent = f, Size = UDim2.new(1, -54, 0.62, 0), Position = UDim2.new(0, 48, 0.04, 0), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 30, strokeThickness = 2 })
	local sub = Kit.label({ Text = "", Parent = f, Size = UDim2.new(1, -54, 0.34, 0), Position = UDim2.new(0, 48, 0.62, 0), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color, Font = T.FontBody, MaxTextSize = 16 })
	return f, value, sub
end

local MENU = {
	{ id = "Shop", icon = "🛒", label = "Loja", color = T.Gold },
	{ id = "Inventory", icon = "🐉", label = "Pets", color = Color3.fromRGB(110, 200, 255) },
	{ id = "Index", icon = "📖", label = "Index", color = Color3.fromRGB(90, 220, 140) },
	{ id = "Trails", icon = "✨", label = "Trails", color = Color3.fromRGB(170, 120, 255) },
	{ id = "Upgrades", icon = "🏛", label = "Base", color = Color3.fromRGB(255, 150, 80) },
	{ id = "Rewards", icon = "🎁", label = "Prêmios", color = Color3.fromRGB(255, 110, 160) },
	{ id = "Events", icon = "🎉", label = "Eventos", color = Color3.fromRGB(255, 90, 90) },
	{ id = "Settings", icon = "⚙", label = "Config", color = Color3.fromRGB(160, 160, 190) },
}

local function build()
	local screen = Kit.screen("SAG_HUD", 1)
	Kit.autoScale(screen)
	ui.screen = screen

	-- money / income
	local goldPill, goldValue, incomeSub = pill(screen, "💰", T.Gold, UDim2.fromOffset(24, 14), UDim2.fromOffset(250, 58))
	ui.gold, ui.income, ui.goldPill = goldValue, incomeSub, goldPill
	local speedPill, speedValue, walkSub = pill(screen, "⚡", T.Accent, UDim2.fromOffset(24, 80), UDim2.fromOffset(250, 58))
	ui.speed, ui.walk, ui.speedPill = speedValue, walkSub, speedPill

	-- biome progress (top center)
	local bp = Kit.new("Frame", { BackgroundColor3 = T.Panel, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(420, 62), Parent = screen })
	Kit.corner(bp, 16)
	Kit.stroke(bp, T.Gold, 2.5)
	Kit.gradient(bp, T.PanelLight, T.Panel)
	ui.biomeName = Kit.label({ Text = "Bosque de Arcadia", Parent = bp, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 4), MaxTextSize = 24 })
	local barBg = Kit.new("Frame", { BackgroundColor3 = Color3.fromRGB(20, 16, 40), Position = UDim2.new(0, 12, 0, 34), Size = UDim2.new(1, -24, 0, 18), Parent = bp })
	Kit.corner(barBg, 9)
	ui.biomeBar = Kit.new("Frame", { BackgroundColor3 = T.Gold, Size = UDim2.fromScale(0, 1), Parent = barBg })
	Kit.corner(ui.biomeBar, 9)
	Kit.gradient(ui.biomeBar, Color3.fromRGB(255, 240, 150), T.GoldDark, 0)
	ui.biomeNext = Kit.label({ Text = "", Parent = barBg, Size = UDim2.fromScale(1, 1), Font = T.FontBody, MaxTextSize = 14, ZIndex = 2 })

	-- left menu
	local menu = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0.5, -10), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(150, 380), Parent = screen })
	Kit.grid(menu, UDim2.fromOffset(68, 80), 8)
	ui.menuButtons = {}
	for i, m in MENU do
		local b = Kit.button({ Text = "", color = m.color, Size = UDim2.fromOffset(68, 68), LayoutOrder = i, Parent = menu, radius = 16, onClick = function()
			C.Panels.toggle(m.id)
		end })
		Kit.label({ Text = m.icon, Parent = b, Size = UDim2.fromScale(0.62, 0.62), Position = UDim2.fromScale(0.19, 0.06), stroke = false, ZIndex = 3 })
		Kit.label({ Text = m.label, Parent = b, Size = UDim2.new(1, 4, 0.34, 0), Position = UDim2.new(0, -2, 0.7, 0), ZIndex = 3, MaxTextSize = 15 })
		ui.menuButtons[m.id] = b
	end

	-- ability button (bottom right)
	local ab = Kit.new("TextButton", { Name = "Ability", Text = "", AutoButtonColor = false, BackgroundColor3 = T.Panel, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(120, 120), Parent = screen })
	Kit.corner(ab, 60)
	ui.abilityStroke = Kit.stroke(ab, T.Gold, 4)
	Kit.gradient(ab, T.PanelLight, T.Panel)
	ui.abilityIcon = Kit.label({ Text = "✦", Parent = ab, Size = UDim2.fromScale(0.5, 0.4), Position = UDim2.fromScale(0.25, 0.12), stroke = false, ZIndex = 2 })
	ui.abilityName = Kit.label({ Text = "Sem pet", Parent = ab, Size = UDim2.fromScale(0.84, 0.24), Position = UDim2.fromScale(0.08, 0.54), MaxTextSize = 16, ZIndex = 2 })
	ui.abilityKey = Kit.label({ Text = "[Q]", Parent = ab, Size = UDim2.fromScale(0.5, 0.16), Position = UDim2.fromScale(0.25, 0.78), Font = T.FontBody, TextColor3 = T.TextDim, MaxTextSize = 13, ZIndex = 2 })
	ui.abilityCd = Kit.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), ZIndex = 3, Parent = ab })
	Kit.corner(ui.abilityCd, 60)
	ui.abilityCdText = Kit.label({ Text = "", Parent = ab, Size = UDim2.fromScale(0.6, 0.35), Position = UDim2.fromScale(0.2, 0.3), ZIndex = 4, MaxTextSize = 36 })
	ab.Activated:Connect(function()
		Hud.useAbility()
	end)
	ui.ability = ab

	-- trap / drop buttons
	local trap, trapLabel = Kit.button({ Text = "🪤 0/3 [T]", color = Color3.fromRGB(150, 90, 60), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -154, 1, -86), Size = UDim2.fromOffset(150, 52), Parent = screen, MaxTextSize = 20, onClick = function()
		Hud.placeTrap()
	end })
	ui.trap, ui.trapLabel = trap, trapLabel
	Kit.button({ Text = "Recolher [R]", color = Color3.fromRGB(110, 80, 60), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -154, 1, -30), Size = UDim2.fromOffset(150, 48), Parent = screen, MaxTextSize = 18, onClick = function()
		Hud.removeTrap()
	end })
	local drop = Kit.button({ Text = "Soltar ovo [G]", color = T.Bad, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -154, 1, -146), Size = UDim2.fromOffset(150, 48), Parent = screen, MaxTextSize = 18, onClick = function()
		Net.send("DropEgg")
	end })
	drop.Visible = false
	ui.drop = drop

	-- carry indicator
	local carry = Kit.new("Frame", { BackgroundColor3 = Color3.fromRGB(60, 30, 20), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -90), Size = UDim2.fromOffset(420, 46), Visible = false, Parent = screen })
	Kit.corner(carry, 14)
	Kit.stroke(carry, Color3.fromRGB(255, 170, 60), 3)
	ui.carryLabel = Kit.label({ Text = "", Parent = carry, Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), MaxTextSize = 22 })
	ui.carry = carry

	-- right top: event timer + trail + protection
	local info = Kit.new("Frame", { BackgroundColor3 = T.Panel, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 12), Size = UDim2.fromOffset(250, 92), Parent = screen })
	Kit.corner(info, 14)
	Kit.stroke(info, Color3.fromRGB(255, 110, 200), 2.5)
	Kit.gradient(info, T.PanelLight, T.Panel)
	ui.eventLine = Kit.label({ Text = "", Parent = info, Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 4), MaxTextSize = 20, TextColor3 = Color3.fromRGB(255, 150, 220) })
	ui.specialLine = Kit.label({ Text = "", Parent = info, Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 34), MaxTextSize = 17, Font = T.FontBody })
	ui.trailLine = Kit.label({ Text = "", Parent = info, Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 62), MaxTextSize = 15, Font = T.FontBody, TextColor3 = T.TextDim })
	ui.protect = Kit.label({ Text = "", Parent = screen, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 110), Size = UDim2.fromOffset(250, 26), MaxTextSize = 18, TextColor3 = T.Good })
end

-- ===================== ACTIONS =====================
function Hud.useAbility()
	Net.send("UseAbility")
end

function Hud.placeTrap()
	local ok, msg = Net.request("PlaceTrap", {})
	C.Notifications.toast(ok and "Info" or "Warning", ok and "Armadilha" or "Não foi possível", msg or "")
end

function Hud.removeTrap()
	local ok, msg = Net.request("RemoveTrap", {})
	C.Notifications.toast(ok and "Info" or "Warning", "Armadilha", msg or "")
end

function Hud.setCooldown(seconds: number)
	if seconds and seconds > 0 then
		cooldownEnd = os.clock() + seconds
		cooldownTotal = math.max(seconds, cooldownTotal)
		local _, creature = Hud.equippedAbility()
		if creature then
			cooldownTotal = creature.ab.cd
		end
	end
end

function Hud.equippedAbility()
	local d = C.State.get()
	if not d or not d.equippedPet then
		return nil, nil
	end
	for _, pet in d.pets do
		if pet.uid == d.equippedPet then
			local c = Creatures.ById[pet.species]
			return c and c.ab, c
		end
	end
	return nil, nil
end

-- ===================== REFRESH =====================
local function refresh(d)
	if not d then
		return
	end
	ui.income.Text = "+" .. NF.format(d.income or 0) .. "/s" .. ((d.vault or 0) >= 1 and ("  •  cofre " .. NF.format(d.vault)) or "")
	ui.speed.Text = NF.format(d.speed) .. " Speed"
	local unlocked = d.unlockedBiome or 1
	local b = Formulas.biome(unlocked)
	local nextB = Balance.biomes[unlocked + 1]
	ui.walk.Text = string.format("Velocidade %.0f", Formulas.walkSpeed(d.speed))
	ui.biomeName.Text = "🗺 " .. b.name .. " (" .. unlocked .. "/12)"
	if nextB then
		local p = math.clamp((d.speed - b.speedRequired) / (nextB.speedRequired - b.speedRequired), 0, 1)
		TweenService:Create(ui.biomeBar, TweenInfo.new(0.3), { Size = UDim2.fromScale(p, 1) }):Play()
		ui.biomeNext.Text = "Próximo: " .. nextB.name .. " — " .. NF.format(d.speed) .. " / " .. NF.format(nextB.speedRequired)
	else
		ui.biomeBar.Size = UDim2.fromScale(1, 1)
		ui.biomeNext.Text = "Todos os biomas desbloqueados!"
	end
	if not d.partial then
		local ab, creature = Hud.equippedAbility()
		if ab and creature then
			ui.abilityName.Text = ab.name
			ui.abilityStroke.Color = Kit.mythColor(creature.mythology)
			ui.abilityIcon.Text = (creature.mythology == "Greek" and "⚡") or (creature.mythology == "Norse" and "❄") or (creature.mythology == "Egyptian" and "☀") or "✦"
		else
			ui.abilityName.Text = "Equipe um pet"
			ui.abilityIcon.Text = "✦"
		end
		ui.trapLabel.Text = "🪤 " .. (d.trapsActive or 0) .. "/" .. Balance.traps.maxActive .. " [T]"
		ui.carry.Visible = d.carrying ~= nil
		ui.drop.Visible = d.carrying ~= nil
		if d.carrying then
			local pen = Balance.speed.carryPenaltyBySize[d.carrying.size] or 0
			ui.carryLabel.Text = "🥚 Carregando ovo " .. Formulas.size(d.carrying.size).eggName .. (d.carrying.mutation ~= "None" and (" " .. d.carrying.mutation) or "") .. "  (−" .. math.floor(pen * 100) .. "% velocidade) → volte à base!"
		end
		local trail = Formulas.trail(d.equippedTrail)
		ui.trailLine.Text = trail and ("Trail: " .. trail.name .. " (" .. trail.mult .. "x treino)") or "Sem Trail equipado"
		ui.protect.Text = d.protected and ("🛡 Base protegida: " .. d.protected) or ""
	end
end

function Hud.start()
	build()
	C.State.Changed:Connect(function(d, partial)
		d.partial = partial
		refresh(d)
		d.partial = nil
	end)
	Net.listen("Effect", function(e)
		if e.kind == "AbilityResult" then
			if e.ok then
				Hud.setCooldown(e.cooldown)
			elseif e.message then
				C.Notifications.toast("Warning", "Habilidade", e.message)
			end
		end
	end)
	-- per-frame: smooth gold counter, cooldown sweep, timers
	RunService.RenderStepped:Connect(function(dt)
		local d = C.State.get()
		if d then
			local target = d.gold or 0
			displayedGold += (target - displayedGold) * math.clamp(dt * 8, 0, 1)
			if math.abs(target - displayedGold) < 1 then
				displayedGold = target
			end
			ui.gold.Text = NF.format(displayedGold)
		end
		local left = cooldownEnd - os.clock()
		if left > 0 then
			ui.abilityCd.Size = UDim2.fromScale(1, math.clamp(left / cooldownTotal, 0, 1))
			ui.abilityCdText.Text = tostring(math.ceil(left))
		else
			ui.abilityCd.Size = UDim2.fromScale(1, 0)
			ui.abilityCdText.Text = ""
		end
		local now = C.State.now()
		local w = C.State.World
		if w.event and w.endsAt then
			local name = w.event
			for _, e in GameConfig.Events do
				if e.id == w.event then
					name = e.name
				end
			end
			ui.eventLine.Text = "🎉 " .. name .. " " .. NF.time(w.endsAt - now)
		else
			ui.eventLine.Text = "🎉 Nenhum evento ativo"
		end
		if w.nextSpecialAt then
			ui.specialLine.Text = "🥚 Ovo Divino em " .. NF.time(w.nextSpecialAt - now)
		end
	end)
end

return Hud
