--!strict
-- Rede do servidor: cria os remotes, limita taxa por jogador e valida a entrada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Remotes)

local Net = {}

local folder: Folder
do
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
end

local remotes: { [string]: RemoteEvent } = {}

function Net.make(name: string): RemoteEvent
	local existing = remotes[name]
	if existing then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	remotes[name] = remote
	return remote
end

function Net.makeAll()
	for _, name in RemoteNames.C2S do
		Net.make(name)
	end
	for _, name in RemoteNames.S2C do
		Net.make(name)
	end
end

-- Balde de fichas por jogador e por remote.
local buckets: { [Player]: { [string]: { tokens: number, last: number } } } = {}

local function allow(player: Player, key: string, ratePerSec: number, burst: number): boolean
	local now = os.clock()
	local playerBuckets = buckets[player]
	if not playerBuckets then
		playerBuckets = {}
		buckets[player] = playerBuckets
	end
	local bucket = playerBuckets[key]
	if not bucket then
		bucket = { tokens = burst, last = now }
		playerBuckets[key] = bucket
	end
	bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.last) * ratePerSec)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

Players.PlayerRemoving:Connect(function(player: Player)
	buckets[player] = nil
end)

function Net.on(name: string, ratePerSec: number, burst: number, handler: (Player, ...unknown) -> ())
	local remote = Net.make(name)
	remote.OnServerEvent:Connect(function(player: Player, ...: unknown)
		if not allow(player, name, ratePerSec, burst) then
			return
		end
		handler(player, ...)
	end)
end

function Net.fire(name: string, player: Player, ...: any)
	Net.make(name):FireClient(player, ...)
end

function Net.fireOthers(name: string, except: Player, ...: any)
	local remote = Net.make(name)
	for _, player in Players:GetPlayers() do
		if player ~= except then
			remote:FireClient(player, ...)
		end
	end
end

function Net.fireAll(name: string, ...: any)
	Net.make(name):FireAllClients(...)
end

-- Validadores reutilizáveis (tipo -> faixa).
function Net.isFiniteNumber(value: unknown): boolean
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

return Net
