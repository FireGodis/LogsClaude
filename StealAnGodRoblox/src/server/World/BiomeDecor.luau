--[[
	BiomeDecor — themed scenery for each of the 12 biomes. Everything is built from parts with a
	deterministic Random so the map is identical every time it is generated.
	Rule: nothing collidable is placed inside the avenue (|x| < AvenueWidth/2) so NPC navigation
	along the avenue never needs pathfinding.
]]

local ModelFactory = require(game:GetService("ReplicatedStorage").Shared.Factory.ModelFactory)

local C3 = Color3.fromRGB
local M = Enum.Material

local BiomeDecor = {}

local function part(parent, size, cf, color, mat, collide, shape)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.SmoothPlastic
	p.CanCollide = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end
BiomeDecor.part = part

local function wedge(parent, size, cf, color, mat)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = mat or M.SmoothPlastic
	w.Parent = parent
	return w
end

-- ---------- reusable props ----------
local function tree(parent, pos: Vector3, rng: Random, trunkC, leafC, kind)
	local h = rng:NextNumber(8, 14)
	part(parent, Vector3.new(1.6, h, 1.6), CFrame.new(pos + Vector3.new(0, h / 2, 0)), trunkC, M.Wood)
	if kind == "pine" then
		for i = 0, 2 do
			local s = 9 - i * 2.5
			wedge(parent, Vector3.new(s, 4, s / 2), CFrame.new(pos + Vector3.new(0, h - 1 + i * 3, -s / 4)), leafC, M.Grass)
			wedge(parent, Vector3.new(s, 4, s / 2), CFrame.new(pos + Vector3.new(0, h - 1 + i * 3, s / 4)) * CFrame.Angles(0, math.pi, 0), leafC, M.Grass)
		end
	elseif kind == "palm" then
		for i = 1, 5 do
			local a = math.rad(i * 72)
			part(parent, Vector3.new(7, 0.4, 1.8), CFrame.new(pos + Vector3.new(math.cos(a) * 3, h, math.sin(a) * 3)) * CFrame.Angles(0, -a, math.rad(-15)), leafC, M.Grass, false)
		end
	else
		part(parent, Vector3.new(8, 8, 8), CFrame.new(pos + Vector3.new(0, h + 2, 0)), leafC, M.Grass, false, Enum.PartType.Ball)
		part(parent, Vector3.new(6, 6, 6), CFrame.new(pos + Vector3.new(2.5, h + 4, 1)), leafC:Lerp(C3(255, 255, 255), 0.08), M.Grass, false, Enum.PartType.Ball)
	end
end

local function column(parent, pos: Vector3, h: number, color, mat, broken)
	local height = broken and h * 0.6 or h
	part(parent, Vector3.new(height, 2.6, 2.6), CFrame.new(pos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, mat or M.Marble, true, Enum.PartType.Cylinder)
	part(parent, Vector3.new(3.4, 0.8, 3.4), CFrame.new(pos + Vector3.new(0, 0.4, 0)), color, mat or M.Marble)
	if not broken then
		part(parent, Vector3.new(3.4, 0.8, 3.4), CFrame.new(pos + Vector3.new(0, height + 0.4, 0)), color, mat or M.Marble)
	end
end
BiomeDecor.column = column

local function temple(parent, center: Vector3, w: number, d: number, h: number, color, roofColor, mat)
	part(parent, Vector3.new(w + 4, 2, d + 4), CFrame.new(center + Vector3.new(0, 1, 0)), color, mat or M.Marble)
	local cols = math.max(2, math.floor(w / 6))
	for i = 0, cols do
		local x = -w / 2 + i * (w / cols)
		column(parent, center + Vector3.new(x, 2, -d / 2), h, color, mat)
		column(parent, center + Vector3.new(x, 2, d / 2), h, color, mat)
	end
	part(parent, Vector3.new(w + 3, 1.5, d + 3), CFrame.new(center + Vector3.new(0, h + 3.5, 0)), color, mat or M.Marble)
	wedge(parent, Vector3.new(w + 3, 4, (d + 3) / 2), CFrame.new(center + Vector3.new(0, h + 6.25, -(d + 3) / 4)), roofColor, mat or M.Marble)
	wedge(parent, Vector3.new(w + 3, 4, (d + 3) / 2), CFrame.new(center + Vector3.new(0, h + 6.25, (d + 3) / 4)) * CFrame.Angles(0, math.pi, 0), roofColor, mat or M.Marble)
end
BiomeDecor.temple = temple

local function statue(parent, pos: Vector3, scale: number, color, mat, faceTowardX: boolean?)
	part(parent, Vector3.new(5, 3, 5), CFrame.new(pos + Vector3.new(0, 1.5, 0)), C3(200, 195, 185), M.Marble)
	local body = Instance.new("Model")
	body.Name = "Statue"
	local s = scale
	part(body, Vector3.new(2 * s, 3 * s, 1.2 * s), CFrame.new(pos + Vector3.new(0, 3 + 2.6 * s, 0)), color, mat)
	part(body, Vector3.new(0.8 * s, 2.6 * s, 0.8 * s), CFrame.new(pos + Vector3.new(-0.55 * s, 3 + 0.65 * s, 0)), color, mat)
	part(body, Vector3.new(0.8 * s, 2.6 * s, 0.8 * s), CFrame.new(pos + Vector3.new(0.55 * s, 3 + 0.65 * s, 0)), color, mat)
	part(body, Vector3.new(1.6 * s, 1.6 * s, 1.6 * s), CFrame.new(pos + Vector3.new(0, 3 + 4.9 * s, 0)), color, mat, true, Enum.PartType.Ball)
	part(body, Vector3.new(0.6 * s, 3.4 * s, 0.6 * s), CFrame.new(pos + Vector3.new(1.4 * s, 3 + 3.4 * s, 0)) * CFrame.Angles(0, 0, math.rad(-35)), color, mat)
	body.Parent = parent
	return body
end
BiomeDecor.statue = statue

local function rock(parent, pos: Vector3, rng: Random, color, mat)
	local s = rng:NextNumber(3, 8)
	part(parent, Vector3.new(s, s * 0.7, s * 0.9), CFrame.new(pos + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), color, mat or M.Slate)
end

local function crystal(parent, pos: Vector3, rng: Random, color)
	local last
	for _ = 1, 3 do
		local h = rng:NextNumber(4, 10)
		local p = wedge(parent, Vector3.new(1.4, h, 1.4), CFrame.new(pos + Vector3.new(rng:NextNumber(-2, 2), h / 2, rng:NextNumber(-2, 2))) * CFrame.Angles(0, rng:NextNumber(0, 6), rng:NextNumber(-0.25, 0.25)), color, M.Neon)
		p.Transparency = 0.15
		p.CanCollide = false
		last = p
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Brightness = 1
	light.Parent = last
end

local function pyramid(parent, center: Vector3, size: number, color)
	local layers = 6
	for i = 0, layers - 1 do
		local s = size * (1 - i / layers)
		part(parent, Vector3.new(s, size / layers, s), CFrame.new(center + Vector3.new(0, (i + 0.5) * size / layers, 0)), color, M.Sandstone)
	end
	part(parent, Vector3.new(size / layers, size / layers, size / layers), CFrame.new(center + Vector3.new(0, size + size / layers * 0.5, 0)), C3(255, 210, 80), M.Metal)
end

local function obelisk(parent, pos: Vector3, h: number, color)
	part(parent, Vector3.new(3, h, 3), CFrame.new(pos + Vector3.new(0, h / 2, 0)), color, M.Sandstone)
	wedge(parent, Vector3.new(3, 3, 1.5), CFrame.new(pos + Vector3.new(0, h + 1.5, -0.75)), C3(255, 210, 80), M.Metal)
	wedge(parent, Vector3.new(3, 3, 1.5), CFrame.new(pos + Vector3.new(0, h + 1.5, 0.75)) * CFrame.Angles(0, math.pi, 0), C3(255, 210, 80), M.Metal)
end

local function hut(parent, pos: Vector3, rot: number)
	local cf = CFrame.new(pos) * CFrame.Angles(0, rot, 0)
	part(parent, Vector3.new(14, 7, 10), cf * CFrame.new(0, 3.5, 0), C3(120, 80, 50), M.WoodPlanks)
	wedge(parent, Vector3.new(15, 5, 6), cf * CFrame.new(0, 9.5, -3), C3(90, 60, 40), M.Wood)
	wedge(parent, Vector3.new(15, 5, 6), cf * CFrame.new(0, 9.5, 3) * CFrame.Angles(0, math.pi, 0), C3(90, 60, 40), M.Wood)
	part(parent, Vector3.new(3, 5, 0.4), cf * CFrame.new(0, 2.5, -5.1), C3(60, 40, 25), M.Wood)
end

local function water(parent, cf: CFrame, size: Vector3, color)
	local w = part(parent, size, cf, color, M.Glass, false)
	w.Transparency = 0.35
	w.Reflectance = 0.1
	w.CanQuery = false
	return w
end

local function cloud(parent, pos: Vector3, rng: Random)
	for i = 1, 4 do
		local s = rng:NextNumber(8, 14)
		local c = part(parent, Vector3.new(s, s * 0.6, s), CFrame.new(pos + Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-1, 2), rng:NextNumber(-6, 6))), C3(255, 255, 255), M.SmoothPlastic, false, Enum.PartType.Ball)
		c.Transparency = 0.15
	end
end

local function torch(parent, pos: Vector3, color)
	part(parent, Vector3.new(0.6, 5, 0.6), CFrame.new(pos + Vector3.new(0, 2.5, 0)), C3(80, 60, 40), M.Wood)
	local f = part(parent, Vector3.new(1.2, 1.2, 1.2), CFrame.new(pos + Vector3.new(0, 5.4, 0)), color, M.Neon, false, Enum.PartType.Ball)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = 16
	l.Brightness = 1.5
	l.Parent = f
	ModelFactory.addParticles(f, color, 5, { speed = 2, size = 0.3 })
end
BiomeDecor.torch = torch

-- Side positions avoid the avenue. side = -1 (left) or 1 (right)
local function sidePos(rng: Random, z0: number, length: number, minX: number, maxX: number)
	local side = rng:NextNumber() < 0.5 and -1 or 1
	return Vector3.new(side * rng:NextNumber(minX, maxX), 0, z0 + rng:NextNumber(8, length - 8))
end

-- ---------- per-biome builders ----------
-- ctx = {folder, z0, length, width, avenueHalf, rng}
local Builders = {}

Builders[1] = function(ctx) -- Arcadia
	local f, rng = ctx.folder, ctx.rng
	for _ = 1, 26 do
		tree(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 8, ctx.width / 2 - 6), rng, C3(110, 75, 45), C3(90 + rng:NextInteger(0, 40), 170, 70))
	end
	for i = 0, 4 do
		column(f, Vector3.new(-ctx.avenueHalf - 4, 0, ctx.z0 + 25 + i * 45), 12, C3(235, 230, 215), M.Marble, i % 2 == 1)
		column(f, Vector3.new(ctx.avenueHalf + 4, 0, ctx.z0 + 25 + i * 45), 12, C3(235, 230, 215), M.Marble, i % 2 == 0)
	end
	temple(f, Vector3.new(-70, 0, ctx.z0 + 160), 18, 12, 10, C3(240, 235, 220), C3(200, 120, 90))
	-- fountain
	local center = Vector3.new(68, 0, ctx.z0 + 70)
	part(f, Vector3.new(2, 16, 16), CFrame.new(center + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), C3(230, 225, 210), M.Marble, true, Enum.PartType.Cylinder)
	water(f, CFrame.new(center + Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.4, 14, 14), C3(90, 180, 255)).Shape = Enum.PartType.Cylinder
	statue(f, center + Vector3.new(0, 2, 0), 0.8, C3(235, 230, 220), M.Marble)
end

Builders[2] = function(ctx) -- Aegean coast
	local f, rng = ctx.folder, ctx.rng
	water(f, CFrame.new(-ctx.width / 2 + 25, 0.3, ctx.z0 + ctx.length / 2), Vector3.new(50, 1, ctx.length), C3(40, 140, 220))
	water(f, CFrame.new(ctx.width / 2 - 25, 0.3, ctx.z0 + ctx.length / 2), Vector3.new(50, 1, ctx.length), C3(40, 140, 220))
	for i = 0, 5 do
		local z = ctx.z0 + 20 + i * 38
		part(f, Vector3.new(6, 1, 30), CFrame.new(-ctx.avenueHalf - 12, 0.6, z), C3(240, 220, 170), M.Sand, true)
		part(f, Vector3.new(6, 1, 30), CFrame.new(ctx.avenueHalf + 12, 0.6, z), C3(240, 220, 170), M.Sand, true)
	end
	temple(f, Vector3.new(66, 0, ctx.z0 + 120), 16, 12, 11, C3(230, 240, 250), C3(60, 120, 200))
	statue(f, Vector3.new(-62, 0, ctx.z0 + 60), 1.6, C3(60, 130, 200), M.Marble)
	for _ = 1, 10 do
		column(f, Vector3.new(-ctx.width / 2 + rng:NextNumber(8, 40), -2, ctx.z0 + rng:NextNumber(10, ctx.length - 10)), 9, C3(200, 220, 230), M.Marble, true)
	end
	for _ = 1, 12 do
		rock(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 20, ctx.width / 2 - 4), rng, C3(160, 150, 130), M.Slate)
	end
end

Builders[3] = function(ctx) -- Labyrinth
	local f, rng = ctx.folder, ctx.rng
	local wallC = C3(150, 120, 90)
	-- maze walls on both sides (avenue stays open, nests sit in maze pockets)
	for side = -1, 1, 2 do
		for i = 0, 7 do
			local z = ctx.z0 + 15 + i * 28
			local len = rng:NextNumber(18, 34)
			part(f, Vector3.new(2, 12, len), CFrame.new(side * (ctx.avenueHalf + rng:NextNumber(26, 62)), 6, z), wallC, M.Cobblestone)
			part(f, Vector3.new(rng:NextNumber(12, 28), 12, 2), CFrame.new(side * (ctx.avenueHalf + rng:NextNumber(32, 64)), 6, z + rng:NextNumber(-8, 8)), wallC, M.Cobblestone)
		end
		part(f, Vector3.new(2, 14, ctx.length), CFrame.new(side * (ctx.width / 2 - 2), 7, ctx.z0 + ctx.length / 2), wallC:Lerp(C3(0, 0, 0), 0.2), M.Cobblestone)
	end
	for i = 0, 9 do
		torch(f, Vector3.new((i % 2 == 0 and -1 or 1) * (ctx.avenueHalf + 2), 0, ctx.z0 + 12 + i * 23), C3(255, 150, 60))
	end
	-- bull skull gate statue
	statue(f, Vector3.new(0, 0, ctx.z0 + ctx.length - 6) + Vector3.new(ctx.avenueHalf + 10, 0, 0), 1.4, C3(120, 80, 50), M.Slate)
end

Builders[4] = function(ctx) -- Olympus
	local f, rng = ctx.folder, ctx.rng
	for _ = 1, 16 do
		cloud(f, Vector3.new((rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(40, 95), rng:NextNumber(18, 40), ctx.z0 + rng:NextNumber(0, ctx.length)), rng)
	end
	temple(f, Vector3.new(-62, 0, ctx.z0 + 90), 26, 16, 16, C3(250, 245, 235), C3(255, 205, 80))
	temple(f, Vector3.new(62, 0, ctx.z0 + 170), 22, 14, 14, C3(250, 245, 235), C3(255, 205, 80))
	for i = 0, 3 do
		statue(f, Vector3.new((i % 2 == 0 and -1 or 1) * (ctx.avenueHalf + 9), 0, ctx.z0 + 35 + i * 55), 1.5, C3(255, 210, 90), M.Metal)
	end
	for i = 0, 5 do
		local bolt = part(f, Vector3.new(1, 22, 1), CFrame.new((i % 2 == 0 and -80 or 80), 30, ctx.z0 + 20 + i * 40) * CFrame.Angles(0, 0, math.rad(15)), C3(255, 250, 150), M.Neon, false)
		bolt.Transparency = 0.2
		local l = Instance.new("PointLight")
		l.Range = 30
		l.Color = C3(255, 245, 160)
		l.Parent = bolt
	end
end

Builders[5] = function(ctx) -- Midgard
	local f, rng = ctx.folder, ctx.rng
	for _ = 1, 30 do
		tree(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 8, ctx.width / 2 - 6), rng, C3(90, 60, 40), C3(40, 100, 60), "pine")
	end
	hut(f, Vector3.new(-62, 0, ctx.z0 + 60), math.rad(90))
	hut(f, Vector3.new(64, 0, ctx.z0 + 130), math.rad(-90))
	hut(f, Vector3.new(-66, 0, ctx.z0 + 190), math.rad(90))
	for i = 0, 5 do
		local stone = part(f, Vector3.new(3, 8, 1.5), CFrame.new((i % 2 == 0 and -1 or 1) * (ctx.avenueHalf + 6), 4, ctx.z0 + 20 + i * 38), C3(120, 120, 125), M.Slate)
		local rune = part(f, Vector3.new(1.4, 3, 0.2), stone.CFrame * CFrame.new(0, 1, 0.8), C3(120, 210, 255), M.Neon, false)
		rune.Transparency = 0.1
	end
	for _ = 1, 8 do
		rock(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 20, ctx.width / 2 - 4), rng, C3(110, 110, 105), M.Slate)
	end
end

Builders[6] = function(ctx) -- Jotunheim
	local f, rng = ctx.folder, ctx.rng
	for side = -1, 1, 2 do
		for i = 0, 5 do
			local h = rng:NextNumber(30, 60)
			wedge(f, Vector3.new(30, h, 24), CFrame.new(side * (ctx.width / 2 - 12), h / 2, ctx.z0 + 20 + i * 40) * CFrame.Angles(0, side > 0 and math.rad(-90) or math.rad(90), 0), C3(220, 235, 250), M.Snow)
		end
	end
	water(f, CFrame.new(-50, 0.25, ctx.z0 + 120), Vector3.new(36, 0.6, 60), C3(170, 220, 255)).Material = M.Ice
	water(f, CFrame.new(52, 0.25, ctx.z0 + 70), Vector3.new(30, 0.6, 40), C3(170, 220, 255)).Material = M.Ice
	for _ = 1, 14 do
		tree(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 10, ctx.width / 2 - 30), rng, C3(80, 60, 50), C3(220, 240, 250), "pine")
	end
	for _ = 1, 6 do
		crystal(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 15, ctx.width / 2 - 30), rng, C3(150, 220, 255))
	end
	statue(f, Vector3.new(ctx.avenueHalf + 18, 0, ctx.z0 + 200), 3, C3(170, 210, 240), M.Ice)
end

Builders[7] = function(ctx) -- Nidavellir
	local f, rng = ctx.folder, ctx.rng
	for side = -1, 1, 2 do
		part(f, Vector3.new(30, 50, ctx.length), CFrame.new(side * (ctx.width / 2 + 8), 25, ctx.z0 + ctx.length / 2), C3(60, 50, 50), M.Basalt)
		local lava = part(f, Vector3.new(14, 0.6, ctx.length - 20), CFrame.new(side * (ctx.avenueHalf + 52), 0.2, ctx.z0 + ctx.length / 2), C3(255, 100, 20), M.Neon, false)
		lava.CanQuery = false
	end
	for i = 0, 3 do
		local x = (i % 2 == 0 and -1 or 1) * 62
		local z = ctx.z0 + 30 + i * 55
		part(f, Vector3.new(14, 8, 10), CFrame.new(x, 4, z), C3(80, 70, 70), M.Brick)
		local fire = part(f, Vector3.new(6, 3, 4), CFrame.new(x, 9.5, z), C3(255, 120, 30), M.Neon, false)
		ModelFactory.addParticles(fire, C3(255, 140, 40), 8, { speed = 4, size = 0.4 })
		part(f, Vector3.new(4, 3, 2.5), CFrame.new(x + 9, 1.5, z), C3(90, 90, 100), M.Metal) -- anvil
	end
	for _ = 1, 10 do
		crystal(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 8, ctx.width / 2 - 10), rng, (rng:NextNumber() < 0.5) and C3(255, 120, 60) or C3(120, 220, 255))
	end
end

Builders[8] = function(ctx) -- Asgard
	local f, rng = ctx.folder, ctx.rng
	local gold = C3(255, 205, 70)
	for side = -1, 1, 2 do
		for i = 0, 2 do
			local x = side * rng:NextNumber(55, 80)
			local z = ctx.z0 + 40 + i * 75
			part(f, Vector3.new(24, 26, 20), CFrame.new(x, 13, z), C3(240, 230, 200), M.Marble)
			part(f, Vector3.new(26, 3, 22), CFrame.new(x, 27.5, z), gold, M.Metal)
			wedge(f, Vector3.new(26, 10, 11), CFrame.new(x, 34, z - 5.5), gold, M.Metal)
			wedge(f, Vector3.new(26, 10, 11), CFrame.new(x, 34, z + 5.5) * CFrame.Angles(0, math.pi, 0), gold, M.Metal)
		end
	end
	-- Bifrost bridge (decorative, above avenue)
	for i = 0, 11 do
		local seg = part(f, Vector3.new(ctx.avenueHalf * 2 + 20, 1, 4), CFrame.new(0, 26, ctx.z0 + 60 + i * 4), Color3.fromHSV(i / 12, 0.7, 1), M.Neon, false)
		seg.Transparency = 0.3
	end
	for i = 0, 4 do
		statue(f, Vector3.new((i % 2 == 0 and -1 or 1) * (ctx.avenueHalf + 8), 0, ctx.z0 + 30 + i * 45), 1.8, gold, M.Metal)
	end
end

Builders[9] = function(ctx) -- Nile
	local f, rng = ctx.folder, ctx.rng
	water(f, CFrame.new(-60, 0.3, ctx.z0 + ctx.length / 2), Vector3.new(26, 0.8, ctx.length), C3(40, 160, 170))
	for _ = 1, 24 do
		tree(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 6, ctx.width / 2 - 6), rng, C3(150, 110, 60), C3(80, 170, 70), "palm")
	end
	for i = 0, 2 do
		part(f, Vector3.new(12, 6, 12), CFrame.new(62, 3, ctx.z0 + 40 + i * 70), C3(220, 190, 140), M.Sandstone)
		part(f, Vector3.new(13, 1, 13), CFrame.new(62, 6.5, ctx.z0 + 40 + i * 70), C3(200, 170, 120), M.Sandstone)
	end
	statue(f, Vector3.new(ctx.avenueHalf + 10, 0, ctx.z0 + 120), 1.6, C3(220, 190, 130), M.Sandstone)
end

Builders[10] = function(ctx) -- Necropolis
	local f, rng = ctx.folder, ctx.rng
	pyramid(f, Vector3.new(-70, 0, ctx.z0 + 80), 44, C3(215, 185, 125))
	pyramid(f, Vector3.new(72, 0, ctx.z0 + 170), 38, C3(205, 175, 115))
	-- sphinx
	local sx = Vector3.new(64, 0, ctx.z0 + 50)
	part(f, Vector3.new(10, 8, 26), CFrame.new(sx + Vector3.new(0, 4, 0)), C3(215, 185, 125), M.Sandstone)
	part(f, Vector3.new(8, 9, 8), CFrame.new(sx + Vector3.new(0, 11, -11)), C3(215, 185, 125), M.Sandstone)
	part(f, Vector3.new(10, 6, 2), CFrame.new(sx + Vector3.new(0, 11, -9)), C3(60, 90, 160), M.Fabric)
	for i = 0, 7 do
		part(f, Vector3.new(4, 3, 6), CFrame.new((i % 2 == 0 and -1 or 1) * (ctx.avenueHalf + rng:NextNumber(10, 40)), 1.5, ctx.z0 + 15 + i * 27), C3(120, 110, 100), M.Slate) -- tombs
	end
	for i = 0, 3 do
		local portal = part(f, Vector3.new(1, 14, 10), CFrame.new((i % 2 == 0 and -1 or 1) * (ctx.width / 2 - 10), 7, ctx.z0 + 30 + i * 55), C3(140, 90, 255), M.Neon, false)
		portal.Transparency = 0.4
	end
end

Builders[11] = function(ctx) -- Duat
	local f, rng = ctx.folder, ctx.rng
	for side = -1, 1, 2 do
		local river = water(f, CFrame.new(side * (ctx.avenueHalf + 26), 0.3, ctx.z0 + ctx.length / 2), Vector3.new(16, 0.8, ctx.length), C3(60, 30, 110))
		river.Material = M.Neon
		river.Transparency = 0.5
		for i = 0, 3 do
			local h = rng:NextNumber(30, 50)
			part(f, Vector3.new(10, h, 10), CFrame.new(side * (ctx.width / 2 - 14), h / 2, ctx.z0 + 25 + i * 60), C3(40, 30, 55), M.Basalt)
			local eye = part(f, Vector3.new(6, 3, 0.5), CFrame.new(side * (ctx.width / 2 - 19.3), h - 6, ctx.z0 + 25 + i * 60), C3(80, 220, 255), M.Neon, false)
			eye.CFrame = eye.CFrame * CFrame.Angles(0, math.rad(90), 0)
		end
	end
	for _ = 1, 10 do
		crystal(f, sidePos(rng, ctx.z0, ctx.length, ctx.avenueHalf + 40, ctx.width / 2 - 22), rng, C3(160, 90, 255))
	end
end

Builders[12] = function(ctx) -- Solar temple
	local f, rng = ctx.folder, ctx.rng
	local gold = C3(255, 200, 60)
	for i = 0, 7 do
		obelisk(f, Vector3.new((i % 2 == 0 and -1 or 1) * (ctx.avenueHalf + 6), 0, ctx.z0 + 15 + i * 28), 22, C3(230, 200, 140))
	end
	-- giant temple at the end
	local tz = ctx.z0 + ctx.length - 30
	part(f, Vector3.new(ctx.width - 20, 4, 40), CFrame.new(0, 2, tz), C3(230, 200, 140), M.Sandstone)
	for i = -4, 4 do
		if math.abs(i) > 1 then
			column(f, Vector3.new(i * 10, 4, tz - 16), 26, gold, M.Metal)
		end
	end
	part(f, Vector3.new(ctx.width - 20, 4, 40), CFrame.new(0, 32, tz), gold, M.Metal)
	local sun = part(f, Vector3.new(2, 40, 40), CFrame.new(0, 60, tz + 10) * CFrame.Angles(0, math.rad(90), 0), C3(255, 180, 40), M.Neon, false, Enum.PartType.Cylinder)
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 3
	light.Color = C3(255, 200, 100)
	light.Parent = sun
	for i = 0, 5 do
		local ray = part(f, Vector3.new(2, 70, 2), CFrame.new(0, 60, tz + 10) * CFrame.Angles(0, 0, math.rad(i * 30)), C3(255, 220, 120), M.Neon, false)
		ray.Transparency = 0.6
	end
	for _ = 1, 8 do
		local portalPos = sidePos(rng, ctx.z0, ctx.length - 50, ctx.avenueHalf + 30, ctx.width / 2 - 20)
		local ring = part(f, Vector3.new(1, 12, 12), CFrame.new(portalPos + Vector3.new(0, 7, 0)) * CFrame.Angles(0, math.rad(90), 0), C3(255, 230, 150), M.Neon, false, Enum.PartType.Cylinder)
		ring.Transparency = 0.5
	end
end

function BiomeDecor.build(biomeId: number, ctx)
	local builder = Builders[biomeId]
	if builder then
		builder(ctx)
	end
end

return BiomeDecor
