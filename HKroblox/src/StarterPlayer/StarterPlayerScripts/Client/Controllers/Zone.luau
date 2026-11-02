--!strict
-- Zonas: ao mudar de sala, ajusta luz, névoa e distância da câmera ao bioma,
-- e mostra o nome da área (como um título de região).

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldMap = require(ReplicatedStorage.Shared.WorldMap)
local CameraRig = require(script.Parent.CameraRig)

local Zone = {}

local player = Players.LocalPlayer
local currentRoom = ""
local currentBiome = ""

local gui = Instance.new("ScreenGui")
gui.Name = "RK_Zone"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0.14, 0)
banner.Size = UDim2.new(0.8, 0, 0, 64)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.Garamond
banner.TextSize = 54
banner.TextColor3 = Color3.fromRGB(236, 235, 228)
banner.TextTransparency = 1
banner.Text = ""
banner.Parent = gui
local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = Color3.fromRGB(8, 10, 22)
bannerStroke.Thickness = 2
bannerStroke.Transparency = 1
bannerStroke.Parent = banner
local rule = Instance.new("Frame")
rule.AnchorPoint = Vector2.new(0.5, 0)
rule.Position = UDim2.new(0.5, 0, 0.14, 66)
rule.Size = UDim2.new(0, 0, 0, 2)
rule.BackgroundColor3 = Color3.fromRGB(236, 235, 228)
rule.BackgroundTransparency = 1
rule.BorderSizePixel = 0
rule.Parent = gui
local bannerId = 0

local function showBanner(text: string)
	bannerId += 1
	local id = bannerId
	banner.Text = text
	rule.Size = UDim2.new(0, 0, 0, 2)
	TweenService:Create(banner, TweenInfo.new(1.0), { TextTransparency = 0 }):Play()
	TweenService:Create(bannerStroke, TweenInfo.new(1.0), { Transparency = 0.3 }):Play()
	TweenService:Create(rule, TweenInfo.new(1.4, Enum.EasingStyle.Quint), { Size = UDim2.new(0, 340, 0, 2), BackgroundTransparency = 0.2 }):Play()
	task.delay(3.6, function()
		if id == bannerId then
			TweenService:Create(banner, TweenInfo.new(1.4), { TextTransparency = 1 }):Play()
			TweenService:Create(bannerStroke, TweenInfo.new(1.4), { Transparency = 1 }):Play()
			TweenService:Create(rule, TweenInfo.new(1.4), { BackgroundTransparency = 1 }):Play()
		end
	end)
end

local function roomAt(x: number, y: number): WorldMap.Room?
	for _, room in WorldMap.Rooms do
		if x >= room.x0 - 4 and x <= room.x1 + 4 and y >= room.y0 - 4 and y <= room.y1 + 4 then
			return room
		end
	end
	return nil
end

local function apply(room: WorldMap.Room, instant: boolean)
	local biome = WorldMap.Biomes[room.biome]
	if not biome then
		return
	end
	local info = TweenInfo.new(if instant then 0.01 else 1.6, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, {
		Ambient = biome.ambient,
		OutdoorAmbient = biome.outdoor,
		Brightness = biome.brightness,
	}):Play()
	local atmosphere = Lighting:FindFirstChild("MareAtmo")
	if atmosphere and atmosphere:IsA("Atmosphere") then
		TweenService:Create(atmosphere, info, {
			Color = biome.accent:Lerp(Color3.new(1, 1, 1), 0.2),
			Decay = biome.fogColor,
			Density = 0.04 + biome.fogDensity * 0.1,
			Haze = 0.9,
			Offset = 0,
		}):Play()
	end
	local grade = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if grade then
		TweenService:Create(grade, info, { TintColor = biome.tint }):Play()
	end
	CameraRig.setDistanceGoal(room.camera)
end

function Zone.start()
	local blur = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if blur then
		blur.Enabled = false
	end
	task.spawn(function()
		while true do
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if root and root:IsA("BasePart") then
				local room = roomAt(root.Position.X, root.Position.Y)
				if room and room.id ~= currentRoom then
					local first = currentRoom == ""
					currentRoom = room.id
					apply(room, first)
					if room.biome ~= currentBiome then
						currentBiome = room.biome
						if not first then
							showBanner(WorldMap.Biomes[room.biome].name)
						end
					end
				end
			end
			task.wait(0.25)
		end
	end)
end

-- Título da região ao começar o jogo (depois da cutscene).
function Zone.announceCurrent()
	local biome = WorldMap.Biomes[currentBiome]
	if biome then
		showBanner(biome.name)
	end
end

return Zone
