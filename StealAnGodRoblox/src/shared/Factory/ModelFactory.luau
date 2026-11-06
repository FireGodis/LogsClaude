--[[
	ModelFactory — builds every gameplay model procedurally (stylized, low part count, Roblox-native).

	Used by the server (world/pets/eggs/guardians/treadmills) and by the client (ViewportFrames in
	the Index/Inventory). Blender-authored meshes can replace any builder later: put a Model named
	after the species/egg/treadmill into ReplicatedStorage.Assets.<Category> and the factory will
	clone it instead (see docs/ASSET_PIPELINE.md).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = script.Parent.Parent
local Creatures = require(Shared.Config.Creatures)
local Formulas = require(Shared.Util.Formulas)

local ModelFactory = {}

local C3 = Color3.fromRGB
local EYE = C3(20, 20, 28)

local function rgb(arr)
	if typeof(arr) == "Color3" then
		return arr
	end
	return C3(arr[1], arr[2], arr[3])
end
ModelFactory.rgb = rgb

-- ---------- primitive helpers ----------
local function newPart(model: Model, name: string, shape: Enum.PartType?, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Anchored = true
	p.CastShadow = false
	p.Parent = model
	return p
end
ModelFactory.newPart = newPart

local function ball(model, name, d, cf, color, mat)
	return newPart(model, name, Enum.PartType.Ball, Vector3.new(d, d, d), cf, color, mat)
end
local function block(model, name, size, cf, color, mat)
	return newPart(model, name, Enum.PartType.Block, size, cf, color, mat)
end
local function cyl(model, name, size, cf, color, mat)
	return newPart(model, name, Enum.PartType.Cylinder, size, cf, color, mat)
end
local function wedge(model, name, size, cf, color, mat)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = mat or Enum.Material.SmoothPlastic
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	w.CastShadow = false
	w.Parent = model
	return w
end
local function ellipsoid(model, name, size, cf, color, mat)
	local p = newPart(model, name, Enum.PartType.Block, size, cf, color, mat)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end
ModelFactory.ellipsoid = ellipsoid

local function eyes(model, headCF: CFrame, spacing: number, d: number, forward: number)
	ball(model, "EyeL", d, headCF * CFrame.new(-spacing, 0.1, -forward), EYE)
	ball(model, "EyeR", d, headCF * CFrame.new(spacing, 0.1, -forward), EYE)
	-- tiny shine
	ball(model, "ShineL", d * 0.35, headCF * CFrame.new(-spacing + d * 0.15, 0.1 + d * 0.15, -forward - d * 0.35), C3(255, 255, 255), Enum.Material.Neon)
	ball(model, "ShineR", d * 0.35, headCF * CFrame.new(spacing + d * 0.15, 0.1 + d * 0.15, -forward - d * 0.35), C3(255, 255, 255), Enum.Material.Neon)
end

local function finalize(model: Model, root: BasePart)
	model.PrimaryPart = root
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = d
			w.Parent = d
		end
	end
	return model
end

local function addLight(part: BasePart, color: Color3, range: number, brightness: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1.5
	l.Shadows = false
	l.Parent = part
	return l
end
ModelFactory.addLight = addLight

local function addParticles(part: BasePart, color: Color3, rate: number, opts)
	opts = opts or {}
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color, opts.color2 or color)
	pe.LightEmission = opts.lightEmission or 0.8
	pe.Rate = rate
	pe.Lifetime = NumberRange.new(opts.life or 0.8, (opts.life or 0.8) * 1.6)
	pe.Speed = NumberRange.new(opts.speed or 1.5, (opts.speed or 1.5) * 2)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, opts.size or 0.25), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	pe.Texture = opts.texture or "rbxasset://textures/particles/sparkles_main.dds"
	pe.Parent = part
	CollectionService:AddTag(pe, "VFX")
	return pe
end
ModelFactory.addParticles = addParticles

-- ---------- archetype builders ----------
-- Each returns (root, headCF, handCF). Model extends from y=0 (feet) upward, facing -Z.
local Arch = {}

function Arch.Humanoid(m, p, s, a)
	local root = block(m, "Root", Vector3.new(1.4, 0.4, 1), CFrame.new(0, 0.2, 0), s)
	block(m, "LegL", Vector3.new(0.55, 1.1, 0.6), CFrame.new(-0.36, 0.75, 0), s)
	block(m, "LegR", Vector3.new(0.55, 1.1, 0.6), CFrame.new(0.36, 0.75, 0), s)
	block(m, "Torso", Vector3.new(1.5, 1.35, 0.85), CFrame.new(0, 1.95, 0), p)
	block(m, "Belt", Vector3.new(1.55, 0.2, 0.9), CFrame.new(0, 1.35, 0), a)
	block(m, "ArmL", Vector3.new(0.45, 1.25, 0.5), CFrame.new(-1.0, 1.95, 0) * CFrame.Angles(0, 0, math.rad(-8)), p)
	block(m, "ArmR", Vector3.new(0.45, 1.25, 0.5), CFrame.new(1.0, 1.95, 0) * CFrame.Angles(0, 0, math.rad(8)), p)
	ball(m, "HandL", 0.5, CFrame.new(-1.1, 1.25, 0), s)
	ball(m, "HandR", 0.5, CFrame.new(1.1, 1.25, 0), s)
	local headCF = CFrame.new(0, 3.25, 0)
	ball(m, "Head", 1.45, headCF, s)
	block(m, "Hair", Vector3.new(1.35, 0.45, 1.3), headCF * CFrame.new(0, 0.5, 0.1), p)
	eyes(m, headCF, 0.3, 0.26, 0.6)
	return root, headCF, CFrame.new(1.1, 1.25, -0.1)
end

function Arch.Quadruped(m, p, s, a)
	local root = block(m, "Root", Vector3.new(1.2, 0.3, 2), CFrame.new(0, 0.15, 0), p)
	ellipsoid(m, "Body", Vector3.new(1.9, 1.5, 2.8), CFrame.new(0, 1.45, 0), p)
	for i, off in { Vector3.new(-0.6, 0.5, -0.9), Vector3.new(0.6, 0.5, -0.9), Vector3.new(-0.6, 0.5, 0.9), Vector3.new(0.6, 0.5, 0.9) } do
		block(m, "Leg" .. i, Vector3.new(0.45, 1.0, 0.45), CFrame.new(off), s)
	end
	local headCF = CFrame.new(0, 2.2, -1.55)
	ball(m, "Head", 1.3, headCF, p)
	ellipsoid(m, "Snout", Vector3.new(0.75, 0.55, 0.6), headCF * CFrame.new(0, -0.2, -0.6), s)
	ball(m, "Nose", 0.22, headCF * CFrame.new(0, -0.1, -0.92), EYE)
	eyes(m, headCF, 0.3, 0.22, 0.5)
	block(m, "EarL", Vector3.new(0.25, 0.45, 0.15), headCF * CFrame.new(-0.45, 0.6, 0.1), s)
	block(m, "EarR", Vector3.new(0.25, 0.45, 0.15), headCF * CFrame.new(0.45, 0.6, 0.1), s)
	block(m, "Tail", Vector3.new(0.25, 0.25, 1.0), CFrame.new(0, 1.8, 1.7) * CFrame.Angles(math.rad(30), 0, 0), a)
	return root, headCF, CFrame.new(0, 2.2, 0)
end

function Arch.Canine(m, p, s, a)
	local root, headCF, hand = Arch.Quadruped(m, p, s, a)
	-- pointed ears + longer snout
	for _, n in { "EarL", "EarR" } do
		local e = m:FindFirstChild(n) :: BasePart
		e.Size = Vector3.new(0.3, 0.7, 0.2)
		e.CFrame = e.CFrame * CFrame.new(0, 0.15, 0)
	end
	local snout = m:FindFirstChild("Snout") :: BasePart
	snout.Size = Vector3.new(0.7, 0.55, 1.0)
	snout.CFrame = snout.CFrame * CFrame.new(0, 0, -0.2)
	return root, headCF, hand
end

function Arch.Feline(m, p, s, a)
	local root, headCF, hand = Arch.Quadruped(m, p, s, a)
	local body = m:FindFirstChild("Body") :: BasePart
	body.Size = Vector3.new(1.6, 1.3, 2.7)
	for _, n in { "EarL", "EarR" } do
		local e = m:FindFirstChild(n) :: BasePart
		e:Destroy()
	end
	wedge(m, "EarL", Vector3.new(0.2, 0.55, 0.45), headCF * CFrame.new(-0.4, 0.7, 0.05), p)
	wedge(m, "EarR", Vector3.new(0.2, 0.55, 0.45), headCF * CFrame.new(0.4, 0.7, 0.05), p)
	local tail = m:FindFirstChild("Tail") :: BasePart
	tail.Size = Vector3.new(0.22, 0.22, 1.6)
	tail.CFrame = CFrame.new(0, 2.2, 1.9) * CFrame.Angles(math.rad(55), 0, 0)
	return root, headCF, hand
end

function Arch.Horse(m, p, s, a)
	local root = block(m, "Root", Vector3.new(1.2, 0.3, 2), CFrame.new(0, 0.15, 0), p)
	ellipsoid(m, "Body", Vector3.new(1.6, 1.5, 3.0), CFrame.new(0, 2.0, 0), p)
	for i, off in { Vector3.new(-0.5, 0.75, -1.0), Vector3.new(0.5, 0.75, -1.0), Vector3.new(-0.5, 0.75, 1.0), Vector3.new(0.5, 0.75, 1.0) } do
		block(m, "Leg" .. i, Vector3.new(0.4, 1.5, 0.4), CFrame.new(off), p)
		block(m, "Hoof" .. i, Vector3.new(0.45, 0.25, 0.45), CFrame.new(off.X, 0.12, off.Z), s)
	end
	block(m, "Neck", Vector3.new(0.7, 1.4, 0.8), CFrame.new(0, 3.0, -1.35) * CFrame.Angles(math.rad(-25), 0, 0), p)
	local headCF = CFrame.new(0, 3.75, -1.9)
	block(m, "Head", Vector3.new(0.8, 0.8, 1.4), headCF, p)
	block(m, "Mane", Vector3.new(0.25, 1.6, 0.6), CFrame.new(0, 3.3, -1.1) * CFrame.Angles(math.rad(-25), 0, 0), a)
	eyes(m, headCF * CFrame.new(0, 0.1, 0.2), 0.42, 0.2, 0.2)
	block(m, "Tail", Vector3.new(0.3, 1.4, 0.3), CFrame.new(0, 1.9, 1.7) * CFrame.Angles(math.rad(25), 0, 0), a)
	return root, headCF, CFrame.new(0, 2.8, 0)
end

function Arch.Bird(m, p, s, a)
	local root = block(m, "Root", Vector3.new(1, 0.3, 1), CFrame.new(0, 0.15, 0), s)
	block(m, "LegL", Vector3.new(0.18, 0.8, 0.18), CFrame.new(-0.3, 0.5, 0), a)
	block(m, "LegR", Vector3.new(0.18, 0.8, 0.18), CFrame.new(0.3, 0.5, 0), a)
	ellipsoid(m, "Body", Vector3.new(1.6, 1.8, 2.0), CFrame.new(0, 1.7, 0), p)
	ellipsoid(m, "Belly", Vector3.new(1.2, 1.3, 0.6), CFrame.new(0, 1.55, -0.75), s)
	local headCF = CFrame.new(0, 2.95, -0.35)
	ball(m, "Head", 1.15, headCF, p)
	wedge(m, "Beak", Vector3.new(0.3, 0.3, 0.6), headCF * CFrame.new(0, -0.1, -0.75) * CFrame.Angles(0, math.rad(180), 0), a)
	eyes(m, headCF, 0.28, 0.2, 0.45)
	block(m, "WingL", Vector3.new(0.2, 1.3, 1.6), CFrame.new(-0.95, 1.9, 0.1) * CFrame.Angles(0, 0, math.rad(-20)), p)
	block(m, "WingR", Vector3.new(0.2, 1.3, 1.6), CFrame.new(0.95, 1.9, 0.1) * CFrame.Angles(0, 0, math.rad(20)), p)
	wedge(m, "TailFeathers", Vector3.new(0.9, 0.2, 1.0), CFrame.new(0, 1.4, 1.2), s)
	return root, headCF, CFrame.new(0, 2, 0)
end

function Arch.Serpent(m, p, s, a)
	local root = block(m, "Root", Vector3.new(1.2, 0.3, 1.2), CFrame.new(0, 0.15, 0), p)
	local coils = { { 1.7, Vector3.new(0, 0.85, 0.6) }, { 1.5, Vector3.new(0.6, 1.3, 0.1) }, { 1.3, Vector3.new(0.1, 1.9, -0.3) }, { 1.1, Vector3.new(-0.3, 2.55, -0.45) } }
	for i, c in coils do
		ball(m, "Coil" .. i, c[1], CFrame.new(c[2]), (i % 2 == 0) and s or p)
	end
	local headCF = CFrame.new(-0.2, 3.25, -0.75)
	ellipsoid(m, "Head", Vector3.new(1.0, 0.8, 1.3), headCF, p)
	block(m, "Tongue", Vector3.new(0.08, 0.04, 0.5), headCF * CFrame.new(0, -0.2, -0.8), C3(220, 40, 60))
	eyes(m, headCF, 0.3, 0.2, 0.45)
	ball(m, "TailTip", 0.6, CFrame.new(-0.7, 0.4, 1.3), a)
	return root, headCF, CFrame.new(0, 2, 0)
end

function Arch.Golem(m, p, s, a)
	local root = block(m, "Root", Vector3.new(1.8, 0.4, 1.4), CFrame.new(0, 0.2, 0), s)
	block(m, "LegL", Vector3.new(0.8, 1.2, 0.8), CFrame.new(-0.55, 0.8, 0), s)
	block(m, "LegR", Vector3.new(0.8, 1.2, 0.8), CFrame.new(0.55, 0.8, 0), s)
	block(m, "Torso", Vector3.new(2.3, 1.8, 1.4), CFrame.new(0, 2.3, 0), p)
	block(m, "Core", Vector3.new(0.6, 0.6, 0.2), CFrame.new(0, 2.4, -0.72), a, Enum.Material.Neon)
	block(m, "ArmL", Vector3.new(0.8, 1.9, 0.8), CFrame.new(-1.6, 2.0, 0), p)
	block(m, "ArmR", Vector3.new(0.8, 1.9, 0.8), CFrame.new(1.6, 2.0, 0), p)
	local headCF = CFrame.new(0, 3.65, -0.1)
	block(m, "Head", Vector3.new(1.1, 0.9, 1.0), headCF, s)
	ball(m, "EyeL", 0.25, headCF * CFrame.new(-0.25, 0.05, -0.5), a, Enum.Material.Neon)
	ball(m, "EyeR", 0.25, headCF * CFrame.new(0.25, 0.05, -0.5), a, Enum.Material.Neon)
	return root, headCF, CFrame.new(1.6, 1.1, 0)
end

function Arch.Dragon(m, p, s, a)
	local root, headCF, hand = Arch.Quadruped(m, p, s, a)
	local snout = m:FindFirstChild("Snout") :: BasePart
	snout.Size = Vector3.new(0.8, 0.5, 1.1)
	snout.CFrame = snout.CFrame * CFrame.new(0, 0, -0.25)
	block(m, "WingL", Vector3.new(1.8, 0.15, 1.2), CFrame.new(-1.4, 2.4, 0) * CFrame.Angles(0, 0, math.rad(25)), a)
	block(m, "WingR", Vector3.new(1.8, 0.15, 1.2), CFrame.new(1.4, 2.4, 0) * CFrame.Angles(0, 0, math.rad(-25)), a)
	for i = 1, 3 do
		wedge(m, "Spike" .. i, Vector3.new(0.15, 0.4, 0.4), CFrame.new(0, 2.25, -0.6 + i * 0.5), a)
	end
	return root, headCF, hand
end

function Arch.Spirit(m, p, s, a)
	local root = block(m, "Root", Vector3.new(0.8, 0.2, 0.8), CFrame.new(0, 0.1, 0), s)
	root.Transparency = 1
	local core = ball(m, "Body", 1.8, CFrame.new(0, 1.9, 0), p, Enum.Material.Neon)
	core.Transparency = 0.15
	ball(m, "Inner", 1.1, CFrame.new(0, 1.9, 0), s, Enum.Material.Neon)
	local headCF = CFrame.new(0, 3.1, 0)
	ball(m, "Head", 1.1, headCF, p)
	eyes(m, headCF, 0.25, 0.22, 0.45)
	for i = 1, 3 do
		local ang = math.rad(i * 120)
		ball(m, "Wisp" .. i, 0.4, CFrame.new(math.cos(ang) * 1.3, 1.6, math.sin(ang) * 1.3), a, Enum.Material.Neon)
	end
	addLight(core, p, 8, 1)
	return root, headCF, CFrame.new(0, 2, 0)
end

function Arch.Insect(m, p, s, a)
	local root = block(m, "Root", Vector3.new(1.2, 0.3, 1.6), CFrame.new(0, 0.15, 0), s)
	ellipsoid(m, "Shell", Vector3.new(2.0, 1.3, 2.4), CFrame.new(0, 1.1, 0.2), p, Enum.Material.Glass)
	block(m, "ShellLine", Vector3.new(0.08, 1.32, 2.42), CFrame.new(0, 1.1, 0.2), a)
	local headCF = CFrame.new(0, 1.1, -1.2)
	ball(m, "Head", 0.9, headCF, s)
	eyes(m, headCF, 0.22, 0.2, 0.35)
	for i = 1, 3 do
		local z = -0.6 + (i - 1) * 0.6
		block(m, "LegL" .. i, Vector3.new(0.9, 0.12, 0.12), CFrame.new(-1.1, 0.45, z) * CFrame.Angles(0, 0, math.rad(30)), s)
		block(m, "LegR" .. i, Vector3.new(0.9, 0.12, 0.12), CFrame.new(1.1, 0.45, z) * CFrame.Angles(0, 0, math.rad(-30)), s)
	end
	block(m, "HornA", Vector3.new(0.12, 0.6, 0.12), headCF * CFrame.new(-0.2, 0.5, -0.1), a)
	block(m, "HornB", Vector3.new(0.12, 0.6, 0.12), headCF * CFrame.new(0.2, 0.5, -0.1), a)
	return root, headCF, CFrame.new(0, 1.5, 0)
end

-- ---------- accessories ----------
local function accessory(m: Model, kind: string, headCF: CFrame, handCF: CFrame, colors, mythology: string)
	local p, s, a = colors[1], colors[2], colors[3]
	local gold = C3(255, 205, 70)
	if kind == "horns" then
		wedge(m, "HornL", Vector3.new(0.2, 0.7, 0.4), headCF * CFrame.new(-0.45, 0.75, 0) * CFrame.Angles(0, 0, math.rad(20)), C3(240, 230, 210))
		wedge(m, "HornR", Vector3.new(0.2, 0.7, 0.4), headCF * CFrame.new(0.45, 0.75, 0) * CFrame.Angles(0, 0, math.rad(-20)), C3(240, 230, 210))
	elseif kind == "wings" then
		local w1 = block(m, "WingL", Vector3.new(0.15, 1.6, 1.2), headCF * CFrame.new(-0.9, -1.0, 0.7) * CFrame.Angles(0, math.rad(-25), math.rad(-25)), C3(255, 255, 255), Enum.Material.SmoothPlastic)
		local w2 = block(m, "WingR", Vector3.new(0.15, 1.6, 1.2), headCF * CFrame.new(0.9, -1.0, 0.7) * CFrame.Angles(0, math.rad(25), math.rad(25)), C3(255, 255, 255), Enum.Material.SmoothPlastic)
		w1.Transparency = 0.05
		w2.Transparency = 0.05
	elseif kind == "crown" then
		cyl(m, "Crown", Vector3.new(0.35, 1.0, 1.0), headCF * CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Metal)
		ball(m, "Gem", 0.25, headCF * CFrame.new(0, 0.8, -0.5), a, Enum.Material.Neon)
	elseif kind == "helmet" then
		ball(m, "Helmet", 1.55, headCF * CFrame.new(0, 0.12, 0.05), C3(190, 190, 200), Enum.Material.Metal)
		block(m, "Crest", Vector3.new(0.18, 0.6, 1.4), headCF * CFrame.new(0, 0.85, 0.1), a)
		-- re-add eyes in front of helmet
		eyes(m, headCF, 0.3, 0.24, 0.72)
	elseif kind == "halo" then
		local h = cyl(m, "Halo", Vector3.new(0.1, 1.3, 1.3), headCF * CFrame.new(0, 1.0, 0) * CFrame.Angles(0, 0, math.rad(90)), C3(255, 250, 180), Enum.Material.Neon)
		addLight(h, C3(255, 240, 160), 6, 1)
	elseif kind == "trident" then
		block(m, "Shaft", Vector3.new(0.15, 3.2, 0.15), handCF * CFrame.new(0, 0.9, 0), gold, Enum.Material.Metal)
		for i = -1, 1 do
			block(m, "Prong" .. i, Vector3.new(0.12, 0.6, 0.12), handCF * CFrame.new(i * 0.25, 2.7, 0), gold, Enum.Material.Metal)
		end
	elseif kind == "lightning" then
		local bolt = block(m, "Bolt", Vector3.new(0.2, 1.4, 0.2), handCF * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(20)), C3(255, 245, 120), Enum.Material.Neon)
		block(m, "Bolt2", Vector3.new(0.2, 0.9, 0.2), handCF * CFrame.new(0.15, 1.7, 0) * CFrame.Angles(0, 0, math.rad(-30)), C3(255, 245, 120), Enum.Material.Neon)
		addLight(bolt, C3(255, 240, 120), 7, 1.5)
	elseif kind == "sun" then
		local disk = cyl(m, "SunDisk", Vector3.new(0.15, 1.6, 1.6), headCF * CFrame.new(0, 1.0, 0.45) * CFrame.Angles(0, math.rad(90), 0), C3(255, 170, 40), Enum.Material.Neon)
		addLight(disk, C3(255, 180, 60), 8, 1.4)
	elseif kind == "ankh" then
		block(m, "AnkhStem", Vector3.new(0.15, 1.0, 0.15), handCF * CFrame.new(0, 0.6, 0), gold, Enum.Material.Metal)
		block(m, "AnkhBar", Vector3.new(0.6, 0.15, 0.15), handCF * CFrame.new(0, 1.0, 0), gold, Enum.Material.Metal)
		cyl(m, "AnkhLoop", Vector3.new(0.12, 0.45, 0.45), handCF * CFrame.new(0, 1.35, 0) * CFrame.Angles(0, math.rad(90), 0), gold, Enum.Material.Metal)
	elseif kind == "mask" then
		block(m, "Mask", Vector3.new(1.0, 0.5, 0.2), headCF * CFrame.new(0, 0.12, -0.62), gold, Enum.Material.Metal)
		block(m, "Headdress", Vector3.new(1.6, 1.2, 0.3), headCF * CFrame.new(0, -0.1, 0.45), a)
	elseif kind == "hammer" then
		block(m, "Handle", Vector3.new(0.15, 1.3, 0.15), handCF * CFrame.new(0, 0.4, 0), C3(110, 70, 40), Enum.Material.Wood)
		block(m, "HammerHead", Vector3.new(0.7, 0.5, 0.45), handCF * CFrame.new(0, 1.1, 0), C3(170, 170, 185), Enum.Material.Metal)
	elseif kind == "spear" then
		block(m, "Spear", Vector3.new(0.12, 3.2, 0.12), handCF * CFrame.new(0, 0.9, 0), C3(140, 100, 60), Enum.Material.Wood)
		wedge(m, "SpearTip", Vector3.new(0.12, 0.5, 0.3), handCF * CFrame.new(0, 2.7, 0), C3(220, 220, 230), Enum.Material.Metal)
	elseif kind == "bow" then
		cyl(m, "Bow", Vector3.new(0.12, 1.8, 1.8), handCF * CFrame.new(0.15, 0.6, 0) * CFrame.Angles(0, math.rad(90), 0), C3(220, 220, 255), Enum.Material.Neon).Transparency = 0.3
	elseif kind == "lyre" then
		block(m, "LyreL", Vector3.new(0.12, 0.9, 0.12), handCF * CFrame.new(-0.2, 0.5, 0), gold, Enum.Material.Metal)
		block(m, "LyreR", Vector3.new(0.12, 0.9, 0.12), handCF * CFrame.new(0.2, 0.5, 0), gold, Enum.Material.Metal)
		block(m, "LyreTop", Vector3.new(0.55, 0.12, 0.12), handCF * CFrame.new(0, 0.95, 0), gold, Enum.Material.Metal)
	elseif kind == "rune" then
		local r = block(m, "Rune", Vector3.new(0.45, 0.6, 0.12), headCF * CFrame.new(0.9, 0.6, 0), C3(120, 210, 255), Enum.Material.Neon)
		addLight(r, C3(120, 200, 255), 5, 1)
	elseif kind == "flame" then
		local f = ball(m, "Flame", 0.5, headCF * CFrame.new(0, 0.85, 0), C3(255, 140, 40), Enum.Material.Neon)
		addParticles(f, C3(255, 150, 40), 6, { color2 = C3(255, 60, 20), speed = 2, size = 0.35 })
		addLight(f, C3(255, 130, 40), 7, 1.2)
	elseif kind == "crystal" then
		for i = -1, 1 do
			wedge(m, "Crystal" .. i, Vector3.new(0.25, 0.7, 0.35), headCF * CFrame.new(i * 0.35, 0.75, 0.1), C3(160, 230, 255), Enum.Material.Glass)
		end
	elseif kind == "fins" then
		wedge(m, "FinTop", Vector3.new(0.15, 0.6, 1.0), headCF * CFrame.new(0, 0.65, 0.3), a)
	elseif kind == "flower" then
		ball(m, "Flower", 0.45, headCF * CFrame.new(0.45, 0.6, 0), C3(255, 150, 200), Enum.Material.Neon)
		ball(m, "FlowerCore", 0.22, headCF * CFrame.new(0.45, 0.6, -0.15), C3(255, 230, 80))
	end
end

-- Mythology flourish (small, cheap) so every pantheon reads differently.
local function mythologyFlourish(m: Model, root: BasePart, mythology: string)
	if mythology == "Greek" then
		ball(m, "Laurel", 0.25, root.CFrame * CFrame.new(0, 0.3, 0.6), C3(120, 200, 90))
	elseif mythology == "Norse" then
		block(m, "RuneMark", Vector3.new(0.3, 0.3, 0.05), root.CFrame * CFrame.new(0, 0.3, 0.55), C3(120, 210, 255), Enum.Material.Neon)
	elseif mythology == "Egyptian" then
		block(m, "GoldBand", Vector3.new(0.9, 0.1, 0.9), root.CFrame * CFrame.new(0, 0.3, 0), C3(255, 205, 70), Enum.Material.Metal)
	end
end

-- ---------- mutation + rarity visuals ----------
local SKIP_RECOLOR = { EyeL = true, EyeR = true, ShineL = true, ShineR = true, Nose = true, Tongue = true }

function ModelFactory.applyMutation(model: Model, mutationName: string?)
	local mut = Formulas.mutation(mutationName)
	model:SetAttribute("Mutation", mut.name)
	if mut.name == "None" or not mut.color then
		return
	end
	local mc = rgb(mut.color)
	local strength = 0.6
	local material = nil
	if mut.name == "Golden" then
		material = Enum.Material.Metal
		strength = 0.75
	elseif mut.name == "Silver" then
		material = Enum.Material.Metal
	elseif mut.name == "Shadow" or mut.name == "Void" then
		strength = 0.8
	elseif mut.name == "Radiant" then
		material = Enum.Material.Neon
		strength = 0.45
	elseif mut.name == "Cosmic" then
		material = Enum.Material.Glass
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not SKIP_RECOLOR[d.Name] and d.Transparency < 1 then
			d.Color = d.Color:Lerp(mc, strength)
			if material and d.Material ~= Enum.Material.Neon then
				d.Material = material
			end
		end
	end
	local root = model.PrimaryPart
	if root then
		local fx = {
			Golden = { C3(255, 220, 80), 4 }, Silver = { C3(230, 235, 255), 3 }, Shadow = { C3(120, 60, 200), 4 },
			Celestial = { C3(150, 210, 255), 5 }, Radiant = { C3(255, 250, 200), 6 }, Cosmic = { C3(150, 100, 255), 6 },
			Void = { C3(60, 0, 90), 6 }, Rainbow = { C3(255, 120, 220), 7 },
		}
		local e = fx[mut.name]
		if e then
			addParticles(root, e[1], e[2], { size = 0.3, speed = 1 })
		end
		if mut.name == "Rainbow" then
			CollectionService:AddTag(model, "RainbowModel")
		end
		if mut.name == "Radiant" or mut.name == "Celestial" or mut.name == "Cosmic" then
			addLight(root, mc, 10, 1.2)
		end
	end
end

function ModelFactory.applyRarityAura(model: Model, rarityName: string)
	local r = Formulas.rarity(rarityName)
	local root = model.PrimaryPart
	if not root or r.index < 5 then
		return
	end
	local color = rgb(r.color)
	addParticles(root, color, 2 + (r.index - 5) * 2, { size = 0.35, speed = 0.8, life = 1.2 })
	if r.index >= 8 then
		addLight(root, color, 12, 1.5)
	end
end

-- Optional Blender/mesh override: ReplicatedStorage.Assets.<category>.<name>
local function override(category: string, name: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild(category)
	local m = folder and folder:FindFirstChild(name)
	if m and m:IsA("Model") then
		return m:Clone()
	end
	return nil
end

-- ---------- public builders ----------
-- Builds a creature. Model is anchored; call ModelFactory.unanchor for followers.
function ModelFactory.creature(speciesId: string, sizeName: string?, mutationName: string?, opts): Model
	opts = opts or {}
	local c = Creatures.ById[speciesId]
	local model = override("Creatures", speciesId)
	if not model then
		model = Instance.new("Model")
		model.Name = speciesId
		local colors = c and c.colors or { C3(200, 200, 200), C3(150, 150, 150), C3(255, 255, 255) }
		local builder = Arch[c and c.arch or "Quadruped"] or Arch.Quadruped
		local root, headCF, handCF = builder(model, colors[1], colors[2], colors[3])
		if c and c.acc and c.acc ~= "none" then
			accessory(model, c.acc, headCF, handCF, colors, c.mythology)
		end
		if c then
			mythologyFlourish(model, root, c.mythology)
		end
		finalize(model, root)
	end
	model:SetAttribute("Species", speciesId)
	if c then
		ModelFactory.applyRarityAura(model, c.rarity)
	end
	ModelFactory.applyMutation(model, mutationName)
	local scale = Formulas.size(sizeName).scale * (opts.scale or 1)
	if scale ~= 1 then
		model:ScaleTo(scale)
	end
	return model
end

-- Egg model. variant: "normal" | "rare" | "special" | "event"
local MYTH_PATTERN = { Greek = C3(255, 215, 90), Norse = C3(120, 210, 255), Egyptian = C3(255, 190, 60) }
function ModelFactory.egg(biomeId: number, sizeName: string?, mutationName: string?, variant: string?, eventColor: Color3?): Model
	local biome = Formulas.biome(math.max(1, biomeId))
	local model = Instance.new("Model")
	model.Name = "Egg"
	local base = rgb(biome.eggColor)
	if variant == "event" and eventColor then
		base = eventColor
	end
	local mythology = biome.mythology
	local shell = ellipsoid(model, "Shell", Vector3.new(2.1, 2.7, 2.1), CFrame.new(0, 1.35, 0), base)
	local root = shell
	local pattern = MYTH_PATTERN[mythology] or C3(255, 255, 255)
	if mythology == "Greek" then
		cyl(model, "Band", Vector3.new(0.25, 2.05, 2.05), CFrame.new(0, 1.35, 0) * CFrame.Angles(0, 0, math.rad(90)), pattern, Enum.Material.Metal)
		for i = 1, 6 do
			local ang = math.rad(i * 60)
			ball(model, "Leaf" .. i, 0.3, CFrame.new(math.cos(ang) * 1.02, 1.65, math.sin(ang) * 1.02), C3(120, 200, 90))
		end
	elseif mythology == "Norse" then
		for i = 1, 4 do
			local ang = math.rad(i * 90 + 45)
			local r = block(model, "Rune" .. i, Vector3.new(0.35, 0.55, 0.08), CFrame.new(math.cos(ang) * 1.0, 1.4, math.sin(ang) * 1.0) * CFrame.Angles(0, -ang + math.rad(90), 0), pattern, Enum.Material.Neon)
			r.Transparency = 0.1
		end
	else
		cyl(model, "Stripe1", Vector3.new(0.18, 1.95, 1.95), CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)), pattern, Enum.Material.Metal)
		cyl(model, "Stripe2", Vector3.new(0.18, 1.85, 1.85), CFrame.new(0, 1.75, 0) * CFrame.Angles(0, 0, math.rad(90)), C3(40, 90, 200))
	end
	ball(model, "Spot1", 0.45, CFrame.new(0.55, 2.0, -0.7), base:Lerp(C3(255, 255, 255), 0.5))
	ball(model, "Spot2", 0.35, CFrame.new(-0.6, 0.8, -0.75), base:Lerp(C3(255, 255, 255), 0.5))
	if variant == "rare" then
		shell.Material = Enum.Material.Metal
		addParticles(shell, C3(255, 230, 120), 5, { size = 0.3 })
		addLight(shell, C3(255, 220, 120), 8, 1)
	elseif variant == "special" then
		shell.Material = Enum.Material.Neon
		shell.Color = C3(255, 245, 200)
		addParticles(shell, C3(255, 240, 150), 12, { size = 0.45, speed = 3 })
		addLight(shell, C3(255, 230, 140), 18, 3)
	elseif variant == "event" then
		shell.Material = Enum.Material.Neon
		addParticles(shell, base, 10, { size = 0.4, speed = 2.5 })
		addLight(shell, base, 14, 2)
	end
	finalize(model, root)
	ModelFactory.applyMutation(model, mutationName)
	local s = Formulas.size(sizeName).scale
	if s ~= 1 then
		model:ScaleTo(s)
	end
	return model
end

function ModelFactory.unanchor(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.Massless = true
			d.CanCollide = false
		end
	end
end

-- ---------- guardians ----------
ModelFactory.GuardianDefs = {
	[1] = { name = "Cyclops Shepherd", arch = "Golem", colors = { C3(150, 170, 110), C3(200, 170, 130), C3(255, 230, 120) }, acc = "none" },
	[2] = { name = "Scylla Warden", arch = "Serpent", colors = { C3(40, 120, 160), C3(120, 210, 220), C3(255, 120, 90) }, acc = "fins" },
	[3] = { name = "Minotaur Warden", arch = "Humanoid", colors = { C3(110, 60, 35), C3(170, 120, 80), C3(230, 230, 230) }, acc = "horns" },
	[4] = { name = "Bronze Talos", arch = "Golem", colors = { C3(205, 140, 60), C3(150, 95, 40), C3(255, 240, 150) }, acc = "lightning" },
	[5] = { name = "Draugr Chief", arch = "Humanoid", colors = { C3(80, 100, 90), C3(140, 150, 140), C3(120, 220, 255) }, acc = "helmet" },
	[6] = { name = "Frost Jotun", arch = "Golem", colors = { C3(150, 200, 235), C3(220, 240, 255), C3(80, 160, 255) }, acc = "crystal" },
	[7] = { name = "Forge Colossus", arch = "Golem", colors = { C3(70, 60, 60), C3(120, 80, 60), C3(255, 120, 30) }, acc = "flame" },
	[8] = { name = "Einherjar Champion", arch = "Humanoid", colors = { C3(200, 200, 215), C3(255, 210, 90), C3(120, 200, 255) }, acc = "spear" },
	[9] = { name = "Crocodile Sentinel", arch = "Dragon", colors = { C3(60, 110, 60), C3(190, 180, 110), C3(255, 210, 80) }, acc = "crown" },
	[10] = { name = "Mummy Pharaoh", arch = "Humanoid", colors = { C3(225, 215, 190), C3(200, 190, 160), C3(255, 200, 60) }, acc = "mask" },
	[11] = { name = "Duat Devourer", arch = "Canine", colors = { C3(40, 30, 60), C3(120, 80, 200), C3(255, 60, 140) }, acc = "flame" },
	[12] = { name = "Solar Sphinx", arch = "Feline", colors = { C3(230, 190, 110), C3(255, 150, 40), C3(255, 250, 200) }, acc = "sun" },
}

-- Guardian = scaled creature + HumanoidRootPart + Humanoid (moves via Humanoid:MoveTo).
function ModelFactory.guardian(biomeId: number): Model
	local def = ModelFactory.GuardianDefs[biomeId] or ModelFactory.GuardianDefs[1]
	local model = Instance.new("Model")
	model.Name = "Guardian_" .. biomeId
	local builder = Arch[def.arch]
	local root, headCF, handCF = builder(model, def.colors[1], def.colors[2], def.colors[3])
	if def.acc ~= "none" then
		accessory(model, def.acc, headCF, handCF, def.colors, "")
	end
	-- angry brows
	block(model, "Brow", Vector3.new(0.9, 0.12, 0.1), headCF * CFrame.new(0, 0.38, -0.62) * CFrame.Angles(0, 0, 0), C3(30, 20, 20))
	local scale = 2.6
	local _, size = model:GetBoundingBox()
	local height = size.Y
	local hrp = block(model, "HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, height * 0.5, 0), C3(255, 255, 255))
	hrp.Transparency = 1
	model.PrimaryPart = hrp
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= hrp then
			local w = Instance.new("WeldConstraint")
			w.Part0 = hrp
			w.Part1 = d
			w.Parent = d
		end
	end
	model:ScaleTo(scale)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = d ~= hrp
		end
	end
	hrp.CanCollide = true
	local hum = Instance.new("Humanoid")
	hum.HipHeight = hrp.Position.Y - hrp.Size.Y / 2 -- feet were at y=0
	hum.WalkSpeed = 12
	hum.MaxHealth = math.huge
	hum.Health = math.huge
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false
	hum.Parent = model
	model:SetAttribute("GuardianName", def.name)
	return model
end

-- ---------- treadmills ----------
local TREADMILL_STYLE = {
	[1] = { frame = C3(120, 125, 135), belt = C3(40, 40, 45), accent = C3(90, 200, 255), mat = Enum.Material.SmoothPlastic },
	[2] = { frame = C3(140, 95, 55), belt = C3(70, 50, 35), accent = C3(200, 160, 100), mat = Enum.Material.WoodPlanks },
	[3] = { frame = C3(150, 155, 165), belt = C3(35, 35, 40), accent = C3(255, 120, 40), mat = Enum.Material.DiamondPlate },
	[4] = { frame = C3(255, 200, 60), belt = C3(60, 45, 20), accent = C3(255, 255, 200), mat = Enum.Material.Metal },
	[5] = { frame = C3(30, 35, 60), belt = C3(20, 20, 35), accent = C3(80, 180, 255), mat = Enum.Material.Metal },
	[6] = { frame = C3(240, 235, 225), belt = C3(60, 50, 40), accent = C3(255, 215, 90), mat = Enum.Material.Marble },
	[7] = { frame = C3(150, 190, 255), belt = C3(20, 20, 50), accent = C3(200, 160, 255), mat = Enum.Material.Glass },
	[8] = { frame = C3(30, 20, 25), belt = C3(15, 10, 10), accent = C3(255, 80, 20), mat = Enum.Material.Basalt },
	[9] = { frame = C3(225, 195, 140), belt = C3(80, 55, 20), accent = C3(255, 170, 40), mat = Enum.Material.Sandstone },
	[10] = { frame = C3(250, 250, 255), belt = C3(30, 20, 50), accent = C3(255, 120, 220), mat = Enum.Material.Glass },
}

-- Returns a Model at origin (front faces -Z). Contains "Belt" (conveyor) and "Stripe#" parts.
function ModelFactory.treadmill(tier: number): Model
	local m = override("Treadmills", "Treadmill" .. tier)
	if m then
		return m
	end
	local style = TREADMILL_STYLE[tier] or TREADMILL_STYLE[1]
	m = Instance.new("Model")
	m.Name = "Treadmill"
	local length, width = 14, 6
	local deck = block(m, "Deck", Vector3.new(width + 1.2, 1, length + 1), CFrame.new(0, 0.5, 0), style.frame, style.mat)
	deck.CanCollide = true
	local belt = block(m, "Belt", Vector3.new(width, 0.3, length), CFrame.new(0, 1.15, 0), style.belt, Enum.Material.Fabric)
	belt.CanCollide = true
	belt.CanQuery = true
	for i = 1, 7 do
		local stripe = block(m, "Stripe" .. i, Vector3.new(width - 0.2, 0.05, 0.25), CFrame.new(0, 1.33, -length / 2 + i * (length / 7) - 1), style.accent, Enum.Material.Neon)
		stripe.Transparency = 0.35
		stripe:SetAttribute("Index", i)
	end
	-- rollers
	cyl(m, "RollerFront", Vector3.new(width + 0.6, 1.1, 1.1), CFrame.new(0, 1.0, -length / 2) , style.accent, Enum.Material.Metal)
	cyl(m, "RollerBack", Vector3.new(width + 0.6, 1.1, 1.1), CFrame.new(0, 1.0, length / 2), style.accent, Enum.Material.Metal)
	-- rails + console
	local railC = style.frame:Lerp(C3(255, 255, 255), 0.15)
	block(m, "RailL", Vector3.new(0.35, 0.35, length * 0.6), CFrame.new(-width / 2 - 0.3, 4, -length * 0.15), railC, style.mat)
	block(m, "RailR", Vector3.new(0.35, 0.35, length * 0.6), CFrame.new(width / 2 + 0.3, 4, -length * 0.15), railC, style.mat)
	block(m, "PostL", Vector3.new(0.4, 3.2, 0.4), CFrame.new(-width / 2 - 0.3, 2.6, -length / 2 + 0.6), railC, style.mat)
	block(m, "PostR", Vector3.new(0.4, 3.2, 0.4), CFrame.new(width / 2 + 0.3, 2.6, -length / 2 + 0.6), railC, style.mat)
	local console = block(m, "Console", Vector3.new(width + 0.8, 1.6, 0.5), CFrame.new(0, 4.6, -length / 2 + 0.6) * CFrame.Angles(math.rad(-20), 0, 0), style.frame, style.mat)
	local screen = block(m, "Screen", Vector3.new(width * 0.7, 1.0, 0.1), console.CFrame * CFrame.new(0, 0, 0.27), style.accent, Enum.Material.Neon)
	screen.Transparency = 0.2
	-- tier decorations
	if tier == 2 then
		for i = -1, 1, 2 do
			cyl(m, "Rope" .. i, Vector3.new(0.25, length * 0.6, 0.25), CFrame.new(i * (width / 2 + 0.3), 3.4, -length * 0.15) * CFrame.Angles(0, math.rad(90), 0), C3(200, 170, 110), Enum.Material.Fabric)
		end
	elseif tier == 3 then
		for i = 1, 6 do
			ball(m, "Rivet" .. i, 0.3, CFrame.new((i % 2 == 0) and width / 2 + 0.55 or -width / 2 - 0.55, 0.8, -length / 2 + i * 2), C3(90, 90, 100), Enum.Material.Metal)
		end
	elseif tier == 4 then
		for i = -1, 1, 2 do
			ball(m, "Gem" .. i, 0.6, CFrame.new(i * (width / 2 + 0.3), 5.6, -length / 2 + 0.6), C3(255, 60, 90), Enum.Material.Neon)
		end
	elseif tier == 5 then
		for i = -1, 1, 2 do
			local rod = block(m, "Rod" .. i, Vector3.new(0.3, 4, 0.3), CFrame.new(i * (width / 2 + 0.6), 3, length / 2 - 0.5), C3(80, 80, 100), Enum.Material.Metal)
			local tip = ball(m, "RodTip" .. i, 0.7, rod.CFrame * CFrame.new(0, 2.2, 0), style.accent, Enum.Material.Neon)
			addLight(tip, style.accent, 10, 2)
			addParticles(tip, style.accent, 6, { speed = 4, size = 0.2 })
		end
	elseif tier == 6 then
		local halo = cyl(m, "Halo", Vector3.new(0.3, 8, 8), CFrame.new(0, 7.5, -length / 2 + 0.5) * CFrame.Angles(0, math.rad(90), 0), style.accent, Enum.Material.Neon)
		halo.Transparency = 0.3
		for i = -1, 1, 2 do
			cyl(m, "Column" .. i, Vector3.new(5, 1.1, 1.1), CFrame.new(i * (width / 2 + 1.1), 3, length / 2 - 1) * CFrame.Angles(0, 0, math.rad(90)), C3(245, 240, 230), Enum.Material.Marble)
		end
	elseif tier == 7 then
		for i = 1, 5 do
			local star = ball(m, "Star" .. i, 0.45, CFrame.new(math.sin(i) * 4, 6 + (i % 3), -length / 2 + i * 2.5), C3(220, 200, 255), Enum.Material.Neon)
			star.Transparency = 0.1
		end
		addParticles(deck, style.accent, 6, { size = 0.25 })
	elseif tier == 8 then
		for i = 1, 6 do
			wedge(m, "Spike" .. i, Vector3.new(0.6, 1.4, 0.8), CFrame.new((i % 2 == 0) and width / 2 + 0.8 or -width / 2 - 0.8, 1.4, -length / 2 + i * 2), C3(40, 30, 30), Enum.Material.Basalt)
		end
		local lava = block(m, "LavaStrip", Vector3.new(width + 1.3, 0.2, 0.6), CFrame.new(0, 1.05, length / 2 + 0.3), style.accent, Enum.Material.Neon)
		addParticles(lava, C3(255, 120, 30), 8, { speed = 3, size = 0.25 })
	elseif tier == 9 then
		local sun = cyl(m, "SunDisk", Vector3.new(0.4, 7, 7), CFrame.new(0, 8, -length / 2 + 0.3) * CFrame.Angles(0, math.rad(90), 0), style.accent, Enum.Material.Neon)
		addLight(sun, style.accent, 18, 2)
		for i = -1, 1, 2 do
			wedge(m, "Obelisk" .. i, Vector3.new(1, 6, 1), CFrame.new(i * (width / 2 + 1.3), 3.5, length / 2 - 1), C3(220, 190, 130), Enum.Material.Sandstone)
		end
	elseif tier == 10 then
		for i = 1, 3 do
			local ring = cyl(m, "Ring" .. i, Vector3.new(0.25, 6 + i * 1.5, 6 + i * 1.5), CFrame.new(0, 7 + i * 0.8, -length / 2 + 1) * CFrame.Angles(math.rad(i * 25), math.rad(90), 0), Color3.fromHSV(i / 3, 0.6, 1), Enum.Material.Neon)
			ring.Transparency = 0.25
			CollectionService:AddTag(ring, "SpinRing")
		end
		addParticles(deck, C3(255, 150, 255), 10, { size = 0.3, speed = 2 })
	end
	m.PrimaryPart = deck
	return m
end

-- ---------- traps ----------
function ModelFactory.trap(): Model
	local m = Instance.new("Model")
	m.Name = "Trap"
	local base = cyl(m, "Base", Vector3.new(0.3, 3.2, 3.2), CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), C3(90, 90, 100), Enum.Material.Metal)
	for i = 1, 8 do
		local ang = math.rad(i * 45)
		local tooth = wedge(m, "Tooth" .. i, Vector3.new(0.25, 0.6, 0.35), CFrame.new(math.cos(ang) * 1.3, 0.55, math.sin(ang) * 1.3) * CFrame.Angles(0, -ang, 0), C3(200, 200, 210), Enum.Material.Metal)
		tooth:SetAttribute("Angle", ang)
	end
	block(m, "Plate", Vector3.new(1.2, 0.1, 1.2), CFrame.new(0, 0.32, 0), C3(160, 60, 50), Enum.Material.Metal)
	finalize(m, base)
	return m
end

return ModelFactory
