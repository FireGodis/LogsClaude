--!strict
-- Gerenciador de inimigos: um loop só, ativação por distância, inimigos criados a partir
-- de marcadores (tag "EnemySpawn") do mapa. Rastejador, Mariposa, Guardião e o chefe.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.Config)
local EnemySpec = require(ReplicatedStorage.Shared.EnemySpec)
local MaskMath = require(ReplicatedStorage.Shared.MaskMath)
local Types = require(script.Parent.EnemyTypes)
local Net = require(script.Parent.Net)
local PlayerData = require(script.Parent.PlayerData)
local EnemyRig = require(script.Parent.EnemyRig)
local BossAI = require(script.Parent.BossAI)

type Enemy = Types.Enemy
type Target = Types.Target

local Enemies = {}

local ACTIVE_RADIUS = 130
local FOREVER = 1e6

local list: { Enemy } = {}
local targetsBuf: { Target } = {}
local playerDamage: (Player, number, number) -> () = function() end
local bossDefeated = false
local container: Instance = Workspace
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function sign(value: number): number
	return if value >= 0 then 1 else -1
end

local function floorY(x: number, y: number): number?
	local result = Workspace:Raycast(Vector3.new(x, y + 3, 0), Vector3.new(0, -60, 0), rayParams)
	return if result then result.Position.Y else nil
end

local function wallAhead(x: number, y: number, dir: number, distance: number): boolean
	return Workspace:Raycast(Vector3.new(x, y, 0), Vector3.new(dir * distance, 0, 0), rayParams) ~= nil
end

local function setState(enemy: Enemy, state: string, duration: number, last: string?)
	enemy.state = state
	enemy.stateEnd = os.clock() + duration
	local model = enemy.model
	model:SetAttribute("State", state)
	model:SetAttribute("StateAt", Workspace:GetServerTimeNow())
	model:SetAttribute("Dur", math.max(math.min(duration, 3600), 0.01))
	if last then
		model:SetAttribute("Last", last)
	end
end

local env: Types.Env = {
	now = 0,
	targets = targetsBuf,
	floorY = floorY,
	damage = function(player: Player, masks: number, sourceX: number)
		playerDamage(player, masks, sourceX)
	end,
	fx = function(kind: string, a: any?, b: any?, c: any?, d: any?)
		Net.fireAll("Fx", kind, a, b, c, d)
	end,
	setState = setState,
}

function Enemies.setPlayerDamage(fn: (Player, number, number) -> ())
	playerDamage = fn
end

local function attrNumber(inst: Instance, name: string, default: number): number
	local value = inst:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local function openBarriers()
	for _, barrier in CollectionService:GetTagged("BossBarrier") do
		if barrier:IsA("BasePart") then
			barrier.CanCollide = false
			barrier.Transparency = 1
			Net.fireAll("Fx", "BossSlam", barrier.Position, true)
		end
	end
end

local function nearestTarget(x: number, y: number, maxDistance: number): (Target?, number)
	local best: Target? = nil
	local bestDistance = maxDistance
	for _, target in targetsBuf do
		local p = target.root.Position
		local distance = math.sqrt((p.X - x) ^ 2 + (p.Y - y) ^ 2)
		if distance < bestDistance then
			best, bestDistance = target, distance
		end
	end
	return best, bestDistance
end

local function removeFromList(enemy: Enemy)
	local index = table.find(list, enemy)
	if index then
		table.remove(list, index)
	end
end

local function spawnFromMarker(marker: BasePart)
	local kind = marker:GetAttribute("Kind")
	if typeof(kind) ~= "string" then
		return
	end
	local def = EnemySpec.Defs[kind]
	if not def or (kind == "Boss" and bossDefeated) then
		return
	end
	local position = marker.Position
	local groundY = position.Y
	local rootY = if def.flying then position.Y else position.Y + def.footOffset
	local model = EnemyRig.build(def, Vector3.new(position.X, rootY, 0))
	model.Parent = container

	local enemy: Enemy = {
		def = def,
		model = model,
		root = model.PrimaryPart :: BasePart,
		x = position.X,
		y = rootY,
		facing = if marker:GetAttribute("Facing") == -1 then -1 else 1,
		knockVx = 0,
		health = def.health,
		maxHealth = def.health,
		state = "Idle",
		stateEnd = FOREVER,
		nextAction = 0,
		stunnedUntil = 0,
		homeX = position.X,
		homeY = position.Y,
		range = attrNumber(marker, "Range", 14),
		groundY = groundY,
		aimX = 0,
		aimY = 0,
		phaseOffset = (position.X * 0.37) % 6.28,
		boss = nil,
		shownTo = {},
		markerId = marker.Name,
	}
	if kind == "Boss" then
		BossAI.init(enemy, attrNumber(marker, "ArenaMin", position.X - 60), attrNumber(marker, "ArenaMax", position.X + 60))
		setState(enemy, "Dormant", FOREVER)
	elseif kind == "Flier" then
		setState(enemy, "Hover", FOREVER)
	else
		setState(enemy, "Patrol", FOREVER)
	end
	model:SetAttribute("Facing", enemy.facing)
	table.insert(list, enemy)
end

local function die(enemy: Enemy, killer: Player?)
	removeFromList(enemy)
	Net.fireAll("Fx", "Death", Vector3.new(enemy.x, enemy.y, 0), enemy.def.id == "Boss")
	if killer then
		local profile = PlayerData.get(killer)
		if profile then
			profile.cacos = math.min(9999999, profile.cacos + enemy.def.reward)
			PlayerData.publish(killer)
			Net.fire("Fx", killer, "Cacos", enemy.def.reward)
		end
	end
	if enemy.def.id == "Boss" then
		bossDefeated = true
		openBarriers()
		Net.fireAll("Boss", "defeated", enemy.def.displayName)
		for _, player in Players:GetPlayers() do
			local profile = PlayerData.get(player)
			if profile then
				profile.flags["boss_vigia"] = true
				PlayerData.publish(player)
			end
		end
	end
	enemy.model:Destroy()
end

local function isBlocking(enemy: Enemy): boolean
	return enemy.def.blocksFront
		and (enemy.state == "Patrol" or enemy.state == "Guard" or enemy.state == "SlamWind")
end

local function hurtEnemy(enemy: Enemy, damage: number, fromX: number, player: Player)
	enemy.health = math.max(0, enemy.health - damage)
	local model = enemy.model
	model:SetAttribute("Health", enemy.health)
	model:SetAttribute("HitAt", Workspace:GetServerTimeNow())
	local dirX = sign(enemy.x - fromX)
	Net.fireAll("Fx", "Hit", Vector3.new(enemy.x, enemy.y, 0), dirX)
	if enemy.boss then
		BossAI.onDamaged(enemy, damage)
		Net.fireAll("Boss", "hp", enemy.def.displayName, enemy.health, enemy.maxHealth)
	else
		enemy.knockVx = dirX * (if enemy.def.id == "Shield" then 6 else 14)
		enemy.stunnedUntil = os.clock() + 0.18
		if enemy.def.id == "Flier" and (enemy.state == "Windup" or enemy.state == "Dive") then
			setState(enemy, "Retreat", 1.0)
		end
	end
	if enemy.health <= 0 then
		die(enemy, player)
	end
end

-- Golpe do jogador. Retorna (acertos, bloqueados).
function Enemies.strike(center: Vector2, half: Vector2, damage: number, fromX: number, player: Player, dir: string): (number, number)
	local hits, blocked = 0, 0
	for index = #list, 1, -1 do
		local enemy = list[index]
		if enemy and enemy.root.Parent ~= nil then
			if
				MaskMath.overlaps(
					center,
					half,
					Vector2.new(enemy.x, enemy.y),
					Vector2.new(enemy.def.radiusX, enemy.def.radiusY)
				)
			then
				local fromFront = (fromX - enemy.x) * enemy.facing > 0
				if dir == "F" and isBlocking(enemy) and fromFront then
					blocked += 1
					enemy.knockVx = -enemy.facing * 3
					Net.fireAll("Fx", "Block", Vector3.new(enemy.x + enemy.facing * enemy.def.radiusX, enemy.y, 0), enemy.facing)
				elseif enemy.boss and BossAI.isInvulnerable(enemy) then
					blocked += 1
					Net.fireAll("Fx", "Block", Vector3.new(enemy.x, enemy.y, 0), enemy.facing)
				else
					hits += 1
					hurtEnemy(enemy, damage, fromX, player)
				end
			end
		end
	end
	return hits, blocked
end

-- Atalho de teste (só chamado pelo Cheats, que só existe no Studio).
function Enemies.cheatDamageBoss(player: Player, amount: number)
	for _, enemy in list do
		if enemy.boss then
			hurtEnemy(enemy, amount, enemy.x - 5, player)
		end
	end
end

function Enemies.stunNear(position: Vector3, radius: number, duration: number)
	local untilTime = os.clock() + duration
	for _, enemy in list do
		if enemy.boss == nil and (Vector3.new(enemy.x, enemy.y, 0) - position).Magnitude <= radius then
			enemy.stunnedUntil = untilTime
		end
	end
end

local function contact(enemy: Enemy, now: number)
	if now < enemy.stunnedUntil then
		return
	end
	for _, target in targetsBuf do
		local p = target.root.Position
		if math.abs(p.X - enemy.x) <= enemy.def.radiusX + 1.1 and math.abs(p.Y - enemy.y) <= enemy.def.radiusY + 2.2 then
			playerDamage(target.player, enemy.def.contactDamage, enemy.x)
		end
	end
end

local function edgeOrWall(enemy: Enemy): boolean
	local ahead = enemy.x + enemy.facing * (enemy.def.radiusX + 1.2)
	local floor = floorY(ahead, enemy.y)
	if not floor or floor < enemy.groundY - 3 then
		return true
	end
	return wallAhead(enemy.x, enemy.y, enemy.facing, enemy.def.radiusX + 0.8)
end

local function followGround(enemy: Enemy)
	local floor = floorY(enemy.x, enemy.y)
	if floor then
		enemy.groundY = floor
		enemy.y = floor + enemy.def.footOffset
	end
end

local function stepCrawler(enemy: Enemy, dt: number, now: number)
	local state = enemy.state
	local target = nearestTarget(enemy.x, enemy.y, 24)
	if state == "Patrol" then
		if now >= enemy.stunnedUntil then
			if edgeOrWall(enemy) or (enemy.x - enemy.homeX) * enemy.facing > enemy.range then
				enemy.facing = -enemy.facing
			else
				enemy.x += enemy.facing * 4 * dt
			end
			if target and now >= enemy.nextAction then
				local dx = target.root.Position.X - enemy.x
				if math.abs(dx) < 18 and math.abs(target.root.Position.Y - enemy.y) < 7 and dx * enemy.facing > 0 then
					setState(enemy, "Notice", 0.5)
				end
			end
		end
	elseif state == "Notice" then
		if target then
			enemy.facing = sign(target.root.Position.X - enemy.x)
		end
		if now >= enemy.stateEnd then
			setState(enemy, "Charge", 1.1)
		end
	elseif state == "Charge" then
		if edgeOrWall(enemy) or now >= enemy.stateEnd then
			setState(enemy, "Recover", 0.95)
		else
			enemy.x += enemy.facing * 17 * dt
		end
	elseif state == "Recover" then
		if now >= enemy.stateEnd then
			setState(enemy, "Patrol", FOREVER)
			enemy.nextAction = now + 1.2
		end
	end
	followGround(enemy)
end

local function stepFlier(enemy: Enemy, dt: number, now: number)
	local state = enemy.state
	local target = nearestTarget(enemy.x, enemy.y, 30)
	if state == "Hover" then
		local t = now + enemy.phaseOffset
		local goalX = enemy.homeX + math.sin(t * 0.9) * enemy.range * 0.5
		local goalY = enemy.homeY + math.sin(t * 1.7) * 1.6
		local blend = math.min(1, dt * 6)
		enemy.x += (goalX - enemy.x) * blend
		enemy.y += (goalY - enemy.y) * blend
		enemy.facing = if math.cos(t * 0.9) >= 0 then 1 else -1
		if target and now >= enemy.nextAction and now >= enemy.stunnedUntil then
			setState(enemy, "Windup", 0.6)
		end
	elseif state == "Windup" then
		enemy.y += 5 * dt
		if target then
			enemy.facing = sign(target.root.Position.X - enemy.x)
		end
		if now >= enemy.stateEnd then
			local goal = if target then target.root.Position else Vector3.new(enemy.x + enemy.facing * 8, enemy.y - 6, 0)
			local direction = Vector2.new(goal.X - enemy.x, goal.Y - enemy.y)
			direction = if direction.Magnitude > 0.1 then direction.Unit else Vector2.new(enemy.facing, -0.4)
			enemy.aimX, enemy.aimY = direction.X, direction.Y
			setState(enemy, "Dive", 0.9)
		end
	elseif state == "Dive" then
		enemy.x += enemy.aimX * 32 * dt
		enemy.y += enemy.aimY * 32 * dt
		local floor = floorY(enemy.x, enemy.y)
		local hitFloor = floor ~= nil and enemy.y - floor < 1.4
		if hitFloor or wallAhead(enemy.x, enemy.y, sign(enemy.aimX), 1.8) or now >= enemy.stateEnd then
			setState(enemy, "Retreat", 1.0)
		end
	elseif state == "Retreat" then
		local blend = math.min(1, dt * 3.2)
		enemy.x += (enemy.homeX - enemy.x) * blend
		enemy.y += (enemy.homeY - enemy.y) * blend
		if now >= enemy.stateEnd then
			setState(enemy, "Hover", FOREVER)
			enemy.nextAction = now + 1.8
		end
	end
end

local function stepShield(enemy: Enemy, dt: number, now: number)
	local state = enemy.state
	local target, distance = nearestTarget(enemy.x, enemy.y, 30)
	if state == "Patrol" then
		if edgeOrWall(enemy) or (enemy.x - enemy.homeX) * enemy.facing > enemy.range then
			enemy.facing = -enemy.facing
		else
			enemy.x += enemy.facing * 3 * dt
		end
		if target and distance < 20 and now >= enemy.nextAction then
			setState(enemy, "Guard", 6)
		end
	elseif state == "Guard" then
		if not target or distance > 26 or now >= enemy.stateEnd then
			setState(enemy, "Patrol", FOREVER)
			enemy.nextAction = now + 1.5
		else
			local dx = target.root.Position.X - enemy.x
			enemy.facing = sign(dx)
			if math.abs(dx) > 8 and not edgeOrWall(enemy) then
				enemy.x += enemy.facing * 2.4 * dt
			elseif now >= enemy.nextAction then
				setState(enemy, "SlamWind", 0.75)
			end
		end
	elseif state == "SlamWind" then
		if now >= enemy.stateEnd then
			setState(enemy, "Slam", 0.2)
			for _, t in targetsBuf do
				local p = t.root.Position
				local dx = (p.X - enemy.x) * enemy.facing
				if dx >= -1 and dx <= 9.5 and math.abs(p.Y - enemy.y) <= 6 then
					playerDamage(t.player, 1, enemy.x)
				end
			end
			Net.fireAll("Fx", "BossSlam", Vector3.new(enemy.x + enemy.facing * 6, enemy.groundY, 0), false)
		end
	elseif state == "Slam" then
		if now >= enemy.stateEnd then
			setState(enemy, "Recover", 1.3)
		end
	elseif state == "Recover" then
		if now >= enemy.stateEnd then
			setState(enemy, "Guard", 6)
			enemy.nextAction = now + 1.0
		end
	end
	followGround(enemy)
end

local function refreshTargets()
	table.clear(targetsBuf)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and player:GetAttribute("Ready") == true then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
				table.insert(targetsBuf, { player = player, root = root, humanoid = humanoid })
			end
		end
	end
end

local function onHeartbeat(dt: number)
	if #list == 0 then
		return
	end
	refreshTargets()
	local now = os.clock()
	env.now = now
	for index = #list, 1, -1 do
		local enemy = list[index]
		if not enemy then
			continue
		end
		if enemy.root.Parent == nil then
			table.remove(list, index)
			continue
		end

		-- Só pensa quem está perto de alguém (o chefe vigia a própria arena).
		local active = enemy.boss ~= nil and (enemy.state ~= "Dormant" or #targetsBuf > 0)
		if not active then
			local _, distance = nearestTarget(enemy.x, enemy.y, ACTIVE_RADIUS)
			active = distance < ACTIVE_RADIUS
		end
		if not active then
			continue
		end

		local boss = enemy.boss
		if boss then
			if BossAI.step(enemy, dt, env) then
				for _, t in targetsBuf do
					local p = t.root.Position
					if p.X >= boss.arenaMin and p.X <= boss.arenaMax then
						enemy.shownTo[t.player] = true
						Net.fire("Boss", t.player, "show", enemy.def.displayName, enemy.health, enemy.maxHealth)
					end
				end
			end
			if enemy.state == "Dormant" and next(enemy.shownTo) ~= nil then
				table.clear(enemy.shownTo)
				Net.fireAll("Boss", "reset")
			end
			-- Quem entra na arena no meio da luta também vê a barra.
			if enemy.state ~= "Dormant" then
				for _, t in targetsBuf do
					local p = t.root.Position
					if not enemy.shownTo[t.player] and p.X >= boss.arenaMin and p.X <= boss.arenaMax then
						enemy.shownTo[t.player] = true
						Net.fire("Boss", t.player, "show", enemy.def.displayName, enemy.health, enemy.maxHealth)
					end
				end
			end
		else
			if enemy.def.id == "Crawler" then
				stepCrawler(enemy, dt, now)
			elseif enemy.def.id == "Flier" then
				stepFlier(enemy, dt, now)
			else
				stepShield(enemy, dt, now)
			end
			if math.abs(enemy.knockVx) > 0.3 then
				enemy.x += enemy.knockVx * dt
				enemy.knockVx *= math.max(0, 1 - dt * 7)
			end
			contact(enemy, now)
		end

		enemy.root.CFrame = CFrame.new(enemy.x, enemy.y, 0)
		if enemy.model:GetAttribute("Facing") ~= enemy.facing then
			enemy.model:SetAttribute("Facing", enemy.facing)
		end
	end
end

local function clearAll()
	for _, enemy in list do
		enemy.model:Destroy()
	end
	table.clear(list)
end

local function spawnAll()
	for _, marker in CollectionService:GetTagged("EnemySpawn") do
		if marker:IsA("BasePart") then
			spawnFromMarker(marker)
		end
	end
end

-- Descanso em um marco: todos voltam (menos o chefe, se já caiu).
function Enemies.respawnAll()
	clearAll()
	spawnAll()
end

function Enemies.silenceBoss()
	bossDefeated = true
	for index = #list, 1, -1 do
		local enemy = list[index]
		if enemy and enemy.boss then
			enemy.model:Destroy()
			table.remove(list, index)
		end
	end
	openBarriers()
end

function Enemies.start()
	local mundo = Workspace:FindFirstChild("Mundo")
	local geometry = if mundo then mundo:FindFirstChild("Geometria") else nil
	if geometry then
		rayParams.FilterDescendantsInstances = { geometry }
	end
	local folder = if mundo then mundo:FindFirstChild("Inimigos") else nil
	if folder then
		container = folder
	elseif mundo then
		local created = Instance.new("Folder")
		created.Name = "Inimigos"
		created.Parent = mundo
		container = created
	end
	spawnAll()
	RunService.Heartbeat:Connect(onHeartbeat)
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, enemy in list do
			enemy.shownTo[player] = nil
		end
	end)
end

return Enemies
