--!strict
-- Anima todos os inimigos e o chefe: as peças vêm do servidor, cada cliente move as juntas
-- a partir do estado replicado (State / StateAt / Dur / Facing). Também toca os sons.

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local EnemySpec = require(ReplicatedStorage.Shared.EnemySpec)
local CameraRig = require(script.Parent.CameraRig)

local EnemyAnim = {}

type G = { x: number, y: number, r: number }
type Rig = {
	model: Model,
	def: EnemySpec.EnemyDef,
	root: BasePart,
	parts: { BasePart },
	joints: { Motor6D },
	specs: { EnemySpec.EnemyPart },
	cur: { [string]: G },
	target: { [string]: G },
	baseColors: { Color3 },
	walkPhase: number,
	lastX: number,
	lastState: string,
	flash: boolean,
	warn: boolean,
	stepSide: number,
}

local rigs: { [Model]: Rig } = {}
local WHITE = Color3.fromRGB(255, 255, 255)

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
local function lerp(a: number, b: number, x: number): number
	return a + (b - a) * math.clamp(x, 0, 1)
end

-- Sons posicionais: reaproveitam os efeitos existentes com tom e volume diferentes.
local function sfx(source: string, root: BasePart, volume: number, pitch: number)
	local template = SoundService:FindFirstChild(source)
	if not template or not template:IsA("Sound") then
		return
	end
	local sound = template:Clone()
	sound.Volume = volume
	sound.Looped = false
	sound.PlaybackSpeed = pitch * (0.94 + math.random() * 0.12)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 14
	sound.RollOffMaxDistance = 110
	sound.Parent = root
	sound:Play()
	Debris:AddItem(sound, 8)
end

local function onStateSound(id: string, state: string, root: BasePart)
	if id == "Crawler" then
		if state == "Notice" then sfx("Mare_Impact", root, 0.22, 1.9)
		elseif state == "Charge" then sfx("Mare_Dash", root, 0.25, 0.85) end
	elseif id == "Flier" then
		if state == "Windup" then sfx("Mare_Swing", root, 0.22, 1.9)
		elseif state == "Dive" then sfx("Mare_Dash", root, 0.3, 1.5) end
	elseif id == "Shield" then
		if state == "Guard" then sfx("Mare_Impact", root, 0.25, 1.4)
		elseif state == "SlamWind" then sfx("Mare_Swing", root, 0.35, 0.5)
		elseif state == "Slam" then sfx("Mare_Impact", root, 0.6, 0.6) end
	elseif id == "Boss" then
		if state == "Intro" or state == "PhaseRoar" or state == "RainWind" then
			sfx("Mare_Impact", root, 0.8, 0.35)
			sfx("Mare_Pulse", root, 0.5, 0.4)
		elseif state == "SweepWind" or state == "SlamWind" or state == "ChargeWind" or state == "LeapWind" then
			sfx("Mare_Swing", root, 0.5, 0.42)
		elseif state == "Sweep" then sfx("Mare_Swing", root, 0.7, 0.55)
		elseif state == "Slam" or state == "Land" or state == "Crash" then sfx("Mare_Impact", root, 0.95, 0.4)
		elseif state == "Leap" then sfx("Mare_Dash", root, 0.55, 0.5)
		elseif state == "Charge" then sfx("Mare_Dash", root, 0.6, 0.45)
		elseif state == "Stagger" then
			sfx("Mare_Impact", root, 0.7, 0.55)
			CameraRig.shake(0.6, 0.3)
		end
	end
end

-- Poses ---------------------------------------------------------------------

local function crawlerPose(g: { [string]: G }, state: string, p: number, t: number, walk: number)
	local legA, legB, body, head = g.legA, g.legB, g.body, g.head
	if not (legA and legB and body and head) then return end
	body.y = math.sin(t * 3) * 0.05
	if state == "Patrol" then
		local s = math.sin(walk)
		legA.r, legB.r = s * 0.6, -s * 0.6
		body.y += math.abs(s) * 0.08
		head.r = s * 0.06
	elseif state == "Notice" then
		local e = smooth(p * 3)
		body.r, head.r, head.x, body.y = 0.4 * e, 0.55 * e, -0.1 * e, 0.3 * e
		legA.r, legB.r = 0.3 * e, -0.2 * e
		head.y = math.sin(t * 30) * 0.05
	elseif state == "Charge" then
		local s = math.sin(walk)
		legA.r, legB.r = s * 0.9, -s * 0.9
		body.r, head.r = -0.1, -0.25
	elseif state == "Recover" then
		body.r = math.sin(t * 10) * 0.1 * (1 - p)
		head.r = 0.3 * (1 - p)
		body.y -= 0.15
	end
end

local function flierPose(g: { [string]: G }, state: string, p: number, t: number)
	local wingA, wingB, body, head = g.wingA, g.wingB, g.body, g.head
	if not (wingA and wingB and body and head) then return end
	body.y = math.sin(t * 3) * 0.1
	local speed = if state == "Windup" then 12 elseif state == "Retreat" then 18 else 26
	wingA.r = 0.5 + math.sin(t * speed) * 0.9
	wingB.r = 0.5 + math.sin(t * speed + 0.9) * 0.9
	if state == "Windup" then
		body.r = -0.45 * smooth(p * 2)
		head.r = -0.3
	elseif state == "Dive" then
		wingA.r, wingB.r = 0.05, 0.05
		body.r, head.r = 0.8, 0.5
	end
end

local function shieldPose(g: { [string]: G }, state: string, p: number, t: number, walk: number)
	local body, head, legF, legB = g.body, g.head, g.legF, g.legB
	local armF, shield = g.armF, g.shield
	if not (body and head and legF and legB and armF and shield) then return end
	body.y = math.sin(t * 2) * 0.06
	if state == "Patrol" then
		local s = math.sin(walk)
		legF.r, legB.r, armF.r = s * 0.35, -s * 0.35, 0.2 + s * 0.2
	elseif state == "Guard" then
		shield.x, shield.y, head.y, armF.r = 0.5, 0.2, -0.2, 0.2
		local s = math.sin(walk)
		legF.r, legB.r = s * 0.2, -s * 0.2
	elseif state == "SlamWind" then
		local e = smooth(p)
		armF.r = lerp(0.2, 3.1, e)
		body.x, shield.x = -0.3 * e, 0.2
	elseif state == "Slam" then
		armF.r = lerp(3.1, 0.5, smooth(p * 1.5))
		body.x, shield.x = 0.6, 0.5
	elseif state == "Recover" then
		body.y = -0.5 * smooth(p * 4)
		shield.x, shield.y, head.y, armF.r = -0.5, -0.8, -0.4, 0.5
	end
end

local function bossPose(g: { [string]: G }, state: string, last: string, p: number, t: number, walk: number)
	local torso, pelvis, head = g.torso, g.pelvis, g.head
	local armF, armB, legF, legB = g.armF, g.armB, g.legF, g.legB
	if not (torso and pelvis and head and armF and armB and legF and legB) then return end
	local breath = math.sin(t * 1.7)
	torso.y = breath * 0.12
	head.y = breath * 0.1
	armF.r = 0.05 + breath * 0.02
	armB.r = 0.12

	if state == "Walk" then
		local s = math.sin(walk)
		legF.r, legB.r = s * 0.4, -s * 0.4
		torso.y += math.abs(s) * 0.25 - 0.1
		torso.r = 0.06
		armB.r = 0.12 - s * 0.2
	elseif state == "SweepWind" then
		local e = smooth(p)
		armF.r = lerp(0.05, -0.9, e)
		torso.x, torso.r, head.x = -0.5 * e, -0.12 * e, -0.4 * e
	elseif state == "Sweep" then
		local e = 1 - (1 - p) * (1 - p)
		armF.r = lerp(-0.9, 1.0, e)
		torso.x, torso.r = lerp(-0.5, 0.8, e), lerp(-0.12, 0.15, e)
	elseif state == "SlamWind" then
		local e = smooth(p)
		armF.r = lerp(0.05, 3.3, e)
		torso.r, head.y = -0.2 * e, head.y + 0.4 * e
		legF.r, legB.r = 0.25 * e, -0.25 * e
	elseif state == "Slam" then
		armF.r = lerp(3.3, 0.55, p * p)
		torso.r, torso.x, head.y = 0.2, 0.8, head.y - 0.4
		legF.r, legB.r = 0.4, -0.2
	elseif state == "LeapWind" then
		local e = smooth(p)
		torso.y -= 1.3 * e
		legF.r, legB.r = 0.9 * e, -0.9 * e
		armF.r = lerp(0.05, -0.4, e)
	elseif state == "Leap" then
		legF.r, legB.r = 0.7, -0.4
		armF.r, armB.r = 2.5, 2.2
		torso.r = -0.1
	elseif state == "Land" then
		torso.y -= 1.0
		armF.r = lerp(2.0, 0.8, p)
		legF.r, legB.r = 0.7, -0.7
	elseif state == "ChargeWind" then
		local e = smooth(p)
		armF.r = lerp(0.05, -0.6, e)
		torso.r, head.y = 0.15 * e, head.y - 0.4 * e
		legF.r = math.sin(t * 18) * 0.25 * e
	elseif state == "Charge" then
		local s = math.sin(walk)
		legF.r, legB.r = s * 0.8, -s * 0.8
		torso.r, head.x, armF.r = 0.3, 1.0, -0.7
	elseif state == "Crash" then
		torso.x, torso.r = -0.6, -0.3
		armF.r = 0.9
	elseif state == "Intro" or state == "PhaseRoar" or state == "RainWind" then
		local e = smooth(p * 3)
		armF.r, armB.r = lerp(0.05, 2.4, e), lerp(0.12, 2.4, e)
		head.y += 0.8 * e
		torso.r = -0.25 * e
		torso.x = math.sin(t * 40) * 0.08 * e
	elseif state == "Stagger" then
		torso.y, torso.r = -2.2, 0.3
		head.y, head.x = -1.0, 0.6
		armF.r = 0.35
		legF.r, legB.r = 1.0, -1.0
		torso.x = math.sin(t * 25) * 0.05 * (1 - smooth(p))
	elseif state == "Recover" then
		local back = smooth(p)
		if last == "Slam" then
			armF.r, torso.r, head.y = lerp(0.55, 0.05, back), 0.2 * (1 - back), head.y - 0.4 * (1 - back)
		elseif last == "Sweep" then
			armF.r, torso.x = lerp(1.0, 0.05, back), 0.8 * (1 - back)
		elseif last == "Leap" then
			armF.r, torso.y = 0.8 * (1 - back), torso.y - 0.6 * (1 - back)
		else
			armF.r, torso.r = lerp(0.9, 0.05, back), 0.2 * (1 - back)
		end
	end
end

local function applyPose(rig: Rig, state: string, age: number, dur: number, now: number, last: string)
	for _, group in rig.target do
		group.x, group.y, group.r = 0, 0, 0
	end
	local progress = math.clamp(age / dur, 0, 1)
	local id = rig.def.id
	if id == "Crawler" then
		crawlerPose(rig.target, state, progress, now, rig.walkPhase)
	elseif id == "Flier" then
		flierPose(rig.target, state, progress, now)
	elseif id == "Shield" then
		shieldPose(rig.target, state, progress, now, rig.walkPhase)
	else
		bossPose(rig.target, state, last, progress, now, rig.walkPhase)
	end
end

local function updateRig(rig: Rig, dt: number, now: number, serverNow: number)
	local model = rig.model
	local state = model:GetAttribute("State")
	local stateAt = model:GetAttribute("StateAt")
	local duration = model:GetAttribute("Dur")
	local facing = model:GetAttribute("Facing")
	local last = model:GetAttribute("Last")
	if typeof(state) ~= "string" then
		return
	end
	local stateAge = if typeof(stateAt) == "number" then math.max(0, serverNow - stateAt) else 0
	local f = if facing == -1 then -1 else 1

	-- Fase de caminhada: avança com a distância percorrida.
	local x = rig.root.Position.X
	local scale = if rig.def.id == "Boss" then 0.34 elseif rig.def.id == "Shield" then 0.75 else 0.9
	rig.walkPhase += math.abs(x - rig.lastX) * scale
	rig.lastX = x

	if state ~= rig.lastState then
		rig.lastState = state
		onStateSound(rig.def.id, state, rig.root)
	end
	-- Passos pesados do chefe.
	if rig.def.id == "Boss" and (state == "Walk" or state == "Charge") then
		local side = math.floor(rig.walkPhase / math.pi) % 2
		if side ~= rig.stepSide then
			rig.stepSide = side
			sfx("Mare_Impact", rig.root, 0.35, 0.3)
			CameraRig.shake(0.18, 0.12)
		end
	end

	applyPose(rig, state, stateAge, if typeof(duration) == "number" then duration else 1, now, if typeof(last) == "string" then last else "")

	local alpha = 1 - math.exp(-dt * 22)
	for name, current in rig.cur do
		local goal = rig.target[name]
		if goal then
			current.x += (goal.x - current.x) * alpha
			current.y += (goal.y - current.y) * alpha
			current.r += (goal.r - current.r) * alpha
		end
	end
	for index, spec in rig.specs do
		local joint = rig.joints[index]
		local g = rig.cur[spec.group]
		if joint and g then
			joint.C0 = CFrame.new((spec.joint.X + g.x) * f, spec.joint.Y + g.y, spec.joint.Z)
				* CFrame.Angles(0, 0, (spec.rot + g.r) * f)
			joint.C1 = CFrame.Angles(0, spec.yaw * f, 0)
				* CFrame.new(-spec.pivot.X * f, -spec.pivot.Y, -spec.pivot.Z)
		end
	end

	-- Clarão branco ao levar um golpe; peças de brilho ficam vermelhas nos avisos.
	local hitAt = model:GetAttribute("HitAt")
	local flashing = typeof(hitAt) == "number" and serverNow - hitAt >= 0 and serverNow - hitAt < 0.09
	local warning = string.sub(state, -4) == "Wind" or state == "Notice" or state == "Windup"
	if flashing ~= rig.flash or warning ~= rig.warn then
		rig.flash, rig.warn = flashing, warning
		for index, part in rig.parts do
			local spec = rig.specs[index]
			if flashing then
				part.Color = WHITE
			elseif spec and spec.glow and warning then
				part.Color = EnemySpec.Colors.Warn
			else
				part.Color = rig.baseColors[index] or part.Color
			end
		end
	end
end

local function attach(model: Model)
	task.spawn(function()
		local kind = model:GetAttribute("Kind")
		local def = if typeof(kind) == "string" then EnemySpec.Defs[kind] else nil
		local root = model:WaitForChild("Root", 10)
		if not def or not root or not root:IsA("BasePart") then
			return
		end
		local parts: { BasePart } = {}
		local joints: { Motor6D } = {}
		local specs: { EnemySpec.EnemyPart } = {}
		local colors: { Color3 } = {}
		for _, spec in def.parts do
			local part = model:WaitForChild(spec.name, 10)
			if not part or not part:IsA("BasePart") then
				return
			end
			local joint = part:WaitForChild("Joint", 10)
			if not joint or not joint:IsA("Motor6D") then
				return
			end
			table.insert(parts, part)
			table.insert(joints, joint)
			table.insert(specs, spec)
			table.insert(colors, spec.color)
		end
		local cur: { [string]: G } = {}
		local target: { [string]: G } = {}
		for _, name in def.groups do
			cur[name] = { x = 0, y = 0, r = 0 }
			target[name] = { x = 0, y = 0, r = 0 }
		end
		rigs[model] = {
			model = model, def = def, root = root, parts = parts, joints = joints, specs = specs,
			cur = cur, target = target, baseColors = colors,
			walkPhase = 0, lastX = root.Position.X, lastState = "", flash = false, warn = false, stepSide = 0,
		}
		model.Destroying:Once(function()
			rigs[model] = nil
		end)
	end)
end

function EnemyAnim.start()
	for _, model in CollectionService:GetTagged("Enemy") do
		if model:IsA("Model") then
			attach(model)
		end
	end
	CollectionService:GetInstanceAddedSignal("Enemy"):Connect(function(model: Instance)
		if model:IsA("Model") then
			attach(model)
		end
	end)
	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		local serverNow = Workspace:GetServerTimeNow()
		for model, rig in rigs do
			if model.Parent then
				updateRig(rig, dt, now, serverNow)
			end
		end
	end)
end

return EnemyAnim
