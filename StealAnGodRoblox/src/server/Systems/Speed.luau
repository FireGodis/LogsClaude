--[[
	Speed — treadmill training, walk speed application and treadmill purchases.

	Training is server-authoritative: an actor only gains Speed while standing on the belt of the
	treadmill IN THEIR OWN BASE and actively moving (players send a throttled TrainPing, bots are
	read directly). Gain per step = treadmill.perStep × trail mult × (2x pass) × (boost) × (ability).
	Real movement speed = log-scaled Speed, capped, minus carry penalty.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Formulas = require(Shared.Util.Formulas)
local NumberFormatter = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)

local Speed = {}
local S

function Speed.init(sys)
	S = sys
end

local function ownTreadmillBelt(id: number): BasePart?
	local m = S.Bases.modelOf(id)
	local tm = m and m.Visuals:FindFirstChild("Treadmill")
	return tm and tm:FindFirstChild("Belt") :: BasePart? or nil
end

function Speed.treadmillCFrame(id: number): CFrame?
	local belt = ownTreadmillBelt(id)
	return belt and belt.CFrame or nil
end

function Speed.isOnTreadmill(id: number): boolean
	local belt = ownTreadmillBelt(id)
	local pos = S.Actors.position(id)
	if not belt or not pos then
		return false
	end
	local rel = belt.CFrame:PointToObjectSpace(pos)
	return math.abs(rel.X) < belt.Size.X / 2 + 0.5 and math.abs(rel.Z) < belt.Size.Z / 2 + 0.5 and rel.Y > 0 and rel.Y < 7
end

local function isMoving(id: number): boolean
	local hum = S.Actors.humanoid(id)
	if not hum then
		return false
	end
	if S.Actors.isBot(id) then
		return hum.MoveDirection.Magnitude > 0.1
	end
	local st = S.Actors.state(id)
	return st ~= nil and os.clock() - st.lastTrainPing < 0.6
end

function Speed.trainingModifiers(id: number)
	local p = S.PlayerData.get(id)
	return {
		trainingPass = S.Monetization.has(id, "DoubleTraining"),
		trainingBoost = p ~= nil and S.Economy.boostActive(p, "training"),
		abilityMult = S.Actors.buff(id, "TrainBoost"),
	}
end

function Speed.gainPerStep(id: number): number
	local p = S.PlayerData.get(id)
	if not p then
		return 0
	end
	return Formulas.trainGain(p.treadmillTier, p.equippedTrail, Speed.trainingModifiers(id))
end

local function checkUnlock(id: number, before: number, after: number)
	local b0 = Formulas.unlockedBiome(before)
	local b1 = Formulas.unlockedBiome(after)
	if b1 > b0 then
		local p = S.PlayerData.get(id)
		p.stats.biomesUnlocked = math.max(p.stats.biomesUnlocked, b1)
		local biome = Formulas.biome(b1)
		local player = S.Actors.player(id)
		if player then
			Net.fire(player, "Notify", { kind = "Unlock", title = "NOVA REGIÃO DESBLOQUEADA!", text = biome.name })
			Net.fire(player, "Effect", { kind = "Unlock", biome = b1 })
		end
		S.Collection.checkAchievements(id)
		S.Tutorial.progress(id, "UnlockBiome")
		S.PlayerData.dirty(id)
	end
end

function Speed.addSpeed(id: number, amount: number)
	local p = S.PlayerData.get(id)
	if not p or amount <= 0 or amount ~= amount then
		return
	end
	local before = p.speed
	p.speed += amount
	checkUnlock(id, before, p.speed)
	S.PlayerData.dirtyLight(id)
end

function Speed.walkSpeedOf(id: number): number
	local p = S.PlayerData.get(id)
	local st = S.Actors.state(id)
	if not p or not st then
		return 16
	end
	if S.Actors.isStuck(id) then
		return 0
	end
	local carrySize = st.carry and st.carry.record.size or nil
	local relief = S.Actors.buff(id, "WeightRelief") or 0
	local mult = 1
	local burst = S.Actors.buff(id, "SpeedBurst")
	if burst then
		local carryingOnly = S.Actors.buff(id, "SpeedBurstCarryOnly")
		if not carryingOnly or st.carry then
			mult *= burst
		end
	end
	if not st.carry and Speed.isOnTreadmill(id) then
		return 16 -- treadmill running speed stays readable
	end
	return Formulas.walkSpeed(p.speed, carrySize, relief, mult)
end

function Speed.buyNext(id: number): (boolean, string?)
	local p = S.PlayerData.get(id)
	if not p then
		return false, "Sem dados"
	end
	local nextTier = p.treadmillTier + 1
	local def = Balance.treadmills[nextTier]
	if not def then
		return false, "Você já tem a melhor esteira!"
	end
	if not S.Economy.spend(id, def.price) then
		return false, "GOLD insuficiente"
	end
	p.treadmillTier = nextTier
	S.Bases.refreshVisuals(id)
	S.PlayerData.dirty(id)
	S.Tutorial.progress(id, "BuyTreadmill")
	return true, def.name .. " instalada! (+" .. NumberFormatter.format(def.perStep) .. " por passo)"
end

function Speed.start()
	S.Net.on("TrainPing", function(player, moving)
		local st = S.Actors.state(player.UserId)
		if st and moving == true then
			st.lastTrainPing = os.clock()
		end
	end)
	S.Net.handle("BuyTreadmill", function(player)
		return Speed.buyNext(player.UserId)
	end)

	-- training loop
	local stepTime = 1 / Balance.speed.stepsPerSecond
	task.spawn(function()
		while true do
			task.wait(stepTime)
			for id in S.Actors.all() do
				if S.PlayerData.get(id) and isMoving(id) and Speed.isOnTreadmill(id) and not S.Actors.isStuck(id) then
					local st = S.Actors.state(id)
					if st and not st.carry then
						Speed.addSpeed(id, Speed.gainPerStep(id))
						S.Tutorial.progress(id, "Train")
					end
				end
			end
		end
	end)

	-- walk speed loop
	task.spawn(function()
		while true do
			task.wait(0.2)
			for id in S.Actors.all() do
				local hum = S.Actors.humanoid(id)
				if hum and hum.Health > 0 then
					local ws = Speed.walkSpeedOf(id)
					if math.abs(hum.WalkSpeed - ws) > 0.05 then
						hum.WalkSpeed = ws
					end
					local stuck = S.Actors.isStuck(id)
					hum.UseJumpPower = false
					local jh = stuck and 0 or 7.2
					if hum.JumpHeight ~= jh then
						hum.JumpHeight = jh
					end
				end
			end
		end
	end)
end

return Speed
