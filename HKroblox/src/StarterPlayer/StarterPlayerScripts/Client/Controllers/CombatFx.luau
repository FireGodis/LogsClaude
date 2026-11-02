--!strict
-- Efeitos visuais e de "game feel" do combate: arcos de golpe, faíscas, tremor, clarão.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(script.Parent.Net)
local Audio = require(script.Parent.Audio)
local CameraRig = require(script.Parent.CameraRig)

local CombatFx = {}

-- Preenchidos pelo Movement (evita dependência circular).
CombatFx.hooks = {
	hitStop = function(_duration: number) end,
}

local WHITE = Color3.fromRGB(240, 246, 255)
local PALE = Color3.fromRGB(170, 205, 255)
local CYAN = Color3.fromRGB(87, 225, 216)
local EMBER = Color3.fromRGB(255, 170, 90)

local overlay: Frame
do
	local gui = Instance.new("ScreenGui")
	gui.Name = "RK_Fx"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 60
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = WHITE
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Active = false
	overlay.Parent = gui
end

local function flashScreen(color: Color3, strength: number, duration: number)
	overlay.BackgroundColor3 = color
	overlay.BackgroundTransparency = 1 - strength
	TweenService:Create(overlay, TweenInfo.new(duration), { BackgroundTransparency = 1 }):Play()
end

local function burst(position: Vector3, color: Color3, count: number, speed: number, lifetime: number, gravity: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(lifetime * 0.6, lifetime)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 1
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Acceleration = Vector3.new(0, gravity, 0)
	emitter.Parent = anchor
	anchor.Parent = Workspace
	emitter:Emit(count)
	Debris:AddItem(anchor, lifetime + 0.4)
end

-- Arco branco do golpe do Prego (um Trail que viaja em arco).
function CombatFx.slash(character: Model, dir: string, facing: number)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Position = root.Position

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.3, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1.3, 0)
	a1.Parent = part

	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.2
	trail.MinLength = 0
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(WHITE, PALE)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) })
	trail.Parent = part
	part.Parent = Workspace

	local startAngle, endAngle = 1.15, -1.05
	if dir == "U" then
		startAngle, endAngle = 0.15, math.pi - 0.15
	elseif dir == "D" then
		startAngle, endAngle = -0.15, -(math.pi - 0.15)
	end
	local radius = if dir == "F" then 5.3 else 4.9
	local duration = 0.13
	local startedAt = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function()
		local alpha = math.min(1, (os.clock() - startedAt) / duration)
		local angle = startAngle + (endAngle - startAngle) * alpha
		local ax = math.cos(angle) * facing
		local ay = math.sin(angle)
		local origin = root.Position + Vector3.new(0, 0.4, 0)
		part.CFrame = CFrame.new(origin + Vector3.new(ax * radius, ay * radius, 0.3))
			* CFrame.Angles(0, 0, math.atan2(ay, ax) - math.pi / 2)
		if alpha >= 1 and connection then
			connection:Disconnect()
			connection = nil
		end
	end)
	Debris:AddItem(part, 0.6)
end

function CombatFx.dashTrail(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.8, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -2.2, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.22
	trail.FaceCamera = true
	trail.LightEmission = 0.8
	trail.Color = ColorSequence.new(PALE, Color3.fromRGB(40, 60, 120))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	trail.Parent = root
	Debris:AddItem(a0, 0.6)
	Debris:AddItem(a1, 0.6)
	Debris:AddItem(trail, 0.6)
end

function CombatFx.dust(position: Vector3, strength: number)
	burst(position, Color3.fromRGB(150, 165, 190), math.floor(4 + strength * 6), 8 + strength * 6, 0.45, 4)
end

function CombatFx.flap(position: Vector3)
	burst(position + Vector3.new(0, 1.1, 0), Color3.fromRGB(196, 235, 255), 16, 15, 0.42, 4)
end

function CombatFx.wallJump(position: Vector3, wallSide: number)
	burst(position + Vector3.new(wallSide * 0.8, 0, 0), Color3.fromRGB(150, 205, 230), 12, 12, 0.35, 3)
end

local function pulseRing(position: Vector3)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.Material = Enum.Material.Neon
	ring.Color = CYAN
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, math.pi / 2, 0)
	ring.Parent = Workspace
	local diameter = Config.Combat.PulseRadius * 2
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, diameter, diameter),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.7)
end

-- Onda de choque que corre pelo chão (o servidor decide o dano; isto é só o visual).
function CombatFx.spawnWave(position: Vector3, dir: number, speed: number, life: number)
	local wave = Instance.new("Part")
	wave.Anchored = true
	wave.CanCollide = false
	wave.CanTouch = false
	wave.CanQuery = false
	wave.Material = Enum.Material.Neon
	wave.Color = CYAN
	wave.Transparency = 0.25
	wave.Size = Vector3.new(1.2, 4.2, 3.2)
	wave.Position = position + Vector3.new(0, 2.1, 0)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 60
	emitter.Lifetime = NumberRange.new(0.3, 0.5)
	emitter.Speed = NumberRange.new(4, 8)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.LightEmission = 1
	emitter.Color = ColorSequence.new(CYAN)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	emitter.Parent = wave
	wave.Parent = Workspace
	local startedAt = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function(dt: number)
		local age = os.clock() - startedAt
		wave.Position += Vector3.new(dir * speed * dt, 0, 0)
		wave.Transparency = 0.25 + 0.75 * math.clamp(age / life, 0, 1) ^ 2
		if age >= life and connection then
			connection:Disconnect()
			connection = nil
			wave:Destroy()
		end
	end)
	Debris:AddItem(wave, life + 0.5)
end

-- Aviso no chão onde uma pedra vai cair.
function CombatFx.debrisMark(position: Vector3, delay: number)
	local mark = Instance.new("Part")
	mark.Shape = Enum.PartType.Cylinder
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanTouch = false
	mark.CanQuery = false
	mark.Material = Enum.Material.Neon
	mark.Color = Color3.fromRGB(255, 96, 70)
	mark.Transparency = 0.6
	mark.Size = Vector3.new(0.2, 6, 6)
	mark.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0.5)) * CFrame.Angles(0, 0, math.pi / 2)
	mark.Parent = Workspace
	TweenService:Create(mark, TweenInfo.new(delay, Enum.EasingStyle.Linear), {
		Size = Vector3.new(0.2, 2.4, 2.4),
		Transparency = 0.15,
	}):Play()
	Debris:AddItem(mark, delay + 0.1)
end

function CombatFx.debrisFall(position: Vector3, fallTime: number)
	local rock = Instance.new("Part")
	rock.Anchored = true
	rock.CanCollide = false
	rock.CanTouch = false
	rock.CanQuery = false
	rock.Material = Enum.Material.Slate
	rock.Color = Color3.fromRGB(74, 80, 104)
	rock.Size = Vector3.new(3.4, 3.4, 3.4)
	rock.CFrame = CFrame.new(position + Vector3.new(0, 38, 0)) * CFrame.Angles(0.4, 0.6, 0.2)
	rock.Parent = Workspace
	TweenService:Create(rock, TweenInfo.new(fallTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = CFrame.new(position + Vector3.new(0, 1.7, 0)) * CFrame.Angles(1.6, 1.1, 0.7),
	}):Play()
	Debris:AddItem(rock, fallTime + 0.25)
end

function CombatFx.start()
	Net.on("Fx", function(kind: any, a: any, b: any)
		if kind == "Hit" and typeof(a) == "Vector3" then
			burst(a, WHITE, 16, 40, 0.35, -10)
			Audio.play("hit")
		elseif kind == "Confirm" then
			CombatFx.hooks.hitStop(Config.Combat.HitStop)
			CameraRig.shake(0.35, 0.12)
		elseif kind == "PlayerHit" and typeof(a) == "Vector3" then
			burst(a, WHITE, 22, 36, 0.45, -6)
		elseif kind == "Death" and typeof(a) == "Vector3" then
			local boss = b == true
			burst(a, EMBER, if boss then 60 else 26, if boss then 60 else 40, 0.7, -14)
			burst(a, WHITE, if boss then 30 else 12, 30, 0.5, -8)
			CameraRig.shake(if boss then 1.6 else 0.4, if boss then 0.6 else 0.15)
		elseif kind == "Pulse" and typeof(a) == "Vector3" then
			pulseRing(a)
			Audio.play("pulse")
		elseif kind == "Flap" and typeof(a) == "Vector3" then
			CombatFx.flap(a)
		elseif kind == "WallJump" and typeof(a) == "Vector3" and typeof(b) == "number" then
			CombatFx.wallJump(a, -b)
		elseif kind == "Heal" and typeof(a) == "Vector3" then
			burst(a, WHITE, 18, 14, 0.8, 10)
			Audio.play("heal")
			flashScreen(PALE, 0.18, 0.5)
		elseif kind == "Bench" and typeof(a) == "Vector3" then
			burst(a + Vector3.new(0, 2, 0), PALE, 28, 10, 1.2, 6)
		elseif kind == "BossSlam" and typeof(a) == "Vector3" then
			local heavy = b == true
			CameraRig.shake(if heavy then 1.3 else 0.5, if heavy then 0.35 else 0.2)
			burst(a + Vector3.new(0, 0.5, 0), Color3.fromRGB(150, 165, 190), if heavy then 34 else 16, if heavy then 24 else 14, 0.7, 4)
			Audio.play("thud")
		elseif kind == "Block" and typeof(a) == "Vector3" then
			burst(a, Color3.fromRGB(205, 215, 235), 14, 34, 0.3, -6)
			CameraRig.shake(0.15, 0.1)
			Audio.play("hit")
		elseif kind == "Wave" and typeof(a) == "Vector3" and typeof(b) == "number" and typeof(c) == "number" and typeof(d) == "number" then
			CombatFx.spawnWave(a, b, c, d)
		elseif kind == "DebrisMark" and typeof(a) == "Vector3" and typeof(b) == "number" then
			CombatFx.debrisMark(a, b)
		elseif kind == "DebrisFall" and typeof(a) == "Vector3" and typeof(b) == "number" then
			CombatFx.debrisFall(a, b)
		elseif kind == "DebrisHit" and typeof(a) == "Vector3" then
			burst(a + Vector3.new(0, 1, 0), Color3.fromRGB(160, 172, 195), 20, 24, 0.6, -14)
			CameraRig.shake(0.45, 0.18)
			Audio.play("thud")
		end
	end)
end

function CombatFx.playerHurt()
	flashScreen(WHITE, 0.55, 0.28)
	CameraRig.shake(0.9, 0.25)
	Audio.play("hurt")
end

return CombatFx
