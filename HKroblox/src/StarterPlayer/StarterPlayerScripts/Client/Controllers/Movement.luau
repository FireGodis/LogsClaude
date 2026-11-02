--!strict
-- Movimento fluido estilo metroidvania: pulo variável, coyote time, buffer de pulo,
-- dash, golpe em 3 direções, pogo, recuo de dano e foco. Roda em PreSimulation.
-- O cliente controla o PRÓPRIO corpo; o servidor decide dano, cura e cooldowns.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local MaskMath = require(ReplicatedStorage.Shared.MaskMath)
local Input = require(script.Parent.Input)
local Net = require(script.Parent.Net)
local Audio = require(script.Parent.Audio)
local CombatFx = require(script.Parent.CombatFx)
local CameraRig = require(script.Parent.CameraRig)

local Movement = {}

local player = Players.LocalPlayer
local M = Config.Move
local K = Config.Combat

local info: Types.AnimInfo = {
	state = "Idle",
	facing = 1,
	vx = 0,
	vy = 0,
	grounded = true,
	attackDir = "F",
	attackP = -1,
	hurt = false,
	dashing = false,
	focusing = false,
	dead = false,
	flapP = -1,
	wallSide = 0,
}

local enabled = false
local requestedEnabled = false
local controlLocks: { [number]: boolean } = {}
local nextLockId = 0
local character: Model? = nil
local humanoid: Humanoid? = nil
local root: BasePart? = nil

local coyote = 0.0
local jumpBuffer = 0.0
local jumpLock = 0.0
local jumping = false
local dashT = 0.0
local dashCd = 0.0
local dashDir = 1
local airDashUsed = false
local doubleJumpUsed = false
local wallJumpUsed = false
local lastWallSide = 0
local wallJumpLock = 0.0
local wallJumpDir = 0
local flapT = -1.0
local attackCd = 0.0
local attackT = 0.0
local attackBuffer = 0.0
local dashBuffer = 0.0
local staggerT = 0.0
local knockVx = 0.0
local hitStopT = 0.0
local frozenVel = Vector3.zero
local focusing = false
local focusAsked = 0.0
local pogoQueued = false
local hurtQueued = false
local wasGrounded = true

local function attrNumber(name: string, default: number): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local function resetState()
	coyote, jumpBuffer, jumpLock = 0, 0, 0
	jumping = false
	dashT, dashCd, attackCd, attackT = 0, 0, 0, 0
	attackBuffer, dashBuffer, staggerT, knockVx, hitStopT = 0, 0, 0, 0, 0
	focusing = false
	pogoQueued, hurtQueued = false, false
	airDashUsed = false
	doubleJumpUsed = false
	wallJumpUsed, lastWallSide = false, 0
	wallJumpLock, wallJumpDir, flapT = 0, 0, -1
	info.wallSide, info.flapP = 0, -1
	wasGrounded = true
	info.attackP = -1
	info.dead = false
end

local function cancelFocus()
	if focusing then
		focusing = false
		Net.send("Focus", false)
	end
end

local function tryStartFocus()
	local hum = humanoid
	if focusing or not hum or hum.Health <= 0 or staggerT > 0 or dashT > 0 then
		return
	end
	if hum.FloorMaterial == Enum.Material.Air then
		return
	end
	if
		MaskMath.canFocus(
			attrNumber("Soul", 0),
			attrNumber("Masks", 0),
			attrNumber("MaxMasks", Config.Masks.Default),
			Config.Soul.FocusCost
		)
	then
		focusing = true
		focusAsked = os.clock()
		Net.send("Focus", true)
	end
end

function Movement.getInfo(): Types.AnimInfo
	return info
end

local function applyEnabledState()
	enabled = requestedEnabled and next(controlLocks) == nil
	Input.setEnabled(enabled)
	if not enabled then
		jumpBuffer, attackBuffer, dashBuffer = 0, 0, 0
		cancelFocus()
	end
end

function Movement.setEnabled(value: boolean)
	requestedEnabled = value
	applyEnabledState()
end

function Movement.acquireControlLock(): () -> ()
	nextLockId += 1
	local lockId = nextLockId
	controlLocks[lockId] = true
	applyEnabledState()
	local released = false
	return function()
		if released then
			return
		end
		released = true
		controlLocks[lockId] = nil
		applyEnabledState()
	end
end

function Movement.hitStop(duration: number)
	local rt = root
	if rt and hitStopT <= 0 then
		frozenVel = rt.AssemblyLinearVelocity
	end
	hitStopT = math.max(hitStopT, duration)
end

local function step(dt: number)
	local hum, rt, char = humanoid, root, character
	if not hum or not rt or not char or hum.Parent == nil then
		return
	end
	if hum.Health <= 0 then
		info.dead = true
		focusing = false
		return
	end
	info.dead = false

	local pos = rt.Position
	local vel = rt.AssemblyLinearVelocity

	-- Hit-stop: congela um instante para o golpe ter peso.
	if hitStopT > 0 then
		hitStopT -= dt
		rt.AssemblyLinearVelocity = Vector3.zero
		if hitStopT <= 0 then
			rt.AssemblyLinearVelocity = frozenVel
		end
		return
	end

	local grounded = hum.FloorMaterial ~= Enum.Material.Air
	if not enabled then
		hum:Move(Vector3.zero, false)
		if next(controlLocks) ~= nil then
			rt.AssemblyLinearVelocity = Vector3.zero
			info.vx, info.vy, info.grounded, info.state = 0, 0, grounded, "Idle"
		else
			info.vx, info.vy, info.grounded, info.state = vel.X, vel.Y, grounded, "Idle"
		end
		return
	end

	-- Timers.
	jumpBuffer = math.max(0, jumpBuffer - dt)
	attackBuffer = math.max(0, attackBuffer - dt)
	dashBuffer = math.max(0, dashBuffer - dt)
	jumpLock = math.max(0, jumpLock - dt)
	dashCd = math.max(0, dashCd - dt)
	attackCd = math.max(0, attackCd - dt)
	staggerT = math.max(0, staggerT - dt)
	if grounded then
		airDashUsed = false
		doubleJumpUsed = false
		wallJumpUsed, lastWallSide = false, 0
	end
	wallJumpLock = math.max(0, wallJumpLock - dt)
	flapT = if flapT > 0 then math.max(-1, flapT - dt) else -1
	info.flapP = if flapT > 0 then 1 - flapT / 0.42 else -1
	local wallSide = 0
	if not grounded and dashT <= 0 then
		local castParams = RaycastParams.new()
		castParams.FilterType = Enum.RaycastFilterType.Exclude
		castParams.FilterDescendantsInstances = { char }
		local rightHit = Workspace:Raycast(pos, Vector3.new(M.WallProbeDistance, 0, 0), castParams)
		local leftHit = Workspace:Raycast(pos, Vector3.new(-M.WallProbeDistance, 0, 0), castParams)
		if rightHit and math.abs(rightHit.Normal.Y) < 0.35 then
			wallSide = 1
		elseif leftHit and math.abs(leftHit.Normal.Y) < 0.35 then
			wallSide = -1
		end
	end
	if wallSide ~= 0 and lastWallSide ~= 0 and wallSide ~= lastWallSide then
		wallJumpUsed = false
	end
	info.wallSide = wallSide
	if grounded and jumpLock <= 0 then
		coyote = M.CoyoteTime
	else
		coyote = math.max(0, coyote - dt)
	end
	if grounded and not wasGrounded and vel.Y < -20 then
		CombatFx.dust(pos - Vector3.new(0, 2.9, 0), math.clamp(-vel.Y / 60, 0, 1))
		Audio.play("land")
	end
	wasGrounded = grounded

	if focusing and os.clock() - focusAsked > 0.5 and char:GetAttribute("Focusing") ~= true then
		focusing = false -- o servidor recusou ou terminou
	end

	local axis = Input.axisX()
	local vx = vel.X
	local vy = vel.Y

	if hurtQueued then
		hurtQueued = false
		staggerT = M.HurtStagger
		vy = M.KnockbackY
		dashT = 0
		jumping = false
		focusing = false
	end
	if pogoQueued then
		pogoQueued = false
		vy = M.PogoVelocity
		jumping = false
		coyote = 0
		jumpLock = 0.08
		airDashUsed = false
	end
	if focusing and axis ~= 0 then
		cancelFocus()
	end

	-- Ações.
	if
		dashBuffer > 0
		and dashCd <= 0
		and dashT <= 0
		and staggerT <= 0
		and not focusing
		and player:GetAttribute("Ability_dash") == true
		and (grounded or not airDashUsed)
	then
		dashBuffer = 0
		dashDir = if axis ~= 0 then axis else info.facing
		info.facing = dashDir
		dashT = M.DashTime
		dashCd = M.DashCooldown
		if not grounded then
			airDashUsed = true
		end
		jumping = false
		Net.send("Dash", dashDir)
		Audio.play("dash")
		CombatFx.dashTrail(char)
	end

	if attackBuffer > 0 and attackCd <= 0 and staggerT <= 0 and dashT <= 0 and not focusing then
		attackBuffer = 0
		local up = Input.axisY()
		local dir = if up > 0 then "U" elseif up < 0 and not grounded then "D" else "F"
		if axis ~= 0 then
			info.facing = axis
		end
		attackCd = K.AttackCooldown
		attackT = K.AttackTime
		info.attackDir = dir
		Net.send("Attack", dir, info.facing)
		Audio.play("swing")
		CombatFx.slash(char, dir, info.facing)
	end

	if jumpBuffer > 0 and staggerT <= 0 and dashT <= 0 and not focusing then
		if coyote > 0 then
			jumpBuffer = 0
			coyote = 0
			jumpLock = 0.12
			jumping = true
			vy = M.JumpVelocity
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			Audio.play("jump")
		elseif wallSide ~= 0 and not wallJumpUsed and player:GetAttribute("Ability_claw") == true then
			jumpBuffer = 0
			wallJumpUsed = true
			lastWallSide = wallSide
			wallJumpDir = -wallSide
			wallJumpLock = M.WallJumpLock
			info.facing = wallJumpDir
			info.wallSide = 0
			vy = M.WallJumpVelocityY
			vx = wallJumpDir * M.WallJumpVelocityX
			jumping = true
			doubleJumpUsed = false
			Net.send("Ability", "WallJump", wallJumpDir)
			Audio.play("wall")
			CombatFx.wallJump(pos, wallSide)
		elseif player:GetAttribute("Ability_wings") == true and not doubleJumpUsed then
			jumpBuffer = 0
			doubleJumpUsed = true
			wallJumpDir = 0
			jumping = true
			vy = M.DoubleJumpVelocity
			wallJumpLock = M.DoubleJumpFloatTime
			Net.send("Ability", "Flap", info.facing)
			Audio.play("flap")
			Audio.play("flap2")
			CombatFx.flap(pos)
			flapT = 0.42
		end
	end

	-- Horizontal.
	local dashing = dashT > 0
	if staggerT > 0 then
		vx = knockVx
		knockVx *= math.max(0, 1 - dt * 6)
		hum:Move(Vector3.zero, false)
	elseif dashing then
		vx = dashDir * M.DashSpeed
		vy = 0
		dashT -= dt
		hum:Move(Vector3.zero, false)
	elseif focusing then
		vx = 0
		hum:Move(Vector3.zero, false)
	elseif wallJumpLock > 0 then
		local lockAxis = if wallJumpDir ~= 0 then wallJumpDir else axis
		vx = if wallJumpDir ~= 0 then wallJumpDir * M.WallJumpVelocityX else lockAxis * M.DoubleJumpDrift
		hum:Move(Vector3.new(lockAxis, 0, 0), false)
	else
		vx = axis * M.RunSpeed
		hum:Move(Vector3.new(axis, 0, 0), false)
		if axis ~= 0 then
			info.facing = axis
		end
	end

	-- Vertical: pulo variável + queda mais pesada.
	if jumping then
		if vy <= 0 then
			jumping = false
		elseif not Input.isHeld("jump") and vy > 12 then
			vy *= M.JumpCut
			jumping = false
		end
	end
	if not grounded and vy < 0 and not dashing then
		vy = math.max(vy - Workspace.Gravity * (M.FallGravityMult - 1) * dt, -M.MaxFallSpeed)
		if wallSide ~= 0 and player:GetAttribute("Ability_claw") == true then
			vy = math.max(vy, -M.WallSlideSpeed)
		end
	end

	rt.AssemblyLinearVelocity = Vector3.new(vx, vy, 0)
	if math.abs(pos.Z) > 0.05 then
		rt.CFrame = rt.CFrame - Vector3.new(0, 0, pos.Z)
	end

	-- Estado para a animação.
	attackT = math.max(0, attackT - dt)
	info.attackP = if attackT > 0 then 1 - attackT / K.AttackTime else -1
	info.vx, info.vy, info.grounded = vx, vy, grounded
	info.dashing = dashing
	info.focusing = focusing
	info.hurt = staggerT > 0
	if not grounded then
		info.state = if vy > 1 then "Jump" else "Fall"
	elseif math.abs(vx) > 1 then
		info.state = "Run"
	else
		info.state = "Idle"
	end
end

function Movement.bind(newCharacter: Model)
	local hum = newCharacter:WaitForChild("Humanoid", 10)
	local rt = newCharacter:WaitForChild("HumanoidRootPart", 10)
	if not hum or not rt or not hum:IsA("Humanoid") or not rt:IsA("BasePart") then
		return
	end
	character, humanoid, root = newCharacter, hum, rt
	resetState()
	hum.AutoRotate = false
	hum.AutoJumpEnabled = false
	hum.UseJumpPower = true
	hum.JumpPower = M.JumpVelocity
	hum.WalkSpeed = M.RunSpeed
	CameraRig.snap()
end

function Movement.start()
	-- Desliga os controles padrão: aqui o movimento é todo nosso.
	task.spawn(function()
		pcall(function()
			local scripts = player:WaitForChild("PlayerScripts")
			local moduleScript = scripts:WaitForChild("PlayerModule", 3)
			if moduleScript and moduleScript:IsA("ModuleScript") then
				local playerModule = require(moduleScript) :: any
				playerModule:GetControls():Disable()
			end
		end)
	end)

	Input.onPress("jump", function()
		jumpBuffer = M.JumpBuffer
		cancelFocus()
	end)
	Input.onPress("attack", function()
		attackBuffer = 0.12
	end)
	Input.onPress("dash", function()
		dashBuffer = 0.12
	end)
	Input.onPress("pulse", function()
		if player:GetAttribute("Ability_pulse") == true and staggerT <= 0 then
			Net.send("Pulse")
		end
	end)
	Input.onPress("focus", tryStartFocus)
	Input.onRelease("focus", cancelFocus)

	Net.on("Pogo", function()
		pogoQueued = true
	end)
	Net.on("Hurt", function(dirX: any, _amount: any)
		if typeof(dirX) ~= "number" then
			return
		end
		knockVx = dirX * M.KnockbackX
		hurtQueued = true
		Movement.hitStop(0.08)
		CombatFx.playerHurt()
	end)

	RunService.PreSimulation:Connect(step)
end

return Movement
