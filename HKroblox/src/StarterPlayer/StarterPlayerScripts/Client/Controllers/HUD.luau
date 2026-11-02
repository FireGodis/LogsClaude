--!strict
-- Interface em jogo: máscaras (vida), vaso de alma, cacos, avisos e barra de chefe.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(script.Parent.Net)

local HUD = {}

local player = Players.LocalPlayer
local BONE = Color3.fromRGB(236, 235, 228)
local INK = Color3.fromRGB(13, 13, 21)
local SOUL = Color3.fromRGB(214, 232, 255)

type MaskIcon = { holder: Frame, body: Frame, eyes: { Frame }, scale: UIScale }

local gui = Instance.new("ScreenGui")
gui.Name = "RK_HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent: GuiObject, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function attrNumber(name: string, default: number): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- Vaso de alma.
local vessel = Instance.new("Frame")
vessel.Name = "VasoDeAlma"
vessel.Position = UDim2.fromOffset(26, 22)
vessel.Size = UDim2.fromOffset(78, 78)
vessel.BackgroundColor3 = INK
vessel.BackgroundTransparency = 0.05
vessel.ClipsDescendants = true
vessel.Parent = gui
corner(vessel, UDim.new(1, 0))
do
	local stroke = Instance.new("UIStroke")
	stroke.Color = BONE
	stroke.Thickness = 3
	stroke.Parent = vessel
end
local fill = Instance.new("Frame")
fill.Name = "Alma"
fill.AnchorPoint = Vector2.new(0, 1)
fill.Position = UDim2.fromScale(0, 1)
fill.Size = UDim2.fromScale(1, 0)
fill.BackgroundColor3 = SOUL
fill.BorderSizePixel = 0
fill.Parent = vessel
for _, spec in { { 0.26, -22 }, { 0.58, 22 } } do
	local eye = Instance.new("Frame")
	eye.Size = UDim2.fromOffset(11, 19)
	eye.Position = UDim2.fromScale(spec[1] :: number, 0.36)
	eye.Rotation = spec[2] :: number
	eye.BackgroundColor3 = INK
	eye.BorderSizePixel = 0
	eye.ZIndex = 3
	eye.Parent = vessel
	corner(eye, UDim.new(1, 0))
end

-- Máscaras.
local masksRow = Instance.new("Frame")
masksRow.Name = "Mascaras"
masksRow.Position = UDim2.fromOffset(120, 30)
masksRow.Size = UDim2.fromOffset(640, 44)
masksRow.BackgroundTransparency = 1
masksRow.Parent = gui
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 7)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = masksRow
end

local icons: { MaskIcon } = {}
local lastMasks = 0

local function makeMask(index: number): MaskIcon
	local holder = Instance.new("Frame")
	holder.Name = "Mascara" .. index
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(32, 40)
	holder.LayoutOrder = index
	holder.Parent = masksRow
	local scale = Instance.new("UIScale")
	scale.Parent = holder

	local body = Instance.new("Frame")
	body.Size = UDim2.fromScale(1, 1)
	body.BackgroundColor3 = BONE
	body.BorderSizePixel = 0
	body.Parent = holder
	corner(body, UDim.new(0.46, 0))
	local stroke = Instance.new("UIStroke")
	stroke.Color = BONE
	stroke.Thickness = 1.5
	stroke.Transparency = 0.45
	stroke.Parent = body

	local eyes: { Frame } = {}
	for _, spec in { { 0.14, -16 }, { 0.58, 16 } } do
		local eye = Instance.new("Frame")
		eye.Size = UDim2.fromOffset(8, 15)
		eye.Position = UDim2.fromScale(spec[1] :: number, 0.3)
		eye.Rotation = spec[2] :: number
		eye.BackgroundColor3 = INK
		eye.BorderSizePixel = 0
		eye.Parent = body
		corner(eye, UDim.new(1, 0))
		table.insert(eyes, eye)
	end
	return { holder = holder, body = body, eyes = eyes, scale = scale }
end

local function rebuildMasks(total: number)
	for _, icon in icons do
		icon.holder:Destroy()
	end
	table.clear(icons)
	for index = 1, total do
		table.insert(icons, makeMask(index))
	end
end

local function pop(icon: MaskIcon, from: number)
	icon.scale.Scale = from
	TweenService:Create(
		icon.scale,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
end

local function refreshMasks()
	local masks = attrNumber("Masks", 0)
	for index, icon in icons do
		local full = index <= masks
		TweenService:Create(icon.body, TweenInfo.new(0.2), { BackgroundTransparency = if full then 0 else 0.88 }):Play()
		for _, eye in icon.eyes do
			eye.BackgroundTransparency = if full then 0 else 1
		end
		if lastMasks >= index and not full then
			pop(icon, 1.5)
		elseif lastMasks < index and full and lastMasks > 0 then
			pop(icon, 1.35)
		end
	end
	lastMasks = masks
end

local function refreshSoul()
	local soul = attrNumber("Soul", 0)
	TweenService:Create(fill, TweenInfo.new(0.18), { Size = UDim2.fromScale(1, math.clamp(soul / Config.Soul.Max, 0, 1)) }):Play()
end

-- Cacos e fragmentos.
local cacosIcon = Instance.new("Frame")
cacosIcon.Position = UDim2.fromOffset(124, 90)
cacosIcon.Size = UDim2.fromOffset(14, 14)
cacosIcon.Rotation = 45
cacosIcon.BackgroundColor3 = BONE
cacosIcon.BorderSizePixel = 0
cacosIcon.Parent = gui
corner(cacosIcon, UDim.new(0, 3))

local cacosLabel = Instance.new("TextLabel")
cacosLabel.Position = UDim2.fromOffset(148, 80)
cacosLabel.Size = UDim2.fromOffset(180, 32)
cacosLabel.BackgroundTransparency = 1
cacosLabel.Font = Enum.Font.Garamond
cacosLabel.TextSize = 28
cacosLabel.TextColor3 = BONE
cacosLabel.TextXAlignment = Enum.TextXAlignment.Left
cacosLabel.Text = "0"
cacosLabel.Parent = gui

local fragmentsLabel = Instance.new("TextLabel")
fragmentsLabel.Position = UDim2.fromOffset(120, 112)
fragmentsLabel.Size = UDim2.fromOffset(260, 22)
fragmentsLabel.BackgroundTransparency = 1
fragmentsLabel.Font = Enum.Font.Garamond
fragmentsLabel.TextSize = 20
fragmentsLabel.TextColor3 = Color3.fromRGB(150, 165, 200)
fragmentsLabel.TextXAlignment = Enum.TextXAlignment.Left
fragmentsLabel.Text = ""
fragmentsLabel.Parent = gui

local function refreshCounters()
	cacosLabel.Text = tostring(attrNumber("Cacos", 0))
	local fragments = attrNumber("Fragments", 0)
	fragmentsLabel.Text = if fragments > 0 then `Fragmentos de vidro: {fragments}` else ""
end

-- Aviso central.
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -70)
toast.Size = UDim2.new(0.7, 0, 0, 40)
toast.BackgroundTransparency = 1
toast.Font = Enum.Font.Garamond
toast.TextSize = 30
toast.TextColor3 = BONE
toast.TextTransparency = 1
toast.Text = ""
toast.Parent = gui
local toastId = 0

local function showToast(text: string)
	toastId += 1
	local id = toastId
	toast.Text = text
	TweenService:Create(toast, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	task.delay(3.2, function()
		if id == toastId then
			TweenService:Create(toast, TweenInfo.new(0.7), { TextTransparency = 1 }):Play()
		end
	end)
end

-- Barra de chefe.
local bossFrame = Instance.new("Frame")
bossFrame.AnchorPoint = Vector2.new(0.5, 0)
bossFrame.Position = UDim2.new(0.5, 0, 0, 28)
bossFrame.Size = UDim2.new(0.42, 0, 0, 44)
bossFrame.BackgroundTransparency = 1
bossFrame.Visible = false
bossFrame.Parent = gui
local bossName = Instance.new("TextLabel")
bossName.Size = UDim2.new(1, 0, 0, 26)
bossName.BackgroundTransparency = 1
bossName.Font = Enum.Font.Garamond
bossName.TextSize = 26
bossName.TextColor3 = BONE
bossName.Parent = bossFrame
local bossTrack = Instance.new("Frame")
bossTrack.Position = UDim2.new(0, 0, 0, 30)
bossTrack.Size = UDim2.new(1, 0, 0, 8)
bossTrack.BackgroundColor3 = INK
bossTrack.BorderSizePixel = 0
bossTrack.Parent = bossFrame
do
	local stroke = Instance.new("UIStroke")
	stroke.Color = BONE
	stroke.Thickness = 1.5
	stroke.Parent = bossTrack
end
local bossFill = Instance.new("Frame")
bossFill.Size = UDim2.fromScale(1, 1)
bossFill.BackgroundColor3 = BONE
bossFill.BorderSizePixel = 0
bossFill.Parent = bossTrack

function HUD.setVisible(visible: boolean)
	gui.Enabled = visible
end

function HUD.start()
	rebuildMasks(attrNumber("MaxMasks", Config.Masks.Default))
	refreshMasks()
	refreshSoul()
	refreshCounters()

	player:GetAttributeChangedSignal("MaxMasks"):Connect(function()
		rebuildMasks(attrNumber("MaxMasks", Config.Masks.Default))
		lastMasks = 0
		refreshMasks()
	end)
	player:GetAttributeChangedSignal("Masks"):Connect(refreshMasks)
	player:GetAttributeChangedSignal("Soul"):Connect(refreshSoul)
	player:GetAttributeChangedSignal("Cacos"):Connect(refreshCounters)
	player:GetAttributeChangedSignal("Fragments"):Connect(refreshCounters)

	Net.on("Notify", function(text: any)
		if typeof(text) == "string" then
			showToast(text)
		end
	end)
	Net.on("Boss", function(action: any, name: any, health: any, maxHealth: any)
		if action == "show" and typeof(name) == "string" then
			bossName.Text = name
			bossFill.Size = UDim2.fromScale(math.clamp((health :: number) / (maxHealth :: number), 0, 1), 1)
			bossFrame.Visible = true
		elseif action == "hp" and typeof(health) == "number" and typeof(maxHealth) == "number" then
			bossFrame.Visible = true
			TweenService:Create(bossFill, TweenInfo.new(0.15), { Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1) }):Play()
		elseif action == "reset" then
			bossFrame.Visible = false
		elseif action == "defeated" then
			bossFrame.Visible = false
			showToast("O silêncio cai. Algo se abre à frente.")
		end
	end)
end

return HUD
