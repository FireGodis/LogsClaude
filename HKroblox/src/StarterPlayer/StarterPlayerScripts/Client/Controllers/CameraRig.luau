--!strict
-- Câmera 2.5D lateral: segue o cavaleiro com suavização, olhar à frente e tremor.
-- Aceita um "override" para cenas cinematográficas.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local CameraRig = {}

local player = Players.LocalPlayer
local settings = Config.Camera

local focusX = 0.0
local focusY = 6.0
local initialized = false
local shakeMagnitude = 0.0
local shakeDuration = 0.1
local shakeEnd = 0.0
local distance = settings.Distance
local distanceGoal = settings.Distance
local gameplayCFrame = CFrame.new(0, 6, settings.Distance)
local facingProvider: () -> number = function()
	return 1
end
local override: ((dt: number) -> (CFrame, number))? = nil

function CameraRig.setFacingProvider(provider: () -> number)
	facingProvider = provider
end

function CameraRig.setDistanceGoal(value: number)
	distanceGoal = value
end

function CameraRig.snap()
	initialized = false
end

function CameraRig.shake(magnitude: number, duration: number)
	shakeMagnitude = magnitude
	shakeDuration = math.max(duration, 0.01)
	shakeEnd = os.clock() + duration
end

-- Câmera de jogo calculada neste quadro (para a cena se encaixar nela no fim).
function CameraRig.getGameplay(): (CFrame, number)
	return gameplayCFrame, settings.FOV
end

function CameraRig.setOverride(callback: ((dt: number) -> (CFrame, number))?)
	override = callback
end

function CameraRig.start()
	RunService:BindToRenderStep("RK_Camera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		camera.CameraType = Enum.CameraType.Scriptable

		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			local position = root.Position
			local targetX = position.X + facingProvider() * settings.LookAhead
			local targetY = position.Y + settings.VerticalOffset
			if not initialized then
				focusX, focusY, initialized = targetX, targetY, true
			end
			focusX += (targetX - focusX) * (1 - math.exp(-dt * 5))
			focusY += (targetY - focusY) * (1 - math.exp(-dt * 3.2))
		end

		local x = math.max(focusX, settings.MinX)
		local offsetX, offsetY = 0, 0
		local now = os.clock()
		if now < shakeEnd then
			local falloff = (shakeEnd - now) / shakeDuration
			offsetX = (math.random() * 2 - 1) * shakeMagnitude * falloff
			offsetY = (math.random() * 2 - 1) * shakeMagnitude * falloff
		end
		distance += (distanceGoal - distance) * (1 - math.exp(-dt * 1.6))
		local eye = Vector3.new(x, focusY, distance)
		gameplayCFrame = CFrame.lookAt(eye, Vector3.new(eye.X, eye.Y, 0))

		local scripted = override
		if scripted then
			local cframe, fov = scripted(dt)
			camera.FieldOfView = fov
			camera.CFrame = cframe * CFrame.new(offsetX, offsetY, 0)
		else
			camera.FieldOfView = settings.FOV
			camera.CFrame = gameplayCFrame * CFrame.new(offsetX, offsetY, 0)
		end
	end)
end

return CameraRig
