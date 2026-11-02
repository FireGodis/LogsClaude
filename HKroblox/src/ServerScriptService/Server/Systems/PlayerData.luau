--!strict
-- Persistência segura: retry com backoff, trava de sessão, versão de esquema,
-- autosave escalonado, BindToClose. Falha de leitura NUNCA vira perfil novo.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Config = require(ReplicatedStorage.Shared.Config)

type Profile = Types.Profile

local CURRENT_VERSION = 2
local AUTOSAVE_SECONDS = 60
local LOCK_STALE_SECONDS = 150
local JOB_ID: string = if game.JobId ~= "" then game.JobId else "studio-" .. HttpService:GenerateGUID(false)
local KNOWN_ABILITIES = { "dash", "pulse", "wings", "claw" }
local WorldMap = require(ReplicatedStorage.Shared.WorldMap)
local validCheckpoints: { [string]: boolean } = {}
for _, bench in WorldMap.Benches do
	validCheckpoints[bench.id] = true
end

local PlayerData = {}

type Entry = { data: Profile, ephemeral: boolean, closing: boolean }
local entries: { [Player]: Entry } = {}
local loadedCallbacks: { (Player, Profile) -> () } = {}

local store: DataStore? = nil
local legacyStore: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("RollowKnifeProfiles_v1")
	end)
	if ok then
		store = result
	end
	local okLegacy, legacyResult = pcall(function()
		return DataStoreService:GetDataStore("MareProgress_v1")
	end)
	if okLegacy then
		legacyStore = legacyResult
	end
end

local function withRetry(attempts: number, fn: () -> any): (boolean, any)
	local delaySeconds = 1
	local lastError: any = nil
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < attempts then
			task.wait(delaySeconds)
			delaySeconds = math.min(delaySeconds * 2, 8)
		end
	end
	return false, lastError
end

local function clampInt(value: any, low: number, high: number): number
	local number = tonumber(value) or 0
	if number ~= number then
		number = 0
	end
	return math.floor(math.clamp(number, low, high))
end

local function defaultProfile(): Profile
	local abilities: { [string]: boolean } = {}
	for name, enabled in Config.DefaultAbilities do
		abilities[name] = enabled
	end
	return {
		version = CURRENT_VERSION,
		cacos = 0,
		fragments = 0,
		maxMasks = Config.Masks.Default,
		checkpoint = "Inicio",
		flags = {},
		collected = {},
		abilities = abilities,
		lock = nil,
	}
end

local function copyBoolMap(source: any): { [string]: boolean }
	local out: { [string]: boolean } = {}
	if type(source) == "table" then
		for key, value in source do
			if type(key) == "string" and value == true then
				out[key] = true
			end
		end
	end
	return out
end

-- Converte qualquer coisa vinda do DataStore em um perfil válido e atual.
local function sanitize(raw: any): Profile
	local profile = defaultProfile()
	if type(raw) ~= "table" then
		return profile
	end
	if raw.Version == 1 then
		-- Formato antigo do protótipo "Maré de Vidro".
		profile.fragments = clampInt(raw.Fragments, 0, 999)
		profile.checkpoint = if raw.Checkpoint == "Galeria" then "g1" else "Inicio"
		if profile.fragments > 0 then
			profile.collected["vidro_01"] = true
		end
		return profile
	end
	profile.cacos = clampInt(raw.cacos, 0, 9999999)
	profile.fragments = clampInt(raw.fragments, 0, 9999)
	profile.maxMasks = clampInt(raw.maxMasks, Config.Masks.Default, Config.Masks.Max)
	local saved = raw.checkpoint
	if saved == "Galeria" then
		saved = "g1"
	end
	profile.checkpoint = if type(saved) == "string" and validCheckpoints[saved] then saved else "Inicio"
	profile.flags = copyBoolMap(raw.flags)
	profile.collected = copyBoolMap(raw.collected)
	local savedAbilities = copyBoolMap(raw.abilities)
	for _, name in KNOWN_ABILITIES do
		if savedAbilities[name] then
			profile.abilities[name] = true
		end
	end
	return profile
end

local function serialize(profile: Profile): Profile
	return {
		version = CURRENT_VERSION,
		cacos = profile.cacos,
		fragments = profile.fragments,
		maxMasks = profile.maxMasks,
		checkpoint = profile.checkpoint,
		flags = table.clone(profile.flags),
		collected = table.clone(profile.collected),
		abilities = table.clone(profile.abilities),
		lock = nil,
	}
end

local function keyFor(player: Player): string
	return "p" .. tostring(player.UserId)
end

local function lockIsFresh(old: any): boolean
	if type(old) ~= "table" or type(old.lock) ~= "table" then
		return false
	end
	local lock = old.lock
	if lock.jobId == JOB_ID then
		return false
	end
	return (os.time() - (tonumber(lock.at) or 0)) < LOCK_STALE_SECONDS
end

-- Lê o progresso do protótipo antigo, só para migrar jogadores novos no formato v2.
local function readLegacy(player: Player): any
	local legacy = legacyStore
	if not legacy then
		return nil
	end
	local ok, result = withRetry(2, function()
		return legacy:GetAsync("player-" .. tostring(player.UserId))
	end)
	if ok then
		return result
	end
	return nil
end

-- Reivindica a trava e carrega. Retorna (perfil, motivo da falha).
local function claim(player: Player, seed: any): (Profile?, string)
	local dataStore = store
	if not dataStore then
		return nil, "nostore"
	end
	local outcome = "ok"
	local claimed: Profile? = nil
	local ok = withRetry(3, function()
		dataStore:UpdateAsync(keyFor(player), function(old: any)
			outcome = "ok"
			if lockIsFresh(old) then
				outcome = "locked"
				return nil
			end
			local profile = sanitize(if old == nil then seed else old)
			claimed = profile
			local out = serialize(profile)
			out.lock = { jobId = JOB_ID, at = os.time() }
			return out
		end)
		return true
	end)
	if not ok then
		return nil, "error"
	end
	if outcome == "locked" then
		return nil, "locked"
	end
	return claimed, "ok"
end

local function save(player: Player, entry: Entry, release: boolean): boolean
	if entry.ephemeral then
		return true
	end
	local dataStore = store
	if not dataStore then
		return false
	end
	local ok = withRetry(if release then 4 else 2, function()
		dataStore:UpdateAsync(keyFor(player), function(old: any)
			if lockIsFresh(old) then
				return nil
			end
			local out = serialize(entry.data)
			out.lock = if release then nil else { jobId = JOB_ID, at = os.time() }
			return out
		end)
		return true
	end)
	return ok
end

-- Espelha o perfil em atributos do jogador para o cliente desenhar HUD.
function PlayerData.publish(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	local data = entry.data
	player:SetAttribute("Cacos", data.cacos)
	player:SetAttribute("Fragments", data.fragments)
	player:SetAttribute("MaxMasks", data.maxMasks)
	for _, name in KNOWN_ABILITIES do
		player:SetAttribute("Ability_" .. name, data.abilities[name] == true)
	end
	for id in data.collected do
		player:SetAttribute("Collected_" .. id, true)
	end
	for id in data.flags do
		player:SetAttribute("Flag_" .. id, true)
	end
end

function PlayerData.get(player: Player): Profile?
	local entry = entries[player]
	return if entry then entry.data else nil
end

function PlayerData.saveNow(player: Player): boolean
	local entry = entries[player]
	if not entry or entry.closing then
		return false
	end
	return save(player, entry, false)
end

function PlayerData.onLoaded(callback: (Player, Profile) -> ())
	table.insert(loadedCallbacks, callback)
end

local function load(player: Player)
	if entries[player] then
		return
	end
	local profile: Profile? = nil
	local reason = "nostore"
	if store then
		local seed = readLegacy(player)
		for _ = 1, 4 do
			profile, reason = claim(player, seed)
			if profile or reason ~= "locked" then
				break
			end
			task.wait(3)
		end
	end

	if not player.Parent then
		-- Saiu enquanto carregava: devolve a trava, se chegou a pegá-la.
		if profile then
			save(player, { data = profile, ephemeral = false, closing = true }, true)
		end
		return
	end

	local ephemeral = false
	if not profile then
		if RunService:IsStudio() then
			warn(`[PlayerData] Falha ao carregar ({reason}). Perfil temporário, NÃO será salvo.`)
			profile = defaultProfile()
			ephemeral = true
		else
			player:Kick("Não foi possível carregar o seu progresso. Entre novamente em instantes.")
			return
		end
	end

	local entry: Entry = { data = profile :: Profile, ephemeral = ephemeral, closing = false }
	entries[player] = entry
	PlayerData.publish(player)
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, entry.data)
	end

	-- Autosave escalonado por UserId.
	task.spawn(function()
		task.wait(player.UserId % AUTOSAVE_SECONDS)
		while entries[player] == entry and not entry.closing do
			save(player, entry, false)
			task.wait(AUTOSAVE_SECONDS)
		end
	end)
end

local function release(player: Player)
	local entry = entries[player]
	if not entry or entry.closing then
		return
	end
	entry.closing = true
	save(player, entry, true)
	entries[player] = nil
end

function PlayerData.start()
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(load, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		task.spawn(release, player)
	end)
	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				release(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + (if RunService:IsStudio() then 3 else 25)
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return PlayerData
