--!strict
-- Anima o Cavaleiro de TODOS os jogadores. O servidor constrói as peças;
-- cada cliente move as juntas (Motor6D) a partir do estado replicado.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local KnightSpec = require(ReplicatedStorage.Shared.KnightSpec)
local Types = require(ReplicatedStorage.Shared.Types)
local Movement = require(script.Parent.Movement)

local KnightAnim = {}

type G = { x: number, y: number, r: number }
type Rig = {
	character: Model,
	root: BasePart,
	humanoid: Humanoid,
	isLocal: boolean,
	parts: { BasePart },
	joints: { Motor6D },
	specs: { KnightSpec.PartSpec },
	cur: { [string]: G },
	target: { [string]: G },
	info: Types.AnimInfo,
	flicker: boolean,
	nailShown: boolean,
	wingsShown: boolean,
	nail: BasePart?,
	glow: PointLight?,
}

local rigs: { [Model]: Rig } = {}
local IS_STUDIO = RunService:IsStudio()

-- Modo cinematográfico: uma cena assume a pose do cavaleiro local.
export type Cinematic = {
	apply: ({ [string]: G }) -> (),
	facing: number,
	nail: boolean,
	glow: boolean,
}
local cinematic: Cinematic? = nil

function KnightAnim.setCinematic(value: Cinematic?)
	cinematic = value
end

-- Ferramenta de QA (só Studio): o atributo local DebugPose força uma pose para inspeção visual.
-- Exemplo: "attack=F;p=0.4"  |  "dash=1"  |  "focus=1"  |  "hurt=1"  |  "dead=1"  |  "air=-10"  |  "run=21"
local function applyDebugPose(info: Types.AnimInfo, spec: string)
	for key, value in string.gmatch(spec, "(%w+)=([%w%.%-]+)") do
		if key == "attack" then
			info.attackDir = value
			if info.attackP < 0 then
				info.attackP = 0.5
			end
		elseif key == "p" then
			info.attackP = tonumber(value) or -1
		elseif key == "dash" then
			info.dashing = value == "1"
		elseif key == "focus" then
			info.focusing = value == "1"
		elseif key == "hurt" then
			info.hurt = value == "1"
		elseif key == "dead" then
			info.dead = value == "1"
		elseif key == "air" then
			info.grounded = false
			info.vy = tonumber(value) or 0
		elseif key == "run" then
			info.vx = tonumber(value) or 0
		elseif key == "flap" then
			info.flapP = tonumber(value) or -1
		elseif key == "wall" then
			info.wallSide = tonumber(value) or 0
			info.grounded = false
		elseif key == "face" then
			info.facing = if value == "-1" then -1 else 1
		end
	end
end

local function computeTargets(info: Types.AnimInfo, t: number, out: { [string]: G })
	for _, g in out do
		g.x, g.y, g.r = 0, 0, 0
	end
	local head, body, cloak = out.head, out.body, out.cloak
	local armF, armB, legF, legB, nail = out.armF, out.armB, out.legF, out.legB, out.nail
	local speed = math.abs(info.vx)
	local breath = math.sin(t * 2.4)
	head.y = breath * 0.05
	body.y = breath * 0.03
	cloak.r = math.sin(t * 1.8) * 0.05

	if info.dead then
		body.y, body.x = -1.6, -0.2
		head.x, head.y = -1.6, -3.7
		legF.r, legB.r, legF.y, legB.y = 1.35, 1.2, -1.3, -1.3
		armF.r, armB.r, armF.y, armB.y = 1.3, 1.1, -1.6, -1.6
		cloak.r, cloak.y = 1.2, -1.7
		nail.x, nail.y, nail.r = armF.x, armF.y, armF.r
		return
	end

	if info.focusing then
		head.y -= 0.5
		head.x = 0.1
		body.y -= 0.35
		legF.r, legB.r = 0.5, -0.5
		armF.r, armB.r = 0.9, -0.6
		cloak.r = 0.15 + math.sin(t * 6) * 0.08
	elseif info.dashing then
		head.x, head.y = 0.6, -0.35
		body.x, body.y = 0.35, -0.2
		legF.r, legB.r = -1.25, -1.5
		armF.r, armB.r = -1.4, -1.55
		cloak.r = -1.5
	elseif not info.grounded then
		if info.vy > 1 then
			legF.r, legB.r = 0.85, -0.25
			armF.r, armB.r = 0.5, 0.2
			cloak.r = 0.1
		else
			legF.r, legB.r = 0.15, -0.15
			armF.r, armB.r = 0.9, 0.7
			cloak.r = 1.25 + math.sin(t * 22) * 0.12
		end
	elseif speed > 1 then
		local phase = t * (11 + speed * 0.18)
		local s = math.sin(phase)
		local bounce = math.abs(math.cos(phase)) * 0.12 - 0.06
		legF.r, legB.r = s * 0.95, -s * 0.95
		armF.r, armB.r = -s * 0.7, s * 0.7
		body.y += bounce
		head.x = 0.18
		head.y += bounce
		cloak.r = -0.55 - math.abs(s) * 0.15
	end

	local wingA, wingB = out.wingA, out.wingB
	if info.wallSide ~= 0 and not info.grounded then
		-- agarrado à parede: encosta o corpo, braços para cima, pernas dobradas
		body.x, head.x = 0.35, 0.5
		armF.r, armB.r = 2.6, 2.2
		legF.r, legB.r = 0.8, 0.3
		cloak.r = -0.2
	end
	if info.flapP >= 0 and wingA and wingB then
		-- bater de asas: duas batidas largas, corpo se encolhe e braços sobem
		local p = info.flapP
		local beat = math.sin(p * math.pi * 4 - math.pi / 2)
		wingA.r = 0.3 + beat * 1.15
		wingB.r = 0.15 + beat * 1.15
		body.y += 0.25 * (1 - p)
		head.y += 0.2
		legF.r, legB.r = 0.6, -0.2
		armF.r, armB.r = 2.2, 2.0
		cloak.r = 0.9
	end

	if info.attackP >= 0 then
		local p = info.attackP
		local e = 1 - (1 - p) * (1 - p)
		local angle: number
		if info.attackDir == "U" then
			angle = 1.0 + (3.3 - 1.0) * e
		elseif info.attackDir == "D" then
			angle = 1.2 + (-0.1 - 1.2) * e
		else
			angle = 3.0 + (0.45 - 3.0) * e
		end
		armF.r = angle
		armB.r = -0.7 + e * 0.5
		local lean = math.sin(math.pi * math.min(1, p)) * 0.28
		body.x += lean
		head.x += lean * 1.3
	end

	if info.hurt then
		body.x -= 0.3
		head.x -= 0.45
		head.y += 0.1
		armF.r, armB.r = 1.6, 1.2
	end

	nail.x, nail.y, nail.r = armF.x, armF.y, armF.r
end

local function deriveRemote(rig: Rig, serverNow: number)
	local info = rig.info
	local character = rig.character
	local v = rig.root.AssemblyLinearVelocity
	info.vx, info.vy = v.X, v.Y
	info.grounded = rig.humanoid.FloorMaterial ~= Enum.Material.Air
	local facing = character:GetAttribute("Facing")
	if typeof(facing) == "number" then
		info.facing = facing
	end
	if math.abs(v.X) > 2 then
		info.facing = if v.X > 0 then 1 else -1
	end
	local attackAt = character:GetAttribute("AtkAt")
	if typeof(attackAt) == "number" and serverNow - attackAt >= 0 and serverNow - attackAt < Config.Combat.AttackTime then
		info.attackP = (serverNow - attackAt) / Config.Combat.AttackTime
		local dir = character:GetAttribute("AtkDir")
		info.attackDir = if typeof(dir) == "string" then dir else "F"
	else
		info.attackP = -1
	end
	local dashAt = character:GetAttribute("DashAt")
	info.dashing = typeof(dashAt) == "number" and serverNow - dashAt >= 0 and serverNow - dashAt < Config.Move.DashTime
	info.focusing = character:GetAttribute("Focusing") == true
	local flapAt = character:GetAttribute("FlapAt")
	info.flapP = if typeof(flapAt) == "number" and serverNow - flapAt >= 0 and serverNow - flapAt < 0.42 then (serverNow - flapAt) / 0.42 else -1
	info.wallSide = 0
	info.dead = rig.humanoid.Health <= 0
	info.hurt = false
	if not info.grounded then
		info.state = if v.Y > 1 then "Jump" else "Fall"
	elseif math.abs(v.X) > 1 then
		info.state = "Run"
	else
		info.state = "Idle"
	end
end

local function updateRig(rig: Rig, dt: number, now: number, serverNow: number)
	local info = rig.info
	if rig.isLocal then
		info = Movement.getInfo()
	else
		deriveRemote(rig, serverNow)
	end

	if IS_STUDIO then
		local debugPose = rig.character:GetAttribute("DebugPose")
		if typeof(debugPose) == "string" then
			applyDebugPose(info, debugPose)
		end
	end

	computeTargets(info, now, rig.target)
	local scene = cinematic
	if scene and rig.isLocal then
		scene.apply(rig.target)
		info.facing = scene.facing
	end
	local alpha = 1 - math.exp(-dt * 24)
	for _, name in KnightSpec.Groups do
		local current, target = rig.cur[name], rig.target[name]
		if current and target then
			current.x += (target.x - current.x) * alpha
			current.y += (target.y - current.y) * alpha
			current.r += (target.r - current.r) * alpha
		end
	end

	local f = info.facing
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

	local flapping = info.flapP >= 0
	if flapping ~= rig.wingsShown then
		rig.wingsShown = flapping
		for index, part in rig.parts do
			local wingSpec = rig.specs[index]
			if wingSpec and string.sub(wingSpec.name, 1, 4) == "Wing" then
				part.Transparency = if flapping then 0.05 else 1
			end
		end
	end

	local nail = rig.nail
	if nail then
		local show = info.attackP >= 0 or (scene ~= nil and rig.isLocal and scene.nail)
		if show ~= rig.nailShown then
			rig.nailShown = show
			nail.Transparency = if show then 0 else 1
		end
	end
	if rig.glow then
		rig.glow.Enabled = info.focusing or (scene ~= nil and rig.isLocal and scene.glow)
	end

	-- Piscar durante os quadros de invulnerabilidade.
	local invulnerableUntil = rig.character:GetAttribute("InvulnUntil")
	local flicker = typeof(invulnerableUntil) == "number"
		and serverNow < invulnerableUntil
		and math.floor(now * 14) % 2 == 0
	if flicker ~= rig.flicker then
		rig.flicker = flicker
		for index, part in rig.parts do
			local spec = rig.specs[index]
			if spec and spec.name ~= "Nail" and string.sub(spec.name, 1, 4) ~= "Wing" then
				part.Transparency = if flicker then 0.65 else 0
			end
		end
	end
end

local function attach(character: Model, isLocal: boolean)
	task.spawn(function()
		local folder = character:WaitForChild("KnightRig", 15)
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not folder or not humanoid or not root then
			return
		end
		if not humanoid:IsA("Humanoid") or not root:IsA("BasePart") then
			return
		end

		local parts: { BasePart } = {}
		local joints: { Motor6D } = {}
		local specs: { KnightSpec.PartSpec } = {}
		local nail: BasePart? = nil
		local glow: PointLight? = nil
		for _, spec in KnightSpec.Parts do
			local part = folder:WaitForChild(spec.name, 10)
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
			if spec.name == "Nail" then
				nail = part
			elseif spec.name == "Body" then
				local light = part:FindFirstChild("Glow")
				if light and light:IsA("PointLight") then
					glow = light
				end
			end
		end

		local cur: { [string]: G } = {}
		local target: { [string]: G } = {}
		for _, name in KnightSpec.Groups do
			cur[name] = { x = 0, y = 0, r = 0 }
			target[name] = { x = 0, y = 0, r = 0 }
		end

		rigs[character] = {
			character = character,
			root = root,
			humanoid = humanoid,
			isLocal = isLocal,
			parts = parts,
			joints = joints,
			specs = specs,
			cur = cur,
			target = target,
			info = {
				state = "Idle", facing = 1, vx = 0, vy = 0, grounded = true, attackDir = "F",
				attackP = -1, hurt = false, dashing = false, focusing = false, dead = false, flapP = -1, wallSide = 0,
			},
			flicker = false,
			nailShown = false,
			wingsShown = false,
			nail = nail,
			glow = glow,
		}
		character.Destroying:Once(function()
			rigs[character] = nil
		end)
	end)
end

function KnightAnim.start()
	local localPlayer = Players.LocalPlayer
	local function watch(target: Player)
		local isLocal = target == localPlayer
		if target.Character then
			attach(target.Character, isLocal)
		end
		target.CharacterAdded:Connect(function(character: Model)
			attach(character, isLocal)
		end)
	end
	for _, target in Players:GetPlayers() do
		watch(target)
	end
	Players.PlayerAdded:Connect(watch)

	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		local serverNow = Workspace:GetServerTimeNow()
		for character, rig in rigs do
			if character.Parent then
				updateRig(rig, dt, now, serverNow)
			end
		end
	end)
end

return KnightAnim
