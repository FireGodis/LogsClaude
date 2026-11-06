--[[
	Guardians — one central AI loop (5 Hz) for every biome guardian.

	States: Sleeping → Patrolling ↔ Observing → Detecting → Chasing → Attacking → Returning
	  • Sleeping: periodic naps, detection radius halved (the "window" to steal)
	  • Patrolling/Observing: walks between the nests it protects, pauses to look around
	  • Detecting: brief "!" before the chase (gives a reaction window)
	  • Chasing: follows egg carriers (and nest intruders) up to the leash distance
	  • Attacking: knockback + the carried egg drops (recoverable for 20s)
	  • Returning: walks home ignoring targets for a few seconds
	Abilities can stun/slow guardians or distract them with decoys.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Formulas = require(Shared.Util.Formulas)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Net = require(Shared.Util.Net)

local Guardians = {}
local S

local list = {} -- guardian records
local decoys = {} -- {position, untilT, model}
local fury = false

function Guardians.init(sys)
	S = sys
end

function Guardians.setFury(on: boolean)
	fury = on
end

local function setState(g, state: string)
	if g.state ~= state then
		g.state = state
		g.stateSince = os.clock()
		g.model:SetAttribute("State", state)
	end
end

local function spawnGuardian(biomeId: number, index: number, points: { Vector3 })
	local model = ModelFactory.guardian(biomeId)
	model.Name = "Guardian_" .. biomeId .. "_" .. index
	local start = points[1] + Vector3.new(0, 6, 0)
	model:PivotTo(CFrame.new(start))
	model:SetAttribute("BiomeId", biomeId)
	model.Parent = Workspace.Runtime.Guardians
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart
	pcall(function()
		hrp:SetNetworkOwner(nil)
	end)
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local center = Vector3.zero
	for _, p in points do
		center += p
	end
	center /= #points
	local g = {
		biome = biomeId, model = model, hrp = hrp, hum = hum, points = points, home = center,
		pointIndex = 1, state = "", stateSince = 0, target = nil, lastHit = 0,
		stunUntil = 0, slowUntil = 0, slowFactor = 0, nextNap = os.clock() + math.random(25, 60),
		ignoreUntil = 0, cfg = Formulas.biome(biomeId),
	}
	setState(g, "Patrolling")
	table.insert(list, g)
	return g
end

local function speedOf(g): number
	local now = os.clock()
	if g.stunUntil > now then
		return 0
	end
	local s = g.cfg.guardianSpeed
	if fury then
		s *= 1.2
	end
	if g.slowUntil > now then
		s *= 1 - g.slowFactor
	end
	if g.state == "Returning" then
		s *= 1.1
	elseif g.state == "Patrolling" then
		s *= 0.55
	end
	return s
end

-- Picks the best target in range: decoys first, then egg carriers, then nest intruders.
local function findTarget(g)
	local pos = g.hrp.Position
	local detect = g.cfg.guardianDetect * (g.state == "Sleeping" and 0.5 or 1)
	for _, d in decoys do
		if d.untilT > os.clock() and (d.position - pos).Magnitude < detect * 1.6 then
			return { decoy = d }
		end
	end
	local best, bestDist = nil, math.huge
	for id in S.Actors.all() do
		local root = S.Actors.root(id)
		if root and S.Actors.alive(id) then
			local dist = (root.Position - pos).Magnitude
			local st = S.Actors.state(id)
			local carrying = st and st.carry ~= nil
			local nearNest = (root.Position - g.home).Magnitude < 22
			local inBiome = S.WorldBuilder.biomeAt(root.Position.Z) == g.biome
			if inBiome and (carrying or nearNest) and dist < detect and dist < bestDist then
				best, bestDist = id, dist
			end
		end
	end
	return best and { actor = best } or nil
end

local function targetPosition(target): Vector3?
	if not target then
		return nil
	end
	if target.decoy then
		return target.decoy.untilT > os.clock() and target.decoy.position or nil
	end
	return S.Actors.position(target.actor)
end

local function attack(g, id: number)
	g.lastHit = os.clock()
	local st = S.Actors.state(id)
	if not st then
		return
	end
	if st.hitImmuneUntil > os.clock() then
		return
	end
	st.hitImmuneUntil = os.clock() + Balance.abilities.globalImmunitySeconds * 0.5
	Net.fireAll("Effect", { kind = "GuardianSlam", position = g.hrp.Position, biome = g.biome })
	if S.Actors.buff(id, "GuardShield") then
		S.Actors.clearBuff(id, "GuardShield")
		local player = S.Actors.player(id)
		if player then
			Net.fire(player, "Notify", { kind = "Info", title = "Escudo divino!", text = "Seu escudo bloqueou o golpe." })
		end
		return
	end
	local pos = S.Actors.position(id)
	if pos then
		local dir = (pos - g.hrp.Position) * Vector3.new(1, 0, 1)
		dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(0, 0, -1)
		S.Abilities.knockback(id, dir * 75 + Vector3.new(0, 45, 0))
	end
	st.stunUntil = math.max(st.stunUntil, os.clock() + 0.8)
	S.Eggs.dropCarry(id, "guardian")
end

local function step(g, dt: number)
	local now = os.clock()
	if not g.model.Parent then
		return
	end
	g.hum.WalkSpeed = speedOf(g)
	g.model:SetAttribute("Stunned", g.stunUntil > now)
	local pos = g.hrp.Position

	if g.state == "Sleeping" then
		if now - g.stateSince > g.napLength then
			g.nextNap = now + math.random(30, 70)
			setState(g, "Patrolling")
		else
			local t = findTarget(g)
			if t and t.actor and (S.Actors.position(t.actor) - pos).Magnitude < g.cfg.guardianDetect * 0.35 then
				g.target = t
				setState(g, "Detecting")
			end
		end
		return
	end

	if g.state == "Patrolling" or g.state == "Observing" then
		if now > g.nextNap and math.random() < 0.02 then
			g.napLength = math.random(6, 12)
			g.hum:MoveTo(pos)
			setState(g, "Sleeping")
			return
		end
		if now > g.ignoreUntil then
			local t = findTarget(g)
			if t then
				g.target = t
				g.hum:MoveTo(pos)
				setState(g, "Detecting")
				return
			end
		end
		if g.state == "Observing" then
			if now - g.stateSince > g.observeFor then
				g.pointIndex = g.pointIndex % #g.points + 1
				setState(g, "Patrolling")
			else
				g.hrp.CFrame = g.hrp.CFrame * CFrame.Angles(0, math.rad(40) * dt, 0)
			end
			return
		end
		local goal = g.points[g.pointIndex]
		if (Vector3.new(goal.X, pos.Y, goal.Z) - pos).Magnitude < 5 then
			g.observeFor = math.random(15, 35) / 10
			setState(g, "Observing")
		else
			g.hum:MoveTo(goal)
		end
		return
	end

	if g.state == "Detecting" then
		if now - g.stateSince > 0.6 then
			setState(g, "Chasing")
		end
		return
	end

	if g.state == "Chasing" or g.state == "Attacking" then
		local tpos = targetPosition(g.target)
		local leash = g.cfg.guardianLeash
		if not tpos or (tpos - g.home).Magnitude > leash or (g.target.actor and S.WorldBuilder.biomeAt(tpos.Z) ~= g.biome) then
			g.target = nil
			g.ignoreUntil = now + 2
			setState(g, "Returning")
			return
		end
		-- a target that dropped its egg and left the nest area is no longer interesting
		if g.target.actor then
			local st = S.Actors.state(g.target.actor)
			if st and not st.carry and (tpos - g.home).Magnitude > 26 then
				g.target = nil
				setState(g, "Returning")
				return
			end
		end
		g.hum:MoveTo(tpos)
		local dist = (Vector3.new(tpos.X, pos.Y, tpos.Z) - pos).Magnitude
		if dist < 7.5 and now - g.lastHit > 1.4 and g.stunUntil <= now then
			setState(g, "Attacking")
			if g.target.decoy then
				g.target.decoy.untilT = 0
				g.target = nil
				setState(g, "Returning")
			else
				attack(g, g.target.actor)
				g.target = nil
				g.ignoreUntil = now + 3
				setState(g, "Returning")
			end
		elseif g.state == "Attacking" then
			setState(g, "Chasing")
		end
		return
	end

	if g.state == "Returning" then
		local nearest, nd = 1, math.huge
		for i, p in g.points do
			local d = (p - pos).Magnitude
			if d < nd then
				nearest, nd = i, d
			end
		end
		g.pointIndex = nearest
		if nd < 6 then
			setState(g, "Patrolling")
		else
			g.hum:MoveTo(g.points[nearest])
		end
	end
end

-- ===================== ABILITY HOOKS =====================
function Guardians.stunNear(position: Vector3, radius: number, seconds: number): number
	local n = 0
	for _, g in list do
		if (g.hrp.Position - position).Magnitude <= radius then
			g.stunUntil = math.max(g.stunUntil, os.clock() + seconds)
			g.target = nil
			g.ignoreUntil = os.clock() + seconds + 1
			setState(g, "Returning")
			n += 1
		end
	end
	return n
end

function Guardians.slowNear(position: Vector3, radius: number, factor: number, seconds: number): number
	local n = 0
	for _, g in list do
		if (g.hrp.Position - position).Magnitude <= radius then
			g.slowUntil = os.clock() + seconds
			g.slowFactor = math.clamp(factor, 0, 0.8)
			n += 1
		end
	end
	return n
end

function Guardians.addDecoy(position: Vector3, seconds: number, ownerId: number)
	local model = Instance.new("Model")
	model.Name = "Decoy"
	local char = S.Actors.character(ownerId)
	if char then
		for _, d in char:GetChildren() do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				local c = d:Clone()
				c:ClearAllChildren()
				c.Anchored = true
				c.CanCollide = false
				c.Transparency = 0.45
				c.Material = Enum.Material.ForceField
				c.Parent = model
			end
		end
		model:PivotTo(CFrame.new(position) * (char:GetPivot() - char:GetPivot().Position) * CFrame.new(-4, 0, 0))
	end
	model.Parent = Workspace.Runtime.Effects
	local d = { position = position + Vector3.new(-4, 0, 0), untilT = os.clock() + seconds, model = model }
	table.insert(decoys, d)
	task.delay(seconds, function()
		model:Destroy()
	end)
	return d
end

function Guardians.list()
	return list
end

-- Danger estimate for bots: distance to closest awake guardian chasing/near a point.
function Guardians.threatAt(position: Vector3): (number, any)
	local best, bestG = math.huge, nil
	for _, g in list do
		if g.state ~= "Sleeping" and g.stunUntil < os.clock() then
			local d = (g.hrp.Position - position).Magnitude
			if d < best then
				best, bestG = d, g
			end
		end
	end
	return best, bestG
end

function Guardians.start()
	for _, biomeFolder in Workspace.Map:GetChildren() do
		local biomeId = biomeFolder:GetAttribute("BiomeId")
		local gp = biomeFolder:FindFirstChild("GuardianPoints")
		if biomeId and gp then
			for _, gf in gp:GetChildren() do
				local points = {}
				for _, mk in gf:GetChildren() do
					table.insert(points, mk.Position)
				end
				table.sort(points, function(a, b)
					return a.Z < b.Z
				end)
				if #points > 0 then
					spawnGuardian(biomeId, tonumber(string.match(gf.Name, "%d+")) or 1, points)
				end
			end
		end
	end
	task.spawn(function()
		while true do
			local dt = task.wait(0.2)
			for i = #decoys, 1, -1 do
				if decoys[i].untilT < os.clock() then
					table.remove(decoys, i)
				end
			end
			for _, g in list do
				local ok, err = pcall(step, g, dt)
				if not ok then
					warn("[Guardians]", err)
				end
				-- recover a guardian that fell or got stuck far away
				if g.hrp.Position.Y < -20 or (g.hrp.Position - g.home).Magnitude > g.cfg.guardianLeash * 2 then
					g.model:PivotTo(CFrame.new(g.points[1] + Vector3.new(0, 6, 0)))
					setState(g, "Patrolling")
				end
			end
		end
	end)
end

return Guardians
