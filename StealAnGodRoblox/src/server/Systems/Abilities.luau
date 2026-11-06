--[[
	Abilities — the signature system of STEAL AN GOD. The equipped companion grants exactly one
	ability (each of the 52 creatures has its own name, numbers, VFX theme and description).

	Server-authoritative: cooldowns, effects and validations live here; clients only request
	"UseAbility" and render the Effect broadcast. Balance guards:
	  • no teleport to the end of the map, no remote stealing, no infinite money
	  • abilities never stun/disable other PLAYERS (only guardians are affected)
	  • a global ability lockout (1.5s) + per-ability cooldown + immunity windows
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Creatures = require(Shared.Config.Creatures)
local Net = require(Shared.Util.Net)

local Abilities = {}
local S

function Abilities.init(sys)
	S = sys
end

-- Applies an impulse to an actor (client-owned for players → ask the client).
function Abilities.knockback(id: number, velocity: Vector3)
	local player = S.Actors.player(id)
	local st = S.Actors.state(id)
	if st then
		st.teleportGrace = os.clock() + 1.5
	end
	if player then
		Net.fire(player, "Knockback", velocity)
	else
		local root = S.Actors.root(id)
		if root then
			root.AssemblyLinearVelocity = velocity
		end
	end
end

function Abilities.definitionFor(id: number)
	local pet = S.Pets.equipped(id)
	if not pet then
		return nil, nil
	end
	local c = Creatures.ById[pet.species]
	return c and c.ab or nil, c
end

function Abilities.cooldownLeft(id: number): number
	local st = S.Actors.state(id)
	local ab = Abilities.definitionFor(id)
	if not st or not ab then
		return 0
	end
	local readyAt = st.cooldowns[ab.id] or 0
	return math.max(0, readyAt - os.clock())
end

local function broadcast(id: number, ab, creature, extra)
	local pos = S.Actors.position(id)
	local payload = { kind = "Ability", ability = ab.kind, name = ab.name, mythology = creature.mythology, color = creature.colors[3], position = pos, actor = id }
	if extra then
		for k, v in extra do
			payload[k] = v
		end
	end
	Net.fireAll("Effect", payload)
end

-- Returns ok, message
function Abilities.use(id: number): (boolean, string?)
	local st = S.Actors.state(id)
	local ab, creature = Abilities.definitionFor(id)
	if not st or not ab then
		return false, "Equipe um pet para usar habilidades"
	end
	if not S.Actors.alive(id) then
		return false, "Indisponível"
	end
	local now = os.clock()
	if (st.cooldowns[ab.id] or 0) > now then
		return false, string.format("Recarregando (%.0fs)", st.cooldowns[ab.id] - now)
	end
	if (st.cooldowns._global or 0) > now then
		return false, "Aguarde"
	end
	local p = ab.p
	local pos = S.Actors.position(id) :: Vector3
	local root = S.Actors.root(id)
	local kind = ab.kind
	local extra = nil

	if kind == "SpeedBurst" then
		S.Actors.addBuff(id, "SpeedBurst", p.duration, p.mult)
		if p.carryingOnly then
			S.Actors.addBuff(id, "SpeedBurstCarryOnly", p.duration, true)
		else
			S.Actors.clearBuff(id, "SpeedBurstCarryOnly")
		end
	elseif kind == "Dash" or kind == "Leap" then
		if S.Actors.isStuck(id) then
			return false, "Você está preso!"
		end
		local look = root and root.CFrame.LookVector or Vector3.new(0, 0, 1)
		look = Vector3.new(look.X, 0, look.Z).Unit
		local v = kind == "Dash" and (look * p.power + Vector3.new(0, 18, 0)) or (look * p.power * 0.45 + Vector3.new(0, p.power * 0.75, 0))
		Abilities.knockback(id, v)
	elseif kind == "Reveal" then
		extra = { filter = p.filter, radius = p.radius, duration = p.duration }
		local player = S.Actors.player(id)
		if player then
			Net.fire(player, "Reveal", { filter = p.filter, radius = p.radius, duration = p.duration, position = pos })
		end
		S.Actors.addBuff(id, "Reveal", p.duration, p)
	elseif kind == "Shockwave" then
		local n = S.Guardians.stunNear(pos, p.radius, p.stun)
		extra = { radius = p.radius, hits = n }
	elseif kind == "Frost" then
		local n = S.Guardians.slowNear(pos, p.radius, p.slow, p.duration)
		extra = { radius = p.radius, hits = n }
	elseif kind == "Decoy" then
		S.Guardians.addDecoy(pos, p.duration, id)
	elseif kind == "GuardShield" then
		S.Actors.addBuff(id, "GuardShield", p.duration, true)
	elseif kind == "EggShield" then
		S.Actors.addBuff(id, "EggShield", p.duration, true)
	elseif kind == "WeightRelief" then
		S.Actors.addBuff(id, "WeightRelief", p.duration, p.reduction)
	elseif kind == "TrapWard" then
		S.Actors.addBuff(id, "TrapWard", p.duration, true)
	elseif kind == "Rescue" then
		st.trappedUntil = 0
		st.stunUntil = 0
		S.Traps.releaseActor(id)
		if pos.Y < -15 then
			local cf = S.Bases.spawnCFrame(id)
			local char = S.Actors.character(id)
			if cf and char then
				st.teleportGrace = os.clock() + 2
				char:PivotTo(cf) -- back to your own base, never forward
			end
		end
		S.Actors.addBuff(id, "TrapWard", 3, true)
	elseif kind == "HatchBoost" then
		local n = S.Hatch.reduceAll(id, p.seconds)
		if n == 0 then
			return false, "Nenhum ovo incubando"
		end
		extra = { eggs = n }
	elseif kind == "IncomeBoost" then
		S.Actors.addBuff(id, "IncomeBoost", p.duration, p.mult)
	elseif kind == "TrainBoost" then
		S.Actors.addBuff(id, "TrainBoost", p.duration, p.mult)
	elseif kind == "CatchReach" then
		S.Actors.addBuff(id, "CatchReach", p.duration, p.radius)
	else
		return false, "Habilidade desconhecida"
	end

	st.cooldowns[ab.id] = now + ab.cd
	st.cooldowns._global = now + 1.5
	broadcast(id, ab, creature, extra)
	S.Tutorial.progress(id, "Ability")
	S.PlayerData.dirty(id)
	return true, ab.name
end

function Abilities.start()
	S.Net.on("UseAbility", function(player)
		local ok, msg = Abilities.use(player.UserId)
		Net.fire(player, "Effect", { kind = "AbilityResult", ok = ok, message = msg, cooldown = Abilities.cooldownLeft(player.UserId) })
	end)
end

return Abilities
