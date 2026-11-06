--[[
	Effects — all client-side juice, kept cheap (distance culling, low update rates):
	  hatch bursts by rarity, mythology-themed ability VFX (Greek lightning/gold, Norse ice/runes,
	  Egyptian sand/solar fire), coin pops, camera shake, knockback, trap snap, guardian slam,
	  reveal highlights, incubator countdowns + wobble, pet idle bob, rainbow mutation cycling,
	  treadmill belt animation, base alarm/protection visuals, guardian state icons.
	Respects Settings: VFX quality (High/Low) and camera shake toggle.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local NF = require(Shared.Util.NumberFormatter)
local Net = require(Shared.Util.Net)
local Kit = require(script.Parent.Parent.UI.Kit)

local Effects = {}
local C
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local shakeUntil, shakeIntensity = 0, 0
local lowVfx = false
local shakeEnabled = true
local fxFolder

local MYTH_COLORS = {
	Greek = { Color3.fromRGB(255, 230, 120), Color3.fromRGB(120, 190, 255) },
	Norse = { Color3.fromRGB(150, 220, 255), Color3.fromRGB(230, 250, 255) },
	Egyptian = { Color3.fromRGB(255, 190, 60), Color3.fromRGB(255, 110, 30) },
	Event = { Color3.fromRGB(255, 120, 220), Color3.fromRGB(150, 90, 255) },
}

function Effects.init(ctx)
	C = ctx
end

local function myRoot(): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart? or nil
end

function Effects.shake(intensity: number)
	if not shakeEnabled then
		return
	end
	shakeIntensity = math.max(shakeIntensity, intensity)
	shakeUntil = os.clock() + 0.35 + intensity * 0.3
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = fxFolder
	return p
end

local function burst(position: Vector3, color: Color3, color2: Color3?, amount: number, speed: number?, size: number?)
	if lowVfx then
		amount = math.floor(amount / 3)
	end
	local a = part({ Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(position) })
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color, color2 or color)
	pe.LightEmission = 1
	pe.Speed = NumberRange.new((speed or 20) * 0.5, speed or 20)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Lifetime = NumberRange.new(0.5, 1.2)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 0
	pe.Drag = 3
	pe.Parent = a
	pe:Emit(amount)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 4
	light.Parent = a
	TweenService:Create(light, TweenInfo.new(0.8), { Brightness = 0 }):Play()
	Debris:AddItem(a, 2)
end

local function ring(position: Vector3, color: Color3, radius: number, duration: number?)
	local r = part({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = 0.2, Size = Vector3.new(0.4, 2, 2), CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)) })
	TweenService:Create(r, TweenInfo.new(duration or 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.4, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(r, (duration or 0.5) + 0.1)
end

local function pillar(position: Vector3, color: Color3, height: number, duration: number?)
	local p = part({ Color = color, Transparency = 0.3, Size = Vector3.new(3, 0.5, 3), CFrame = CFrame.new(position) })
	TweenService:Create(p, TweenInfo.new(duration or 0.6), { Size = Vector3.new(0.5, height, 0.5), CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)), Transparency = 1 }):Play()
	Debris:AddItem(p, (duration or 0.6) + 0.1)
end

local function lightning(from: Vector3, to: Vector3, color: Color3)
	local segments = 6
	local last = from
	for i = 1, segments do
		local t = i / segments
		local point = from:Lerp(to, t) + (i < segments and Vector3.new(math.random(-3, 3), math.random(-2, 2), math.random(-3, 3)) or Vector3.zero)
		local len = (point - last).Magnitude
		local seg = part({ Color = color, Size = Vector3.new(0.35, 0.35, len), CFrame = CFrame.lookAt((last + point) / 2, point) })
		TweenService:Create(seg, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		Debris:AddItem(seg, 0.4)
		last = point
	end
end

local function floatingText(position: Vector3, text: string, color: Color3)
	local a = part({ Transparency = 1, Size = Vector3.one, CFrame = CFrame.new(position) })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 40)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 90
	bb.Parent = a
	local l = Kit.label({ Text = text, Parent = bb, TextColor3 = color, MaxTextSize = 30 })
	TweenService:Create(a, TweenInfo.new(1.2), { CFrame = CFrame.new(position + Vector3.new(0, 5, 0)) }):Play()
	TweenService:Create(l, TweenInfo.new(1.2), { TextTransparency = 1 }):Play()
	Debris:AddItem(a, 1.3)
end
Effects.floatingText = floatingText

-- ===================== ABILITY VFX =====================
local function abilityFx(e)
	if not e.position then
		return
	end
	local colors = MYTH_COLORS[e.mythology] or MYTH_COLORS.Event
	local c1, c2 = colors[1], colors[2]
	local pos = e.position
	C.Sound.play("Ability", pos)
	local kind = e.ability
	if kind == "Shockwave" or kind == "Frost" then
		ring(pos - Vector3.new(0, 2.5, 0), c1, e.radius or 25, 0.6)
		ring(pos - Vector3.new(0, 2, 0), c2, (e.radius or 25) * 0.7, 0.45)
		if e.mythology == "Greek" or e.mythology == "Event" then
			for _ = 1, 3 do
				lightning(pos + Vector3.new(math.random(-8, 8), 40, math.random(-8, 8)), pos + Vector3.new(math.random(-6, 6), -2, math.random(-6, 6)), c1)
			end
		elseif e.mythology == "Norse" then
			for i = 1, 6 do
				local a = math.rad(i * 60)
				local shard = part({ Shape = Enum.PartType.Block, Color = c2, Material = Enum.Material.Ice, Transparency = 0.2, Size = Vector3.new(1, 4, 1), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 6, -2, math.sin(a) * 6)) })
				TweenService:Create(shard, TweenInfo.new(0.8), { Transparency = 1, Size = Vector3.new(0.4, 7, 0.4) }):Play()
				Debris:AddItem(shard, 0.9)
			end
		else
			burst(pos, c1, c2, 50, 30, 1.2) -- desert sandstorm
		end
		if (myRoot() and (myRoot().Position - pos).Magnitude < 60) then
			Effects.shake(0.4)
		end
	elseif kind == "SpeedBurst" or kind == "Dash" or kind == "Leap" then
		burst(pos, c1, c2, 25, 15, 0.5)
		ring(pos - Vector3.new(0, 2.5, 0), c1, 8, 0.35)
	elseif kind == "Reveal" then
		ring(pos, c1, math.min(e.radius or 60, 80), 1.2)
		pillar(pos, c2, 30, 0.9)
	elseif kind == "Decoy" then
		burst(pos, c2, Color3.fromRGB(200, 120, 255), 30, 10, 0.8)
	elseif kind == "HatchBoost" or kind == "IncomeBoost" or kind == "TrainBoost" then
		pillar(pos, c1, 26, 0.9)
		burst(pos + Vector3.new(0, 3, 0), c1, Color3.fromRGB(255, 255, 255), 30, 8, 0.5)
	else -- shields, wards, rescue, reach
		local bubble = part({ Shape = Enum.PartType.Ball, Color = c1, Material = Enum.Material.ForceField, Transparency = 0.2, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(pos) })
		TweenService:Create(bubble, TweenInfo.new(0.6), { Size = Vector3.new(9, 9, 9), Transparency = 1 }):Play()
		Debris:AddItem(bubble, 0.7)
	end
end

-- ===================== REVEAL HIGHLIGHTS =====================
local function reveal(data)
	local root = myRoot()
	if not root then
		return
	end
	local highlights = {}
	local function mark(model: Instance, color: Color3)
		local h = Instance.new("Highlight")
		h.FillColor = color
		h.OutlineColor = Color3.new(1, 1, 1)
		h.FillTransparency = 0.45
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = model
		table.insert(highlights, h)
	end
	local filter = data.filter
	if filter ~= "guardians" then
		for _, egg in CollectionService:GetTagged("WorldEgg") do
			local pp = egg.PrimaryPart
			if pp and (pp.Position - root.Position).Magnitude <= data.radius then
				local v = egg:GetAttribute("Variant")
				local ok = filter == "all" or (filter == "rare" and v ~= "normal") or (filter == "special" and (v == "special" or v == "event"))
				if ok then
					mark(egg, v == "special" and Color3.fromRGB(255, 240, 120) or (v == "event" and Color3.fromRGB(255, 120, 220) or Color3.fromRGB(120, 255, 160)))
				end
			end
		end
	end
	if filter == "all" or filter == "guardians" then
		for _, g in Workspace.Runtime.Guardians:GetChildren() do
			local pp = g.PrimaryPart
			if pp and (pp.Position - root.Position).Magnitude <= data.radius then
				mark(g, Color3.fromRGB(255, 70, 70))
			end
		end
	end
	task.delay(data.duration, function()
		for _, h in highlights do
			h:Destroy()
		end
	end)
	C.Notifications.toast("Info", "Visão divina", #highlights .. " alvo(s) revelado(s)")
end

-- ===================== WORLD ANIMATION LOOP =====================
local function updateIncubators(now: number, root: BasePart?)
	for _, egg in CollectionService:GetTagged("IncubatingEgg") do
		local pp = egg.PrimaryPart
		if pp and (not root or (pp.Position - root.Position).Magnitude < 140) then
			local hatchAt = egg:GetAttribute("HatchAt") or now
			local duration = math.max(1, egg:GetAttribute("Duration") or 1)
			local left = hatchAt - now
			local timer = pp:FindFirstChild("Timer")
			if timer then
				local label = timer:FindFirstChild("Time")
				local bar = timer:FindFirstChild("BarBg") and timer.BarBg:FindFirstChild("Bar")
				if egg:GetAttribute("Ready") then
					label.Text = "PRONTO! (sem espaço)"
					label.TextColor3 = Color3.fromRGB(255, 170, 60)
				elseif left > 0 then
					label.Text = NF.time(left)
					label.TextColor3 = Color3.new(1, 1, 1)
				else
					label.Text = "Chocando..."
				end
				if bar then
					bar.Size = UDim2.fromScale(math.clamp(1 - left / duration, 0, 1), 1)
				end
			end
			-- wobble near the end
			local base = egg:GetAttribute("BasePivot")
			if not base then
				egg:SetAttribute("BasePivot", egg:GetPivot())
				base = egg:GetPivot()
			end
			local frac = left / duration
			if frac < 0.2 and not lowVfx then
				local amp = (0.2 - frac) * 0.6
				egg:PivotTo(base * CFrame.Angles(0, 0, math.sin(now * 14) * amp))
			end
		end
	end
end

local function updatePets(now: number, root: BasePart?)
	if not root then
		return
	end
	for _, pet in CollectionService:GetTagged("PetDisplay") do
		local pp = pet.PrimaryPart
		if pp and (pp.Position - root.Position).Magnitude < 90 then
			local base = pet:GetAttribute("BasePivot")
			if not base then
				pet:SetAttribute("BasePivot", pet:GetPivot())
				base = pet:GetPivot()
			end
			local seed = (pp.Position.X + pp.Position.Z) * 0.3
			pet:PivotTo(base * CFrame.new(0, math.abs(math.sin(now * 2 + seed)) * 0.4, 0) * CFrame.Angles(0, math.sin(now * 0.7 + seed) * 0.35, 0))
		end
	end
	for _, m in CollectionService:GetTagged("RainbowModel") do
		local pp = m.PrimaryPart
		if pp and (pp.Position - root.Position).Magnitude < 90 and not lowVfx then
			local hue = (now * 0.25) % 1
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 1 and not string.find(d.Name, "Eye") then
					d.Color = Color3.fromHSV((hue + (d.Size.X * 0.05)) % 1, 0.6, 1)
				end
			end
		end
	end
end

local function updateTreadmills(now: number, root: BasePart?)
	local bases = Workspace:FindFirstChild("Bases")
	if not bases or not root then
		return
	end
	for _, base in bases:GetChildren() do
		local tm = base:FindFirstChild("Visuals") and base.Visuals:FindFirstChild("Treadmill")
		if tm and tm.PrimaryPart and (tm.PrimaryPart.Position - root.Position).Magnitude < 120 then
			local belt = tm:FindFirstChild("Belt")
			if belt then
				for i = 1, 7 do
					local s = tm:FindFirstChild("Stripe" .. i)
					if s then
						local z = ((i / 7) + now * 0.18) % 1
						s.CFrame = belt.CFrame * CFrame.new(0, 0.18, -belt.Size.Z / 2 + z * belt.Size.Z)
					end
				end
			end
			for _, r in tm:GetChildren() do
				if CollectionService:HasTag(r, "SpinRing") then
					r.CFrame = r.CFrame * CFrame.Angles(math.rad(1.5), 0, 0)
				end
			end
		end
	end
end

local guardianIcons = {}
local function updateGuardians()
	for _, g in Workspace.Runtime.Guardians:GetChildren() do
		local head = g.PrimaryPart
		if head then
			local bb = guardianIcons[g]
			if not bb then
				bb = Instance.new("BillboardGui")
				bb.Size = UDim2.fromOffset(60, 60)
				bb.StudsOffset = Vector3.new(0, 12, 0)
				bb.MaxDistance = 110
				bb.LightInfluence = 0
				bb.AlwaysOnTop = true
				local l = Kit.label({ Text = "", Parent = bb, stroke = false })
				l.Name = "Icon"
				local nameL = Kit.label({ Text = g:GetAttribute("GuardianName") or "", Parent = bb, Size = UDim2.new(3, 0, 0.4, 0), Position = UDim2.new(-1, 0, 1, 0), MaxTextSize = 16, TextColor3 = Color3.fromRGB(255, 150, 150) })
				nameL.Name = "Name"
				bb.Parent = head
				guardianIcons[g] = bb
			end
			local state = g:GetAttribute("State")
			local icon = (g:GetAttribute("Stunned") and "💫") or (state == "Sleeping" and "💤") or (state == "Detecting" and "❗") or ((state == "Chasing" or state == "Attacking") and "😡") or (state == "Observing" and "👀") or ""
			bb.Icon.Text = icon
		end
	end
	for g, bb in guardianIcons do
		if not g.Parent then
			bb:Destroy()
			guardianIcons[g] = nil
		end
	end
end

local alarmLights = {}
local domes = {}
local function updateBases(now: number)
	local bases = Workspace:FindFirstChild("Bases")
	if not bases then
		return
	end
	for _, base in bases:GetChildren() do
		local anchor = base.PrimaryPart
		if anchor then
			local alarm = base:GetAttribute("Alarm") == true
			local light = alarmLights[base]
			if alarm and not light then
				local p = part({ Transparency = 1, Size = Vector3.one, CFrame = anchor.CFrame * CFrame.new(0, 14, 0) })
				local pl = Instance.new("PointLight")
				pl.Color = Color3.fromRGB(255, 40, 40)
				pl.Range = 50
				pl.Parent = p
				alarmLights[base] = p
				light = p
			elseif not alarm and light then
				light:Destroy()
				alarmLights[base] = nil
				light = nil
			end
			if light then
				light.PointLight.Brightness = 3 + math.sin(now * 12) * 3
			end
			local protected = base:GetAttribute("Protected") == true and base:GetAttribute("Owner") ~= nil
			local dome = domes[base]
			if protected and not dome then
				local size = base:FindFirstChild("Region") and base.Region.Size or Vector3.new(76, 16, 70)
				dome = part({ Shape = Enum.PartType.Ball, Material = Enum.Material.ForceField, Color = Color3.fromRGB(120, 200, 255), Transparency = 0.3, Size = Vector3.new(size.X * 1.1, size.X * 0.6, size.X * 1.1), CFrame = anchor.CFrame })
				domes[base] = dome
			elseif not protected and dome then
				dome:Destroy()
				domes[base] = nil
			end
		end
	end
end

local trapTweened = {}
local function updateTraps()
	for _, trap in Workspace.Runtime.Traps:GetChildren() do
		if trap:GetAttribute("Triggered") and not trapTweened[trap] then
			trapTweened[trap] = true
			for _, d in trap:GetChildren() do
				if d:IsA("BasePart") and d:GetAttribute("Angle") then
					local a = d:GetAttribute("Angle")
					TweenService:Create(d, TweenInfo.new(0.12), { CFrame = d.CFrame * CFrame.new(-math.cos(a) * 0.9 * 0, 0, 0) * CFrame.Angles(math.rad(-70), 0, 0) }):Play()
				end
			end
		end
	end
	for trap in trapTweened do
		if not trap.Parent then
			trapTweened[trap] = nil
		end
	end
end

local coinTimer = 0
local function coinPops(dt: number)
	coinTimer += dt
	if coinTimer < 3.5 then
		return
	end
	coinTimer = 0
	local d = C.State.get()
	if not d or not d.baseIndex then
		return
	end
	local base = Workspace.Bases:FindFirstChild("Base_" .. d.baseIndex)
	if not base then
		return
	end
	local pets = base.PetDisplays:GetChildren()
	for i = 1, math.min(3, #pets) do
		local pet = pets[math.random(1, #pets)]
		local pp = pet.PrimaryPart
		local inc = pet:GetAttribute("Income") or 0
		if pp and inc > 0 then
			floatingText(pp.Position + Vector3.new(0, 4, 0), "+" .. NF.format(inc * 3.5), Color3.fromRGB(255, 215, 70))
		end
		task.wait(0.15)
	end
end

function Effects.setQuality(quality: string)
	lowVfx = quality == "Low"
	for _, pe in CollectionService:GetTagged("VFX") do
		if pe:IsA("ParticleEmitter") then
			pe.Enabled = not lowVfx
		end
	end
end

function Effects.setShake(on: boolean)
	shakeEnabled = on
end

function Effects.start()
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "SAG_ClientFX"
	fxFolder.Parent = Workspace
	CollectionService:GetInstanceAddedSignal("VFX"):Connect(function(pe)
		if lowVfx and pe:IsA("ParticleEmitter") then
			pe.Enabled = false
		end
	end)

	Net.listen("Effect", function(e)
		local kind = e.kind
		if kind == "HatchBurst" and e.position then
			local col = Kit.rarityColor(e.rarity)
			burst(e.position + Vector3.new(0, 2, 0), col, Color3.new(1, 1, 1), 40, 25, 0.8)
			ring(e.position, col, 10, 0.6)
			if e.rarity == "Mythic" or e.rarity == "Secret" or e.rarity == "Eternal" or e.rarity == "Divine" then
				pillar(e.position, col, 60, 1.4)
				burst(e.position + Vector3.new(0, 6, 0), col, Color3.fromRGB(255, 255, 255), 80, 40, 1.2)
				if e.owner == player.UserId then
					Effects.shake(1)
				end
			end
		elseif kind == "Ability" then
			abilityFx(e)
		elseif kind == "Pickup" and e.position then
			burst(e.position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 230, 120), nil, 20, 12, 0.4)
			C.Sound.play("Pickup")
		elseif kind == "Deposit" and e.position then
			burst(e.position, Color3.fromRGB(120, 255, 160), nil, 20, 10, 0.4)
			C.Sound.play("Deposit")
		elseif kind == "Collect" then
			local root = myRoot()
			if root then
				floatingText(root.Position + Vector3.new(0, 4, 0), "+" .. NF.format(e.amount) .. " 💰", Color3.fromRGB(255, 215, 70))
				burst(root.Position, Color3.fromRGB(255, 215, 70), nil, 25, 14, 0.5)
			end
			C.Sound.play("Coins")
		elseif kind == "BaseUpgrade" and e.position then
			for i = -2, 2 do
				pillar(e.position + Vector3.new(i * 12, 0, 0), Color3.fromRGB(255, 215, 90), 40, 1.2)
			end
			burst(e.position + Vector3.new(0, 8, 0), Color3.fromRGB(255, 215, 90), Color3.new(1, 1, 1), 60, 30, 1)
			C.Sound.play("Unlock")
		elseif kind == "TrapSnap" and e.position then
			burst(e.position + Vector3.new(0, 1, 0), Color3.fromRGB(220, 220, 230), nil, 15, 10, 0.3)
			C.Sound.play("Trap", e.position)
		elseif kind == "GuardianSlam" and e.position then
			ring(e.position - Vector3.new(0, 4, 0), Color3.fromRGB(200, 170, 130), 14, 0.4)
			local root = myRoot()
			if root and (root.Position - e.position).Magnitude < 40 then
				Effects.shake(0.6)
			end
			C.Sound.play("GuardianAttack", e.position)
		elseif kind == "Alarm" then
			Effects.shake(0.3)
		elseif kind == "Unlock" then
			local root = myRoot()
			if root then
				pillar(root.Position, Color3.fromRGB(180, 120, 255), 50, 1.2)
			end
			C.Sound.play("Unlock")
		end
	end)

	Net.listen("Knockback", function(velocity: Vector3)
		local root = myRoot()
		if root then
			root.AssemblyLinearVelocity = velocity
		end
	end)

	Net.listen("Trapped", function(seconds: number)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			C.Notifications.toast("Alarm", "Preso!", "Livre em " .. seconds .. "s")
		end
		Effects.shake(0.5)
	end)

	Net.listen("Reveal", reveal)

	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		-- camera shake
		local now = os.clock()
		if now < shakeUntil then
			local m = shakeIntensity * (shakeUntil - now)
			camera.CFrame = camera.CFrame * CFrame.Angles(math.rad((math.random() - 0.5) * m), math.rad((math.random() - 0.5) * m), 0)
		else
			shakeIntensity = 0
		end
		acc += dt
		if acc >= 1 / 20 then
			local step = acc
			acc = 0
			local root = myRoot()
			local serverNow = C.State.now()
			updatePets(now, root)
			updateTreadmills(now, root)
			if math.floor(now * 5) ~= math.floor((now - step) * 5) then
				updateIncubators(serverNow, root)
				updateGuardians()
				updateBases(now)
				updateTraps()
			end
			task.spawn(coinPops, step)
		end
	end)
end

return Effects
