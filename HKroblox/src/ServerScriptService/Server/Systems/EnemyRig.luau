--!strict
-- Monta o modelo de um inimigo a partir do EnemySpec (servidor). Raiz ancorada,
-- peças soltas ligadas por Motor6D. Os clientes animam as juntas.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EnemySpec = require(ReplicatedStorage.Shared.EnemySpec)

local EnemyRig = {}

function EnemyRig.build(def: EnemySpec.EnemyDef, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = def.displayName

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = def.rootSize
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root

	for _, spec in def.parts do
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
		part.CastShadow = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth

		local joint = Instance.new("Motor6D")
		joint.Name = "Joint"
		joint.Part0 = root
		joint.Part1 = part
		joint.C0 = CFrame.new(spec.joint)
		joint.C1 = CFrame.Angles(0, spec.yaw, 0) * CFrame.new(-spec.pivot)
		joint.Parent = part
		part.Parent = model
	end

	local aura = Instance.new("PointLight")
	aura.Name = "Aura"
	aura.Color = Color3.fromRGB(160, 190, 255)
	aura.Range = if def.id == "Boss" then 46 else 18
	aura.Brightness = if def.id == "Boss" then 1.6 else 1.1
	aura.Shadows = false
	aura.Parent = root

	model:SetAttribute("Kind", def.id)
	model:SetAttribute("State", "Idle")
	model:SetAttribute("StateAt", Workspace:GetServerTimeNow())
	model:SetAttribute("Dur", 1)
	model:SetAttribute("Facing", 1)
	model:SetAttribute("Health", def.health)
	model:SetAttribute("MaxHealth", def.health)
	model:SetAttribute("HitAt", 0)
	CollectionService:AddTag(model, "Enemy")
	return model
end

return EnemyRig
