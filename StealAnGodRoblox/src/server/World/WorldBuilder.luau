--[[
	WorldBuilder — generates the whole STEAL AN GOD map:
	  hub (spawn, 7 base plots, shop plaza, ranking board), the long avenue and the 12 biomes with
	  gates, nests, guardian patrol points and themed scenery.

	Runs automatically on server start when Workspace.Map is missing (or has an older build
	version). It can also be run in EDIT mode from the Studio command bar so the map is saved
	inside the place file — see tools/StudioWipeAndBuild.luau.
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Balance = require(Shared.Config.Balance)
local ModelFactory = require(Shared.Factory.ModelFactory)
local BiomeDecor = require(script.Parent.BiomeDecor)

local C3 = Color3.fromRGB
local M = Enum.Material
local W = GameConfig.World

local WorldBuilder = {}
WorldBuilder.BUILD_VERSION = 3

local part = BiomeDecor.part

local BIOME_FLOOR = {
	{ C3(110, 175, 80), M.Grass }, { C3(235, 215, 165), M.Sand }, { C3(130, 115, 100), M.Cobblestone },
	{ C3(245, 245, 250), M.Marble }, { C3(90, 140, 70), M.Grass }, { C3(235, 245, 255), M.Snow },
	{ C3(55, 45, 45), M.Basalt }, { C3(240, 225, 180), M.Marble }, { C3(225, 200, 140), M.Sand },
	{ C3(205, 175, 120), M.Sandstone }, { C3(45, 30, 65), M.Slate }, { C3(240, 205, 120), M.Sandstone },
}
local AVENUE_COLOR = {
	C3(200, 190, 170), C3(215, 205, 180), C3(150, 140, 125), C3(255, 235, 170), C3(130, 120, 110), C3(200, 220, 235),
	C3(90, 75, 70), C3(255, 215, 110), C3(210, 190, 150), C3(180, 160, 120), C3(80, 60, 110), C3(255, 215, 120),
}

function WorldBuilder.biomeZ(biomeId: number): (number, number)
	local z0 = W.HubLength + (biomeId - 1) * W.BiomeLength
	return z0, z0 + W.BiomeLength
end

function WorldBuilder.biomeAt(z: number): number
	if z < W.HubLength then
		return 0
	end
	return math.clamp(math.floor((z - W.HubLength) / W.BiomeLength) + 1, 1, #Balance.biomes)
end

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function marker(name: string, cf: CFrame, parent: Instance, size: Vector3?)
	local p = part(parent, size or Vector3.new(1, 1, 1), cf, C3(255, 255, 255), M.SmoothPlastic, false)
	p.Name = name
	p.Transparency = 1
	p.CanQuery = false
	p.CanTouch = false
	return p
end

local function sign(parentPart: BasePart, face: Enum.NormalId, text: string, color: Color3, textSize: number?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = textSize == nil
	label.TextSize = textSize or 14
	label.Font = GameConfig.Theme.Font
	label.TextStrokeTransparency = 0.2
	label.Name = "Label"
	label.Parent = gui
	gui.Parent = parentPart
	return label
end
WorldBuilder.sign = sign

-- ===================== LIGHTING =====================
local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.2
	Lighting.Ambient = C3(110, 110, 130)
	Lighting.OutdoorAmbient = C3(140, 140, 160)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local a = Instance.new("Atmosphere")
		a.Density = 0.28
		a.Offset = 0.1
		a.Color = C3(200, 215, 240)
		a.Decay = C3(110, 120, 170)
		a.Glare = 0.2
		a.Haze = 1.2
		a.Parent = Lighting
	end
	if not Lighting:FindFirstChild("SAG_Bloom") then
		local b = Instance.new("BloomEffect")
		b.Name = "SAG_Bloom"
		b.Intensity = 0.6
		b.Size = 28
		b.Threshold = 1.6
		b.Parent = Lighting
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "SAG_Color"
		cc.Saturation = 0.12
		cc.Contrast = 0.05
		cc.Parent = Lighting
		local sr = Instance.new("SunRaysEffect")
		sr.Name = "SAG_SunRays"
		sr.Intensity = 0.04
		sr.Parent = Lighting
	end
end

-- ===================== HUB =====================
local function buildHub(map: Folder)
	local hub = folder("Hub", map)
	local floor = part(hub, Vector3.new(W.HubWidth, 2, W.HubLength + 40), CFrame.new(0, -1, (W.HubLength - 40) / 2), C3(120, 170, 95), M.Grass)
	floor.Name = "HubFloor"
	-- plaza tiles around avenue
	local plaza = part(hub, Vector3.new(W.AvenueWidth + 20, 0.2, W.HubLength + 40), CFrame.new(0, 0.1, (W.HubLength - 40) / 2), C3(225, 215, 195), M.Pavement)
	plaza.Name = "Plaza"

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(W.SpawnPosition - Vector3.new(0, 4.5, 0))
	spawn.Color = C3(255, 210, 90)
	spawn.Material = M.Marble
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = hub

	-- colossal statue behind spawn (outside the avenue)
	local back = Vector3.new(0, 0, -28)
	part(hub, Vector3.new(30, 4, 14), CFrame.new(back + Vector3.new(0, 2, 0)), C3(235, 230, 220), M.Marble)
	local st = BiomeDecor.statue(hub, back + Vector3.new(0, 4, 0), 3, C3(255, 210, 90), M.Metal)
	st.Name = "PantheonStatue"
	local title = part(hub, Vector3.new(44, 10, 1), CFrame.new(0, 34, -36), C3(30, 25, 60), M.SmoothPlastic, false)
	title.Name = "TitleBoard"
	sign(title, Enum.NormalId.Back, "STEAL AN GOD", GameConfig.Theme.Gold)
	sign(title, Enum.NormalId.Front, "STEAL AN GOD", GameConfig.Theme.Gold)

	-- lamp posts along the hub walkway
	for i = 0, 7 do
		local z = 20 + i * 42
		BiomeDecor.torch(hub, Vector3.new(-W.AvenueWidth / 2 - 3, 0, z), C3(255, 220, 140))
		BiomeDecor.torch(hub, Vector3.new(W.AvenueWidth / 2 + 3, 0, z), C3(255, 220, 140))
	end

	-- hub boundary walls
	local wallH = 40
	for side = -1, 1, 2 do
		local wall = part(hub, Vector3.new(2, wallH, W.HubLength + 40), CFrame.new(side * W.HubWidth / 2, wallH / 2, (W.HubLength - 40) / 2), C3(255, 255, 255), M.SmoothPlastic)
		wall.Transparency = 1
		wall.Name = "Boundary"
		-- connector between hub width and biome width
		local conn = part(hub, Vector3.new((W.HubWidth - W.BiomeWidth) / 2, wallH, 2), CFrame.new(side * (W.BiomeWidth / 2 + (W.HubWidth - W.BiomeWidth) / 4), wallH / 2, W.HubLength), C3(255, 255, 255), M.SmoothPlastic)
		conn.Transparency = 1
		conn.Name = "Boundary"
		-- decorative hedge
		part(hub, Vector3.new(4, 6, W.HubLength + 40), CFrame.new(side * (W.HubWidth / 2 - 2), 3, (W.HubLength - 40) / 2), C3(70, 130, 60), M.Grass)
	end
	local backWall = part(hub, Vector3.new(W.HubWidth, wallH, 2), CFrame.new(0, wallH / 2, -40), C3(255, 255, 255), M.SmoothPlastic)
	backWall.Transparency = 1
	backWall.Name = "Boundary"

	return hub
end

-- ===================== SHOP PLAZA (kiosks) =====================
local KIOSKS = {
	{ id = "Shop", label = "LOJA DIVINA", color = C3(255, 200, 60), offset = Vector3.new(-14, 0, -26) },
	{ id = "Trails", label = "TRAILS", color = C3(150, 120, 255), offset = Vector3.new(14, 0, -26) },
	{ id = "Upgrades", label = "MELHORIAS", color = C3(90, 200, 255), offset = Vector3.new(-14, 0, 0) },
	{ id = "Index", label = "INDEX", color = C3(90, 220, 140), offset = Vector3.new(14, 0, 0) },
	{ id = "Rewards", label = "RECOMPENSAS", color = C3(255, 120, 160), offset = Vector3.new(0, 0, 24) },
}

local function buildPlaza(map: Folder)
	local plaza = folder("ShopPlaza", map)
	local center = Vector3.new(W.BaseOffsetX, 0, W.BaseRows[4])
	part(plaza, Vector3.new(70, 0.4, 76), CFrame.new(center + Vector3.new(0, 0.2, 0)), C3(240, 230, 205), M.Marble).Name = "PlazaFloor"
	for _, k in KIOSKS do
		local pos = center + k.offset
		local kiosk = Instance.new("Model")
		kiosk.Name = "Kiosk_" .. k.id
		local base = part(kiosk, Vector3.new(10, 3, 6), CFrame.new(pos + Vector3.new(0, 1.5, 0)), C3(60, 50, 90), M.Marble)
		part(kiosk, Vector3.new(10.6, 0.6, 6.6), CFrame.new(pos + Vector3.new(0, 3.2, 0)), k.color, M.Metal)
		BiomeDecor.column(kiosk, pos + Vector3.new(-4.5, 3.5, 2.5), 7, C3(240, 235, 220), M.Marble)
		BiomeDecor.column(kiosk, pos + Vector3.new(4.5, 3.5, 2.5), 7, C3(240, 235, 220), M.Marble)
		local board = part(kiosk, Vector3.new(11, 3.5, 0.6), CFrame.new(pos + Vector3.new(0, 12.5, 2.5)), C3(30, 25, 60), M.SmoothPlastic)
		sign(board, Enum.NormalId.Front, k.label, k.color)
		sign(board, Enum.NormalId.Back, k.label, k.color)
		local orb = part(kiosk, Vector3.new(2, 2, 2), CFrame.new(pos + Vector3.new(0, 5, 0)), k.color, M.Neon, false, Enum.PartType.Ball)
		orb.Name = "Orb"
		ModelFactory.addLight(orb, k.color, 12, 1.5)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Abrir"
		prompt.ObjectText = k.label
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("OpenPanel", k.id)
		prompt.Parent = base
		kiosk.PrimaryPart = base
		kiosk.Parent = plaza
	end
	-- ranking board
	local boardPos = center + Vector3.new(30, 0, 0)
	local lb = part(plaza, Vector3.new(1, 22, 30), CFrame.new(boardPos + Vector3.new(0, 13, 0)), C3(25, 22, 50), M.SmoothPlastic)
	lb.Name = "Leaderboard"
	part(plaza, Vector3.new(1.4, 23, 31), CFrame.new(boardPos + Vector3.new(0.3, 13, 0)), C3(255, 205, 70), M.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Parent = lb
	return plaza
end

-- ===================== BASE PLOTS =====================
function WorldBuilder.baseCFrames(): { CFrame }
	local list = {}
	for _, z in W.BaseRows do
		table.insert(list, CFrame.lookAt(Vector3.new(-W.BaseOffsetX, 0, z), Vector3.new(0, 0, z)))
	end
	for i = 1, 3 do
		local z = W.BaseRows[i]
		table.insert(list, CFrame.lookAt(Vector3.new(W.BaseOffsetX, 0, z), Vector3.new(0, 0, z)))
	end
	return list
end

-- Local layout (entrance at local -Z, facing the avenue)
WorldBuilder.BaseLayout = {
	incubatorCols = 7, incubatorRows = 4, incubatorSpacing = 6, incubatorStartZ = -26,
	petCols = 11, petRows = 5, petSpacingX = 6.5, petSpacingZ = 6, petStartZ = 3,
	treadmill = CFrame.new(-29, 0, -20),
	collectPad = CFrame.new(29, 0, -24),
	sign = CFrame.new(0, 0, -34),
}

local function buildBasePlot(index: number, cf: CFrame, parent: Folder)
	local L = WorldBuilder.BaseLayout
	local base = Instance.new("Model")
	base.Name = "Base_" .. index
	base:SetAttribute("BaseIndex", index)
	local size = W.BaseSize
	local floor = part(base, Vector3.new(size.X, 1, size.Z), cf * CFrame.new(0, 0.5, 0), C3(205, 195, 175), M.Slate)
	floor.Name = "Floor"
	local region = marker("Region", cf * CFrame.new(0, 8, 0), base, Vector3.new(size.X, 16, size.Z))
	region.Name = "Region"
	local anchor = marker("Anchor", cf, base)
	base.PrimaryPart = anchor

	-- Incubator slot markers
	local inc = folder("IncubatorSlots", base)
	local n = 0
	for r = 0, L.incubatorRows - 1 do
		for c = 0, L.incubatorCols - 1 do
			n += 1
			local x = (c - (L.incubatorCols - 1) / 2) * L.incubatorSpacing
			local z = L.incubatorStartZ + r * L.incubatorSpacing
			marker("Slot_" .. n, cf * CFrame.new(x, 1, z), inc)
		end
	end
	local pets = folder("PetSlots", base)
	n = 0
	for r = 0, L.petRows - 1 do
		for c = 0, L.petCols - 1 do
			n += 1
			local x = (c - (L.petCols - 1) / 2) * L.petSpacingX
			local z = L.petStartZ + r * L.petSpacingZ
			marker("Pet_" .. n, cf * CFrame.new(x, 1, z) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, math.pi, 0), pets)
		end
	end
	marker("TreadmillSpot", cf * L.treadmill * CFrame.new(0, 1, 0), base)
	-- collect pad (vault)
	local pad = part(base, Vector3.new(8, 0.6, 8), cf * L.collectPad * CFrame.new(0, 1.3, 0), C3(255, 205, 70), M.Neon, false)
	pad.Name = "CollectPad"
	pad.Transparency = 0.2
	pad.CanQuery = true
	local vaultBoard = part(base, Vector3.new(8, 4, 0.5), cf * L.collectPad * CFrame.new(0, 6, 4), C3(30, 25, 60), M.SmoothPlastic, false)
	vaultBoard.Name = "VaultBoard"
	local vaultLabel = sign(vaultBoard, Enum.NormalId.Front, "COLETAR\n0", GameConfig.Theme.Gold)
	vaultLabel.Name = "VaultLabel"
	vaultBoard.CFrame = vaultBoard.CFrame * CFrame.Angles(0, math.pi, 0)

	-- entrance sign
	local signPost = part(base, Vector3.new(24, 5, 1), cf * L.sign * CFrame.new(0, 12, 0), C3(30, 25, 60), M.SmoothPlastic, false)
	signPost.Name = "OwnerSign"
	local ownerLabel = sign(signPost, Enum.NormalId.Front, "BASE LIVRE", C3(255, 255, 255))
	ownerLabel.Name = "OwnerLabel"
	local ownerBack = sign(signPost, Enum.NormalId.Back, "BASE LIVRE", C3(255, 255, 255))
	ownerBack.Name = "OwnerLabelBack"
	folder("Visuals", base)
	folder("Incubating", base)
	folder("PetDisplays", base)
	base.Parent = parent
	return base
end

-- ===================== BIOMES =====================
local function nestModel(cf: CFrame, color: Color3): Model
	local m = Instance.new("Model")
	m.Name = "Nest"
	local hay = part(m, Vector3.new(0.6, 6, 6), cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), C3(200, 170, 90), M.Fabric, false, Enum.PartType.Cylinder)
	for i = 1, 8 do
		local a = math.rad(i * 45)
		part(m, Vector3.new(3.2, 0.8, 0.8), cf * CFrame.new(math.cos(a) * 2.8, 0.7, math.sin(a) * 2.8) * CFrame.Angles(0, -a + math.pi / 2, 0), C3(120, 85, 50), M.Wood, false)
	end
	local glow = part(m, Vector3.new(0.2, 5, 5), cf * CFrame.new(0, 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)), color, M.Neon, false, Enum.PartType.Cylinder)
	glow.Transparency = 0.6
	m.PrimaryPart = hay
	return m
end

local function buildGate(biomeId: number, z: number, parent: Instance)
	local b = Balance.biomes[biomeId]
	local gate = Instance.new("Model")
	gate.Name = "Gate_" .. biomeId
	local archColor = (b.mythology == "Greek" and C3(240, 235, 220)) or (b.mythology == "Norse" and C3(110, 100, 95)) or C3(225, 195, 130)
	local trim = (b.mythology == "Greek" and C3(255, 210, 90)) or (b.mythology == "Norse" and C3(120, 210, 255)) or C3(255, 180, 40)
	local mat = (b.mythology == "Greek" and M.Marble) or (b.mythology == "Norse" and M.Slate) or M.Sandstone
	for side = -1, 1, 2 do
		part(gate, Vector3.new(6, 26, 6), CFrame.new(side * (W.AvenueWidth / 2 + 4), 13, z), archColor, mat)
		part(gate, Vector3.new(7, 2, 7), CFrame.new(side * (W.AvenueWidth / 2 + 4), 26.5, z), trim, M.Metal)
	end
	part(gate, Vector3.new(W.AvenueWidth + 14, 5, 6), CFrame.new(0, 29, z), archColor, mat)
	local board = part(gate, Vector3.new(W.AvenueWidth + 4, 4, 0.4), CFrame.new(0, 29, z - 3.2), C3(30, 25, 60), M.SmoothPlastic, false)
	local req = b.speedRequired
	local label = sign(board, Enum.NormalId.Front, string.upper(b.name), trim)
	label.Name = "GateLabel"
	sign(board, Enum.NormalId.Back, string.upper(b.name), trim)
	local barrier = part(gate, Vector3.new(W.BiomeWidth, 40, 1), CFrame.new(0, 20, z), trim, M.ForceField, false)
	barrier.Name = "Barrier"
	barrier.Transparency = req > 0 and 0.55 or 1
	barrier.CanQuery = false
	barrier:SetAttribute("RequiredSpeed", req)
	barrier:SetAttribute("BiomeId", biomeId)
	gate:SetAttribute("BiomeId", biomeId)
	gate:SetAttribute("RequiredSpeed", req)
	if req > 0 then
		local reqBoard = part(gate, Vector3.new(16, 6, 0.4), CFrame.new(0, 8, z - 1), C3(30, 25, 60), M.SmoothPlastic, false)
		reqBoard.Name = "RequirementBoard"
		reqBoard.Transparency = 0.2
		local l = sign(reqBoard, Enum.NormalId.Front, "REQUER " .. req .. " SPEED", C3(255, 255, 255))
		l.Name = "RequirementLabel"
	end
	gate.Parent = parent
	return gate
end

local function buildBiome(biomeId: number, map: Folder, rng: Random)
	local b = Balance.biomes[biomeId]
	local z0, z1 = WorldBuilder.biomeZ(biomeId)
	local bf = folder("Biome_" .. biomeId, map)
	bf:SetAttribute("BiomeId", biomeId)
	bf:SetAttribute("ZStart", z0)
	bf:SetAttribute("ZEnd", z1)
	bf:SetAttribute("Mythology", b.mythology)
	local fc = BIOME_FLOOR[biomeId]
	local floor = part(bf, Vector3.new(W.BiomeWidth, 2, W.BiomeLength), CFrame.new(0, -1, z0 + W.BiomeLength / 2), fc[1], fc[2])
	floor.Name = "Floor"
	local avenue = part(bf, Vector3.new(W.AvenueWidth, 0.2, W.BiomeLength), CFrame.new(0, 0.1, z0 + W.BiomeLength / 2), AVENUE_COLOR[biomeId], M.Pavement)
	avenue.Name = "Avenue"
	for side = -1, 1, 2 do
		local wall = part(bf, Vector3.new(2, 60, W.BiomeLength), CFrame.new(side * (W.BiomeWidth / 2 + 1), 30, z0 + W.BiomeLength / 2), C3(255, 255, 255), M.SmoothPlastic)
		wall.Transparency = 1
		wall.Name = "Boundary"
		-- curb
		part(bf, Vector3.new(1.2, 0.6, W.BiomeLength), CFrame.new(side * (W.AvenueWidth / 2 + 0.6), 0.3, z0 + W.BiomeLength / 2), AVENUE_COLOR[biomeId]:Lerp(C3(0, 0, 0), 0.25), M.Concrete, false)
	end
	buildGate(biomeId, z0, bf)

	local decor = folder("Decor", bf)
	BiomeDecor.build(biomeId, { folder = decor, z0 = z0, length = W.BiomeLength, width = W.BiomeWidth, avenueHalf = W.AvenueWidth / 2, rng = rng })

	-- Nests (alternate sides, outside the avenue)
	local nests = folder("Nests", bf)
	local maxOff = biomeId == 3 and 18 or 42
	for k = 1, W.NestsPerBiome do
		local side = (k % 2 == 0) and 1 or -1
		local x = side * (W.AvenueWidth / 2 + rng:NextNumber(10, maxOff))
		local z = z0 + 30 + (k - 1) * ((W.BiomeLength - 50) / (W.NestsPerBiome - 1))
		local cf = CFrame.new(x, 0.2, z)
		local nm = nestModel(cf, Color3.fromRGB(b.eggColor[1], b.eggColor[2], b.eggColor[3]))
		nm.Name = "Nest_" .. k
		nm:SetAttribute("BiomeId", biomeId)
		nm:SetAttribute("NestIndex", k)
		marker("EggPoint", cf * CFrame.new(0, 0.7, 0), nm)
		nm.Parent = nests
	end

	-- Guardian spawn + patrol points around the nests
	local guardians = folder("GuardianPoints", bf)
	local count = biomeId <= 4 and 1 or 2
	guardians:SetAttribute("Count", count)
	for g = 1, count do
		local gf = folder("Guardian_" .. g, guardians)
		for k = 1, W.NestsPerBiome do
			local include = count == 1 or ((g == 1) == (k % 2 == 1))
			if include then
				local nest = nests:FindFirstChild("Nest_" .. k) :: Model
				local p = nest.PrimaryPart.Position
				local towardAvenue = -math.sign(p.X) * 9
				marker("Patrol_" .. k, CFrame.new(p.X + towardAvenue, 0.5, p.Z + rng:NextNumber(-6, 6)), gf)
			end
		end
	end

	-- Special egg / event spawn spots (open ground)
	local spots = folder("SpawnSpots", bf)
	for s = 1, 6 do
		local side = (s % 2 == 0) and 1 or -1
		marker("Spot_" .. s, CFrame.new(side * (W.AvenueWidth / 2 + rng:NextNumber(4, 30)), 1, z0 + 20 + (s - 1) * 36), spots)
	end
	return bf
end

-- ===================== ENTRY =====================
function WorldBuilder.isBuilt(): boolean
	local map = Workspace:FindFirstChild("Map")
	return map ~= nil and map:GetAttribute("BuildVersion") == WorldBuilder.BUILD_VERSION and Workspace:FindFirstChild("Bases") ~= nil
end

function WorldBuilder.build(force: boolean?)
	if WorldBuilder.isBuilt() and not force then
		return Workspace.Map
	end
	for _, name in { "Map", "Bases", "Runtime" } do
		local old = Workspace:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	setupLighting()
	local rng = Random.new(20261105)
	local map = Instance.new("Folder")
	map.Name = "Map"
	buildHub(map)
	buildPlaza(map)
	for i = 1, #Balance.biomes do
		buildBiome(i, map, rng)
	end
	-- end wall
	local _, zEnd = WorldBuilder.biomeZ(#Balance.biomes)
	local endWall = part(map, Vector3.new(W.BiomeWidth, 80, 2), CFrame.new(0, 40, zEnd + 1), C3(255, 255, 255), M.SmoothPlastic)
	endWall.Transparency = 1
	endWall.Name = "Boundary"
	map:SetAttribute("BuildVersion", WorldBuilder.BUILD_VERSION)
	map.Parent = Workspace

	local bases = Instance.new("Folder")
	bases.Name = "Bases"
	for i, cf in WorldBuilder.baseCFrames() do
		buildBasePlot(i, cf, bases)
	end
	bases.Parent = Workspace

	local runtime = Instance.new("Folder")
	runtime.Name = "Runtime"
	for _, n in { "Eggs", "Guardians", "Bots", "Traps", "Pets", "Effects" } do
		folder(n, runtime)
	end
	runtime.Parent = Workspace
	return map
end

-- Runtime folders are recreated each server start (they are never saved meaningfully).
function WorldBuilder.ensureRuntime()
	local runtime = Workspace:FindFirstChild("Runtime")
	if runtime then
		runtime:Destroy()
	end
	runtime = Instance.new("Folder")
	runtime.Name = "Runtime"
	for _, n in { "Eggs", "Guardians", "Bots", "Traps", "Pets", "Effects" } do
		folder(n, runtime)
	end
	runtime.Parent = Workspace
	return runtime
end

return WorldBuilder
