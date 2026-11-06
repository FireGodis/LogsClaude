--[[
	Net — the single remote boundary of the game.

	Remotes are created ONLY by the server (Net.serverInit) inside ReplicatedStorage.Remotes from
	the lists below. Every client->server handler passes through per-player rate limiting and the
	server never trusts payload contents (each handler validates its own arguments).
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

-- Client -> Server (RemoteEvent), with max calls per second (token bucket).
Net.ClientEvents = {
	TrainPing = 8,
	UseAbility = 3,
	DropEgg = 2,
}
-- Client -> Server request/response (RemoteFunction "Request"): action name -> max per second.
Net.Actions = {
	BuyTreadmill = 3,
	BuyTrail = 3,
	EquipTrail = 4,
	UpgradeBase = 2,
	EquipPet = 4,
	SellPet = 6,
	PlaceTrap = 2,
	RemoveTrap = 3,
	ClaimIndexReward = 3,
	OpenReliquaryKey = 1,
	ClaimVipDaily = 1,
	SaveSettings = 2,
	TutorialStep = 4,
	GetReliquaryInfo = 2,
	GetLeaderboard = 1,
}
-- Server -> Client (RemoteEvent)
Net.ServerEvents = {
	"State", "Notify", "HatchReveal", "Effect", "Knockback", "Trapped", "Announce",
	"OfflineSummary", "Reveal", "WorldState", "Freeze",
}

local folder: Folder? = nil

-- ===================== SERVER =====================
local buckets = {} -- [player][name] = {tokens, last}

local function allow(player: Player, name: string, rate: number): boolean
	local now = os.clock()
	local perPlayer = buckets[player]
	if not perPlayer then
		perPlayer = {}
		buckets[player] = perPlayer
	end
	local b = perPlayer[name]
	if not b then
		b = { tokens = rate, last = now }
		perPlayer[name] = b
	end
	b.tokens = math.min(rate, b.tokens + (now - b.last) * rate)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

Net.onRateLimited = nil -- optional callback(player, name)

function Net.serverInit()
	assert(RunService:IsServer(), "Net.serverInit is server-only")
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		existing:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "Remotes"
	for name in Net.ClientEvents do
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = f
	end
	for _, name in Net.ServerEvents do
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = f
	end
	local rf = Instance.new("RemoteFunction")
	rf.Name = "Request"
	rf.Parent = f
	f.Parent = ReplicatedStorage
	folder = f

	game:GetService("Players").PlayerRemoving:Connect(function(p)
		buckets[p] = nil
	end)

	local actionHandlers = {}
	Net._actionHandlers = actionHandlers
	rf.OnServerInvoke = function(player, action, payload)
		if typeof(action) ~= "string" then
			return false, "invalid"
		end
		local rate = Net.Actions[action]
		local handler = actionHandlers[action]
		if not rate or not handler then
			return false, "unknown action"
		end
		if not allow(player, "A_" .. action, rate) then
			if Net.onRateLimited then
				Net.onRateLimited(player, action)
			end
			return false, "Muito rápido! Tente novamente."
		end
		if payload ~= nil and typeof(payload) ~= "table" then
			return false, "invalid payload"
		end
		local ok, a, b = pcall(handler, player, payload or {})
		if not ok then
			warn("[Net] action", action, "failed:", a)
			return false, "Erro interno"
		end
		return a, b
	end
end

function Net.handle(action: string, fn)
	assert(Net.Actions[action], "Unknown action " .. action)
	Net._actionHandlers[action] = fn
end

function Net.on(name: string, fn)
	local rate = Net.ClientEvents[name]
	assert(rate, "Unknown client event " .. name)
	local remote = (folder :: Folder):FindFirstChild(name) :: RemoteEvent
	remote.OnServerEvent:Connect(function(player, ...)
		if not allow(player, "E_" .. name, rate) then
			if Net.onRateLimited then
				Net.onRateLimited(player, name)
			end
			return
		end
		local ok, err = pcall(fn, player, ...)
		if not ok then
			warn("[Net] event", name, "failed:", err)
		end
	end)
end

function Net.fire(player: Player?, name: string, ...)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return -- bots have no client
	end
	local remote = (folder :: Folder):FindFirstChild(name) :: RemoteEvent
	remote:FireClient(player, ...)
end

function Net.fireAll(name: string, ...)
	local remote = (folder :: Folder):FindFirstChild(name) :: RemoteEvent
	remote:FireAllClients(...)
end

-- ===================== CLIENT =====================
local clientFolder: Instance? = nil
local function getFolder()
	if not clientFolder then
		clientFolder = ReplicatedStorage:WaitForChild("Remotes")
	end
	return clientFolder :: Instance
end

function Net.send(name: string, ...)
	(getFolder():WaitForChild(name) :: RemoteEvent):FireServer(...)
end

function Net.request(action: string, payload): (boolean, any)
	local rf = getFolder():WaitForChild("Request") :: RemoteFunction
	local ok, a, b = pcall(rf.InvokeServer, rf, action, payload)
	if not ok then
		return false, "Falha de conexão"
	end
	return a, b
end

function Net.listen(name: string, fn)
	return (getFolder():WaitForChild(name) :: RemoteEvent).OnClientEvent:Connect(fn)
end

return Net
