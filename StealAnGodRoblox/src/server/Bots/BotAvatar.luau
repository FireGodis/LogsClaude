--[[
	BotAvatar — builds the character of a simulated participant: an R15 avatar created from a
	HumanoidDescription (random skin/clothing colors + simple accessories), the display name like
	any player's (no "BOT"/"AI"/"NPC" label), and server-side animations driven centrally.

	Clothing asset ids can be added to OUTFITS (only ids you own/are allowed to use).
	If avatar creation fails (e.g. no network in Studio), a stylized fallback rig is used.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModelFactory = require(ReplicatedStorage.Shared.Factory.ModelFactory)

local BotAvatar = {}
local S

local C3 = Color3.fromRGB
local SKIN = { C3(255, 220, 177), C3(234, 184, 146), C3(198, 134, 66), C3(141, 85, 36), C3(255, 204, 153), C3(110, 70, 40) }
local SHIRT = { C3(220, 60, 60), C3(60, 120, 220), C3(40, 170, 90), C3(240, 190, 40), C3(150, 70, 200), C3(30, 30, 40), C3(255, 140, 40), C3(240, 240, 240), C3(60, 200, 200) }
local PANTS = { C3(40, 40, 60), C3(30, 60, 120), C3(70, 50, 40), C3(20, 20, 20), C3(90, 90, 100) }
local OUTFITS = {
	-- { Shirt = 0, Pants = 0 }  -- fill with asset ids you are allowed to use
}

-- Default Roblox R15 animations (Roblox-owned, used by the default Animate script).
local ANIMS = {
	idle = "rbxassetid://507766666",
	walk = "rbxassetid://507777826",
	run = "rbxassetid://507767714",
	jump = "rbxassetid://507765000",
	fall = "rbxassetid://507767968",
}

local tracks = {} -- [id] = {idle, walk, run, current}

function BotAvatar.init(sys)
	S = sys
end

local function pick(list, rng: Random)
	return list[rng:NextInteger(1, #list)]
end

local function hat(model: Model, rng: Random)
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local kind = rng:NextInteger(1, 4)
	local color = pick(SHIRT, rng)
	local p = Instance.new("Part")
	p.CanCollide = false
	p.Massless = true
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	if kind == 1 then -- cap
		p.Size = Vector3.new(1.3, 0.45, 1.3)
		p.CFrame = head.CFrame * CFrame.new(0, 0.55, 0)
	elseif kind == 2 then -- spiky hair
		p.Size = Vector3.new(1.25, 0.6, 1.25)
		p.Color = pick({ C3(40, 30, 20), C3(250, 220, 120), C3(200, 80, 40), C3(20, 20, 20) }, rng)
		p.CFrame = head.CFrame * CFrame.new(0, 0.5, 0.05)
	elseif kind == 3 then -- headband
		p.Size = Vector3.new(1.3, 0.2, 1.3)
		p.CFrame = head.CFrame * CFrame.new(0, 0.3, 0)
	else -- laurel / crown
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.25, 1.3, 1.3)
		p.Color = C3(255, 210, 80)
		p.Material = Enum.Material.Metal
		p.CFrame = head.CFrame * CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90))
	end
	local w = Instance.new("WeldConstraint")
	w.Part0 = head
	w.Part1 = p
	w.Parent = p
	p.Parent = model
end

local function fallbackRig(name: string, rng: Random): Model
	local model = ModelFactory.creature("Hermes", "Normal", "None")
	model.Name = name
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Color = d.Color:Lerp(pick(SHIRT, rng), 0.6)
		end
	end
	local _, size = model:GetBoundingBox()
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CFrame = model:GetPivot() * CFrame.new(0, size.Y / 2, 0)
	hrp.Parent = model
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= hrp then
			local w = Instance.new("WeldConstraint")
			w.Part0 = hrp
			w.Part1 = d
			w.Parent = d
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = d == hrp
			d.Massless = d ~= hrp
		end
	end
	model.PrimaryPart = hrp
	local hum = Instance.new("Humanoid")
	hum.HipHeight = hrp.Position.Y - model:GetPivot().Position.Y - 1
	hum.Parent = model
	return model
end

function BotAvatar.build(id: number, name: string, seed: number): Model
	local rng = Random.new(seed)
	local model: Model? = nil
	local ok, result = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		local skin = pick(SKIN, rng)
		desc.HeadColor = skin
		desc.LeftArmColor = skin
		desc.RightArmColor = skin
		desc.TorsoColor = pick(SHIRT, rng)
		desc.LeftLegColor = pick(PANTS, rng)
		desc.RightLegColor = desc.LeftLegColor
		desc.HeightScale = rng:NextNumber(0.92, 1.05)
		desc.WidthScale = rng:NextNumber(0.9, 1.05)
		if #OUTFITS > 0 then
			local o = pick(OUTFITS, rng)
			desc.Shirt = o.Shirt or 0
			desc.Pants = o.Pants or 0
		end
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and result then
		model = result
		model.Name = name
		hat(model, rng)
		-- shoulders/arms take the shirt color for a "clothed" look
		local torsoColor
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "UpperTorso" then
				torsoColor = d.Color
			end
		end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and (d.Name == "LeftUpperArm" or d.Name == "RightUpperArm") and torsoColor then
				d.Color = torsoColor
			end
		end
		local animate = model:FindFirstChild("Animate")
		if animate then
			animate:Destroy() -- LocalScript would not run on a server NPC; we animate centrally
		end
	else
		warn("[BotAvatar] avatar creation failed, using fallback rig:", result)
		model = fallbackRig(name, rng)
	end
	local m = model :: Model
	local hum = m:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.DisplayName = name
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.NameDisplayDistance = 80
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	m:SetAttribute("ActorId", id)
	m:SetAttribute("Participant", true)
	return m
end

function BotAvatar.setupAnimations(id: number, model: Model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = hum
	local set = {}
	for key, assetId in ANIMS do
		local anim = Instance.new("Animation")
		anim.AnimationId = assetId
		local ok, track = pcall(animator.LoadAnimation, animator, anim)
		if ok and track then
			track.Looped = key ~= "jump"
			set[key] = track
		end
	end
	tracks[id] = set
end

function BotAvatar.forget(id: number)
	local set = tracks[id]
	if set then
		for key, t in set do
			if key ~= "current" then
				pcall(t.Stop, t)
			end
		end
	end
	tracks[id] = nil
end

local function play(set, key: string, speed: number?)
	local t = set[key]
	if not t then
		return
	end
	if set.current ~= key then
		local old = set.current and set[set.current]
		if old then
			old:Stop(0.2)
		end
		t:Play(0.2)
		set.current = key
	end
	if speed then
		t:AdjustSpeed(speed)
	end
end

function BotAvatar.start()
	task.spawn(function()
		while true do
			task.wait(0.15)
			for id, set in tracks do
				local root = S.Actors.root(id)
				local hum = S.Actors.humanoid(id)
				if root and hum then
					local v = root.AssemblyLinearVelocity
					local horizontal = Vector3.new(v.X, 0, v.Z).Magnitude
					local state = hum:GetState()
					if state == Enum.HumanoidStateType.Freefall then
						play(set, "fall")
					elseif hum.MoveDirection.Magnitude > 0.1 or horizontal > 2 then
						if hum.WalkSpeed > 22 then
							play(set, "run", math.clamp(hum.WalkSpeed / 24, 0.8, 2))
						else
							play(set, "walk", math.clamp(hum.WalkSpeed / 14, 0.7, 1.6))
						end
					else
						play(set, "idle")
					end
				end
			end
		end
	end)
end

BotAvatar._workspace = Workspace

return BotAvatar
