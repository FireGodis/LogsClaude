--!strict
-- Tela inicial animada: parallax que segue o mouse, brasas flutuantes,
-- título com brilho, botões com hover e ondas no clique.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Audio = require(script.Parent.Audio)

local Menu = {}

local BONE = Color3.fromRGB(236, 235, 228)
local DIM = Color3.fromRGB(140, 152, 182)
local GLOW = Color3.fromRGB(150, 190, 255)
local LANTERN = Color3.fromRGB(255, 214, 140)

local CONTROLS_TEXT = table.concat({
	"Mover  —  A / D  ou  setas",
	"Pular  —  Espaço ou K  (segure para pular mais alto)",
	"Golpe do Prego  —  J ou clique",
	"      para cima: W + golpe     |     para baixo, no ar: S + golpe (rebate nos inimigos)",
	"Dash  —  L ou Shift",
	"Foco (cura)  —  segure F parado, com alma no vaso",
	"Pulso de Eco  —  Q",
	"",
	"Controle: A pular, X golpe, B dash, Y foco, L1 eco.   Celular: botões na tela.",
}, "\n")

type Layer = { frame: Frame, factor: number }
type Mote = { frame: Frame, x: number, y: number, speed: number, sway: number, freq: number, phase: number }

local function tween(object: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local info = TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local created = TweenService:Create(object, info, goal)
	created:Play()
	return created
end

local function round(parent: GuiObject, radius: UDim?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(1, 0)
	corner.Parent = parent
end

local function select(object: GuiObject?)
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = object
	end
end

function Menu.show(onStart: () -> ())
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "RK_Menu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Name = "Fundo"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	bg.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(18, 26, 54), Color3.fromRGB(3, 4, 10))
	gradient.Rotation = 90
	gradient.Parent = bg

	-- Lua: halo pulsante.
	local halos: { Frame } = {}
	for index, spec in { { 560, 0.95 }, { 400, 0.93 }, { 250, 0.9 } } do
		local halo = Instance.new("Frame")
		halo.AnchorPoint = Vector2.new(0.5, 0.5)
		halo.Position = UDim2.fromScale(0.5, 0.22)
		halo.Size = UDim2.fromOffset(spec[1] :: number, spec[1] :: number)
		halo.BackgroundColor3 = Color3.fromRGB(120, 150, 230)
		halo.BackgroundTransparency = spec[2] :: number
		halo.BorderSizePixel = 0
		halo.Parent = bg
		round(halo)
		halos[index] = halo
	end

	-- Camadas de silhuetas com parallax.
	local layers: { Layer } = {}
	local function makeLayer(factor: number, count: number, minH: number, maxH: number, color: Color3, alpha: number, seed: number, minW: number, maxW: number, lanterns: boolean)
		local rng = Random.new(seed)
		local holder = Instance.new("Frame")
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(1.3, 1.2)
		holder.BackgroundTransparency = 1
		holder.Parent = bg
		for index = 1, count do
			local width = rng:NextNumber(minW, maxW)
			local height = rng:NextNumber(minH, maxH)
			local column = Instance.new("Frame")
			column.AnchorPoint = Vector2.new(0.5, 1)
			column.Position = UDim2.fromScale((index - 0.5) / count + rng:NextNumber(-0.3, 0.3) / count, 1)
			column.Size = UDim2.new(0, width, height, 0)
			column.BackgroundColor3 = color
			column.BackgroundTransparency = alpha
			column.BorderSizePixel = 0
			column.Parent = holder
			round(column, UDim.new(0, math.floor(width * 0.5)))
			if lanterns and rng:NextNumber() < 0.45 then
				local halo = Instance.new("Frame")
				halo.AnchorPoint = Vector2.new(0.5, 0.5)
				halo.Position = UDim2.fromScale(0.5, 0.12)
				halo.Size = UDim2.fromOffset(46, 46)
				halo.BackgroundColor3 = LANTERN
				halo.BackgroundTransparency = 0.88
				halo.BorderSizePixel = 0
				halo.Parent = column
				round(halo)
				local flame = Instance.new("Frame")
				flame.AnchorPoint = Vector2.new(0.5, 0.5)
				flame.Position = UDim2.fromScale(0.5, 0.12)
				flame.Size = UDim2.fromOffset(12, 12)
				flame.BackgroundColor3 = LANTERN
				flame.BorderSizePixel = 0
				flame.Parent = column
				round(flame)
			end
		end
		table.insert(layers, { frame = holder, factor = factor })
	end
	makeLayer(0.012, 9, 0.5, 0.85, Color3.fromRGB(26, 36, 70), 0.3, 11, 70, 150, false)
	makeLayer(0.03, 7, 0.38, 0.7, Color3.fromRGB(14, 20, 42), 0.05, 23, 90, 180, true)
	makeLayer(0.06, 5, 0.22, 0.45, Color3.fromRGB(5, 7, 16), 0, 37, 120, 240, false)

	-- Brasas flutuantes.
	local motes: { Mote } = {}
	local moteRng = Random.new(77)
	for _ = 1, 42 do
		local size = moteRng:NextInteger(2, 5)
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Size = UDim2.fromOffset(size, size)
		frame.BackgroundColor3 = if moteRng:NextNumber() < 0.3 then LANTERN else GLOW
		frame.BorderSizePixel = 0
		frame.Parent = bg
		round(frame)
		table.insert(motes, {
			frame = frame,
			x = moteRng:NextNumber(),
			y = moteRng:NextNumber(),
			speed = moteRng:NextNumber(0.012, 0.04),
			sway = moteRng:NextNumber(0.004, 0.02),
			freq = moteRng:NextNumber(0.4, 1.4),
			phase = moteRng:NextNumber(0, 6.28),
		})
	end
	local moteSpeed = 1

	-- Brilho que acompanha o mouse.
	local cursorGlow = Instance.new("Frame")
	cursorGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	cursorGlow.Size = UDim2.fromOffset(120, 120)
	cursorGlow.BackgroundColor3 = GLOW
	cursorGlow.BackgroundTransparency = 0.9
	cursorGlow.BorderSizePixel = 0
	cursorGlow.ZIndex = 8
	cursorGlow.Parent = bg
	round(cursorGlow)

	local content = Instance.new("CanvasGroup")
	content.Name = "Conteudo"
	content.Size = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.ZIndex = 5
	content.Parent = bg

	-- Título: revelação suave + brilho que varre as letras.
	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.27)
	title.Size = UDim2.fromScale(0.86, 0.2)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Garamond
	title.TextScaled = true
	title.Text = Config.GameTitle
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextTransparency = 1
	title.Parent = content
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 96
	limit.Parent = title
	local titleScale = Instance.new("UIScale")
	titleScale.Scale = 1.14
	titleScale.Parent = title
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(110, 140, 210)
	titleStroke.Thickness = 1.5
	titleStroke.Transparency = 1
	titleStroke.Parent = title
	local glint = Instance.new("UIGradient")
	local base = Color3.fromRGB(196, 204, 222)
	glint.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, base),
		ColorSequenceKeypoint.new(0.42, base),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.58, base),
		ColorSequenceKeypoint.new(1, base),
	})
	glint.Offset = Vector2.new(-1, 0)
	glint.Parent = title

	local divider = Instance.new("Frame")
	divider.AnchorPoint = Vector2.new(0.5, 0.5)
	divider.Position = UDim2.fromScale(0.5, 0.405)
	divider.Size = UDim2.new(0, 0, 0, 2)
	divider.BackgroundColor3 = BONE
	divider.BorderSizePixel = 0
	divider.Parent = content
	local dividerFade = Instance.new("UIGradient")
	dividerFade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	dividerFade.Parent = divider

	local subtitle = Instance.new("TextLabel")
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.fromScale(0.5, 0.43)
	subtitle.Size = UDim2.new(0.8, 0, 0, 32)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.Garamond
	subtitle.TextSize = 24
	subtitle.TextColor3 = DIM
	subtitle.TextTransparency = 1
	subtitle.Text = "Desça. A escuridão guarda o seu nome."
	subtitle.Parent = content

	local buttons = Instance.new("Frame")
	buttons.Name = "Botoes"
	buttons.Position = UDim2.new(0.5, -170, 0.58, 0)
	buttons.Size = UDim2.fromOffset(340, 140)
	buttons.BackgroundTransparency = 1
	buttons.Parent = content
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = buttons

	-- Ondas no clique.
	local function ripple(position: Vector2)
		for index = 0, 1 do
			task.delay(index * 0.09, function()
				local wave = Instance.new("Frame")
				wave.AnchorPoint = Vector2.new(0.5, 0.5)
				wave.Position = UDim2.fromOffset(position.X, position.Y)
				wave.Size = UDim2.fromOffset(10, 10)
				wave.BackgroundTransparency = 1
				wave.ZIndex = 20
				wave.Parent = gui
				round(wave)
				local stroke = Instance.new("UIStroke")
				stroke.Color = if index == 0 then BONE else GLOW
				stroke.Thickness = 3 - index
				stroke.Transparency = 0.1
				stroke.Parent = wave
				local size = 520 + index * 180
				tween(wave, 0.8, { Size = UDim2.fromOffset(size, size) }, Enum.EasingStyle.Quint)
				tween(stroke, 0.8, { Transparency = 1 })
				task.delay(0.9, function()
					wave:Destroy()
				end)
			end)
		end
	end

	local buttonEntries: { { holder: Frame, label: TextButton } } = {}
	local function makeButton(text: string, order: number, callback: () -> ()): TextButton
		local holder = Instance.new("Frame")
		holder.Name = "Item" .. order
		holder.LayoutOrder = order
		holder.Size = UDim2.fromOffset(340, 58)
		holder.BackgroundTransparency = 1
		holder.Parent = buttons
		local scale = Instance.new("UIScale")
		scale.Parent = holder

		local halo = Instance.new("Frame")
		halo.Size = UDim2.fromScale(1, 1)
		halo.BackgroundColor3 = GLOW
		halo.BackgroundTransparency = 1
		halo.BorderSizePixel = 0
		halo.Parent = holder
		round(halo, UDim.new(0, 29))

		local function ornament(side: number): Frame
			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(if side < 0 then 1 else 0, 0.5)
			line.Position = UDim2.new(0.5, side * 120, 0.5, 0)
			line.Size = UDim2.fromOffset(0, 2)
			line.BackgroundColor3 = BONE
			line.BackgroundTransparency = 1
			line.BorderSizePixel = 0
			line.Parent = holder
			return line
		end
		local leftLine, rightLine = ornament(-1), ornament(1)

		local label = Instance.new("TextButton")
		label.Name = "Botao" .. order
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Garamond
		label.TextSize = 36
		label.TextColor3 = DIM
		label.TextTransparency = 1
		label.Text = text
		label.AutoButtonColor = false
		label.Parent = holder

		local function hover(on: boolean)
			tween(label, 0.18, { TextColor3 = if on then Color3.fromRGB(255, 255, 255) else DIM })
			tween(halo, 0.25, { BackgroundTransparency = if on then 0.9 else 1 })
			tween(scale, 0.22, { Scale = if on then 1.08 else 1 }, Enum.EasingStyle.Back)
			tween(leftLine, 0.28, { Size = UDim2.fromOffset(if on then 46 else 0, 2), BackgroundTransparency = if on then 0.15 else 1 })
			tween(rightLine, 0.28, { Size = UDim2.fromOffset(if on then 46 else 0, 2), BackgroundTransparency = if on then 0.15 else 1 })
			if on then
				Audio.play("hover")
			end
		end
		label.MouseEnter:Connect(function()
			hover(true)
		end)
		label.MouseLeave:Connect(function()
			hover(false)
		end)
		label.SelectionGained:Connect(function()
			hover(true)
		end)
		label.SelectionLost:Connect(function()
			hover(false)
		end)
		label.MouseButton1Down:Connect(function()
			tween(scale, 0.08, { Scale = 0.95 })
		end)
		label.Activated:Connect(function()
			tween(scale, 0.2, { Scale = 1.08 }, Enum.EasingStyle.Back)
			Audio.play("click")
			local at = if UserInputService.MouseEnabled
				then UserInputService:GetMouseLocation()
				else label.AbsolutePosition + label.AbsoluteSize / 2
			ripple(at)
			callback()
		end)
		table.insert(buttonEntries, { holder = holder, label = label })
		return label
	end

	-- Painel de controles.
	local panel = Instance.new("Frame")
	panel.Name = "PainelControles"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.7, 0.62)
	panel.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.ZIndex = 12
	panel.Parent = gui
	local panelLimit = Instance.new("UISizeConstraint")
	panelLimit.MaxSize = Vector2.new(820, 440)
	panelLimit.Parent = panel
	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = BONE
	panelStroke.Transparency = 0.5
	panelStroke.Parent = panel
	local controlsLabel = Instance.new("TextLabel")
	controlsLabel.Position = UDim2.fromOffset(24, 20)
	controlsLabel.Size = UDim2.new(1, -48, 1, -90)
	controlsLabel.BackgroundTransparency = 1
	controlsLabel.Font = Enum.Font.Garamond
	controlsLabel.TextSize = 24
	controlsLabel.TextColor3 = BONE
	controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
	controlsLabel.TextYAlignment = Enum.TextYAlignment.Top
	controlsLabel.TextWrapped = true
	controlsLabel.Text = CONTROLS_TEXT
	controlsLabel.ZIndex = 13
	controlsLabel.Parent = panel
	local back = Instance.new("TextButton")
	back.AnchorPoint = Vector2.new(0.5, 1)
	back.Position = UDim2.new(0.5, 0, 1, -14)
	back.Size = UDim2.fromOffset(200, 44)
	back.BackgroundTransparency = 1
	back.Font = Enum.Font.Garamond
	back.TextSize = 30
	back.TextColor3 = DIM
	back.Text = "Voltar"
	back.ZIndex = 13
	back.Parent = panel
	back.MouseEnter:Connect(function()
		tween(back, 0.15, { TextColor3 = BONE })
		Audio.play("hover")
	end)
	back.MouseLeave:Connect(function()
		tween(back, 0.15, { TextColor3 = DIM })
	end)

	-- Fade final para a cena.
	local fade = Instance.new("Frame")
	fade.Name = "FadeFinal"
	fade.Size = UDim2.fromScale(1, 1)
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.BackgroundTransparency = 1
	fade.BorderSizePixel = 0
	fade.ZIndex = 30
	fade.Active = false
	fade.Parent = gui

	local starting = false
	local connection: RBXScriptConnection? = nil
	local function startGame()
		if starting then
			return
		end
		starting = true
		select(nil)
		-- Tudo "sobe": brasas aceleram e o parallax avança em direção à câmera.
		tween(content, 0.7, { GroupTransparency = 1 })
		tween(cursorGlow, 0.5, { BackgroundTransparency = 1 })
		for _, layer in layers do
			local scale = Instance.new("UIScale")
			scale.Parent = layer.frame
			tween(scale, 2.0, { Scale = 1.5 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
		task.spawn(function()
			for step = 1, 20 do
				moteSpeed = 1 + step * 0.5
				task.wait(0.07)
			end
		end)
		task.wait(1.0)
		tween(fade, 0.9, { BackgroundTransparency = 0 })
		task.wait(1.0)
		bg.Visible = false
		if connection then
			connection:Disconnect()
			connection = nil
		end
		onStart()
		task.wait(0.4)
		tween(fade, 1.6, { BackgroundTransparency = 1 })
		task.wait(1.7)
		gui:Destroy()
	end

	local play = makeButton("Iniciar Jornada", 1, function()
		task.spawn(startGame)
	end)
	makeButton("Controles", 2, function()
		panel.Visible = true
		select(back)
	end)
	back.Activated:Connect(function()
		Audio.play("click")
		panel.Visible = false
		select(play)
	end)

	-- Animação contínua.
	local startedAt = os.clock()
	local mouseSmooth = Vector2.zero
	local cursorSmooth = UserInputService:GetMouseLocation()
	connection = RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock() - startedAt
		local viewport = gui.AbsoluteSize
		if viewport.X < 1 or viewport.Y < 1 then
			return
		end
		local mouse = UserInputService:GetMouseLocation()
		local target = Vector2.new(mouse.X / viewport.X - 0.5, mouse.Y / viewport.Y - 0.5)
		mouseSmooth += (target - mouseSmooth) * (1 - math.exp(-dt * 3.5))
		cursorSmooth += (mouse - cursorSmooth) * (1 - math.exp(-dt * 9))
		cursorGlow.Position = UDim2.fromOffset(cursorSmooth.X, cursorSmooth.Y)

		for _, layer in layers do
			local drift = math.sin(now * 0.2 + layer.factor * 40) * layer.factor * viewport.X * 0.12
			layer.frame.Position = UDim2.new(
				0.5,
				-mouseSmooth.X * layer.factor * viewport.X + drift,
				0.5,
				-mouseSmooth.Y * layer.factor * viewport.Y * 0.6
			)
		end
		for index, halo in halos do
			halo.BackgroundTransparency = 0.88 + index * 0.02 + math.sin(now * 0.7 + index) * 0.015
		end
		for _, mote in motes do
			mote.y -= mote.speed * dt * moteSpeed
			if mote.y < -0.05 then
				mote.y = 1.05
				mote.x = math.random()
			end
			mote.frame.Position = UDim2.fromScale(mote.x + math.sin(now * mote.freq + mote.phase) * mote.sway, mote.y)
			mote.frame.BackgroundTransparency = 0.4 + 0.45 * (0.5 + 0.5 * math.sin(now * 2 + mote.phase))
		end
	end)

	-- Entrada em sequência.
	tween(titleScale, 2.4, { Scale = 1 }, Enum.EasingStyle.Quint)
	tween(title, 1.8, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
	tween(titleStroke, 2.4, { Transparency = 0.55 })
	tween(divider, 1.6, { Size = UDim2.new(0.34, 0, 0, 2) }, Enum.EasingStyle.Quint)
	task.delay(1.2, function()
		tween(subtitle, 1.2, { TextTransparency = 0 })
	end)
	for index, entry in buttonEntries do
		task.delay(1.5 + index * 0.18, function()
			entry.holder.Position = UDim2.new(0, 0, 0, 14)
			tween(entry.label, 0.7, { TextTransparency = 0 })
		end)
	end
	task.spawn(function()
		task.wait(2.2)
		while gui.Parent and not starting do
			glint.Offset = Vector2.new(-1, 0)
			tween(glint, 2.2, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(7)
		end
	end)

	select(play)
	Audio.startMenu()
end

return Menu
