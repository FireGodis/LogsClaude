--[[
	Notifications — organized feedback:
	  • toast queue (max 3 on screen, one enters at a time) for rewards, warnings, discoveries…
	  • big center announcements (special egg, world events) with their own queue
	  • the HATCH REVEAL cinematic (egg shake → crack → flash → creature + rarity banner)
	  • offline earnings summary when returning
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage.Shared
local Creatures = require(Shared.Config.Creatures)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Kit = require(script.Parent.Parent.UI.Kit)

local Notifications = {}
local C
local T = Kit.Theme
local screen
local toastHolder
local toastQueue = {}
local visibleToasts = 0
local announceQueue = {}
local announcing = false
local revealQueue = {}
local revealing = false

local KIND_COLOR = {
	Reward = Color3.fromRGB(90, 220, 110), Warning = Color3.fromRGB(255, 170, 60), Alarm = Color3.fromRGB(255, 70, 80),
	Egg = Color3.fromRGB(255, 210, 90), Discovery = Color3.fromRGB(120, 220, 255), Unlock = Color3.fromRGB(180, 120, 255),
	Trail = Color3.fromRGB(200, 140, 255), Achievement = Color3.fromRGB(255, 205, 64), Purchase = Color3.fromRGB(255, 205, 64),
	Info = Color3.fromRGB(150, 180, 255), Rare = Color3.fromRGB(255, 120, 220),
}
local KIND_ICON = { Reward = "🎁", Warning = "⚠", Alarm = "🚨", Egg = "🥚", Discovery = "📖", Unlock = "🗺", Trail = "✨", Achievement = "🏆", Purchase = "💎", Info = "ℹ", Rare = "🌟" }

function Notifications.init(ctx)
	C = ctx
end

-- ===================== TOASTS =====================
local function showNextToast()
	if visibleToasts >= 3 or #toastQueue == 0 then
		return
	end
	local n = table.remove(toastQueue, 1)
	visibleToasts += 1
	local color = KIND_COLOR[n.kind] or T.Accent
	local f = Kit.new("Frame", { BackgroundColor3 = T.Panel, Size = UDim2.fromOffset(380, 70), Parent = toastHolder })
	Kit.corner(f, 14)
	Kit.stroke(f, color, 3)
	Kit.gradient(f, T.PanelLight, T.Panel)
	Kit.label({ Text = KIND_ICON[n.kind] or "✦", Parent = f, Size = UDim2.fromOffset(50, 50), Position = UDim2.fromOffset(8, 10), stroke = false })
	Kit.label({ Text = n.title, Parent = f, Size = UDim2.new(1, -70, 0, 30), Position = UDim2.fromOffset(62, 6), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color, MaxTextSize = 22 })
	Kit.label({ Text = n.text or "", Parent = f, Size = UDim2.new(1, -70, 0, 28), Position = UDim2.fromOffset(62, 36), TextXAlignment = Enum.TextXAlignment.Left, Font = T.FontBody, MaxTextSize = 16 })
	local scale = Kit.new("UIScale", { Scale = 0.6, Parent = f })
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	C.Sound.play(n.kind == "Alarm" and "Alarm" or "Notify")
	task.delay(n.kind == "Alarm" and 4.5 or 3.4, function()
		TweenService:Create(scale, TweenInfo.new(0.2), { Scale = 0 }):Play()
		task.wait(0.22)
		f:Destroy()
		visibleToasts -= 1
		showNextToast()
	end)
	task.delay(0.35, showNextToast)
end

function Notifications.toast(kind: string, title: string, text: string?)
	-- de-duplicate identical messages already waiting
	for _, q in toastQueue do
		if q.title == title and q.text == text then
			return
		end
	end
	table.insert(toastQueue, { kind = kind, title = title, text = text })
	if #toastQueue > 8 then
		table.remove(toastQueue, 1)
	end
	showNextToast()
end

-- ===================== ANNOUNCEMENTS =====================
local function runAnnouncements()
	if announcing then
		return
	end
	announcing = true
	while #announceQueue > 0 do
		local a = table.remove(announceQueue, 1)
		local f = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.28), Size = UDim2.fromOffset(640, 120), BackgroundColor3 = T.Panel, Parent = screen })
		Kit.corner(f, 20)
		Kit.stroke(f, a.color, 4)
		Kit.gradient(f, a.color:Lerp(T.Panel, 0.55), T.Panel)
		Kit.label({ Text = a.title, Parent = f, Size = UDim2.new(1, -30, 0, 58), Position = UDim2.fromOffset(15, 8), TextColor3 = Color3.new(1, 1, 1), MaxTextSize = 46, strokeThickness = 3 })
		Kit.label({ Text = a.text or "", Parent = f, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.fromOffset(15, 70), Font = T.FontBody, MaxTextSize = 22 })
		local scale = Kit.new("UIScale", { Scale = 0.3, Parent = f })
		TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		C.Sound.play("EventStart")
		task.wait(a.duration or 3.5)
		TweenService:Create(scale, TweenInfo.new(0.25), { Scale = 0 }):Play()
		task.wait(0.3)
		f:Destroy()
	end
	announcing = false
end

function Notifications.announce(title: string, text: string?, color: Color3?, duration: number?)
	table.insert(announceQueue, { title = title, text = text, color = color or T.Gold, duration = duration })
	task.spawn(runAnnouncements)
end

-- ===================== HATCH REVEAL =====================
local function playReveal(data)
	local c = Creatures.ById[data.species]
	local rarityColor = Kit.rarityColor(data.rarity)
	local overlay = Kit.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = screen, ZIndex = 20 })
	TweenService:Create(overlay, TweenInfo.new(0.3), { BackgroundTransparency = 0.35 }):Play()
	local holder = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(360, 360), Parent = overlay, ZIndex = 21 })
	-- rays behind
	local rays = Kit.new("Frame", { BackgroundColor3 = rarityColor, BackgroundTransparency = 0.6, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.2, 1.2), Parent = holder, ZIndex = 21 })
	Kit.corner(rays, 400)
	Kit.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 1) }), Parent = rays })
	-- egg phase
	local eggModel = ModelFactory.egg(c and c.biome > 0 and c.biome or 1, data.size, data.mutation, c and c.biome == 0 and "event" or "normal")
	local eggVp = Kit.viewport(holder, eggModel, { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1) })
	eggVp.ZIndex = 22
	C.Sound.play("Hatch")
	for i = 1, 10 do
		local ang = (i % 2 == 0 and 1 or -1) * (4 + i * 1.2)
		eggVp.Rotation = ang
		task.wait(0.07 + (10 - i) * 0.01)
	end
	eggVp.Rotation = 0
	-- flash
	local flash = Kit.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), Parent = overlay, ZIndex = 30 })
	TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	C.Effects.shake(data.rarity == "Divine" and 1.2 or 0.5)
	eggVp:Destroy()
	-- creature phase
	local model = ModelFactory.creature(data.species, data.size, data.mutation)
	local vp = Kit.viewport(holder, model, { Size = UDim2.fromScale(1, 1) })
	vp.ZIndex = 22
	local spin = 0
	local conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
		spin += dt * 50
		rays.Rotation = spin
		local cam = vp.CurrentCamera
		if cam then
			local cf, size = model:GetBoundingBox()
			local dist = size.Magnitude * 1.3 + 1
			local a = math.rad(spin)
			cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(math.sin(a) * dist, dist * 0.25, math.cos(a) * dist), cf.Position)
		end
	end)
	local banner = Kit.new("Frame", { BackgroundColor3 = T.Panel, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromOffset(520, 180), Parent = overlay, ZIndex = 23 })
	Kit.corner(banner, 18)
	Kit.stroke(banner, rarityColor, 4)
	Kit.gradient(banner, rarityColor:Lerp(T.Panel, 0.6), T.Panel)
	local title = (data.mutation ~= "None" and (data.mutation .. " ") or "") .. (data.size ~= "Normal" and (data.size .. " ") or "") .. (c and c.name or data.species)
	Kit.label({ Text = string.upper(data.rarity or "") .. (data.isNew and "  •  NOVA!" or ""), Parent = banner, Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 6), TextColor3 = rarityColor, MaxTextSize = 30, ZIndex = 24, strokeThickness = 2.5 })
	Kit.label({ Text = title, Parent = banner, Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 40), MaxTextSize = 40, ZIndex = 24, strokeThickness = 3 })
	Kit.label({ Text = "💰 +" .. NF.format(data.income) .. "/s   •   Tamanho: " .. Formulas.size(data.size).name .. "   •   Mutação: " .. data.mutation, Parent = banner, Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 88), Font = T.FontBody, MaxTextSize = 20, ZIndex = 24 })
	if c then
		Kit.label({ Text = "✦ " .. c.ab.name .. ": " .. c.ab.desc, Parent = banner, Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 120), Font = T.FontBody, TextColor3 = T.TextDim, MaxTextSize = 17, ZIndex = 24 })
	end
	local scale = Kit.new("UIScale", { Scale = 0.2, Parent = banner })
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local closed = false
	local btn = Kit.new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = overlay, ZIndex = 40 })
	btn.Activated:Connect(function()
		closed = true
	end)
	local t0 = os.clock()
	while not closed and os.clock() - t0 < 5.5 do
		task.wait(0.1)
	end
	conn:Disconnect()
	overlay:Destroy()
end

local function runReveals()
	if revealing then
		return
	end
	revealing = true
	while #revealQueue > 0 do
		local ok, err = pcall(playReveal, table.remove(revealQueue, 1))
		if not ok then
			warn("[Reveal]", err)
		end
	end
	revealing = false
end

-- ===================== OFFLINE SUMMARY =====================
local function showOffline(data)
	local panel = Kit.panel(screen, "BEM-VINDO DE VOLTA!", T.Gold, UDim2.fromScale(0.42, 0.5))
	panel.frame.Visible = true
	panel.frame.ZIndex = 15
	local content = panel.content
	Kit.list(content, 8)
	Kit.label({ Text = "Você ficou fora por " .. NF.time(data.rawSeconds), Parent = content, Size = UDim2.new(1, 0, 0, 34), MaxTextSize = 26, LayoutOrder = 1 })
	Kit.label({ Text = "💰 Seus pets geraram " .. NF.format(data.gold) .. " GOLD (50%, até 8h)", Parent = content, Size = UDim2.new(1, 0, 0, 30), TextColor3 = T.Gold, MaxTextSize = 24, LayoutOrder = 2 })
	Kit.label({ Text = "🥚 Ovos chocados: " .. #data.hatched, Parent = content, Size = UDim2.new(1, 0, 0, 30), MaxTextSize = 22, LayoutOrder = 3 })
	local names = {}
	for i, h in data.hatched do
		if i > 6 then
			table.insert(names, "...")
			break
		end
		local c = Creatures.ById[h.species]
		table.insert(names, (h.mutation ~= "None" and (h.mutation .. " ") or "") .. (c and c.name or h.species))
	end
	if #names > 0 then
		Kit.label({ Text = "Novas criaturas: " .. table.concat(names, ", "), Parent = content, Size = UDim2.new(1, 0, 0, 56), Font = T.FontBody, MaxTextSize = 18, LayoutOrder = 4 })
	end
	Kit.button({ Text = "COLETAR!", color = T.Good, Size = UDim2.fromOffset(200, 54), Parent = content, LayoutOrder = 5, onClick = function()
		panel.frame:Destroy()
	end })
	panel.close.Activated:Connect(function()
		panel.frame:Destroy()
	end)
end

function Notifications.start()
	screen = Kit.screen("SAG_Notifications", 20)
	Kit.autoScale(screen)
	toastHolder = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 150), Size = UDim2.fromOffset(390, 260), Parent = screen })
	Kit.list(toastHolder, 8)

	Net.listen("Notify", function(n)
		Notifications.toast(n.kind or "Info", n.title or "", n.text)
	end)
	Net.listen("HatchReveal", function(data)
		table.insert(revealQueue, data)
		task.spawn(runReveals)
	end)
	Net.listen("OfflineSummary", function(data)
		showOffline(data)
	end)
	Net.listen("Announce", function(a)
		if a.type == "SpecialEggSoon" then
			Notifications.announce("🥚 OVO DIVINO EM " .. a.seconds .. "s!", "Prepare-se para a disputa!", Color3.fromRGB(255, 230, 120), 3)
		elseif a.type == "SpecialEggSpawned" and not a.quiet then
			Notifications.announce("✨ UM OVO DIVINO APARECEU!", "Em " .. (a.biomeName or "?") .. " — siga o feixe de luz!", Color3.fromRGB(255, 230, 120), 4)
		elseif a.type == "SpecialEggTaken" then
			Notifications.toast("Rare", "Ovo Divino capturado!", (a.by or "Alguém") .. " pegou o Ovo Divino!")
		elseif a.type == "SpecialEggGone" then
			Notifications.toast("Info", "O Ovo Divino desapareceu", "Fique atento ao próximo!")
		elseif a.type == "EventStart" then
			Notifications.announce("🎉 " .. a.name, a.desc, Color3.fromRGB(255, 110, 200), 5)
		elseif a.type == "EventWave" then
			Notifications.toast("Rare", a.name, "Novos ovos de evento apareceram pelo mapa!")
		elseif a.type == "EventEnd" then
			Notifications.toast("Info", a.name .. " terminou", "Obrigado por participar!")
		end
	end)
end

return Notifications
