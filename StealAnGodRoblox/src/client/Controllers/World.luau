--[[
	World — client-side world presentation:
	  • locked gates become solid for this player (server double-checks positions)
	  • per-biome lighting/atmosphere and mythology music; world-event lighting overrides
	  • special egg tracker (screen-edge arrow + distance)
	  • proximity prompt routing: kiosks open panels, pets open the info card, your own
	    incubating eggs don't show a "steal" prompt; egg info card when looking at an egg
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local Kit = require(script.Parent.Parent.UI.Kit)

local World = {}
local C
local player = Players.LocalPlayer
local T = Kit.Theme

local BIOME_LIGHT = {
	[0] = { ClockTime = 14, Ambient = Color3.fromRGB(110, 110, 130), Fog = Color3.fromRGB(200, 215, 240), Density = 0.28, Myth = "Hub" },
	{ ClockTime = 13, Ambient = Color3.fromRGB(110, 130, 100), Fog = Color3.fromRGB(210, 235, 200), Density = 0.25, Myth = "Greek" },
	{ ClockTime = 15, Ambient = Color3.fromRGB(100, 130, 150), Fog = Color3.fromRGB(180, 220, 245), Density = 0.25, Myth = "Greek" },
	{ ClockTime = 17.8, Ambient = Color3.fromRGB(80, 60, 50), Fog = Color3.fromRGB(110, 80, 60), Density = 0.42, Myth = "Greek" },
	{ ClockTime = 12, Ambient = Color3.fromRGB(150, 140, 110), Fog = Color3.fromRGB(255, 245, 220), Density = 0.3, Myth = "Greek" },
	{ ClockTime = 10, Ambient = Color3.fromRGB(100, 120, 100), Fog = Color3.fromRGB(190, 210, 200), Density = 0.32, Myth = "Norse" },
	{ ClockTime = 9, Ambient = Color3.fromRGB(120, 140, 170), Fog = Color3.fromRGB(220, 235, 255), Density = 0.45, Myth = "Norse" },
	{ ClockTime = 20, Ambient = Color3.fromRGB(120, 60, 40), Fog = Color3.fromRGB(90, 40, 30), Density = 0.4, Myth = "Norse" },
	{ ClockTime = 16, Ambient = Color3.fromRGB(140, 120, 90), Fog = Color3.fromRGB(255, 225, 170), Density = 0.3, Myth = "Norse" },
	{ ClockTime = 11, Ambient = Color3.fromRGB(130, 130, 100), Fog = Color3.fromRGB(245, 230, 190), Density = 0.3, Myth = "Egyptian" },
	{ ClockTime = 18.5, Ambient = Color3.fromRGB(110, 90, 70), Fog = Color3.fromRGB(200, 160, 110), Density = 0.38, Myth = "Egyptian" },
	{ ClockTime = 0.8, Ambient = Color3.fromRGB(70, 50, 110), Fog = Color3.fromRGB(50, 30, 80), Density = 0.5, Myth = "Egyptian" },
	{ ClockTime = 12.5, Ambient = Color3.fromRGB(170, 140, 80), Fog = Color3.fromRGB(255, 220, 140), Density = 0.32, Myth = "Egyptian" },
}

local currentBiome = -1
local eventActive = nil
local special = nil -- {position}
local arrow
local eggCard

function World.init(ctx)
	C = ctx
end

local function applyLighting(cfg, eventCfg)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	local info = TweenInfo.new(2.5)
	if eventCfg then
		TweenService:Create(Lighting, info, { ClockTime = eventCfg.ClockTime, Brightness = eventCfg.Brightness, Ambient = eventCfg.Ambient, OutdoorAmbient = eventCfg.OutdoorAmbient }):Play()
		if atmo then
			TweenService:Create(atmo, info, { Color = eventCfg.FogColor, Density = 0.4 }):Play()
		end
		return
	end
	TweenService:Create(Lighting, info, { ClockTime = cfg.ClockTime, Ambient = cfg.Ambient, Brightness = 2.2, OutdoorAmbient = cfg.Ambient:Lerp(Color3.new(1, 1, 1), 0.15) }):Play()
	if atmo then
		TweenService:Create(atmo, info, { Color = cfg.Fog, Density = cfg.Density }):Play()
	end
end

local function eventLighting()
	if not eventActive then
		return nil
	end
	for _, e in GameConfig.Events do
		if e.id == eventActive then
			return e.lighting
		end
	end
	return nil
end

local function updateGates()
	local d = C.State.get()
	local speed = d and d.speed or 0
	local map = Workspace:FindFirstChild("Map")
	if not map then
		return
	end
	for _, biome in map:GetChildren() do
		local gate = biome:FindFirstChild("Gate_" .. tostring(biome:GetAttribute("BiomeId")))
		local barrier = gate and gate:FindFirstChild("Barrier")
		if barrier then
			local req = barrier:GetAttribute("RequiredSpeed") or 0
			local locked = speed < req
			barrier.CanCollide = locked
			barrier.Transparency = locked and 0.55 or 1
			local board = gate:FindFirstChild("RequirementBoard")
			if board then
				board.Transparency = locked and 0.2 or 1
				local label = board:FindFirstChild("RequirementLabel", true)
				if label then
					label.Text = locked and ("🔒 " .. NF.format(req) .. " SPEED") or ""
				end
			end
		end
	end
end

-- ===================== EGG INFO CARD =====================
local function showEggCard(model: Model)
	if not eggCard then
		return
	end
	local biome = model:GetAttribute("Biome") or 1
	local variant = model:GetAttribute("Variant") or "normal"
	local size = model:GetAttribute("Size") or "Normal"
	eggCard.Visible = true
	eggCard.Title.Text = model:GetAttribute("EggName") or "Ovo"
	local b = Formulas.biome(biome)
	local difficulty = ({ "Muito fácil", "Fácil", "Médio", "Médio", "Difícil", "Difícil", "Muito difícil", "Muito difícil", "Extremo", "Extremo", "Lendário", "Lendário" })[biome]
	local pen = Balance.speed.carryPenaltyBySize[size] or 0
	local lines = {
		"Raridade: " .. (model:GetAttribute("Rarity") or "?") .. "   •   Bioma: " .. b.name,
		"Tamanho: " .. Formulas.size(size).eggName .. " (x" .. Formulas.size(size).mult .. " renda, −" .. math.floor(pen * 100) .. "% velocidade)",
		"Mutação: " .. (model:GetAttribute("Mutation") or "None") .. "   •   Dificuldade: " .. difficulty,
	}
	local weights = Balance.speciesHatchWeights[variant] or Balance.speciesHatchWeights.normal
	local eventId = model:GetAttribute("EventId")
	local contents = {}
	if variant == "event" and eventId and Creatures.Events[eventId] then
		table.insert(contents, Creatures.Events[eventId].name .. " 100%")
	else
		local total = 0
		for _, w in weights do
			total += w
		end
		for slot = 1, 4 do
			local c = Creatures.ByBiome[biome][slot]
			table.insert(contents, c.name .. " " .. math.floor(weights[slot] / total * 1000 + 0.5) / 10 .. "%")
		end
	end
	table.insert(lines, "Pode conter: " .. table.concat(contents, ", "))
	eggCard.Body.Text = table.concat(lines, "\n")
end

local function buildUi()
	local screen = Kit.screen("SAG_World", 2)
	Kit.autoScale(screen)
	-- the arrow lives in an unscaled, inset-free screen so viewport coordinates map 1:1
	local arrowScreen = Kit.screen("SAG_Tracker", 3)
	arrowScreen.IgnoreGuiInset = true
	arrow = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(70, 70), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, Parent = arrowScreen })
	Kit.label({ Text = "➤", Parent = arrow, Name = "Glyph", TextColor3 = Color3.fromRGB(255, 230, 120), stroke = true })
	Kit.label({ Text = "", Parent = arrow, Name = "Dist", Size = UDim2.fromOffset(120, 24), Position = UDim2.new(0.5, -60, 1, 0), MaxTextSize = 18 })
	eggCard = Kit.new("Frame", { BackgroundColor3 = T.Panel, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(560, 130), Visible = false, Parent = screen })
	Kit.corner(eggCard, 14)
	Kit.stroke(eggCard, T.Gold, 2.5)
	Kit.gradient(eggCard, T.PanelLight, T.Panel)
	local title = Kit.label({ Text = "", Parent = eggCard, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 4), MaxTextSize = 24, TextColor3 = T.Gold })
	title.Name = "Title"
	local body = Kit.label({ Text = "", Parent = eggCard, Size = UDim2.new(1, -20, 1, -40), Position = UDim2.fromOffset(10, 36), Font = T.FontBody, MaxTextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })
	body.Name = "Body"
end

local function handlePrompt(prompt: ProximityPrompt)
	-- hide the steal prompt on your own incubating eggs
	if prompt.Name == "RaidPrompt" and prompt:GetAttribute("Owner") == player.UserId then
		prompt.Enabled = false
	end
end

function World.start()
	buildUi()
	C.State.Changed:Connect(function(_, partial)
		updateGates()
	end)
	C.State.WorldChanged:Connect(function(w)
		eventActive = w.event
		applyLighting(BIOME_LIGHT[math.max(currentBiome, 0)], eventLighting())
	end)
	Net.listen("Announce", function(a)
		if a.type == "SpecialEggSpawned" then
			special = { position = a.position }
		elseif a.type == "SpecialEggTaken" or a.type == "SpecialEggGone" then
			special = nil
		end
	end)

	-- prompts
	for _, d in Workspace:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			handlePrompt(d)
		end
	end
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") then
			task.defer(handlePrompt, d)
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local panel = prompt:GetAttribute("OpenPanel")
		if panel then
			C.Panels.open(panel)
		elseif prompt:GetAttribute("Inspect") then
			local model = prompt:FindFirstAncestorOfClass("Model")
			if model then
				C.PetInfoUI.show(model)
			end
		end
	end)
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt.Name == "StealPrompt" or prompt.Name == "RaidPrompt" then
			local model = prompt:FindFirstAncestorOfClass("Model")
			if model then
				showEggCard(model)
			end
		end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		if (prompt.Name == "StealPrompt" or prompt.Name == "RaidPrompt") and eggCard then
			eggCard.Visible = false
		end
	end)

	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		if acc > 0.5 then
			acc = 0
			local z = root.Position.Z
			local W = GameConfig.World
			local b = z < W.HubLength and 0 or math.clamp(math.floor((z - W.HubLength) / W.BiomeLength) + 1, 1, 12)
			if b ~= currentBiome then
				currentBiome = b
				applyLighting(BIOME_LIGHT[b], eventLighting())
				C.Sound.music(BIOME_LIGHT[b].Myth)
				if b > 0 then
					C.Notifications.toast("Unlock", "Você entrou em", Formulas.biome(b).name)
				end
			end
		end
		-- special egg arrow
		if special and arrow then
			local cam = Workspace.CurrentCamera
			local pos, onScreen = cam:WorldToViewportPoint(special.position)
			local dist = (special.position - root.Position).Magnitude
			arrow.Visible = true
			arrow.Dist.Text = math.floor(dist) .. " studs"
			local vs = cam.ViewportSize
			if onScreen and pos.Z > 0 then
				arrow.Position = UDim2.fromOffset(pos.X, pos.Y - 60)
				arrow.Glyph.Rotation = 90
			else
				local dir = Vector2.new(pos.X - vs.X / 2, pos.Y - vs.Y / 2)
				if pos.Z < 0 then
					dir = -dir
				end
				if dir.Magnitude < 1 then
					dir = Vector2.new(0, -1)
				end
				dir = dir.Unit
				local edge = Vector2.new(vs.X / 2, vs.Y / 2) + dir * (math.min(vs.X, vs.Y) / 2 - 60)
				arrow.Position = UDim2.fromOffset(edge.X, edge.Y)
				arrow.Glyph.Rotation = math.deg(math.atan2(dir.Y, dir.X))
			end
		elseif arrow then
			arrow.Visible = false
		end
	end)
end

return World
