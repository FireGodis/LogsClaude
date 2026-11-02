--!strict
-- Constrói o Cavaleiro no servidor (todos veem). Cada cliente anima as juntas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Spec = require(ReplicatedStorage.Shared.KnightSpec)

local KnightRig = {}

function KnightRig.build(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid then
		return
	end

	-- Esconde o avatar padrão por completo.
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= root then
			descendant.Transparency = 1
		elseif
			descendant:IsA("Accessory")
			or descendant:IsA("Shirt")
			or descendant:IsA("Pants")
			or descendant:IsA("ShirtGraphic")
			or descendant:IsA("BodyColors")
			or descendant:IsA("Decal")
		then
			descendant:Destroy()
		end
	end

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.AutoRotate = false
	humanoid.BreakJointsOnDeath = false
	humanoid.WalkSpeed = Config.Move.RunSpeed

	local rig = Instance.new("Folder")
	rig.Name = "KnightRig"

	for _, spec in Spec.Parts do
		local part: BasePart
		if spec.kind == "Wedge" then
			part = Instance.new("WedgePart")
		else
			local block = Instance.new("Part")
			block.Shape = if spec.kind == "Ball" then Enum.PartType.Ball else Enum.PartType.Block
			part = block
		end
		part.Name = spec.name
		part.Size = spec.size
		part.Color = spec.color
		part.Material = spec.material
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.Anchored = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		if spec.name == "Nail" or string.sub(spec.name, 1, 4) == "Wing" then
			part.Transparency = 1
		end

		local joint = Instance.new("Motor6D")
		joint.Name = "Joint"
		joint.Part0 = root
		joint.Part1 = part
		joint.C0 = CFrame.new(spec.joint)
		joint.C1 = CFrame.Angles(0, spec.yaw, 0) * CFrame.new(-spec.pivot)
		joint.Parent = part

		if spec.name == "Body" then
			local aura = Instance.new("PointLight")
			aura.Name = "Aura"
			aura.Color = Color3.fromRGB(200, 222, 255)
			aura.Brightness = 0.7
			aura.Range = 16
			aura.Shadows = false
			aura.Parent = part

			local glow = Instance.new("PointLight")
			glow.Name = "Glow"
			glow.Color = Color3.fromRGB(190, 220, 255)
			glow.Brightness = 2.2
			glow.Range = 14
			glow.Enabled = false
			glow.Parent = part
		end

		part.Parent = rig
	end

	rig.Parent = character
end

return KnightRig
