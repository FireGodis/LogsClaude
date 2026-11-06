--[[
	Training — tells the server (throttled, 4/s) that the local player is actively running on
	THEIR OWN treadmill. The server validates position + rate and grants the Speed. Also shows
	floating "+Speed" numbers as the authoritative value grows.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NF = require(ReplicatedStorage.Shared.Util.NumberFormatter)
local Net = require(ReplicatedStorage.Shared.Util.Net)

local Training = {}
local C
local player = Players.LocalPlayer
local lastSpeed = nil
local popAcc = 0
local gained = 0

function Training.init(ctx)
	C = ctx
end

local function ownBelt(): BasePart?
	local d = C.State.get()
	if not d or not d.baseIndex then
		return nil
	end
	local base = Workspace.Bases:FindFirstChild("Base_" .. d.baseIndex)
	local tm = base and base.Visuals:FindFirstChild("Treadmill")
	return tm and tm:FindFirstChild("Belt") :: BasePart? or nil
end

function Training.isOnTreadmill(): boolean
	local belt = ownBelt()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not belt or not root then
		return false
	end
	local rel = belt.CFrame:PointToObjectSpace(root.Position)
	return math.abs(rel.X) < belt.Size.X / 2 + 0.5 and math.abs(rel.Z) < belt.Size.Z / 2 + 0.5 and rel.Y > 0 and rel.Y < 7
end

function Training.start()
	task.spawn(function()
		while true do
			task.wait(0.25)
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.MoveDirection.Magnitude > 0.1 and Training.isOnTreadmill() then
				Net.send("TrainPing", true)
			end
		end
	end)
	C.State.Changed:Connect(function(d)
		if lastSpeed and d.speed > lastSpeed then
			gained += d.speed - lastSpeed
		end
		lastSpeed = d.speed
	end)
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		popAcc += dt
		if popAcc > 0.6 and gained > 0 then
			popAcc = 0
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				C.Effects.floatingText(root.Position + Vector3.new(math.random(-2, 2), 3, 0), "+" .. NF.format(gained) .. " ⚡", Color3.fromRGB(120, 210, 255))
			end
			gained = 0
		end
	end)
end

return Training
