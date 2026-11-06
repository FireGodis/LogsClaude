--[[
	BotNavigator — physical movement for simulated participants.

	Strategy (cheap and reliable):
	  1. long trips use the AVENUE LANE (kept obstacle-free by the world builder): step into the
	     avenue, walk along it in 60-stud segments, step out at the destination row
	  2. short/final legs try a direct MoveTo; if the bot gets stuck it jumps, then falls back to
	     PathfindingService (computed only when needed, with a small retry budget)
	Every call can be aborted by a predicate (e.g. "my base is being raided").
]]

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local BotNavigator = {}
local S
local LANE = GameConfig.World.AvenueWidth / 2 - 6

function BotNavigator.init(sys)
	S = sys
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Walks straight to a point; returns true on arrival, false if stuck/aborted/timeout.
local function direct(id: number, goal: Vector3, opts): boolean
	local hum = S.Actors.humanoid(id)
	local root = S.Actors.root(id)
	if not hum or not root then
		return false
	end
	local tolerance = opts.tolerance or 3
	local deadline = os.clock() + (opts.timeout or 30)
	local lastPos = root.Position
	local lastProgress = os.clock()
	local jumps = 0
	while os.clock() < deadline do
		if opts.abort and opts.abort() then
			hum:MoveTo(root.Position)
			return false
		end
		root = S.Actors.root(id)
		if not root or hum.Health <= 0 then
			return false
		end
		if (flat(root.Position) - flat(goal)).Magnitude <= tolerance then
			return true
		end
		hum:MoveTo(goal)
		task.wait(0.25)
		if (root.Position - lastPos).Magnitude > 1 then
			lastPos = root.Position
			lastProgress = os.clock()
		elseif os.clock() - lastProgress > 1.2 and hum.WalkSpeed > 0 then
			jumps += 1
			hum.Jump = true
			lastProgress = os.clock()
			if jumps > 3 then
				return false
			end
		end
	end
	return false
end

local function pathTo(id: number, goal: Vector3, opts): boolean
	local root = S.Actors.root(id)
	if not root then
		return false
	end
	for _ = 1, 3 do
		local path = PathfindingService:CreatePath({ AgentRadius = 2.2, AgentHeight = 5.5, AgentCanJump = true, WaypointSpacing = 6 })
		local ok = pcall(path.ComputeAsync, path, root.Position, goal)
		if not ok or path.Status ~= Enum.PathStatus.Success then
			return false
		end
		local blocked = false
		local conn = path.Blocked:Connect(function()
			blocked = true
		end)
		local success = true
		for _, wp in path:GetWaypoints() do
			if blocked then
				success = false
				break
			end
			local hum = S.Actors.humanoid(id)
			if wp.Action == Enum.PathWaypointAction.Jump and hum then
				hum.Jump = true
			end
			if not direct(id, wp.Position, { tolerance = 2.5, timeout = 6, abort = opts.abort }) then
				success = false
				break
			end
		end
		conn:Disconnect()
		if success then
			return true
		end
		if opts.abort and opts.abort() then
			return false
		end
		root = S.Actors.root(id)
		if not root then
			return false
		end
	end
	return false
end

local function leg(id: number, goal: Vector3, opts): boolean
	if direct(id, goal, opts) then
		return true
	end
	if opts.abort and opts.abort() then
		return false
	end
	if pathTo(id, goal, opts) then
		return true
	end
	return direct(id, goal, { tolerance = (opts.tolerance or 3) + 2, timeout = 6, abort = opts.abort })
end

-- Public: travel anywhere on the map.
function BotNavigator.moveTo(id: number, goal: Vector3, opts): boolean
	opts = opts or {}
	local root = S.Actors.root(id)
	if not root then
		return false
	end
	local from = root.Position
	local dz = math.abs(goal.Z - from.Z)
	if dz > 60 or (math.abs(from.X) > 30 and math.abs(goal.X) > 30 and math.sign(from.X) ~= math.sign(goal.X)) then
		-- 1. into the avenue
		local laneX = math.clamp(from.X, -LANE, LANE)
		if math.abs(from.X) > LANE + 2 then
			if not leg(id, Vector3.new(laneX, from.Y, from.Z), { tolerance = 4, timeout = 15, abort = opts.abort }) then
				if opts.abort and opts.abort() then
					return false
				end
			end
		end
		-- 2. along the avenue
		local x = math.clamp(goal.X, -LANE, LANE) * 0.5 + (opts.laneOffset or 0)
		local z = (S.Actors.root(id) :: BasePart).Position.Z
		local stepDir = goal.Z > z and 1 or -1
		local fails = 0
		while math.abs(goal.Z - z) > 30 do
			z += stepDir * math.min(60, math.abs(goal.Z - z))
			if not direct(id, Vector3.new(x, 1, z), { tolerance = 5, timeout = 12, abort = opts.abort }) then
				if opts.abort and opts.abort() then
					return false
				end
				local r = S.Actors.root(id)
				fails += 1
				if not r or fails > 4 then
					return false
				end
				z = r.Position.Z
			end
		end
	end
	-- 3. final leg
	return leg(id, goal, opts)
end

return BotNavigator
