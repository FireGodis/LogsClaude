--!strict
-- Display-only HUD. All currency and inventory decisions stay on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local theme = require(ReplicatedStorage:WaitForChild("SAG_Shared"):WaitForChild("UIConfig"))
local palette = theme.Palette

local screen = Instance.new("ScreenGui")
screen.Name = "SAG_HUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.DisplayOrder = 10
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "StatusPanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(16, 16)
panel.Size = UDim2.new(0.92, 0, 0, 156)
panel.BackgroundColor3 = palette.Panel
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.Parent = screen

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(270, 156)
sizeLimit.MaxSize = Vector2.new(370, 156)
sizeLimit.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local outline = Instance.new("UIStroke")
outline.Color = palette.Gold
outline.Thickness = 2
outline.Transparency = 0.12
outline.Parent = panel

local function makeLabel(name, y, height, textSize, color, font)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = UDim2.fromOffset(16, y)
    label.Size = UDim2.new(1, -32, 0, height)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = font or Enum.Font.Gotham
    label.TextSize = textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Parent = panel
    return label
end

local title = makeLabel("Title", 10, 28, 21, palette.Gold, Enum.Font.GothamBold)
title.Text = theme.Title
local subtitle = makeLabel("Subtitle", 37, 20, 12, palette.Muted, Enum.Font.GothamMedium)
subtitle.Text = theme.Subtitle
local stats = makeLabel("Stats", 61, 48, 15, palette.Marble, Enum.Font.GothamSemibold)
local status = makeLabel("Status", 111, 34, 12, palette.Sky, Enum.Font.Gotham)

local function refresh()
    if player:GetAttribute("SAG_DataReady") ~= true then
        stats.Text = "Carregando seu perfil..."
        status.Text = tostring(player:GetAttribute("SAG_Status") or "Preparando sua base.")
        return
    end

    local coins = math.floor(tonumber(player:GetAttribute("SAG_Coins")) or 0)
    local pending = math.floor(tonumber(player:GetAttribute("SAG_PendingCoins")) or 0)
    local eggs = math.floor(tonumber(player:GetAttribute("SAG_GreekEggs")) or 0)
    local zeus = math.floor(tonumber(player:GetAttribute("SAG_ZeusCount")) or 0)
    local base = math.floor(tonumber(player:GetAttribute("SAG_BaseIndex")) or 0)
    local baseLevel = math.floor(tonumber(player:GetAttribute("SAG_BaseLevel")) or 1)

    stats.Text = string.format("Coins  %d    •    Para coletar  %d\nGreek Eggs  %d    •    Zeus  %d/1\nBase  %s  •  Nível %d",
        coins, pending, eggs, zeus, base > 0 and tostring(base) or "—", baseLevel)
    status.Text = tostring(player:GetAttribute("SAG_Status") or "Use os prompts próximos para jogar.")
end

for _, attribute in ipairs({
    "SAG_DataReady",
    "SAG_Coins",
    "SAG_PendingCoins",
    "SAG_GreekEggs",
    "SAG_ZeusCount",
    "SAG_BaseIndex",
    "SAG_BaseLevel",
    "SAG_Status",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

refresh()
