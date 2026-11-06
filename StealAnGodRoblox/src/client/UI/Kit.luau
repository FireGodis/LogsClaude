--[[
	Kit — the STEAL AN GOD UI toolkit: themed panels, buttons, labels, cards, tabs, viewports.
	Visual identity: deep celestial navy panels, gold trims, mythology accent colors, chunky
	rounded type (FredokaOne). Everything scales with UIScale for phone/tablet/console/PC.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Kit = {}
local T = GameConfig.Theme
Kit.Theme = T

local clickSound: Sound? = nil

function Kit.new(className: string, props, children)
	local inst = Instance.new(className)
	for k, v in props or {} do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Kit.corner(parent: Instance, radius: number?)
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

function Kit.stroke(parent: Instance, color: Color3?, thickness: number?)
	return Kit.new("UIStroke", { Color = color or T.Gold, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
end

function Kit.textStroke(parent: Instance, thickness: number?)
	return Kit.new("UIStroke", { Color = Color3.fromRGB(20, 12, 40), Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = parent })
end

function Kit.gradient(parent: Instance, c1: Color3, c2: Color3, rotation: number?)
	return Kit.new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rotation or 90, Parent = parent })
end

function Kit.padding(parent: Instance, px: number)
	return Kit.new("UIPadding", { PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px), PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px), Parent = parent })
end

function Kit.label(props)
	local l = Kit.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.Font or T.Font,
		TextColor3 = props.TextColor3 or T.Text,
		TextScaled = props.TextScaled ~= false,
		TextSize = props.TextSize or 18,
		Text = props.Text or "",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
		TextWrapped = true,
		RichText = props.RichText == true,
		ZIndex = props.ZIndex or 1,
		Name = props.Name or "Label",
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	if props.stroke ~= false then
		Kit.textStroke(l, props.strokeThickness or 1.5)
	end
	if props.MaxTextSize then
		Kit.new("UITextSizeConstraint", { MaxTextSize = props.MaxTextSize, Parent = l })
	end
	return l
end

function Kit.playClick()
	if not clickSound then
		clickSound = Instance.new("Sound")
		clickSound.SoundId = GameConfig.Sounds.UIClick
		clickSound.Volume = 0.4
		clickSound.Parent = game:GetService("SoundService")
	end
	if clickSound.SoundId ~= "" and Kit.sfxEnabled ~= false then
		clickSound:Play()
	end
end
Kit.sfxEnabled = true

-- Big glossy button. color = base color.
function Kit.button(props)
	local color = props.color or T.Gold
	local b = Kit.new("TextButton", {
		Name = props.Name or "Button",
		AutoButtonColor = false,
		BackgroundColor3 = color,
		Size = props.Size or UDim2.fromOffset(160, 48),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Text = "",
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	Kit.corner(b, props.radius or 12)
	Kit.gradient(b, color:Lerp(Color3.new(1, 1, 1), 0.25), color:Lerp(Color3.new(0, 0, 0), 0.25))
	Kit.stroke(b, color:Lerp(Color3.new(0, 0, 0), 0.5), 2.5)
	local label = Kit.label({ Text = props.Text or "", Parent = b, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = (props.ZIndex or 1) + 1, MaxTextSize = props.MaxTextSize or 28, Name = "Label" })
	local scale = Kit.new("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	b.Activated:Connect(function()
		Kit.playClick()
		scale.Scale = 0.92
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		if props.onClick then
			props.onClick()
		end
	end)
	return b, label
end

function Kit.setButtonEnabled(b: GuiButton, enabled: boolean, color: Color3?)
	b.Active = enabled
	b.AutoButtonColor = false
	b.BackgroundColor3 = enabled and (color or b.BackgroundColor3) or Color3.fromRGB(90, 90, 110)
	local g = b:FindFirstChildOfClass("UIGradient")
	if g then
		g.Enabled = enabled
	end
end

-- Modal panel with header + close. Returns {frame, content, title, close}
function Kit.panel(screen: Instance, title: string, accent: Color3?, size: UDim2?)
	accent = accent or T.Gold
	local frame = Kit.new("Frame", {
		Name = "Panel_" .. title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = size or UDim2.fromScale(0.62, 0.72),
		BackgroundColor3 = T.Panel,
		Visible = false,
		Parent = screen,
	})
	Kit.new("UISizeConstraint", { MaxSize = Vector2.new(980, 680), MinSize = Vector2.new(320, 260), Parent = frame })
	Kit.corner(frame, 18)
	Kit.stroke(frame, accent, 3)
	Kit.gradient(frame, T.PanelLight, T.Panel, 90)
	local header = Kit.new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = accent, Parent = frame })
	Kit.corner(header, 18)
	Kit.gradient(header, accent:Lerp(Color3.new(1, 1, 1), 0.2), accent:Lerp(Color3.new(0, 0, 0), 0.35))
	-- square off the header bottom
	Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -18), BackgroundColor3 = accent:Lerp(Color3.new(0, 0, 0), 0.3), BorderSizePixel = 0, Parent = header })
	local titleLabel = Kit.label({ Text = title, Parent = header, Size = UDim2.new(1, -120, 0.8, 0), Position = UDim2.new(0, 20, 0.1, 0), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 34, strokeThickness = 2.5 })
	local close = Kit.button({ Text = "✕", color = T.Bad, Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -10, 0, 6), AnchorPoint = Vector2.new(1, 0), Parent = header, ZIndex = 3 })
	local content = Kit.new("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 66), Size = UDim2.new(1, -28, 1, -80), Parent = frame })
	return { frame = frame, content = content, title = titleLabel, close = close }
end

function Kit.scroll(parent: Instance, props)
	local s = Kit.new("ScrollingFrame", {
		Name = props and props.Name or "Scroll",
		BackgroundTransparency = 1,
		Size = props and props.Size or UDim2.fromScale(1, 1),
		Position = props and props.Position or UDim2.new(),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = T.Gold,
		BorderSizePixel = 0,
		Parent = parent,
	})
	return s
end

function Kit.grid(parent: Instance, cellSize: UDim2, padding: number?)
	return Kit.new("UIGridLayout", { CellSize = cellSize, CellPadding = UDim2.fromOffset(padding or 10, padding or 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = parent })
end

function Kit.list(parent: Instance, padding: number?, horizontal: boolean?)
	return Kit.new("UIListLayout", { Padding = UDim.new(0, padding or 8), SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical, HorizontalAlignment = horizontal and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center, VerticalAlignment = horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top, Parent = parent })
end

function Kit.card(parent: Instance, color: Color3?, order: number?)
	local f = Kit.new("Frame", { BackgroundColor3 = T.PanelLight, LayoutOrder = order or 0, Parent = parent })
	Kit.corner(f, 14)
	Kit.stroke(f, color or T.Accent, 2)
	return f
end

-- Tabs bar: returns setTab(name) and container
function Kit.tabs(parent: Instance, names: { string }, onChange, accent: Color3?)
	local bar = Kit.new("Frame", { Name = "Tabs", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = parent })
	Kit.list(bar, 6, true)
	local buttons = {}
	local function set(name)
		for n, b in buttons do
			Kit.setButtonEnabled(b, true, n == name and (accent or T.Gold) or T.PanelLight)
		end
		onChange(name)
	end
	for i, name in names do
		local b = Kit.button({ Text = name, color = T.PanelLight, Size = UDim2.new(1 / #names, -6, 1, 0), LayoutOrder = i, Parent = bar, MaxTextSize = 20, onClick = function()
			set(name)
		end })
		buttons[name] = b
	end
	return set, bar
end

-- ViewportFrame showing a model (cloned). Spins slowly if spin=true.
function Kit.viewport(parent: Instance, model: Model, props)
	local vp = Kit.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = props and props.Size or UDim2.fromScale(1, 1),
		Position = props and props.Position or UDim2.new(),
		LightColor = Color3.fromRGB(255, 245, 230),
		Ambient = Color3.fromRGB(170, 170, 190),
		LightDirection = Vector3.new(-1, -1, -1),
		Parent = parent,
	})
	local world = Kit.new("WorldModel", { Parent = vp })
	model.Parent = world
	local cf, size = model:GetBoundingBox()
	local cam = Kit.new("Camera", { FieldOfView = 40, Parent = vp })
	local dist = size.Magnitude * 1.25 + 1
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.35, dist * 0.25, -dist), cf.Position)
	vp.CurrentCamera = cam
	if props and props.silhouette then
		vp.ImageColor3 = Color3.new(0, 0, 0)
		vp.ImageTransparency = 0.15
	end
	return vp
end

function Kit.autoScale(screen: ScreenGui)
	local scale = Kit.new("UIScale", { Parent = screen })
	local cam = workspace.CurrentCamera
	local function update()
		local v = cam.ViewportSize
		local s = math.min(v.X / 1280, v.Y / 760)
		scale.Scale = math.clamp(s, 0.55, 1.25)
	end
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return scale
end

function Kit.screen(name: string, order: number?): ScreenGui
	local player = Players.LocalPlayer
	local existing = player.PlayerGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local sg = Kit.new("ScreenGui", { Name = name, ResetOnSpawn = false, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = order or 0, Parent = player.PlayerGui })
	return sg
end

function Kit.rarityColor(rarity: string?): Color3
	local Balance = require(ReplicatedStorage.Shared.Config.Balance)
	for _, r in Balance.rarities do
		if r.name == rarity then
			return Color3.fromRGB(r.color[1], r.color[2], r.color[3])
		end
	end
	return Color3.fromRGB(200, 200, 200)
end

function Kit.mythColor(m: string?): Color3
	return (m == "Greek" and T.Greek) or (m == "Norse" and T.Norse) or (m == "Egyptian" and T.Egyptian) or T.Event
end

return Kit
