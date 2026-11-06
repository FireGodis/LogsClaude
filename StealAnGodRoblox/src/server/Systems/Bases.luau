--[[
	Bases — 7 plots, automatic assignment (players and bots), level-based visuals, incubator
	pedestals, the gold collect pad, owner signs and the base-upgrade purchase.

	Each upgrade changes the plot visually: fence material, pillars, banners, torches, arches,
	statues and a divine aura at max level — plus more incubators and pet pads.
]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local NumberFormatter = require(Shared.Util.NumberFormatter)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Net = require(Shared.Util.Net)

local Bases = {}
local S

local C3 = Color3.fromRGB
local M = Enum.Material

local owners = {} -- [baseIndex] = actorId
local baseOf = {} -- [actorId] = baseIndex
local lastVaultText = {}

local LEVEL_STYLE = {
	{ fence = C3(140, 100, 60), mat = M.Wood, trim = C3(170, 130, 80) },
	{ fence = C3(150, 150, 155), mat = M.Cobblestone, trim = C3(190, 190, 195) },
	{ fence = C3(230, 225, 215), mat = M.Marble, trim = C3(200, 170, 110) },
	{ fence = C3(235, 230, 220), mat = M.Marble, trim = C3(255, 205, 70) },
	{ fence = C3(70, 80, 110), mat = M.Slate, trim = C3(120, 210, 255) },
	{ fence = C3(225, 195, 135), mat = M.Sandstone, trim = C3(255, 190, 60) },
	{ fence = C3(250, 245, 235), mat = M.Marble, trim = C3(255, 215, 90) },
	{ fence = C3(255, 215, 110), mat = M.Metal, trim = C3(255, 250, 220) },
}

function Bases.init(sys)
	S = sys
end

local function baseModel(index: number): Model?
	local folder = Workspace:FindFirstChild("Bases")
	return folder and folder:FindFirstChild("Base_" .. index) :: Model? or nil
end
Bases.model = baseModel

function Bases.baseIndexOf(id: number): number?
	return baseOf[id]
end

function Bases.ownerOf(index: number): number?
	return owners[index]
end

function Bases.modelOf(id: number): Model?
	local i = baseOf[id]
	return i and baseModel(i) or nil
end

function Bases.freeCount(): number
	local n = 0
	for i = 1, 7 do
		if not owners[i] then
			n += 1
		end
	end
	return n
end

function Bases.incubatorCount(id: number): number
	local p = S.PlayerData.get(id)
	if not p then
		return 0
	end
	return math.min(28, Formulas.incubatorCount(p.baseLevel, S.Monetization.has(id, "ExtraBase")))
end

function Bases.petSlotCount(id: number): number
	local p = S.PlayerData.get(id)
	return p and Formulas.baseLevel(p.baseLevel).petSlots or 0
end

-- World CFrame of incubator slot / pet pad / treadmill / collect pad
function Bases.slotCFrame(id: number, slot: number): CFrame?
	local m = Bases.modelOf(id)
	local mk = m and m.IncubatorSlots:FindFirstChild("Slot_" .. slot)
	return mk and mk.CFrame or nil
end

function Bases.petCFrame(id: number, n: number): CFrame?
	local m = Bases.modelOf(id)
	local mk = m and m.PetSlots:FindFirstChild("Pet_" .. n)
	return mk and mk.CFrame or nil
end

function Bases.anchorCFrame(id: number): CFrame?
	local m = Bases.modelOf(id)
	return m and m.PrimaryPart and m.PrimaryPart.CFrame or nil
end

function Bases.isInsideBase(index: number, position: Vector3, margin: number?): boolean
	local m = baseModel(index)
	local region = m and m:FindFirstChild("Region") :: BasePart?
	if not region then
		return false
	end
	local rel = region.CFrame:PointToObjectSpace(position)
	local half = region.Size / 2 + Vector3.new(margin or 0, 0, margin or 0)
	return math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and rel.Y > -half.Y - 5 and rel.Y < half.Y + 10
end

-- Which base (index) a position is inside, if any.
function Bases.baseAt(position: Vector3): number?
	for i = 1, 7 do
		if Bases.isInsideBase(i, position) then
			return i
		end
	end
	return nil
end

function Bases.isInOwnBase(id: number): boolean
	local i = baseOf[id]
	local pos = S.Actors.position(id)
	return i ~= nil and pos ~= nil and Bases.isInsideBase(i, pos)
end

-- ===================== VISUALS =====================
local function clearVisuals(m: Model)
	m.Visuals:ClearAllChildren()
end

local function vpart(parent, size, cf, color, mat, collide)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.CanCollide = collide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Bases.refreshVisuals(id: number)
	local index = baseOf[id]
	if not index then
		return
	end
	local m = baseModel(index)
	local p = S.PlayerData.get(id)
	if not m or not p then
		return
	end
	clearVisuals(m)
	local v = m.Visuals
	local cf = m.PrimaryPart.CFrame
	local level = p.baseLevel
	local style = LEVEL_STYLE[level] or LEVEL_STYLE[1]
	local size = GameConfig.World.BaseSize
	local halfX, halfZ = size.X / 2, size.Z / 2
	m.Floor.Color = style.fence:Lerp(C3(210, 200, 180), 0.6)
	m.Floor.Material = level >= 3 and M.Marble or M.Slate

	-- fences (leave the entrance open at local -Z)
	local fenceH = 2 + level * 0.4
	vpart(v, Vector3.new(size.X, fenceH, 1), cf * CFrame.new(0, fenceH / 2 + 1, halfZ), style.fence, style.mat, true)
	vpart(v, Vector3.new(1, fenceH, size.Z), cf * CFrame.new(-halfX, fenceH / 2 + 1, 0), style.fence, style.mat, true)
	vpart(v, Vector3.new(1, fenceH, size.Z), cf * CFrame.new(halfX, fenceH / 2 + 1, 0), style.fence, style.mat, true)
	vpart(v, Vector3.new(size.X / 2 - 8, fenceH, 1), cf * CFrame.new(-halfX + (size.X / 2 - 8) / 2, fenceH / 2 + 1, -halfZ), style.fence, style.mat, true)
	vpart(v, Vector3.new(size.X / 2 - 8, fenceH, 1), cf * CFrame.new(halfX - (size.X / 2 - 8) / 2, fenceH / 2 + 1, -halfZ), style.fence, style.mat, true)
	-- trim
	vpart(v, Vector3.new(size.X + 1, 0.4, 1.4), cf * CFrame.new(0, fenceH + 1.2, halfZ), style.trim, M.Metal)

	-- pillars at the corners (level 2+)
	if level >= 2 then
		for _, c in { Vector3.new(-halfX, 0, -halfZ), Vector3.new(halfX, 0, -halfZ), Vector3.new(-halfX, 0, halfZ), Vector3.new(halfX, 0, halfZ) } do
			local h = 6 + level
			vpart(v, Vector3.new(2.4, h, 2.4), cf * CFrame.new(c.X, h / 2 + 1, c.Z), style.fence, style.mat, true)
			vpart(v, Vector3.new(3, 0.6, 3), cf * CFrame.new(c.X, h + 1.3, c.Z), style.trim, M.Metal)
		end
	end
	-- banners (level 3+)
	if level >= 3 then
		for _, x in { -halfX + 0.8, halfX - 0.8 } do
			local banner = vpart(v, Vector3.new(0.2, 6, 3.5), cf * CFrame.new(x, 7, -10), style.trim, M.Fabric)
			banner.Transparency = 0.05
		end
	end
	-- entrance arch (level 4+)
	if level >= 4 then
		for side = -1, 1, 2 do
			vpart(v, Vector3.new(2, 14, 2), cf * CFrame.new(side * 8, 8, -halfZ), style.fence, style.mat, true)
		end
		vpart(v, Vector3.new(18, 2, 2.4), cf * CFrame.new(0, 15.5, -halfZ), style.trim, M.Metal)
	end
	-- torches (level 5+)
	if level >= 5 then
		for _, c in { Vector3.new(-halfX + 2, 0, -halfZ + 2), Vector3.new(halfX - 2, 0, -halfZ + 2), Vector3.new(-halfX + 2, 0, halfZ - 2), Vector3.new(halfX - 2, 0, halfZ - 2) } do
			local f = vpart(v, Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(c.X, 9 + level, c.Z), style.trim, M.Neon)
			f.Shape = Enum.PartType.Ball
			ModelFactory.addLight(f, style.trim, 18, 1.4)
		end
	end
	-- god statue (level 6+)
	if level >= 6 then
		local statue = ModelFactory.creature(level >= 8 and "Zeus" or (level == 7 and "Odin" or "Ra"), "Titan", "Golden")
		statue:PivotTo(cf * CFrame.new(0, 1, halfZ - 4) * CFrame.Angles(0, 0, 0))
		statue.Parent = v
	end
	-- divine aura (level 8)
	if level >= 8 then
		local aura = vpart(v, Vector3.new(size.X, 0.3, size.Z), cf * CFrame.new(0, 1.1, 0), style.trim, M.Neon)
		aura.Transparency = 0.85
		ModelFactory.addParticles(aura, style.trim, 6, { speed = 1, size = 0.4, life = 2 })
	end
	-- VIP decoration
	if S.Monetization.has(id, "VIP") then
		local crown = vpart(v, Vector3.new(3, 3, 3), cf * CFrame.new(0, 20, -halfZ), C3(255, 210, 60), M.Neon)
		crown.Shape = Enum.PartType.Ball
		ModelFactory.addLight(crown, C3(255, 210, 60), 20, 2)
		local vipSign = vpart(v, Vector3.new(10, 3, 0.5), cf * CFrame.new(0, 17, -halfZ - 0.5), C3(40, 30, 10), M.SmoothPlastic)
		S.WorldBuilder.sign(vipSign, Enum.NormalId.Back, "VIP", C3(255, 215, 80))
	end

	-- treadmill
	local tm = ModelFactory.treadmill(p.treadmillTier)
	tm.Name = "Treadmill"
	tm:PivotTo(m.TreadmillSpot.CFrame * CFrame.new(0, -0.5, 0))
	tm:SetAttribute("Owner", id)
	tm:SetAttribute("Tier", p.treadmillTier)
	local belt = tm:FindFirstChild("Belt") :: BasePart
	belt.AssemblyLinearVelocity = tm.PrimaryPart.CFrame.LookVector * -14 -- conveyor pushes runners backward
	local screen = tm:FindFirstChild("Screen") :: BasePart
	if screen then
		S.WorldBuilder.sign(screen, Enum.NormalId.Back, Formulas.treadmill(p.treadmillTier).name, C3(255, 255, 255))
	end
	tm.Parent = v

	-- incubator pedestals
	local count = Bases.incubatorCount(id)
	for slot = 1, count do
		local mk = m.IncubatorSlots:FindFirstChild("Slot_" .. slot)
		if mk then
			local ped = vpart(v, Vector3.new(4.2, 1, 4.2), mk.CFrame * CFrame.new(0, -0.3, 0), style.trim, M.Marble, true)
			ped.Shape = Enum.PartType.Cylinder
			ped.CFrame = mk.CFrame * CFrame.new(0, -0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
			ped.Size = Vector3.new(1, 4.4, 4.4)
			ped.Name = "Pedestal_" .. slot
			local ring = vpart(v, Vector3.new(0.2, 3.6, 3.6), mk.CFrame * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), C3(255, 230, 150), M.Neon)
			ring.Shape = Enum.PartType.Cylinder
			ring.Transparency = 0.5
		end
	end
	-- pet pads
	for n = 1, Bases.petSlotCount(id) do
		local mk = m.PetSlots:FindFirstChild("Pet_" .. n)
		if mk then
			local pad = vpart(v, Vector3.new(0.4, 4, 4), mk.CFrame * CFrame.new(0, -0.35, 0) * CFrame.Angles(0, 0, math.rad(90)), style.fence:Lerp(C3(255, 255, 255), 0.3), M.Marble)
			pad.Shape = Enum.PartType.Cylinder
		end
	end
	m:SetAttribute("Level", level)
	m:SetAttribute("Protected", S.Theft.protectionReason(id) ~= nil)
	Bases.updateSign(id)
end

function Bases.updateSign(id: number)
	local index = baseOf[id]
	local m = index and baseModel(index)
	if not m then
		return
	end
	local p = S.PlayerData.get(id)
	local text = S.Actors.name(id) .. "\nNível " .. (p and p.baseLevel or 1)
	if p and p.title then
		text = S.Actors.name(id) .. "\n" .. p.title
	end
	m.OwnerSign:FindFirstChild("OwnerLabel", true).Text = text
	m.OwnerSign:FindFirstChild("OwnerLabelBack", true).Text = text
end

function Bases.updateVaultLabel(id: number)
	local index = baseOf[id]
	local m = index and baseModel(index)
	local p = S.PlayerData.get(id)
	if not m or not p then
		return
	end
	local text = S.Monetization.has(id, "AutoCollect") and "AUTO COLLECT\n✓" or ("COLETAR\n" .. NumberFormatter.format(p.vault))
	if lastVaultText[id] ~= text then
		lastVaultText[id] = text
		local label = m.VaultBoard:FindFirstChild("VaultLabel", true)
		if label then
			label.Text = text
		end
	end
end

local function resetBase(index: number)
	local m = baseModel(index)
	if not m then
		return
	end
	clearVisuals(m)
	m.Incubating:ClearAllChildren()
	m.PetDisplays:ClearAllChildren()
	m.OwnerSign:FindFirstChild("OwnerLabel", true).Text = "BASE LIVRE"
	m.OwnerSign:FindFirstChild("OwnerLabelBack", true).Text = "BASE LIVRE"
	m:SetAttribute("Owner", nil)
	m:SetAttribute("OwnerName", nil)
	m:SetAttribute("Protected", false)
	local label = m.VaultBoard:FindFirstChild("VaultLabel", true)
	if label then
		label.Text = "COLETAR\n0"
	end
end

function Bases.assign(id: number): number?
	if baseOf[id] then
		return baseOf[id]
	end
	-- players prefer the left side close to spawn; bots fill from the far end
	local order = S.Actors.isBot(id) and { 7, 4, 6, 3, 5, 2, 1 } or { 1, 5, 2, 6, 3, 7, 4 }
	for _, i in order do
		if not owners[i] then
			owners[i] = id
			baseOf[id] = i
			local m = baseModel(i)
			if m then
				m:SetAttribute("Owner", id)
				m:SetAttribute("OwnerName", S.Actors.name(id))
			end
			Bases.refreshVisuals(id)
			S.Eggs.renderBaseEggs(id)
			S.Pets.renderBase(id)
			S.PlayerData.dirty(id)
			return i
		end
	end
	return nil
end

function Bases.release(id: number)
	local i = baseOf[id]
	if i then
		owners[i] = nil
		baseOf[id] = nil
		lastVaultText[id] = nil
		resetBase(i)
	end
end

function Bases.spawnCFrame(id: number): CFrame?
	local cf = Bases.anchorCFrame(id)
	return cf and cf * CFrame.new(0, 4, -20) or nil
end

-- ===================== UPGRADE =====================
function Bases.upgrade(id: number): (boolean, string?)
	local p = S.PlayerData.get(id)
	if not p then
		return false, "Sem dados"
	end
	local nextLevel = p.baseLevel + 1
	local def = Balance.baseLevels[nextLevel]
	if not def then
		return false, "Sua base já está no nível máximo!"
	end
	if not S.Economy.spend(id, def.price) then
		return false, "GOLD insuficiente"
	end
	p.baseLevel = nextLevel
	Bases.refreshVisuals(id)
	S.Eggs.renderBaseEggs(id)
	S.Pets.renderBase(id)
	S.PlayerData.dirty(id)
	local m = Bases.modelOf(id)
	if m then
		Net.fireAll("Effect", { kind = "BaseUpgrade", position = m.PrimaryPart.Position, level = nextLevel })
	end
	S.Tutorial.progress(id, "UpgradeBase")
	return true, "Base melhorada para o nível " .. nextLevel .. "!"
end

function Bases.start()
	S.PlayerData.Loaded:Connect(function(id)
		Bases.assign(id)
	end)
	S.Actors.Removed:Connect(function(id)
		Bases.release(id)
	end)
	S.Net.handle("UpgradeBase", function(player)
		return Bases.upgrade(player.UserId)
	end)

	-- Players respawn at their base; collect-pad detection
	S.Actors.CharacterAdded:Connect(function(id, char)
		local cf = Bases.spawnCFrame(id)
		if cf and not S.Actors.isBot(id) then
			task.defer(function()
				local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					local st = S.Actors.state(id)
					if st then
						st.teleportGrace = os.clock() + 2
					end
					char:PivotTo(cf)
				end
			end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.3)
			for id, index in baseOf do
				local m = baseModel(index)
				local pos = S.Actors.position(id)
				if m and pos then
					local pad = m:FindFirstChild("CollectPad") :: BasePart
					local rel = pad.CFrame:PointToObjectSpace(pos)
					if math.abs(rel.X) < 4.5 and math.abs(rel.Z) < 4.5 and rel.Y < 8 then
						S.Economy.collectVault(id)
					end
				end
			end
		end
	end)
end

-- tween helper for clients is not needed server-side
Bases._tween = TweenService

return Bases
