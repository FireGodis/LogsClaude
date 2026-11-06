--[[
	Leaderboard — in-world ranking board at the shop plaza (top income / Speed of everyone in the
	server) and the data for the ranking panel. Refreshes every 10s.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.GameConfig)
local NumberFormatter = require(Shared.Util.NumberFormatter)

local Leaderboard = {}
local S
local cached = {}

function Leaderboard.init(sys)
	S = sys
end

local function collect()
	local rows = {}
	for id in S.Actors.all() do
		local p = S.PlayerData.get(id)
		if p then
			table.insert(rows, { name = S.Actors.name(id), income = S.Economy.incomeOf(id), speed = p.speed, pets = #p.pets, title = p.title })
		end
	end
	table.sort(rows, function(a, b)
		return a.income > b.income
	end)
	return rows
end

local function render(rows)
	local board = Workspace.Map:FindFirstChild("ShopPlaza") and Workspace.Map.ShopPlaza:FindFirstChild("Leaderboard")
	local gui = board and board:FindFirstChild("BoardGui")
	if not gui then
		return
	end
	gui:ClearAllChildren()
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = GameConfig.Theme.Panel
	bg.Parent = gui
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.12)
	title.BackgroundTransparency = 1
	title.Text = "🏆 RANKING DO PANTEÃO"
	title.TextColor3 = GameConfig.Theme.Gold
	title.Font = GameConfig.Theme.Font
	title.TextScaled = true
	title.Parent = bg
	for i = 1, math.min(8, #rows) do
		local r = rows[i]
		local row = Instance.new("TextLabel")
		row.Position = UDim2.fromScale(0.04, 0.12 + i * 0.105)
		row.Size = UDim2.fromScale(0.92, 0.095)
		row.BackgroundColor3 = i == 1 and GameConfig.Theme.GoldDark or GameConfig.Theme.PanelLight
		row.BackgroundTransparency = 0.2
		row.Font = GameConfig.Theme.FontBody
		row.TextScaled = true
		row.TextColor3 = Color3.new(1, 1, 1)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = string.format("  #%d  %s   💰 %s/s   ⚡ %s", i, r.name, NumberFormatter.format(r.income), NumberFormatter.format(r.speed))
		Instance.new("UICorner").Parent = row
		row.Parent = bg
	end
end

function Leaderboard.start()
	S.Net.handle("GetLeaderboard", function()
		return true, cached
	end)
	task.spawn(function()
		while true do
			cached = collect()
			pcall(render, cached)
			task.wait(10)
		end
	end)
end

return Leaderboard
