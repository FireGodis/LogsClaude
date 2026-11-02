--!strict
-- Cutscene 3D de abertura: câmera em órbita ao redor do Cavaleiro, com animação
-- própria (ajoelhado -> levanta -> saca o Prego), legendas e barras de cinema.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(script.Parent.Audio)
local CameraRig = require(script.Parent.CameraRig)
local CombatFx = require(script.Parent.CombatFx)
local KnightAnim = require(script.Parent.KnightAnim)
local Movement = require(script.Parent.Movement)

local Cutscene = {}

type Key = { t: number, pos: Vector3, look: Vector3, fov: number }
type Caption = { from: number, to: number, text: string }

local KEYS: { Key } = {
	{ t = 0.0, pos = Vector3.new(18, 11, 34), look = Vector3.new(0, 4.5, 0), fov = 56 },
	{ t = 2.8, pos = Vector3.new(7, 2.6, 14), look = Vector3.new(0.6, 2.4, 0), fov = 42 },
	{ t = 4.8, pos = Vector3.new(-3.5, 3.5, 9.5), look = Vector3.new(0.4, 3.7, 0), fov = 33 },
	{ t = 6.6, pos = Vector3.new(-9, 4.2, 19), look = Vector3.new(0.2, 3.6, 0), fov = 46 },
	{ t = 8.2, pos = Vector3.new(8, 3.6, 21), look = Vector3.new(0.5, 3.5, 0), fov = 50 },
}
local BLEND_END = 9.8
local CAPTIONS: { Caption } = {
	{ from = 0.9, to = 3.9, text = "Lá embaixo, o silêncio ainda canta." },
	{ from = 5.0, to = 7.6, text = "E alguém precisa responder." },
}

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function lerp(a: number, b: number, x: number): number
	return a + (b - a) * math.clamp(x, 0, 1)
end

-- Sequência do cavaleiro: ajoelhado, ergue a cabeça, levanta, saca e corta.
local function poseAt(t: number, out: { [string]: { x: number, y: number, r: number } })
	local head, body, cloak = out.head, out.body, out.cloak
	local armF, armB, legF, legB = out.armF, out.armB, out.legF, out.legB
	local nail = out.nail
	if not (head and body and cloak and armF and armB and legF and legB and nail) then
		return
	end
	local breath = math.sin(t * 1.6)
	local lift = smooth((t - 2.8) / 1.8)
	local kneel = 1 - smooth((t - 4.6) / 1.6)

	head.y = kneel * (-0.55 - 1.3 * (1 - lift)) + breath * 0.04
	head.x = kneel * (0.1 + 0.35 * (1 - lift))
	body.y = kneel * -1.05
	body.x = kneel * 0.25 * (1 - lift * 0.6)
	legF.r = kneel * 1.35
	legB.r = kneel * -1.55
	armF.r = kneel * 0.5
	armB.r = kneel * 0.25
	cloak.r = kneel * 0.2 + math.sin(t * 1.3) * 0.05

	if t >= 6.4 then
		local draw = smooth((t - 6.4) / 0.7)
		if t < 7.3 then
			armF.r = lerp(armF.r, 3.0, draw)
		elseif t < 7.5 then
			armF.r = lerp(3.0, 0.45, (t - 7.3) / 0.2)
			body.x += 0.3
			head.x += 0.4
		else
			armF.r = lerp(0.45, 0.0, smooth((t - 8.4) / 0.9))
		end
	end
	nail.x, nail.y, nail.r = armF.x, armF.y, armF.r
end

local function cameraAt(t: number): (CFrame, number, Vector3)
	local first = KEYS[1] :: Key
	local last = KEYS[#KEYS] :: Key
	local from, to = first, last
	for index = 1, #KEYS - 1 do
		local a, b = KEYS[index] :: Key, KEYS[index + 1] :: Key
		if t >= a.t and t <= b.t then
			from, to = a, b
			break
		end
	end
	local alpha = if t >= last.t then 1 else smooth((t - from.t) / math.max(to.t - from.t, 0.001))
	return CFrame.new(from.pos:Lerp(to.pos, alpha)), lerp(from.fov, to.fov, alpha), from.look:Lerp(to.look, alpha)
end

function Cutscene.play(done: () -> ())
	local player = Players.LocalPlayer
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not root or not root:IsA("BasePart") then
		done()
		return
	end
	local releaseControls = Movement.acquireControlLock()
	local origin = root.Position
	local elapsed = 0.0
	local finished = false
	local slashed, flashed = false, false

	-- Barras de cinema e legendas.
	local gui = Instance.new("ScreenGui")
	gui.Name = "RK_Cutscene"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 70
	gui.Parent = player:WaitForChild("PlayerGui")
	local function bar(top: boolean): Frame
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0, if top then 0 else 1)
		frame.Position = UDim2.fromScale(0, if top then 0 else 1)
		frame.Size = UDim2.fromScale(1, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BorderSizePixel = 0
		frame.Parent = gui
		return frame
	end
	local topBar, bottomBar = bar(true), bar(false)
	TweenService:Create(topBar, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, 0.12) }):Play()
	TweenService:Create(bottomBar, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, 0.12) }):Play()

	local caption = Instance.new("TextLabel")
	caption.AnchorPoint = Vector2.new(0.5, 0.5)
	caption.Position = UDim2.fromScale(0.5, 0.94)
	caption.Size = UDim2.new(0.8, 0, 0, 40)
	caption.BackgroundTransparency = 1
	caption.Font = Enum.Font.Garamond
	caption.TextSize = 34
	caption.TextColor3 = Color3.fromRGB(236, 235, 228)
	caption.TextTransparency = 1
	caption.Text = ""
	caption.ZIndex = 5
	caption.Parent = gui

	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(1, 1)
	hint.Position = UDim2.new(1, -24, 1, -14)
	hint.Size = UDim2.fromOffset(240, 24)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Garamond
	hint.TextSize = 20
	hint.TextColor3 = Color3.fromRGB(150, 160, 185)
	hint.TextTransparency = 1
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = if UserInputService.TouchEnabled then "toque para pular" else "[Espaço] pular"
	hint.ZIndex = 5
	hint.Parent = gui
	task.delay(1.5, function()
		TweenService:Create(hint, TweenInfo.new(0.6), { TextTransparency = 0.2 }):Play()
	end)

	local shownCaption: Caption? = nil
	local pose = {
		apply = function(out: { [string]: { x: number, y: number, r: number } })
			poseAt(elapsed, out)
		end,
		facing = 1,
		nail = false,
		glow = false,
	}
	KnightAnim.setCinematic(pose)

	local inputConnection: RBXScriptConnection? = nil
	local destroyConnection: RBXScriptConnection? = nil
	local function finish()
		if finished then
			return
		end
		finished = true
		releaseControls()
		CameraRig.setOverride(nil)
		KnightAnim.setCinematic(nil)
		CameraRig.snap()
		if inputConnection then
			inputConnection:Disconnect()
		end
		if destroyConnection then
			destroyConnection:Disconnect()
		end
		TweenService:Create(topBar, TweenInfo.new(0.7), { Size = UDim2.fromScale(1, 0) }):Play()
		TweenService:Create(bottomBar, TweenInfo.new(0.7), { Size = UDim2.fromScale(1, 0) }):Play()
		TweenService:Create(caption, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(hint, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.delay(0.9, function()
			gui:Destroy()
		end)
		done()
	end

	destroyConnection = character.Destroying:Connect(finish)
	inputConnection = UserInputService.InputBegan:Connect(function(input: InputObject)
		if elapsed < 1.5 or elapsed > 8.2 then
			return
		end
		local key = input.KeyCode
		if
			key == Enum.KeyCode.Space
			or key == Enum.KeyCode.Return
			or key == Enum.KeyCode.ButtonA
			or input.UserInputType == Enum.UserInputType.Touch
		then
			elapsed = 8.2
			pose.nail = false
		end
	end)

	CameraRig.setOverride(function(dt: number)
		elapsed += dt

		-- Eventos da cena.
		pose.glow = elapsed > 4.2 and elapsed < 5.0
		pose.nail = elapsed > 6.4 and elapsed < 8.8
		if elapsed >= 4.2 and not flashed then
			flashed = true
			Audio.play("pulse")
		end
		if elapsed >= 7.3 and not slashed then
			slashed = true
			Audio.play("swing")
			CombatFx.slash(character, "F", 1)
			CameraRig.shake(0.5, 0.25)
		end

		-- Legendas.
		local wanted: Caption? = nil
		for _, entry in CAPTIONS do
			if elapsed >= entry.from and elapsed <= entry.to then
				wanted = entry
			end
		end
		if wanted ~= shownCaption then
			shownCaption = wanted
			if wanted then
				caption.Text = wanted.text
			end
			TweenService:Create(caption, TweenInfo.new(0.6), { TextTransparency = if wanted then 0 else 1 }):Play()
		end

		-- Câmera: trilho cinematográfico e, no fim, encaixe suave na câmera de jogo.
		local offset, fov, look = cameraAt(elapsed)
		local eye = origin + offset.Position
		local cutCFrame = CFrame.lookAt(eye, origin + look)
		if elapsed >= BLEND_END then
			task.defer(finish)
		end
		if elapsed > KEYS[#KEYS].t then
			local gameplayCFrame, gameplayFov = CameraRig.getGameplay()
			local blend = smooth((elapsed - KEYS[#KEYS].t) / (BLEND_END - KEYS[#KEYS].t))
			return cutCFrame:Lerp(gameplayCFrame, blend), lerp(fov, gameplayFov, blend)
		end
		return cutCFrame, fov
	end)
end

return Cutscene
