--[[
	Economy — GOLD income, vault collection, spending and offline earnings.

	Income/s = Σ petIncome(pet) × globalMultiplier (VIP, 2x Money pass, Money boost, Ra-type ability),
	computed centrally once per second for every actor (players and bots). Income accumulates in the
	base vault; the owner collects it by stepping on the gold pad (Auto Collect pass skips that).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local Net = require(ReplicatedStorage.Shared.Util.Net)

local Economy = {}
local S
local incomeCache = {} -- [id] = number

function Economy.init(sys)
	S = sys
end

local function boostActive(profile, name: string): boolean
	local t = profile.boosts and profile.boosts[name]
	return t ~= nil and t > os.time()
end
Economy.boostActive = boostActive

function Economy.modifiers(id: number, includeTemporary: boolean?)
	local p = S.PlayerData.get(id)
	local temp = includeTemporary ~= false
	return {
		vip = S.Monetization.has(id, "VIP"),
		moneyPass = S.Monetization.has(id, "DoubleMoney"),
		moneyBoost = temp and p ~= nil and boostActive(p, "money"),
		abilityMult = temp and S.Actors.buff(id, "IncomeBoost") or nil,
	}
end

function Economy.computeIncome(id: number, includeTemporary: boolean?): number
	local p = S.PlayerData.get(id)
	if not p then
		return 0
	end
	return Formulas.totalIncome(p.pets, Economy.modifiers(id, includeTemporary))
end

function Economy.incomeOf(id: number): number
	return incomeCache[id] or Economy.computeIncome(id)
end

function Economy.addGold(id: number, amount: number, _reason: string?)
	local p = S.PlayerData.get(id)
	if not p or amount ~= amount or amount <= 0 or amount == math.huge then
		return
	end
	p.gold += amount
	p.totalEarned += amount
	S.PlayerData.dirtyLight(id)
	S.Collection.checkAchievements(id)
end

function Economy.canAfford(id: number, price: number): boolean
	local p = S.PlayerData.get(id)
	return p ~= nil and p.gold >= price
end

function Economy.spend(id: number, price: number): boolean
	local p = S.PlayerData.get(id)
	if not p or price ~= price or price < 0 or p.gold < price then
		return false
	end
	p.gold -= price
	S.PlayerData.dirtyLight(id)
	return true
end

function Economy.collectVault(id: number): number
	local p = S.PlayerData.get(id)
	if not p or p.vault < 1 then
		return 0
	end
	local amount = math.floor(p.vault)
	p.vault -= amount
	p.gold += amount
	S.PlayerData.dirtyLight(id)
	local player = S.Actors.player(id)
	if player then
		Net.fire(player, "Effect", { kind = "Collect", amount = amount })
	end
	S.Tutorial.progress(id, "Collect")
	return amount
end

-- Called once when a profile loads; returns the gold granted.
function Economy.applyOffline(id: number, secondsAway: number): number
	if secondsAway < 60 then
		return 0
	end
	local income = Economy.computeIncome(id, false)
	local amount = Formulas.offlineEarnings(income, secondsAway)
	if amount > 0 then
		local p = S.PlayerData.get(id)
		p.gold += amount
		p.totalEarned += amount
	end
	return amount
end

-- Seconds-of-income helper used by products and rewards.
function Economy.incomeSeconds(id: number, seconds: number, minimum: number): number
	return math.max(minimum, math.floor(Economy.computeIncome(id, false) * seconds))
end

function Economy.start()
	S.Actors.Removed:Connect(function(id)
		incomeCache[id] = nil
	end)
	task.spawn(function()
		while true do
			local dt = task.wait(1)
			for id in S.Actors.all() do
				local p = S.PlayerData.get(id)
				if p then
					local income = Economy.computeIncome(id)
					incomeCache[id] = income
					local gained = income * dt
					if gained > 0 then
						if S.Monetization.has(id, "AutoCollect") then
							p.gold += gained
						else
							p.vault += gained
						end
						p.totalEarned += gained
					end
					S.PlayerData.dirtyLight(id)
					S.Bases.updateVaultLabel(id)
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			for id in S.Actors.all() do
				S.Collection.checkAchievements(id)
			end
		end
	end)
end

return Economy
