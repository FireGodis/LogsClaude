--!strict
-- Combate do jogador: golpes do Prego, dash, foco (cura), dano em máscaras, respawn.
-- O cliente PEDE; o servidor valida taxa, tipo, faixa e plausibilidade, e decide.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local MaskMath = require(ReplicatedStorage.Shared.MaskMath)
local Net = require(script.Parent.Net)
local PlayerData = require(script.Parent.PlayerData)
local KnightRig = require(script.Parent.KnightRig)
local Enemies = require(script.Parent.Enemies)
local WorldSystem = require(script.Parent.WorldSystem)

local WorldMap = require(ReplicatedStorage.Shared.WorldMap)

local Combat = {}

type PlayerState = { cooldowns: { [string]: number } }
local states: { [Player]: PlayerState } = {}
local focusing: { [Player]: number } = {}

local function num(inst: Instance, name: string, default: number): number
	local value = inst:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local function alive(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character or character:GetAttribute("Dead") == true then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function ready(state: PlayerState, action: string, duration: number): boolean
	local now = os.clock()
	if now < (state.cooldowns[action] or 0) then
		return false
	end
	state.cooldowns[action] = now + duration
	return true
end

local function stopFocus(player: Player)
	focusing[player] = nil
	local character = player.Character
	if character then
		character:SetAttribute("Focusing", false)
	end
end

local function addSoul(player: Player, gain: number)
	local soul = num(player, "Soul", 0)
	player:SetAttribute("Soul", MaskMath.addSoul(soul, gain, Config.Soul.Max))
end

-- Descanso: máscaras e alma cheias.
function Combat.restore(player: Player)
	local profile = PlayerData.get(player)
	local maxMasks = if profile then profile.maxMasks else Config.Masks.Default
	player:SetAttribute("MaxMasks", maxMasks)
	player:SetAttribute("Masks", maxMasks)
	player:SetAttribute("Soul", Config.Soul.Max)
end

function Combat.damagePlayer(player: Player, amount: number, sourceX: number)
	local character, humanoid, root = alive(player)
	if not character or not humanoid or not root then
		return
	end
	local serverNow = Workspace:GetServerTimeNow()
	if serverNow < num(character, "InvulnUntil", 0) then
		return
	end
	local masks = num(player, "Masks", Config.Masks.Default)
	local remaining, died = MaskMath.applyDamage(masks, amount)
	player:SetAttribute("Masks", remaining)
	character:SetAttribute("InvulnUntil", serverNow + Config.Masks.IFrames)
	stopFocus(player)
	local dirX = if root.Position.X >= sourceX then 1 else -1
	Net.fire("Hurt", player, dirX, amount)
	Net.fireAll("Fx", "PlayerHit", root.Position)
	if died then
		character:SetAttribute("Dead", true)
		humanoid.Health = 0
	end
end

local function returnToCheckpoint(player: Player)
	local character, _, root = alive(player)
	local spawn = player.RespawnLocation
	if character and root and spawn then
		character:PivotTo(spawn.CFrame * CFrame.new(0, 3.4, 0))
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local lastSafe: { [Player]: Vector3 } = {}
local hazardCooldown: { [Player]: number } = {}

local function returnToSafe(player: Player)
	local character, _, root = alive(player)
	if not character or not root then
		return
	end
	local target = lastSafe[player]
	if target then
		character:PivotTo(CFrame.new(target))
		root.AssemblyLinearVelocity = Vector3.zero
	else
		returnToCheckpoint(player)
	end
end

-- Espinhos: leva uma máscara e volta ao último chão seguro.
function Combat.hazardHit(player: Player)
	local now = os.clock()
	if now < (hazardCooldown[player] or 0) then
		return
	end
	hazardCooldown[player] = now + 0.9
	local _, _, root = alive(player)
	if not root then
		return
	end
	local x = root.Position.X
	returnToSafe(player)
	Combat.damagePlayer(player, 1, x)
end

local function onAbility(player: Player, kind: unknown, facingArg: unknown)
	if typeof(kind) ~= "string" then
		return
	end
	local profile = PlayerData.get(player)
	local character, _, root = alive(player)
	if not profile or not character or not root then
		return
	end
	local state = states[player]
	if not state then
		return
	end
	local facing = if facingArg == -1 then -1 else 1
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.FloorMaterial ~= Enum.Material.Air then
		return
	end
	if kind == "Flap" and profile.abilities.wings and ready(state, "Flap", 0.35) then
		character:SetAttribute("FlapAt", Workspace:GetServerTimeNow())
		character:SetAttribute("Facing", facing)
		Net.fireOthers("Fx", player, "Flap", root.Position)
	elseif kind == "WallJump" and profile.abilities.claw and ready(state, "WallJump", 0.28) then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character }
		local rightHit = Workspace:Raycast(root.Position, Vector3.new(Config.Move.WallProbeDistance + 0.3, 0, 0), params)
		local leftHit = Workspace:Raycast(root.Position, Vector3.new(-Config.Move.WallProbeDistance - 0.3, 0, 0), params)
		if not rightHit and not leftHit then
			return
		end
		character:SetAttribute("WallAt", Workspace:GetServerTimeNow())
		character:SetAttribute("Facing", facing)
		Net.fireOthers("Fx", player, "WallJump", root.Position, facing)
	end
end

local function onAttack(player: Player, dirArg: unknown, facingArg: unknown)
	if typeof(dirArg) ~= "string" or typeof(facingArg) ~= "number" then
		return
	end
	if dirArg ~= "F" and dirArg ~= "U" and dirArg ~= "D" then
		return
	end
	if facingArg ~= 1 and facingArg ~= -1 then
		return
	end
	local state = states[player]
	local character, _, root = alive(player)
	if not state or not character or not root then
		return
	end
	-- 10% de folga para jitter de rede.
	if not ready(state, "Attack", Config.Combat.AttackCooldown * 0.9) then
		return
	end
	stopFocus(player)
	character:SetAttribute("Facing", facingArg)
	character:SetAttribute("AtkDir", dirArg)
	character:SetAttribute("AtkAt", Workspace:GetServerTimeNow())

	local center, half = MaskMath.hitBox(
		Vector2.new(root.Position.X, root.Position.Y),
		dirArg,
		facingArg,
		Config.Combat.ReachForward,
		Config.Combat.ReachVertical,
		Config.Combat.HalfHeight
	)
	local hits, blocked = Enemies.strike(center, half, Config.Combat.NailDamage, root.Position.X, player, dirArg)
	if hits > 0 then
		addSoul(player, Config.Soul.GainPerHit * hits)
		Net.fire("Fx", player, "Confirm", dirArg)
	end
	if (hits > 0 or blocked > 0) and dirArg == "D" then
		Net.fire("Pogo", player)
	elseif blocked > 0 and hits == 0 then
		Net.fire("Fx", player, "Confirm", dirArg)
	end
end

local function onDash(player: Player, facingArg: unknown)
	if typeof(facingArg) ~= "number" or (facingArg ~= 1 and facingArg ~= -1) then
		return
	end
	local profile = PlayerData.get(player)
	local state = states[player]
	local character = alive(player)
	if not profile or not profile.abilities.dash or not state or not character then
		return
	end
	if not ready(state, "Dash", Config.Move.DashCooldown * 0.8) then
		return
	end
	stopFocus(player)
	character:SetAttribute("Facing", facingArg)
	character:SetAttribute("DashAt", Workspace:GetServerTimeNow())
end

local function onPulse(player: Player)
	local profile = PlayerData.get(player)
	local state = states[player]
	local _, _, root = alive(player)
	if not profile or not profile.abilities.pulse or not state or not root then
		return
	end
	if not ready(state, "Pulse", Config.Combat.PulseCooldown) then
		return
	end
	WorldSystem.revealEcho()
	Enemies.stunNear(root.Position, Config.Combat.PulseRadius, Config.Combat.StunDuration)
	Net.fireAll("Fx", "Pulse", root.Position)
end

local function onReady(player: Player)
	if player:GetAttribute("Ready") == true then
		return
	end
	player:SetAttribute("Ready", true)
	local character = player.Character
	if character then
		character:SetAttribute("InvulnUntil", Workspace:GetServerTimeNow() + 2)
	end
end

local function canStartFocus(player: Player, humanoid: Humanoid, root: BasePart): boolean
	local masks = num(player, "Masks", Config.Masks.Default)
	local maxMasks = num(player, "MaxMasks", Config.Masks.Default)
	local soul = num(player, "Soul", 0)
	if not MaskMath.canFocus(soul, masks, maxMasks, Config.Soul.FocusCost) then
		return false
	end
	return humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.X) <= 3
end

local function onFocus(player: Player, active: unknown)
	if typeof(active) ~= "boolean" then
		return
	end
	local character, humanoid, root = alive(player)
	if not character or not humanoid or not root then
		return
	end
	if not active then
		stopFocus(player)
		return
	end
	if canStartFocus(player, humanoid, root) then
		focusing[player] = os.clock()
		character:SetAttribute("Focusing", true)
	end
end

function Combat.registerPlayer(player: Player)
	states[player] = { cooldowns = {} }
end

function Combat.onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	character:WaitForChild("HumanoidRootPart", 10)
	KnightRig.build(character)

	local profile = PlayerData.get(player)
	local maxMasks = if profile then profile.maxMasks else Config.Masks.Default
	player:SetAttribute("MaxMasks", maxMasks)
	player:SetAttribute("Masks", maxMasks)
	player:SetAttribute("Soul", 0)
	character:SetAttribute("Dead", false)
	character:SetAttribute("Facing", 1)
	character:SetAttribute("Focusing", false)
	character:SetAttribute("InvulnUntil", Workspace:GetServerTimeNow() + 1)
	focusing[player] = nil
	lastSafe[player] = nil

	humanoid.Died:Once(function()
		character:SetAttribute("Dead", true)
		focusing[player] = nil
		task.delay(Config.Respawn.Delay, function()
			if player.Parent and player.Character == character and PlayerData.get(player) then
				player:LoadCharacter()
			end
		end)
	end)
end

function Combat.start()
	Net.on("Attack", 6, 3, onAttack)
	Net.on("Dash", 4, 3, onDash)
	Net.on("Pulse", 2, 2, onPulse)
	Net.on("Focus", 6, 4, onFocus)
	Net.on("Ready", 1, 1, onReady)
	Net.on("Ability", 8, 4, onAbility)

	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
		focusing[player] = nil
		lastSafe[player] = nil
		hazardCooldown[player] = nil
	end)

	local hazardClock = 0
	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		for player, startedAt in focusing do
			local character, humanoid, root = alive(player)
			if not character or not humanoid or not root or not canStartFocus(player, humanoid, root) then
				stopFocus(player)
			elseif now - startedAt >= Config.Soul.FocusTime then
				local masks = num(player, "Masks", Config.Masks.Default)
				local maxMasks = num(player, "MaxMasks", Config.Masks.Default)
				player:SetAttribute("Masks", MaskMath.heal(masks, maxMasks, 1))
				player:SetAttribute("Soul", math.max(0, num(player, "Soul", 0) - Config.Soul.FocusCost))
				Net.fireAll("Fx", "Heal", root.Position)
				focusing[player] = now
			end
		end

		-- Queda no vazio: volta ao último marco e custa uma máscara.
		hazardClock += dt
		if hazardClock >= 0.3 then
			hazardClock = 0
			for _, player in Players:GetPlayers() do
				local _, humanoid, root = alive(player)
				if humanoid and root and humanoid.FloorMaterial ~= Enum.Material.Air and root.AssemblyLinearVelocity.Magnitude < 25 then
					lastSafe[player] = root.Position + Vector3.new(0, 0.5, 0)
				end
				if root and root.Position.Y < WorldMap.Bounds.killY then
					returnToCheckpoint(player)
					Combat.damagePlayer(player, 1, root.Position.X)
				end
			end
		end
	end)
end

return Combat
