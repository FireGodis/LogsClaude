--!strict
-- Rede do cliente: só envia PEDIDOS e escuta resultados do servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local folder = ReplicatedStorage:WaitForChild("Remotes")
local cache: { [string]: RemoteEvent } = {}

local function event(name: string): RemoteEvent
	local cached = cache[name]
	if cached then
		return cached
	end
	local remote = folder:WaitForChild(name) :: RemoteEvent
	cache[name] = remote
	return remote
end

function Net.send(name: string, ...: any)
	event(name):FireServer(...)
end

function Net.on(name: string, handler: (...any) -> ()): RBXScriptConnection
	return event(name).OnClientEvent:Connect(handler)
end

function Net.exists(name: string): boolean
	return folder:FindFirstChild(name) ~= nil
end

return Net
