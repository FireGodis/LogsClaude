--[[
	Tutorial — one short objective at a time + a glowing beam from the player to the target.
	Disappears once all objectives are done (progress comes from the server).
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Util.Net)
local Kit = require(script.Parent.Parent.UI.Kit)

local Tutorial = {}
local C
local player = Players.LocalPlayer
local T = Kit.Theme

-- mirrors server/Systems/Tutorial.luau
local STEPS = {
	{ key = "SeeBase", text = "Esta é a sua base! Seus ovos e criaturas ficam aqui." },
	{ key = "StealEgg", text = "Vá ao Bosque de Arcádia e ROUBE um ovo (segure E)." },
	{ key = "Deposit", text = "Volte para a sua base com o ovo para depositá-lo." },
	{ key = "Hatch", text = "Espere o ovo chocar na incubadora." },
	{ key = "Collect", text = "Pise na plataforma dourada para coletar o GOLD dos pets." },
	{ key = "Train", text = "Corra na esteira da sua base para ganhar Speed." },
	{ key = "BuyTrail", text = "Compre seu primeiro Trail (multiplica o treino)." },
	{ key = "UnlockBiome", text = "Alcance 150 Speed e desbloqueie a Costa do Mar Egeu." },
	{ key = "OpenIndex", text = "Abra o Index e veja todas as criaturas." },
	{ key = "RaidTip", text = "Dica: você pode roubar ovos que estão incubando em outras bases!" },
}

local bar, textLabel, beam, a0, a1, targetPart
local currentKey = nil
local raidTipShownAt = nil

function Tutorial.init(ctx)
	C = ctx
end

local function baseModel()
	local d = C.State.get()
	return d and d.baseIndex and Workspace.Bases:FindFirstChild("Base_" .. d.baseIndex)
end

local function targetFor(key: string): Vector3?
	local base = baseModel()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if key == "SeeBase" or key == "Deposit" or key == "Hatch" then
		return base and base.PrimaryPart and (base.PrimaryPart.CFrame * CFrame.new(0, 3, -14)).Position
	elseif key == "StealEgg" then
		local best, bd = nil, math.huge
		for _, egg in CollectionService:GetTagged("WorldEgg") do
			local pp = egg.PrimaryPart
			if pp and egg:GetAttribute("Biome") == 1 and root then
				local d = (pp.Position - root.Position).Magnitude
				if d < bd then
					best, bd = pp.Position, d
				end
			end
		end
		return best
	elseif key == "Collect" then
		local pad = base and base:FindFirstChild("CollectPad")
		return pad and pad.Position
	elseif key == "Train" or key == "UnlockBiome" then
		local tm = base and base.Visuals:FindFirstChild("Treadmill")
		return tm and tm.PrimaryPart and tm.PrimaryPart.Position
	elseif key == "BuyTrail" then
		local k = Workspace.Map.ShopPlaza:FindFirstChild("Kiosk_Trails")
		return k and k.PrimaryPart and k.PrimaryPart.Position
	end
	return nil
end

local function refresh(d)
	local done = d.tutDone or {}
	local step = nil
	local idx = d.tutorial or 1
	if idx > #STEPS then
		bar.Visible = false
		beam.Enabled = false
		currentKey = nil
		return
	end
	for _, s in STEPS do
		if not done[s.key] then
			step = s
			break
		end
	end
	step = step or STEPS[math.clamp(idx, 1, #STEPS)]
	currentKey = step.key
	bar.Visible = true
	textLabel.Text = "🎯 " .. step.text
	if step.key == "RaidTip" and not raidTipShownAt then
		raidTipShownAt = os.clock()
		task.delay(12, function()
			Net.request("TutorialStep", { key = "RaidTip" })
		end)
	end
end

function Tutorial.markIndexOpened()
	if currentKey == "OpenIndex" then
		Net.request("TutorialStep", { key = "OpenIndex" })
	end
end

function Tutorial.start()
	local screen = Kit.screen("SAG_Tutorial", 3)
	Kit.autoScale(screen)
	bar = Kit.new("Frame", { BackgroundColor3 = T.Panel, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 82), Size = UDim2.fromOffset(520, 44), Visible = false, Parent = screen })
	Kit.corner(bar, 14)
	Kit.stroke(bar, T.Good, 2.5)
	Kit.gradient(bar, T.PanelLight, T.Panel)
	textLabel = Kit.label({ Text = "", Parent = bar, Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), MaxTextSize = 20 })

	targetPart = Instance.new("Part")
	targetPart.Anchored = true
	targetPart.CanCollide = false
	targetPart.CanQuery = false
	targetPart.Transparency = 1
	targetPart.Size = Vector3.one
	targetPart.Parent = Workspace
	a1 = Instance.new("Attachment")
	a1.Parent = targetPart
	beam = Instance.new("Beam")
	beam.Color = ColorSequence.new(Color3.fromRGB(120, 255, 160), Color3.fromRGB(255, 240, 140))
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureSpeed = 2
	beam.TextureLength = 4
	beam.Transparency = NumberSequence.new(0.2)
	beam.Attachment1 = a1
	beam.Enabled = false
	beam.Parent = targetPart

	C.State.Changed:Connect(function(d, partial)
		if not partial then
			refresh(d)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local target = currentKey and targetFor(currentKey)
			if root and target then
				if not a0 or a0.Parent ~= root then
					a0 = Instance.new("Attachment")
					a0.Parent = root
					beam.Attachment0 = a0
				end
				targetPart.Position = target + Vector3.new(0, 2, 0)
				beam.Enabled = (target - root.Position).Magnitude > 10
			else
				beam.Enabled = false
			end
		end
	end)
end

return Tutorial
