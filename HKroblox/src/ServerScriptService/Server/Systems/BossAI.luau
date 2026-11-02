--!strict
-- IA do chefe "Vigia Rachado": padrões variados, fases, atordoamento, ondas de choque,
-- chuva de escombros, salto e investida. Escolha ponderada pela distância e pela fase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(script.Parent.EnemyTypes)

type Enemy = Types.Enemy
type Env = Types.Env
type BossData = Types.BossData

local BossAI = {}

local PHASE_K = { 1.0, 0.86, 0.74 } -- fator dos tempos de aviso por fase
local WALK_SPEED = { 7, 8.6, 10.5 }
local STAGGER_TIME = 2.7
local rng = Random.new()

function BossAI.init(enemy: Enemy, arenaMin: number, arenaMax: number)
	enemy.boss = {
		phase = 1,
		lastAttack = "",
		damageSince = 0,
		pendingStagger = false,
		arenaMin = arenaMin,
		arenaMax = arenaMax,
		waves = {},
		rocks = {},
		fromX = 0,
		toX = 0,
		airT = 0,
		airDur = 0.85,
		noTargetSince = 0,
	}
end

local function sign(value: number): number
	return if value >= 0 then 1 else -1
end

local function nearestInArena(enemy: Enemy, boss: BossData, env: Env): (Types.Target?, number)
	local best: Types.Target? = nil
	local bestDistance = math.huge
	for _, target in env.targets do
		local p = target.root.Position
		if p.X >= boss.arenaMin and p.X <= boss.arenaMax and math.abs(p.Y - enemy.groundY) < 40 then
			local distance = math.abs(p.X - enemy.x)
			if distance < bestDistance then
				best, bestDistance = target, distance
			end
		end
	end
	return best, bestDistance
end

-- Zona de dano no chão: quem estiver dentro (e baixo o bastante) leva dano.
local function hitZone(enemy: Enemy, env: Env, x0: number, x1: number, maxHeight: number, masks: number)
	local low, high = math.min(x0, x1), math.max(x0, x1)
	for _, target in env.targets do
		local p = target.root.Position
		if p.X >= low and p.X <= high and p.Y <= enemy.groundY + maxHeight then
			env.damage(target.player, masks, enemy.x)
		end
	end
end

local function spawnWave(enemy: Enemy, boss: BossData, env: Env, x: number, dir: number)
	local life = 1.5
	table.insert(boss.waves, { x = x, y = enemy.groundY, dir = dir, speed = 26, untilT = env.now + life })
	env.fx("Wave", Vector3.new(x, enemy.groundY, 0), dir, 26, life)
end

local function spawnRocks(enemy: Enemy, boss: BossData, env: Env, count: number, aimAt: number?)
	local low, high = boss.arenaMin + 6, boss.arenaMax - 6
	for index = 1, count do
		local x = if index == 1 and aimAt then math.clamp(aimAt, low, high) else rng:NextNumber(low, high)
		local delay = 0.9 + index * 0.2 + rng:NextNumber(0, 0.25)
		table.insert(boss.rocks, { x = x, y = enemy.groundY, hitAt = env.now + delay, fallSent = false })
		env.fx("DebrisMark", Vector3.new(x, enemy.groundY, 0), delay)
	end
end

local function updateHazards(enemy: Enemy, boss: BossData, dt: number, env: Env)
	for index = #boss.waves, 1, -1 do
		local wave = boss.waves[index]
		if wave then
			wave.x += wave.dir * wave.speed * dt
			local expired = env.now >= wave.untilT or wave.x < boss.arenaMin - 4 or wave.x > boss.arenaMax + 4
			local hit = false
			if not expired then
				for _, target in env.targets do
					local p = target.root.Position
					if math.abs(p.X - wave.x) <= 1.8 and p.Y <= wave.y + 7 then
						env.damage(target.player, 1, wave.x - wave.dir * 2)
						hit = true
					end
				end
			end
			if expired or hit then
				table.remove(boss.waves, index)
			end
		end
	end
	for index = #boss.rocks, 1, -1 do
		local rock = boss.rocks[index]
		if rock then
			if not rock.fallSent and env.now >= rock.hitAt - 0.55 then
				rock.fallSent = true
				env.fx("DebrisFall", Vector3.new(rock.x, rock.y, 0), 0.55)
			end
			if env.now >= rock.hitAt then
				for _, target in env.targets do
					local p = target.root.Position
					if math.abs(p.X - rock.x) <= 2.9 then
						env.damage(target.player, 1, rock.x)
					end
				end
				env.fx("DebrisHit", Vector3.new(rock.x, rock.y, 0))
				table.remove(boss.rocks, index)
			end
		end
	end
end

local function startAttack(enemy: Enemy, boss: BossData, env: Env, name: string)
	boss.lastAttack = name
	local k = PHASE_K[boss.phase] or 1
	if name == "Sweep" then
		env.setState(enemy, "SweepWind", 0.7 * k)
	elseif name == "Slam" then
		env.setState(enemy, "SlamWind", 0.9 * k)
	elseif name == "Leap" then
		env.setState(enemy, "LeapWind", 0.62 * k)
	elseif name == "Charge" then
		env.setState(enemy, "ChargeWind", 0.8 * k)
	elseif name == "Rain" then
		env.setState(enemy, "RainWind", 1.05 * k)
	end
end

local function chooseAttack(enemy: Enemy, boss: BossData, distance: number): string
	local options: { { name: string, weight: number } } = {}
	local function add(name: string, weight: number)
		if boss.lastAttack == name then
			weight *= 0.2
		end
		table.insert(options, { name = name, weight = weight })
	end
	if distance < 15 then
		add("Sweep", 4)
	end
	if distance < 20 then
		add("Slam", 3)
	end
	if distance > 10 then
		add("Leap", if boss.phase == 1 then 2 else 3)
	end
	if boss.phase >= 2 and distance > 9 then
		add("Charge", 3)
	end
	if boss.phase >= 2 then
		add("Rain", if boss.phase == 3 then 2.5 else 1.5)
	end
	if #options == 0 then
		add("Slam", 1)
	end
	local total = 0
	for _, option in options do
		total += option.weight
	end
	local roll = rng:NextNumber(0, total)
	for _, option in options do
		roll -= option.weight
		if roll <= 0 then
			return option.name
		end
	end
	return "Slam"
end

local function toIdle(enemy: Enemy, boss: BossData, env: Env, cooldown: number)
	enemy.nextAction = env.now + cooldown * (PHASE_K[boss.phase] or 1)
	env.setState(enemy, "Idle", 1e6)
end

-- Quando um estado cronometrado termina.
local function onStateEnd(enemy: Enemy, boss: BossData, env: Env, target: Types.Target?)
	local state = enemy.state
	local f = enemy.facing
	if state == "Intro" or state == "PhaseRoar" then
		toIdle(enemy, boss, env, 0.5)
	elseif state == "SweepWind" then
		env.setState(enemy, "Sweep", 0.24)
		hitZone(enemy, env, enemy.x - f * 3, enemy.x + f * 13, 8.5, 1)
		env.fx("BossSlam", Vector3.new(enemy.x + f * 8, enemy.groundY, 0), false)
	elseif state == "Sweep" then
		env.setState(enemy, "Recover", 0.6, "Sweep")
	elseif state == "SlamWind" then
		env.setState(enemy, "Slam", 0.2)
		hitZone(enemy, env, enemy.x + f * 3, enemy.x + f * 17, 7.5, 2)
		local impact = enemy.x + f * 11
		env.fx("BossSlam", Vector3.new(impact, enemy.groundY, 0), true)
		spawnWave(enemy, boss, env, impact, f)
		if boss.phase >= 2 then
			spawnWave(enemy, boss, env, impact, -f)
		end
	elseif state == "Slam" then
		env.setState(enemy, "Recover", 0.95, "Slam")
	elseif state == "LeapWind" then
		boss.fromX = enemy.x
		local goal = if target then target.root.Position.X else enemy.x + f * 14
		boss.toX = math.clamp(goal, boss.arenaMin + 6, boss.arenaMax - 6)
		boss.airT = 0
		boss.airDur = 0.85
		env.setState(enemy, "Leap", boss.airDur)
	elseif state == "Leap" then
		enemy.x = boss.toX
		enemy.y = enemy.groundY + enemy.def.footOffset
		env.setState(enemy, "Land", 0.28)
		hitZone(enemy, env, enemy.x - 7.5, enemy.x + 7.5, 8, 2)
		env.fx("BossSlam", Vector3.new(enemy.x, enemy.groundY, 0), true)
		spawnWave(enemy, boss, env, enemy.x, 1)
		spawnWave(enemy, boss, env, enemy.x, -1)
	elseif state == "Land" then
		env.setState(enemy, "Recover", 0.85, "Leap")
	elseif state == "ChargeWind" then
		env.setState(enemy, "Charge", 1.6)
	elseif state == "Charge" then
		env.setState(enemy, "Recover", 0.9, "Charge")
	elseif state == "Crash" then
		env.setState(enemy, "Recover", 1.0, "Charge")
	elseif state == "RainWind" then
		local count = if boss.phase >= 3 then 10 else 6
		spawnRocks(enemy, boss, env, count, if target then target.root.Position.X else nil)
		env.fx("BossSlam", Vector3.new(enemy.x, enemy.groundY, 0), true)
		env.setState(enemy, "Recover", 0.9, "Rain")
	elseif state == "Recover" then
		if boss.pendingStagger then
			boss.pendingStagger = false
			boss.damageSince = 0
			env.setState(enemy, "Stagger", STAGGER_TIME)
		else
			toIdle(enemy, boss, env, 0.55)
		end
	elseif state == "Stagger" then
		toIdle(enemy, boss, env, 0.8)
	end
end

-- Movimento por quadro dos estados que se deslocam.
local function onStateUpdate(enemy: Enemy, boss: BossData, dt: number, env: Env)
	local state = enemy.state
	local f = enemy.facing
	if state == "Slam" then
		enemy.x += f * 20 * dt
	elseif state == "Sweep" then
		enemy.x += f * 8 * dt
	elseif state == "Leap" then
		boss.airT += dt
		local t = math.clamp(boss.airT / boss.airDur, 0, 1)
		enemy.x = boss.fromX + (boss.toX - boss.fromX) * t
		enemy.y = enemy.groundY + enemy.def.footOffset + 4 * 16 * t * (1 - t)
	elseif state == "Charge" then
		enemy.x += f * 30 * dt
		for _, target in env.targets do
			local p = target.root.Position
			if math.abs(p.X - enemy.x) <= enemy.def.radiusX + 1.2 and p.Y <= enemy.groundY + 12 then
				env.damage(target.player, 2, enemy.x)
			end
		end
		local edge = if f > 0 then enemy.x >= boss.arenaMax - 4 else enemy.x <= boss.arenaMin + 4
		if edge then
			env.setState(enemy, "Crash", 1.0)
			env.fx("BossSlam", Vector3.new(enemy.x + f * 4, enemy.groundY, 0), true)
			spawnRocks(enemy, boss, env, 3, enemy.x - f * 8)
		end
	end
	enemy.x = math.clamp(enemy.x, boss.arenaMin + 3, boss.arenaMax - 3)
end

local function decide(enemy: Enemy, boss: BossData, dt: number, env: Env, target: Types.Target?, distance: number)
	local ratio = enemy.health / enemy.maxHealth
	if boss.phase == 1 and ratio <= 0.66 then
		boss.phase = 2
		boss.pendingStagger = false
		env.setState(enemy, "PhaseRoar", 1.5)
		env.fx("BossSlam", Vector3.new(enemy.x, enemy.groundY, 0), true)
		return
	elseif boss.phase == 2 and ratio <= 0.33 then
		boss.phase = 3
		boss.pendingStagger = false
		env.setState(enemy, "PhaseRoar", 1.5)
		env.fx("BossSlam", Vector3.new(enemy.x, enemy.groundY, 0), true)
		return
	end
	if boss.pendingStagger then
		boss.pendingStagger = false
		boss.damageSince = 0
		env.setState(enemy, "Stagger", STAGGER_TIME)
		return
	end
	if not target then
		if enemy.state ~= "Idle" then
			env.setState(enemy, "Idle", 1e6)
		end
		return
	end
	enemy.facing = sign(target.root.Position.X - enemy.x)
	if env.now < enemy.nextAction then
		if distance > 7 then
			enemy.x += enemy.facing * (WALK_SPEED[boss.phase] or 7) * dt
			if enemy.state ~= "Walk" then
				env.setState(enemy, "Walk", 1e6)
			end
		elseif enemy.state ~= "Idle" then
			env.setState(enemy, "Idle", 1e6)
		end
		return
	end
	startAttack(enemy, boss, env, chooseAttack(enemy, boss, distance))
end

function BossAI.onDamaged(enemy: Enemy, damage: number)
	local boss = enemy.boss
	if not boss then
		return
	end
	if enemy.state ~= "Stagger" then
		boss.damageSince += damage
		if boss.damageSince >= enemy.maxHealth * 0.22 then
			boss.pendingStagger = true
		end
	end
end

-- O chefe não pode ser ferido enquanto ruge.
function BossAI.isInvulnerable(enemy: Enemy): boolean
	return enemy.state == "Dormant" or enemy.state == "Intro" or enemy.state == "PhaseRoar"
end

function BossAI.reset(enemy: Enemy, env: Env)
	local boss = enemy.boss
	if not boss then
		return
	end
	enemy.health = enemy.maxHealth
	enemy.model:SetAttribute("Health", enemy.maxHealth)
	enemy.x = enemy.homeX
	enemy.y = enemy.groundY + enemy.def.footOffset
	enemy.facing = -1
	boss.phase = 1
	boss.lastAttack = ""
	boss.damageSince = 0
	boss.pendingStagger = false
	boss.noTargetSince = 0
	table.clear(boss.waves)
	table.clear(boss.rocks)
	enemy.nextAction = 0
	env.setState(enemy, "Dormant", 1e6)
end

function BossAI.step(enemy: Enemy, dt: number, env: Env): boolean
	local boss = enemy.boss
	if not boss then
		return false
	end
	local target, distance = nearestInArena(enemy, boss, env)
	updateHazards(enemy, boss, dt, env)

	if enemy.state == "Dormant" then
		if target then
			enemy.facing = sign(target.root.Position.X - enemy.x)
			env.setState(enemy, "Intro", 2.4)
			env.fx("BossSlam", Vector3.new(enemy.x, enemy.groundY, 0), true)
			return true -- avisa o gerenciador: mostrar barra de vida
		end
		return false
	end

	-- Sem ninguém na arena por um tempo: o chefe recomeça do zero.
	if not target then
		if boss.noTargetSince == 0 then
			boss.noTargetSince = env.now
		elseif env.now - boss.noTargetSince > 6 then
			BossAI.reset(enemy, env)
			return false
		end
	else
		boss.noTargetSince = 0
	end

	-- Acompanha o alvo durante a maior parte dos avisos, depois trava a direção.
	local state = enemy.state
	if target and (state == "SweepWind" or state == "SlamWind" or state == "ChargeWind" or state == "LeapWind") then
		local duration = enemy.model:GetAttribute("Dur")
		local remaining = enemy.stateEnd - env.now
		if typeof(duration) == "number" and remaining > duration * 0.3 then
			enemy.facing = sign(target.root.Position.X - enemy.x)
		end
	end

	if state == "Idle" or state == "Walk" then
		decide(enemy, boss, dt, env, target, distance)
	elseif env.now < enemy.stateEnd then
		onStateUpdate(enemy, boss, dt, env)
	else
		onStateEnd(enemy, boss, env, target)
	end

	-- Contato com o corpo.
	local current = enemy.state
	if current ~= "Intro" and current ~= "PhaseRoar" and current ~= "Stagger" and current ~= "Dormant" then
		for _, t in env.targets do
			local p = t.root.Position
			if math.abs(p.X - enemy.x) <= enemy.def.radiusX and p.Y <= enemy.groundY + enemy.def.radiusY * 1.6 then
				env.damage(t.player, enemy.def.contactDamage, enemy.x)
			end
		end
	end
	return false
end

return BossAI
