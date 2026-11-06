--[[
	PlayerData — persistent profiles with session locking, retries, autosave, BindToClose,
	schema versioning/migration and offline progression.

	Profiles live in memory during the session; DataStore is written on autosave (every 90s),
	on leave and on shutdown — never every second. UpdateAsync is used everywhere so concurrent
	servers can't overwrite each other (session lock = {jobId, time}).

	Bots get an in-memory profile with the SAME shape (never saved).
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Formulas = require(Shared.Util.Formulas)
local Signal = require(Shared.Util.Signal)
local Net = require(Shared.Util.Net)

local PlayerData = {}
PlayerData.Loaded = Signal.new() -- (id, profile, info{isNew, secondsAway})
PlayerData.Releasing = Signal.new() -- (id, profile) fired before final save

local S
local STORE_NAME = "SAG_Profiles_v1"
local SCHEMA_VERSION = 2
local AUTOSAVE_SECONDS = 90
local LOCK_STALE_SECONDS = 120

local store: DataStore? = nil
local profiles = {} -- [id] = profile
local saveable = {} -- [id] = true when backed by DataStore
local dirty = {} -- [id] = true -> push State
local loading = {} -- [userId] = true

-- ===================== TEMPLATE / MIGRATION =====================
local function template()
	return {
		version = SCHEMA_VERSION,
		gold = Balance.economy.startingGold,
		vault = 0,
		speed = 0,
		totalEarned = 0,
		treadmillTier = 1,
		trailsOwned = {},
		equippedTrail = nil,
		baseLevel = 1,
		eggs = {}, -- ["slot"] = egg record
		pets = {}, -- array of {uid, species, size, mutation, tier, at}
		equippedPet = nil,
		index = {}, -- [species] = {s = {Size=true}, m = {Mutation=true}, n = count}
		claimed = {}, -- index milestone ids
		achievements = {},
		stats = { eggsStolen = 0, hatched = 0, raids = 0, defenses = 0, divinePets = 0, discovered = 0, biomesUnlocked = 1,
			greekComplete = 0, norseComplete = 0, egyptianComplete = 0, robbed = 0 },
		settings = { music = true, sfx = true, vfx = "High", shake = true },
		boosts = {}, -- [name] = expiry os.time()
		purchases = {}, -- recent PurchaseIds (idempotency)
		keys = 0, -- free Divine Reliquary keys
		title = nil,
		tutorial = 1,
		tutDone = {},
		firstJoin = os.time(),
		lastSeen = os.time(),
		playtime = 0,
		lastDaily = 0,
		lastVipDaily = 0,
	}
end

local MIGRATIONS = {
	-- [fromVersion] = function(data) ... end
	[1] = function(data)
		data.keys = data.keys or 0
		data.lastVipDaily = data.lastVipDaily or 0
		data.version = 2
	end,
}

local function reconcile(data)
	local t = template()
	for k, v in t do
		if data[k] == nil then
			data[k] = v
		elseif typeof(v) == "table" and typeof(data[k]) == "table" and (k == "stats" or k == "settings") then
			for k2, v2 in v do
				if data[k][k2] == nil then
					data[k][k2] = v2
				end
			end
		end
	end
	return data
end

local function migrate(data)
	local guard = 0
	while (data.version or 1) < SCHEMA_VERSION and guard < 20 do
		local fn = MIGRATIONS[data.version or 1]
		if not fn then
			data.version = SCHEMA_VERSION
			break
		end
		fn(data)
		guard += 1
	end
	return reconcile(data)
end

-- ===================== DATASTORE IO =====================
local function retry(fn, attempts: number?)
	local tries = attempts or 5
	local delay = 1
	local lastErr
	for i = 1, tries do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		if i < tries then
			task.wait(delay)
			delay = math.min(delay * 2, 16)
		end
	end
	return false, lastErr
end

local function keyFor(userId: number)
	return "u_" .. userId
end

local function loadProfile(userId: number)
	if not store then
		return nil, "nostore"
	end
	local jobId = game.JobId ~= "" and game.JobId or "studio"
	for attempt = 1, 6 do
		local lockedByOther = false
		local ok, result = retry(function()
			return (store :: DataStore):UpdateAsync(keyFor(userId), function(old)
				old = old or {}
				local lock = old.lock
				if lock and lock.job ~= jobId and (os.time() - (lock.t or 0)) < LOCK_STALE_SECONDS then
					lockedByOther = true
					return nil -- abort write
				end
				old.lock = { job = jobId, t = os.time() }
				return old
			end)
		end, 4)
		if not ok then
			return nil, result
		end
		if not lockedByOther then
			local data = result and result.data
			return data or false -- false = new player
		end
		task.wait(attempt * 2) -- the other server should release soon
	end
	return nil, "locked"
end

local function writeProfile(userId: number, data, release: boolean)
	if not store then
		return false
	end
	local jobId = game.JobId ~= "" and game.JobId or "studio"
	local snapshot = table.clone(data)
	local ok, err = retry(function()
		return (store :: DataStore):UpdateAsync(keyFor(userId), function(old)
			old = old or {}
			if old.lock and old.lock.job ~= jobId and (os.time() - (old.lock.t or 0)) < LOCK_STALE_SECONDS then
				return nil -- another server owns the session; never overwrite
			end
			old.data = snapshot
			old.lock = (not release) and { job = jobId, t = os.time() } or nil
			return old
		end)
	end, 5)
	if not ok then
		warn("[PlayerData] save failed for", userId, err)
	end
	return ok
end

-- ===================== PUBLIC =====================
function PlayerData.get(id: number)
	return profiles[id]
end

function PlayerData.dirty(id: number)
	if profiles[id] then
		dirty[id] = true
	end
end

-- Light update: only money/speed fields (sent every economy tick without the full snapshot).
local dirtyLight = {}
function PlayerData.dirtyLight(id: number)
	if profiles[id] and not dirty[id] then
		dirtyLight[id] = true
	end
end

function PlayerData.isSaveable(id: number): boolean
	return saveable[id] == true
end

-- Builds the compact snapshot sent to the owning client.
function PlayerData.snapshot(id: number)
	local p = profiles[id]
	if not p then
		return nil
	end
	local now = os.time()
	local eggs = {}
	for slot, e in p.eggs do
		eggs[slot] = { biome = e.biome, size = e.size, mutation = e.mutation, variant = e.variant, event = e.event,
			hatchAt = e.hatchAt, duration = e.duration, ready = e.ready, stolen = S.Theft.isBeingStolen(id, slot) }
	end
	local pets = {}
	for _, pet in p.pets do
		table.insert(pets, { uid = pet.uid, species = pet.species, size = pet.size, mutation = pet.mutation, tier = pet.tier, income = Formulas.petIncome(pet) })
	end
	local boosts = {}
	for k, v in p.boosts do
		if v > now then
			boosts[k] = v
		end
	end
	local st = S.Actors.state(id)
	return {
		gold = p.gold, vault = p.vault, speed = p.speed, totalEarned = p.totalEarned,
		income = S.Economy.incomeOf(id), treadmillTier = p.treadmillTier,
		trailsOwned = p.trailsOwned, equippedTrail = p.equippedTrail,
		baseLevel = p.baseLevel, incubators = S.Bases.incubatorCount(id), petSlots = Formulas.baseLevel(p.baseLevel).petSlots,
		eggs = eggs, pets = pets, equippedPet = p.equippedPet,
		index = p.index, claimed = p.claimed, achievements = p.achievements, stats = p.stats,
		settings = p.settings, boosts = boosts, keys = p.keys, title = p.title, tutorial = p.tutorial, tutDone = p.tutDone,
		playtime = p.playtime, reliquaryRestricted = S.Monetization.isRandomRestricted(id),
		passes = S.Monetization.ownedList(id), trapsActive = S.Traps.activeCount(id),
		protected = S.Theft.protectionReason(id), baseIndex = S.Bases.baseIndexOf(id),
		carrying = st and st.carry and { biome = st.carry.record.biome, size = st.carry.record.size, mutation = st.carry.record.mutation, variant = st.carry.record.variant } or nil,
		unlockedBiome = Formulas.unlockedBiome(p.speed),
		saveable = saveable[id] == true,
		serverTime = now,
	}
end

function PlayerData.newUid(): string
	return string.sub(HttpService:GenerateGUID(false), 1, 13)
end

-- In-memory profile for a simulated participant.
function PlayerData.createBotProfile(id: number, seed)
	local p = template()
	if seed then
		for k, v in seed do
			p[k] = v
		end
	end
	profiles[id] = p
	return p
end

function PlayerData.removeBotProfile(id: number)
	profiles[id] = nil
	dirty[id] = nil
end

-- ===================== LIFECYCLE =====================
local function onPlayerAdded(player: Player)
	local userId = player.UserId
	if loading[userId] or profiles[userId] then
		return -- duplicate load protection
	end
	loading[userId] = true
	local data, err = loadProfile(userId)
	loading[userId] = nil
	if not player.Parent then
		-- left while loading: release lock untouched
		if data then
			writeProfile(userId, data, true)
		end
		return
	end
	local isNew = false
	if data == nil then
		if err == "locked" then
			player:Kick("Seus dados ainda estão abertos em outro servidor. Tente novamente em instantes.")
			return
		end
		warn("[PlayerData] DataStore unavailable (" .. tostring(err) .. ") — using a temporary profile for", player.Name)
		data = template()
		isNew = true
	elseif data == false then
		data = template()
		isNew = true
		saveable[userId] = true
	else
		data = migrate(data)
		saveable[userId] = true
	end
	if store == nil then
		saveable[userId] = nil
	end
	local secondsAway = isNew and 0 or math.max(0, os.time() - (data.lastSeen or os.time()))
	data.lastSeen = os.time()
	profiles[userId] = data
	S.Actors.register(userId, { kind = "Player", player = player, name = player.DisplayName })
	PlayerData.Loaded:Fire(userId, data, { isNew = isNew, secondsAway = secondsAway })
	PlayerData.dirty(userId)
	if not saveable[userId] then
		task.delay(4, function()
			Net.fire(player, "Notify", { kind = "Warning", title = "Progresso temporário", text = "DataStore indisponível (habilite API Services no Studio). O progresso desta sessão não será salvo." })
		end)
	end
end

local function release(player: Player)
	local userId = player.UserId
	local data = profiles[userId]
	if not data then
		return
	end
	PlayerData.Releasing:Fire(userId, data)
	data.lastSeen = os.time()
	S.Actors.unregister(userId)
	if saveable[userId] then
		writeProfile(userId, data, true)
	end
	profiles[userId] = nil
	saveable[userId] = nil
	dirty[userId] = nil
	dirtyLight[userId] = nil
end

function PlayerData.init(sys)
	S = sys
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStore unavailable:", result)
	end
end

function PlayerData.start()
	-- Character hookup for players
	local function hookCharacter(player: Player)
		player.CharacterAdded:Connect(function(char)
			task.wait() -- let the character finish parenting
			if profiles[player.UserId] then
				S.Actors.CharacterAdded:Fire(player.UserId, char)
			end
		end)
	end
	Players.PlayerAdded:Connect(function(player)
		hookCharacter(player)
		onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(release)
	for _, p in Players:GetPlayers() do
		hookCharacter(p)
		task.spawn(onPlayerAdded, p)
	end
	PlayerData.Loaded:Connect(function(id)
		local player = S.Actors.player(id)
		if player and player.Character then
			S.Actors.CharacterAdded:Fire(id, player.Character)
		end
	end)

	-- Settings (validated: only known keys and types are stored)
	S.Net.handle("SaveSettings", function(player, payload)
		local p = profiles[player.UserId]
		if not p then
			return false
		end
		if typeof(payload.music) == "boolean" then
			p.settings.music = payload.music
		end
		if typeof(payload.sfx) == "boolean" then
			p.settings.sfx = payload.sfx
		end
		if payload.vfx == "High" or payload.vfx == "Low" then
			p.settings.vfx = payload.vfx
		end
		if typeof(payload.shake) == "boolean" then
			p.settings.shake = payload.shake
		end
		return true
	end)

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for _, player in Players:GetPlayers() do
				local id = player.UserId
				local data = profiles[id]
				if data and saveable[id] then
					data.lastSeen = os.time()
					task.spawn(writeProfile, id, data, false)
				end
			end
		end
	end)

	-- Playtime + state sync (throttled)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		local step = acc
		acc = 0
		for id in dirtyLight do
			dirtyLight[id] = nil
			local p = profiles[id]
			local player = S.Actors.player(id)
			if p and player and not dirty[id] then
				Net.fire(player, "State", { partial = true, gold = p.gold, vault = p.vault, speed = p.speed, totalEarned = p.totalEarned,
					income = S.Economy.incomeOf(id), unlockedBiome = Formulas.unlockedBiome(p.speed), serverTime = os.time() })
			end
		end
		for id in dirty do
			dirty[id] = nil
			local player = S.Actors.player(id)
			if player then
				local snap = PlayerData.snapshot(id)
				if snap then
					Net.fire(player, "State", snap)
				end
			end
		end
		for _, player in Players:GetPlayers() do
			local p = profiles[player.UserId]
			if p then
				p.playtime += step
			end
		end
	end)

	game:BindToClose(function()
		local threads = 0
		for _, player in Players:GetPlayers() do
			local id = player.UserId
			if profiles[id] and saveable[id] then
				threads += 1
				task.spawn(function()
					profiles[id].lastSeen = os.time()
					writeProfile(id, profiles[id], true)
					threads -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while threads > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

-- Persist immediately (used after purchases). Returns success.
function PlayerData.saveNow(id: number): boolean
	local data = profiles[id]
	if not data then
		return false
	end
	if not saveable[id] then
		return true -- nothing to persist (Studio without API access / bot)
	end
	return writeProfile(id, data, false)
end

return PlayerData
