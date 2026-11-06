--[[
	Theft — stealing incubating eggs from other bases, with anti-frustration protection.

	Rules
	  • only eggs still incubating can be stolen; hatched pets never
	  • the thief must physically carry the egg home; ownership changes ONLY on deposit
	  • the owner can catch the thief (get within catch radius) → the egg returns home
	  • if the owner leaves while the egg is in transit, the egg stays with the owner (no dupes)
	  • protection: new players (first 10 min of play), Base Shield product, and 3 min of
	    protection after being robbed 2 times within 5 minutes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Net = require(Shared.Util.Net)

local Theft = {}
local S

local beingStolen = {} -- ["owner:slot"] = thiefId
local robbedLog = {} -- [ownerId] = {times}
local recoveryUntil = {} -- [ownerId] = os.time()
local alarmToken = {}

local P = Balance.protection

function Theft.init(sys)
	S = sys
end

local function key(owner: number, slot: string)
	return tostring(owner) .. ":" .. slot
end

function Theft.isBeingStolen(owner: number, slot: string): boolean
	return beingStolen[key(owner, tostring(slot))] ~= nil
end

function Theft.protectionReason(owner: number): string?
	local p = S.PlayerData.get(owner)
	if not p then
		return nil
	end
	if S.Economy.boostActive(p, "shield") then
		return "Escudo"
	end
	if (recoveryUntil[owner] or 0) > os.time() then
		return "Recuperação"
	end
	-- newcomer protection ends after 10 min of play or as soon as the newcomer completes a raid
	if not S.Actors.isBot(owner) and p.playtime < P.newPlayerSeconds and (p.stats.raids or 0) == 0 then
		return "Novato"
	end
	return nil
end

local function setAlarm(owner: number)
	local m = S.Bases.modelOf(owner)
	if not m then
		return
	end
	local token = {}
	alarmToken[owner] = token
	m:SetAttribute("Alarm", true)
	task.delay(6, function()
		if alarmToken[owner] == token and m.Parent then
			m:SetAttribute("Alarm", false)
		end
	end)
end

function Theft.tryStealFromBase(thief: number, owner: number, slot: any): (boolean, string?)
	slot = tostring(slot)
	local thiefPlayer = S.Actors.player(thief)
	local function deny(msg)
		if thiefPlayer then
			Net.fire(thiefPlayer, "Notify", { kind = "Warning", title = "Não foi possível roubar", text = msg })
		end
		return false, msg
	end
	if thief == owner then
		return false, "Esse ovo é seu"
	end
	local op = S.PlayerData.get(owner)
	local tp = S.PlayerData.get(thief)
	local st = S.Actors.state(thief)
	if not op or not tp or not st then
		return false, "indisponível"
	end
	local record = op.eggs[slot]
	if not record or beingStolen[key(owner, slot)] then
		return deny("Esse ovo não está disponível.")
	end
	if record.ready then
		return deny("Esse ovo já está chocando!")
	end
	if st.carry then
		return deny("Você já está carregando um ovo.")
	end
	if not S.Actors.alive(thief) or S.Actors.isStuck(thief) or S.Security.isSuspect(thief) then
		return deny("Você não pode roubar agora.")
	end
	local reason = Theft.protectionReason(owner)
	if reason then
		return deny("Base protegida (" .. reason .. ").")
	end
	local cf = S.Bases.slotCFrame(owner, tonumber(slot) :: number)
	if not cf or not S.Security.within(thief, cf.Position, 11) then
		return deny("Muito longe.")
	end
	beingStolen[key(owner, slot)] = thief
	local remaining = math.max(5, (record.hatchAt or os.time()) - os.time())
	S.Eggs.setCarry(thief, record, { kind = "base", owner = owner, slot = slot, remaining = remaining })
	S.Eggs.renderBaseEggs(owner)
	S.PlayerData.dirty(owner)
	setAlarm(owner)
	local ownerPlayer = S.Actors.player(owner)
	if ownerPlayer then
		Net.fire(ownerPlayer, "Notify", { kind = "Alarm", title = "SEU OVO ESTÁ SENDO ROUBADO!", text = S.Actors.name(thief) .. " pegou um ovo da sua base. Alcance-o para recuperar!" })
		Net.fire(ownerPlayer, "Effect", { kind = "Alarm" })
	end
	if thiefPlayer then
		Net.fire(thiefPlayer, "Notify", { kind = "Egg", title = "VOCÊ ROUBOU UM OVO!", text = "Fuja para a sua base antes que " .. S.Actors.name(owner) .. " te alcance!" })
	end
	S.BotBrain.onBaseRaided(owner, thief)
	return true
end

-- Thief deposited in their own base: ownership changes now.
function Theft.completeRaid(thief: number, carry)
	local origin = carry.origin
	local k = key(origin.owner, origin.slot)
	beingStolen[k] = nil
	local op = S.PlayerData.get(origin.owner)
	if op and op.eggs[origin.slot] == carry.record then
		op.eggs[origin.slot] = nil
		op.stats.robbed = (op.stats.robbed or 0) + 1
		S.Eggs.renderBaseEggs(origin.owner)
		S.PlayerData.dirty(origin.owner)
		-- anti-frustration
		local log = robbedLog[origin.owner] or {}
		local now = os.time()
		table.insert(log, now)
		while #log > 0 and now - log[1] > P.robbedWindowSeconds do
			table.remove(log, 1)
		end
		robbedLog[origin.owner] = log
		if #log >= P.robbedLimit then
			recoveryUntil[origin.owner] = now + P.protectSeconds
			robbedLog[origin.owner] = {}
			S.Bases.refreshVisuals(origin.owner)
			local ownerPlayer = S.Actors.player(origin.owner)
			if ownerPlayer then
				Net.fire(ownerPlayer, "Notify", { kind = "Info", title = "Proteção ativada", text = "Sua base está protegida contra roubos por 3 minutos." })
			end
		end
		local ownerPlayer = S.Actors.player(origin.owner)
		if ownerPlayer then
			Net.fire(ownerPlayer, "Notify", { kind = "Alarm", title = "Ovo perdido", text = S.Actors.name(thief) .. " levou seu ovo para a base dele." })
		end
	end
	local tp = S.PlayerData.get(thief)
	if tp then
		tp.stats.raids = (tp.stats.raids or 0) + 1
	end
	S.Collection.checkAchievements(thief)
end

-- Egg goes back to the owner's incubator (caught / dropped / thief left).
function Theft.returnEgg(carry)
	local origin = carry.origin
	beingStolen[key(origin.owner, origin.slot)] = nil
	if S.PlayerData.get(origin.owner) then
		S.Eggs.renderBaseEggs(origin.owner)
		S.PlayerData.dirty(origin.owner)
	end
end

function Theft.start()
	-- owner leaving: invalidate eggs in transit (egg stays saved with the owner)
	S.Actors.Removed:Connect(function(owner)
		for id in S.Actors.all() do
			local st = S.Actors.state(id)
			if st and st.carry and st.carry.origin.kind == "base" and st.carry.origin.owner == owner then
				S.Eggs.dropCarry(id, "caught")
				local p = S.Actors.player(id)
				if p then
					Net.fire(p, "Notify", { kind = "Warning", title = "O ovo sumiu", text = "O dono saiu do servidor e o ovo voltou para ele." })
				end
			end
		end
		for k in beingStolen do
			if string.sub(k, 1, #tostring(owner) + 1) == tostring(owner) .. ":" then
				beingStolen[k] = nil
			end
		end
		robbedLog[owner] = nil
		recoveryUntil[owner] = nil
	end)

	-- catching thieves
	task.spawn(function()
		while true do
			task.wait(0.2)
			for thief in S.Actors.all() do
				local st = S.Actors.state(thief)
				local carry = st and st.carry
				if carry and carry.origin.kind == "base" then
					local owner = carry.origin.owner
					local ownerPos = S.Actors.position(owner)
					local thiefPos = S.Actors.position(thief)
					if ownerPos and thiefPos and S.Actors.alive(owner) then
						local radius = S.Actors.buff(owner, "CatchReach") or P.catchRadius
						if (ownerPos - thiefPos).Magnitude <= radius then
							S.Eggs.dropCarry(thief, "caught")
							local op = S.PlayerData.get(owner)
							if op then
								op.stats.defenses = (op.stats.defenses or 0) + 1
							end
							S.Abilities.knockback(thief, (thiefPos - ownerPos).Unit * 60 + Vector3.new(0, 30, 0))
							local ownerPlayer = S.Actors.player(owner)
							if ownerPlayer then
								Net.fire(ownerPlayer, "Notify", { kind = "Reward", title = "DEFESA BEM-SUCEDIDA!", text = "Você recuperou seu ovo!" })
							end
							local thiefPlayer = S.Actors.player(thief)
							if thiefPlayer then
								Net.fire(thiefPlayer, "Notify", { kind = "Alarm", title = "Pego no flagra!", text = S.Actors.name(owner) .. " recuperou o ovo." })
							end
							S.Collection.checkAchievements(owner)
						end
					end
				end
			end
		end
	end)

	-- refresh protection flags on bases periodically (newcomer timer / recovery expiry)
	task.spawn(function()
		while true do
			task.wait(5)
			for id in S.Actors.all() do
				local m = S.Bases.modelOf(id)
				if m then
					local prot = Theft.protectionReason(id) ~= nil
					if m:GetAttribute("Protected") ~= prot then
						m:SetAttribute("Protected", prot)
						S.PlayerData.dirty(id)
					end
				end
			end
		end
	end)
end

return Theft
