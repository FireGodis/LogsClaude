--[[
	BotBrain — utility-based decision making for simulated participants.

	Each bot runs one lightweight coroutine that alternates THINK (score every option with its
	personality weights + jitter + skill-based mistakes) and ACT (a physical action executed with
	BotNavigator and the SAME server APIs players use: Eggs.tryPickup, Speed training, Bases.upgrade,
	Theft.tryStealFromBase, Abilities.use, Traps.place...). No money is ever created for bots.

	States: Idle, Thinking, Training, ChoosingBiome, Exploring, ObservingGuardian, StealingEgg,
	CarryingEgg, ReturningToBase, DepositingEgg, Hatching, CollectingMoney, PurchasingUpgrade,
	ExpandingBase, SearchingRareEgg, RaidingPlayerBase, DefendingBase, UsingAbility, Recovering.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)

local BotBrain = {}
local S
local bots = {} -- [id] = bot record

local ESCAPE_KINDS = { Shockwave = true, Frost = true, Decoy = true, SpeedBurst = true, Dash = true, GuardShield = true, EggShield = true, WeightRelief = true, Leap = true }

function BotBrain.init(sys)
	S = sys
end

local function setState(bot, state: string)
	bot.state = state
	local model = S.Actors.character(bot.id)
	if model then
		model:SetAttribute("BotState", state) -- QA/debug only (not displayed to players)
	end
end

local function wait(bot, seconds: number)
	local t = os.clock() + seconds
	while os.clock() < t do
		if bot.removed then
			return false
		end
		task.wait(0.25)
	end
	return true
end

local function profile(bot)
	return S.PlayerData.get(bot.id)
end

local function interrupted(bot): boolean
	if bot.removed then
		return true
	end
	local st = S.Actors.state(bot.id)
	if bot.defendTarget and not (st and st.carry) then
		return true
	end
	return false
end

local function tryAbility(bot, kinds)
	local ab = S.Abilities.definitionFor(bot.id)
	if not ab or not kinds[ab.kind] then
		return false
	end
	if S.Abilities.cooldownLeft(bot.id) > 0 or bot.rng:NextNumber() > bot.skill then
		return false
	end
	local prev = bot.state
	setState(bot, "UsingAbility")
	local ok = S.Abilities.use(bot.id)
	setState(bot, prev)
	return ok
end

-- Abort predicate used while carrying: also triggers escape abilities when a guardian is close.
local function carryWatch(bot)
	return function()
		if bot.removed then
			return true
		end
		local pos = S.Actors.position(bot.id)
		if pos then
			local d = S.Guardians.threatAt(pos)
			if d < 14 then
				tryAbility(bot, ESCAPE_KINDS)
			end
		end
		local st = S.Actors.state(bot.id)
		return not (st and st.carry)
	end
end

local function basePoint(bot, offset: Vector3): Vector3?
	local cf = S.Bases.anchorCFrame(bot.id)
	return cf and (cf * CFrame.new(offset)).Position or nil
end

-- ===================== ACTIONS =====================
local Actions = {}

function Actions.ReturnToBase(bot)
	setState(bot, "ReturningToBase")
	local goal = basePoint(bot, Vector3.new(bot.rng:NextNumber(-10, 10), 3, -14))
	if not goal then
		return
	end
	S.BotNavigator.moveTo(bot.id, goal, { abort = carryWatch(bot), tolerance = 4 })
	local st = S.Actors.state(bot.id)
	if st and st.carry and S.Bases.isInOwnBase(bot.id) then
		setState(bot, "DepositingEgg")
		wait(bot, 1.2) -- deposit happens via the Eggs loop; base full -> keep it
		if st.carry then
			Actions.ManagePets(bot)
		end
	elseif not (st and st.carry) then
		-- dropped the egg on the way: maybe recover it
		setState(bot, "Recovering")
		local pos = S.Actors.position(bot.id)
		if pos and bot.rng:NextNumber() < bot.P.risk + 0.2 then
			for eid, e in S.Eggs.worldEggs() do
				if e.kind == "ground" and (e.position - pos).Magnitude < 30 then
					local d = S.Guardians.threatAt(e.position)
					if d > 12 then
						if S.BotNavigator.moveTo(bot.id, e.position, { tolerance = 4, timeout = 8 }) then
							wait(bot, 0.5)
							if S.Eggs.tryPickup(bot.id, eid) then
								Actions.ReturnToBase(bot)
							end
						end
					end
					break
				end
			end
		end
	end
end

local function chooseBiome(bot): number
	local p = profile(bot)
	local unlocked = Formulas.unlockedBiome(p.speed)
	local key = bot.personality
	if key == "Beginner" then
		return math.max(1, unlocked - bot.rng:NextInteger(0, 1))
	elseif key == "Explorer" then
		return bot.rng:NextInteger(math.max(1, unlocked - 2), unlocked)
	elseif key == "Collector" then
		for b = unlocked, math.max(1, unlocked - 3), -1 do
			for slot = 1, 4 do
				if not p.index[Creatures.ByBiome[b][slot].id] then
					return b
				end
			end
		end
	end
	return unlocked
end

function Actions.StealEgg(bot)
	setState(bot, "ChoosingBiome")
	local biome = chooseBiome(bot)
	local candidates = {}
	for _, nest in S.Eggs.nests() do
		if nest.biome == biome and nest.egg then
			table.insert(candidates, nest)
		end
	end
	if #candidates == 0 then
		setState(bot, "Exploring")
		wait(bot, bot.rng:NextNumber(1, 3))
		return
	end
	local nest = candidates[bot.rng:NextInteger(1, #candidates)]
	local nestPos = nest.cframe.Position
	setState(bot, "Exploring")
	local staging = Vector3.new(math.sign(nestPos.X) * 12, 1, nestPos.Z + bot.rng:NextNumber(-8, 8))
	if not S.BotNavigator.moveTo(bot.id, staging, { abort = function()
		return interrupted(bot)
	end }) then
		return
	end
	-- watch the guardian and wait for a window (personality + skill)
	setState(bot, "ObservingGuardian")
	local patience = 4 + (1 - bot.P.risk) * 10
	local deadline = os.clock() + patience
	while os.clock() < deadline do
		if interrupted(bot) or not nest.egg then
			return
		end
		local d = S.Guardians.threatAt(nestPos)
		if d > 24 or bot.rng:NextNumber() < bot.P.risk * 0.15 then
			break
		end
		wait(bot, 0.5)
	end
	local eggId = nest.egg
	local e = eggId and S.Eggs.worldEggs()[eggId]
	if not e then
		return
	end
	setState(bot, "StealingEgg")
	if not S.BotNavigator.moveTo(bot.id, e.position, { tolerance = 4, timeout = 12, abort = function()
		return interrupted(bot) or S.Eggs.worldEggs()[eggId] == nil
	end }) then
		return
	end
	wait(bot, bot.rng:NextNumber(0.6, 1.0)) -- "grab" time, same as the player hold prompt
	if S.Eggs.tryPickup(bot.id, eggId) then
		setState(bot, "CarryingEgg")
		Actions.ReturnToBase(bot)
	end
end

function Actions.SearchingRareEgg(bot)
	local sp = S.Events.special
	if not sp then
		bot.specialTarget = nil
		return
	end
	setState(bot, "SearchingRareEgg")
	local eggId = sp.eggId
	if not S.BotNavigator.moveTo(bot.id, sp.position, { tolerance = 4, abort = function()
		return interrupted(bot) or S.Eggs.worldEggs()[eggId] == nil
	end }) then
		bot.specialTarget = nil
		return
	end
	wait(bot, 0.6)
	bot.specialTarget = nil
	if S.Eggs.tryPickup(bot.id, eggId) then
		Actions.ReturnToBase(bot)
	end
end

function Actions.Training(bot)
	setState(bot, "Training")
	local cf = S.Speed.treadmillCFrame(bot.id)
	if not cf then
		return
	end
	if not S.BotNavigator.moveTo(bot.id, (cf * CFrame.new(0, 3, 0)).Position, { tolerance = 2.5, abort = function()
		return interrupted(bot)
	end }) then
		return
	end
	local duration = bot.rng:NextNumber(20, 70) * bot.P.train
	local stopAt = os.clock() + duration
	local hum = S.Actors.humanoid(bot.id)
	while os.clock() < stopAt and hum do
		if interrupted(bot) or bot.specialTarget or bot.leaving then
			break
		end
		local belt = S.Speed.treadmillCFrame(bot.id)
		if not belt then
			break
		end
		hum:MoveTo((belt * CFrame.new(0, 3, -5)).Position)
		if bot.rng:NextNumber() < 0.05 then
			tryAbility(bot, { TrainBoost = true })
		end
		task.wait(0.4)
		if not S.Speed.isOnTreadmill(bot.id) then
			S.BotNavigator.moveTo(bot.id, (belt * CFrame.new(0, 3, 0)).Position, { tolerance = 2.5, timeout = 6 })
		end
	end
end

function Actions.CollectingMoney(bot)
	setState(bot, "CollectingMoney")
	local m = S.Bases.modelOf(bot.id)
	local pad = m and m:FindFirstChild("CollectPad")
	if pad then
		S.BotNavigator.moveTo(bot.id, pad.Position + Vector3.new(0, 3, 0), { tolerance = 2, abort = function()
			return interrupted(bot)
		end })
		wait(bot, 0.8)
	end
	tryAbility(bot, { IncomeBoost = true })
end

local function purchaseOptions(bot)
	local p = profile(bot)
	local opts = {}
	local t = Balance.treadmills[p.treadmillTier + 1]
	if t then
		table.insert(opts, { kind = "Treadmill", price = t.price, kiosk = "Upgrades" })
	end
	local trail = S.Trails.nextTrail(bot.id)
	if trail then
		table.insert(opts, { kind = "Trail", price = trail.price, id = trail.id, kiosk = "Trails" })
	end
	local b = Balance.baseLevels[p.baseLevel + 1]
	if b then
		table.insert(opts, { kind = "Base", price = b.price, kiosk = "Upgrades" })
	end
	return opts
end

local PRIORITY = {
	Investor = { "Base", "Treadmill", "Trail" },
	Competitive = { "Treadmill", "Trail", "Base" },
	Collector = { "Base", "Trail", "Treadmill" },
	Beginner = { "Treadmill", "Base", "Trail" },
	Explorer = { "Trail", "Treadmill", "Base" },
}

local function affordablePurchase(bot)
	local p = profile(bot)
	local opts = purchaseOptions(bot)
	if bot.personality == "Beginner" then
		table.sort(opts, function(a, b)
			return a.price < b.price
		end)
		for _, o in opts do
			if p.gold >= o.price then
				return o
			end
		end
		return nil
	end
	for _, kind in PRIORITY[bot.personality] or PRIORITY.Explorer do
		for _, o in opts do
			if o.kind == kind and p.gold >= o.price then
				return o
			end
		end
	end
	return nil
end

function Actions.PurchasingUpgrade(bot)
	local o = affordablePurchase(bot)
	if not o then
		return
	end
	setState(bot, o.kind == "Base" and "ExpandingBase" or "PurchasingUpgrade")
	local kiosk = Workspace.Map.ShopPlaza:FindFirstChild("Kiosk_" .. o.kiosk)
	if kiosk and kiosk.PrimaryPart then
		local goal = (kiosk.PrimaryPart.CFrame * CFrame.new(0, 2, -6)).Position
		S.BotNavigator.moveTo(bot.id, goal, { tolerance = 4, abort = function()
			return interrupted(bot)
		end })
		wait(bot, bot.rng:NextNumber(1.5, 3.5)) -- browsing the shop
	end
	if o.kind == "Treadmill" then
		S.Speed.buyNext(bot.id)
	elseif o.kind == "Trail" then
		S.Trails.buy(bot.id, o.id)
	elseif o.kind == "Base" then
		S.Bases.upgrade(bot.id)
		local goal = basePoint(bot, Vector3.new(0, 3, -10))
		if goal then
			S.BotNavigator.moveTo(bot.id, goal, { tolerance = 5 }) -- go admire the new base
		end
	end
end

local function raidTarget(bot)
	local best = nil
	for id in S.Actors.all() do
		if id ~= bot.id and not S.Theft.protectionReason(id) then
			local p = S.PlayerData.get(id)
			local basePos = S.Bases.anchorCFrame(id)
			local ownerPos = S.Actors.position(id)
			if p and basePos and (not ownerPos or (ownerPos - basePos.Position).Magnitude > 70) then
				for slot, record in p.eggs do
					if not record.ready and not S.Theft.isBeingStolen(id, slot) then
						-- prefer other simulated participants; humans only for the bolder personalities
						local weight = S.Actors.isBot(id) and 1 or bot.P.raid * 0.5
						if bot.rng:NextNumber() < weight then
							best = { owner = id, slot = slot }
						end
						break
					end
				end
			end
		end
		if best then
			break
		end
	end
	return best
end

function Actions.RaidingPlayerBase(bot)
	local target = raidTarget(bot)
	bot.lastRaid = os.clock()
	if not target then
		return
	end
	setState(bot, "RaidingPlayerBase")
	local cf = S.Bases.slotCFrame(target.owner, tonumber(target.slot) :: number)
	if not cf then
		return
	end
	if not S.BotNavigator.moveTo(bot.id, cf.Position + Vector3.new(0, 3, 0), { tolerance = 5, abort = function()
		return interrupted(bot) or S.Theft.protectionReason(target.owner) ~= nil
	end }) then
		return
	end
	wait(bot, 1.2) -- same hold time as the player's prompt
	if S.Theft.tryStealFromBase(bot.id, target.owner, target.slot) then
		Actions.ReturnToBase(bot)
	end
end

function Actions.DefendingBase(bot)
	local thief = bot.defendTarget
	bot.defendTarget = nil
	if not thief then
		return
	end
	setState(bot, "DefendingBase")
	local hum = S.Actors.humanoid(bot.id)
	local untilT = os.clock() + 20
	tryAbility(bot, { SpeedBurst = true, Dash = true, CatchReach = true })
	while os.clock() < untilT and hum and not bot.removed do
		local st = S.Actors.state(thief)
		if not st or not st.carry or st.carry.origin.owner ~= bot.id then
			break
		end
		local pos = S.Actors.position(thief)
		if not pos then
			break
		end
		hum:MoveTo(pos)
		task.wait(0.25)
	end
end

function Actions.PlaceTrap(bot)
	setState(bot, "Idle")
	local goal = basePoint(bot, Vector3.new(bot.rng:NextNumber(-12, 12), 3, -28))
	if goal and S.BotNavigator.moveTo(bot.id, goal, { tolerance = 3 }) then
		S.Traps.place(bot.id)
		bot.lastTrap = os.clock()
	end
end

function Actions.ManagePets(bot)
	local p = profile(bot)
	-- equip the best companion
	local best = S.Pets.best(bot.id)
	if best and p.equippedPet ~= best.uid and bot.rng:NextNumber() < bot.skill then
		S.Pets.equip(bot.id, best.uid)
	end
	-- make room when full and something is waiting
	local hasReady = false
	for _, e in p.eggs do
		if e.ready then
			hasReady = true
		end
	end
	if (#p.pets >= S.Pets.capacity(bot.id)) and (hasReady or S.Eggs.isCarrying(bot.id)) then
		local worst, wi = nil, math.huge
		for _, pet in p.pets do
			local inc = Formulas.petIncome(pet)
			if inc < wi and pet.uid ~= p.equippedPet then
				worst, wi = pet, inc
			end
		end
		if worst then
			S.Pets.sell(bot.id, worst.uid)
		end
	end
	tryAbility(bot, { HatchBoost = true, IncomeBoost = true })
end

function Actions.Idle(bot)
	setState(bot, "Idle")
	local p = profile(bot)
	local now = os.time()
	local soon = false
	for _, e in p.eggs do
		if e.hatchAt and e.hatchAt - now < 12 then
			soon = true
		end
	end
	if soon then
		setState(bot, "Hatching") -- go watch the egg hatch
		local goal = basePoint(bot, Vector3.new(bot.rng:NextNumber(-12, 12), 3, -10))
		if goal then
			S.BotNavigator.moveTo(bot.id, goal, { tolerance = 4 })
		end
		wait(bot, bot.rng:NextNumber(4, 10))
		return
	end
	local n = math.max(1, math.min(#p.pets, S.Pets.capacity(bot.id)))
	local cf = S.Bases.petCFrame(bot.id, bot.rng:NextInteger(1, n))
	if cf then
		S.BotNavigator.moveTo(bot.id, (cf * CFrame.new(0, 3, -4)).Position, { tolerance = 4, timeout = 15 })
	end
	wait(bot, bot.rng:NextNumber(2, 7) * bot.P.idle)
end

-- ===================== DECISION =====================
local function decide(bot): string
	local p = profile(bot)
	local st = S.Actors.state(bot.id)
	if st and st.carry then
		return "ReturnToBase"
	end
	if bot.defendTarget then
		return "DefendingBase"
	end
	local P = bot.P
	local rng = bot.rng
	local scores = {}
	local income = S.Economy.incomeOf(bot.id)
	local unlocked = Formulas.unlockedBiome(p.speed)

	if bot.specialTarget and S.Events.special and S.Biomes.canEnter(bot.id, S.Events.special.biome) then
		scores.SearchingRareEgg = P.special * 6
	end
	if not S.Monetization.has(bot.id, "AutoCollect") and p.vault >= math.max(40, income * 25) then
		scores.CollectingMoney = P.collect * 2.5
	end
	if affordablePurchase(bot) then
		scores.PurchasingUpgrade = P.upgrade * 4
	end
	local canHold = S.Eggs.freeSlot(bot.id) ~= nil
	if canHold then
		scores.StealEgg = P.steal * (#p.pets < 3 and 5 or 3)
	end
	local nextReq = Balance.biomes[unlocked + 1]
	local trainNeed = nextReq and 1.5 or 0.4
	if not affordablePurchase(bot) and nextReq then
		trainNeed += 1
	end
	scores.Training = P.train * trainNeed * (canHold and 0.8 or 1.6)
	if os.clock() - (bot.lastRaid or 0) > 90 then
		scores.RaidingPlayerBase = P.raid * 1.1
	end
	local incubating = next(p.eggs) ~= nil
	if incubating and S.Traps.activeCount(bot.id) < 2 and os.clock() - (bot.lastTrap or 0) > 120 then
		scores.PlaceTrap = (P.upgrade + P.collect) * 0.35
	end
	scores.ManagePets = (#p.pets >= S.Pets.capacity(bot.id)) and 3 or 0.4
	scores.Idle = P.idle * 0.7

	-- imperfect decisions: sometimes pick something random
	if rng:NextNumber() < (1 - bot.skill) * 0.3 then
		local keys = {}
		for k, v in scores do
			if v > 0 then
				table.insert(keys, k)
			end
		end
		return keys[rng:NextInteger(1, #keys)]
	end
	local best, bestScore = "Idle", -1
	for k, v in scores do
		local s = v * rng:NextNumber(0.6, 1.4)
		if s > bestScore then
			best, bestScore = k, s
		end
	end
	return best
end

local function loop(bot)
	while not bot.removed do
		if not S.Actors.alive(bot.id) then
			task.wait(1)
		else
			local st = S.Actors.state(bot.id)
			if bot.leaving and not (st and st.carry) then
				bot.readyToLeave = true
				setState(bot, "Idle")
				task.wait(1)
			else
				setState(bot, "Thinking")
				wait(bot, bot.rng:NextNumber(0.4, 1.6) * bot.P.idle)
				if bot.removed then
					break
				end
				local action = decide(bot)
				if bot.leaving then
					action = (st and st.carry) and "ReturnToBase" or "Idle"
				end
				local fn = Actions[action]
				if fn then
					local ok, err = pcall(fn, bot)
					if not ok then
						warn("[BotBrain]", bot.name, action, err)
						task.wait(1)
					end
				end
				if bot.rng:NextNumber() < 0.25 then
					pcall(Actions.ManagePets, bot)
				end
			end
		end
	end
end

-- ===================== PUBLIC =====================
function BotBrain.add(bot)
	bot.P = GameConfig.BotPersonalities[bot.personality]
	bot.skill = math.clamp(bot.P.skill + bot.rng:NextNumber(-0.12, 0.12), 0.3, 0.97)
	bots[bot.id] = bot
	task.spawn(loop, bot)
end

function BotBrain.remove(id: number)
	local bot = bots[id]
	if bot then
		bot.removed = true
		bots[id] = nil
	end
end

function BotBrain.get(id: number)
	return bots[id]
end

function BotBrain.all()
	return bots
end

function BotBrain.onBaseRaided(owner: number, thief: number)
	local bot = bots[owner]
	if not bot then
		return
	end
	local ownerPos = S.Actors.position(owner)
	local thiefPos = S.Actors.position(thief)
	-- reaction depends on distance and skill (they do not always notice)
	if ownerPos and thiefPos and (ownerPos - thiefPos).Magnitude < 160 and bot.rng:NextNumber() < 0.4 + bot.skill * 0.5 then
		bot.defendTarget = thief
	end
end

function BotBrain.onSpecialEgg(special)
	for _, bot in bots do
		if S.Biomes.canEnter(bot.id, special.biome) and bot.rng:NextNumber() < 0.35 * bot.P.special then
			bot.specialTarget = special
		end
	end
end

function BotBrain.start() end

return BotBrain
