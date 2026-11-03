--!strict
-- Ares is a real, server-owned NPC with a small utility-driven progression loop.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Config = require(game:GetService("ServerStorage"):WaitForChild("SAG_Config"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BotAIService = {}
local started = false

local PERSONALITIES = {
    Aggressive = {
        Hatch = 1.25,
        Purchase = 1.15,
        Upgrade = 0.95,
        Collect = 1.0,
    },
}

local function setState(bot, state)
    bot.State = state
    if bot.Model and bot.Model.Parent then
        bot.Model:SetAttribute("SAG_State", state)
    end
    if bot.Base and bot.Base.Model.Parent then
        bot.Base.Model:SetAttribute("SAG_BotState", state)
    end
end

local function syncAttributes(bot)
    if not bot.Model or not bot.Model.Parent then return end
    bot.Model:SetAttribute("SAG_BotCoins", bot.Coins)
    bot.Model:SetAttribute("SAG_BotPendingCoins", bot.PendingCoins)
    bot.Model:SetAttribute("SAG_BotGreekEggs", bot.GreekEggs)
    bot.Model:SetAttribute("SAG_BotZeusCount", bot.ZeusCount)
    bot.Model:SetAttribute("SAG_BotBaseLevel", bot.BaseLevel)
    bot.Base.Model:SetAttribute("SAG_BotCoins", bot.Coins)
    bot.Base.Model:SetAttribute("SAG_BotBaseLevel", bot.BaseLevel)
end

local function addIdentityBillboard(rig)
    local head = rig:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SAG_AIIdentity"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(180, 42)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 180
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(65, 23, 31)
    label.BackgroundTransparency = 0.12
    label.BorderSizePixel = 0
    label.Text = "ARES  •  IA"
    label.TextColor3 = Color3.fromRGB(255, 225, 186)
    label.TextStrokeTransparency = 0.45
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
end

local function createRig(base)
    local description = Instance.new("HumanoidDescription")
    local ok, rigOrError = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
    end)
    description:Destroy()
    if not ok then
        warn("[SAG AI] Could not create Ares rig: " .. tostring(rigOrError))
        return nil, nil, nil
    end

    local rig = rigOrError
    rig.Name = "SAG_AI_ARES"
    local humanoid = rig:FindFirstChildOfClass("Humanoid")
    local root = rig:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        rig:Destroy()
        warn("[SAG AI] Ares rig is missing a Humanoid or HumanoidRootPart.")
        return nil, nil, nil
    end

    humanoid.DisplayName = Config.BotAI.Name .. "  •  IA"
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.WalkSpeed = Config.BotAI.WalkSpeed

    local highlight = Instance.new("Highlight")
    highlight.Name = "SAG_AIHighlight"
    highlight.FillColor = Color3.fromRGB(210, 66, 59)
    highlight.FillTransparency = 0.78
    highlight.OutlineColor = Color3.fromRGB(255, 205, 124)
    highlight.OutlineTransparency = 0.12
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = rig

    addIdentityBillboard(rig)
    return rig, humanoid, root
end

local function moveTo(bot, targetPart)
    local humanoid = bot.Humanoid
    local root = bot.Root
    if not bot.Model.Parent or not humanoid.Parent or not root.Parent then
        return false
    end

    local targetPosition = targetPart.Position + Vector3.new(0, 2.5, 0)
    for attempt = 1, Config.BotAI.MaxPathRetries do
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 8,
        })
        local computed, errorMessage = pcall(function()
            path:ComputeAsync(root.Position, targetPosition)
        end)

        if computed and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            local currentWaypointIndex = 1
            local blocked = false
            local blockedConnection = path.Blocked:Connect(function(blockedIndex)
                if blockedIndex >= currentWaypointIndex then
                    blocked = true
                end
            end)
            local reached = true

            for index = 2, #waypoints do
                currentWaypointIndex = index
                if blocked then
                    reached = false
                    break
                end

                local waypoint = waypoints[index]
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end

                local finished = false
                local moveSucceeded = false
                local moveConnection = humanoid.MoveToFinished:Connect(function(success)
                    finished = true
                    moveSucceeded = success
                end)
                humanoid:MoveTo(waypoint.Position)

                local deadline = os.clock() + 9
                while not finished and os.clock() < deadline and bot.Model.Parent do
                    task.wait(0.1)
                end
                moveConnection:Disconnect()

                if not moveSucceeded or blocked then
                    reached = false
                    break
                end
            end

            blockedConnection:Disconnect()
            if reached and (root.Position - targetPosition).Magnitude <= Config.InteractionDistance + 2 then
                return true
            end
        else
            warn(string.format("[SAG AI] Ares path attempt %d failed: %s", attempt, tostring(errorMessage or path.Status)))
        end
        task.wait(0.35)
    end

    return (root.Position - targetPosition).Magnitude <= Config.InteractionDistance + 2
end

local function chooseAction(bot)
    local weights = PERSONALITIES[bot.Personality] or PERSONALITIES.Aggressive
    local options = {}

    local function offer(name, score, state)
        table.insert(options, {Name = name, Score = score, State = state})
    end

    if bot.GreekEggs > 0 then
        offer("Hatch", 100 * weights.Hatch, "Hatching")
    end
    if bot.ZeusCount < Config.MaxZeus and bot.GreekEggs == 0 and bot.Coins >= Config.GreekEggPrice then
        offer("Purchase", 80 * weights.Purchase, "Purchasing")
    end
    if bot.BaseLevel < Config.MaxBaseLevel and bot.Coins >= Config.BaseUpgradeCost then
        offer("Upgrade", 75 * weights.Upgrade, "Upgrading")
    end
    if bot.PendingCoins > 0 then
        local needsUpgrade = bot.BaseLevel < Config.MaxBaseLevel and bot.Coins < Config.BaseUpgradeCost
        local score = needsUpgrade and 95 or (bot.PendingCoins >= 20 and 45 or 0)
        if score > 0 then
            offer("Collect", score * weights.Collect, "Collecting")
        end
    end

    table.sort(options, function(a, b)
        return a.Score > b.Score
    end)
    return options[1]
end

local function purchaseEgg(bot, world)
    if not moveTo(bot, world.EggStand) then
        setState(bot, "Recovering")
        return
    end
    if bot.Coins < Config.GreekEggPrice or bot.GreekEggs >= Config.MaxGreekEggs then
        setState(bot, "SavingCoins")
        return
    end

    bot.Coins -= Config.GreekEggPrice
    bot.GreekEggs += 1
    bot.Model:SetAttribute("SAG_LastAction", "PurchasedGreekEgg")
    syncAttributes(bot)
end

local function hatchEgg(bot)
    if not moveTo(bot, bot.Base.HatchPad) then
        setState(bot, "Recovering")
        return
    end
    if bot.GreekEggs < 1 or bot.ZeusCount >= Config.MaxZeus then
        setState(bot, "ReturningHome")
        return
    end

    bot.GreekEggs -= 1
    bot.ZeusCount += 1
    WorldBuilder.PlaceZeus(bot.Base)
    bot.Model:SetAttribute("SAG_LastAction", "HatchedZeus")
    syncAttributes(bot)
end

local function collectCoins(bot)
    if not moveTo(bot, bot.Base.CoinPad) then
        setState(bot, "Recovering")
        return
    end
    local amount = math.floor(bot.PendingCoins)
    bot.PendingCoins -= amount
    bot.Coins += amount
    bot.Model:SetAttribute("SAG_LastAction", "CollectedCoins")
    syncAttributes(bot)
end

local function upgradeBase(bot)
    if not moveTo(bot, bot.Base.UpgradePad) then
        setState(bot, "Recovering")
        return
    end
    if bot.BaseLevel >= Config.MaxBaseLevel or bot.Coins < Config.BaseUpgradeCost then
        setState(bot, "SavingCoins")
        return
    end

    bot.Coins -= Config.BaseUpgradeCost
    bot.BaseLevel += 1
    WorldBuilder.SetBaseLevel(bot.Base, bot.BaseLevel)
    bot.Model:SetAttribute("SAG_LastAction", "UpgradedBase")
    syncAttributes(bot)
end

local function runBot(bot, world)
    task.wait(1)
    while bot.Active and bot.Model.Parent do
        local action = chooseAction(bot)
        if action then
            setState(bot, action.State)
            if action.Name == "Purchase" then
                purchaseEgg(bot, world)
            elseif action.Name == "Hatch" then
                hatchEgg(bot)
            elseif action.Name == "Collect" then
                collectCoins(bot)
            elseif action.Name == "Upgrade" then
                upgradeBase(bot)
            end
        else
            setState(bot, bot.ZeusCount > 0 and "Defending" or "SavingCoins")
        end
        syncAttributes(bot)
        task.wait(Config.BotAI.DecisionInterval)
    end
end

local function startIncome(bot)
    task.spawn(function()
        while bot.Active and bot.Model.Parent do
            task.wait(Config.BotAI.IncomeInterval)
            if bot.ZeusCount > 0 then
                local multiplier = 1 + math.max(0, bot.BaseLevel - 1) * Config.BaseUpgradeIncomeBonus
                bot.PendingCoins += math.floor(Config.ZeusIncomePerSecond * multiplier)
                syncAttributes(bot)
            end
        end
    end)
end

function BotAIService.Start(world)
    if started or not Config.BotAI.Enabled then return end
    started = true

    local preferredIndex = math.clamp(Config.BotAI.SpawnBaseIndex, 1, #world.Bases)
    local base = world.Bases[preferredIndex]
    if base.OwnerUserId ~= 0 then
        for index = #world.Bases, 1, -1 do
            if world.Bases[index].OwnerUserId == 0 then
                base = world.Bases[index]
                break
            end
        end
    end
    if not base or base.OwnerUserId ~= 0 then
        warn("[SAG AI] No free base is available for Ares.")
        return
    end

    local botId = -base.Index
    base.OwnerUserId = botId
    base.Model:SetAttribute("OwnerUserId", botId)
    base.Model:SetAttribute("OwnerKind", "AI")
    base.Model:SetAttribute("OwnerName", Config.BotAI.Name)
    WorldBuilder.SetBaseLabel(base, Config.BotAI.Name .. "  •  IA")
    WorldBuilder.SetBaseLevel(base, 1)

    local rig, humanoid, root = createRig(base)
    if not rig then
        base.OwnerUserId = 0
        base.Model:SetAttribute("OwnerUserId", 0)
        base.Model:SetAttribute("OwnerKind", nil)
        base.Model:SetAttribute("OwnerName", nil)
        WorldBuilder.SetBaseLabel(base, "PLAYER BASE " .. base.Index)
        warn("[SAG AI] Ares did not start because its avatar could not be created.")
        return
    end

    rig.Parent = world.Root
    rig:PivotTo(base.SpawnCFrame + Vector3.new(0, 3, 0))
    pcall(function()
        root:SetNetworkOwner(nil)
    end)

    local bot = {
        Active = true,
        Name = Config.BotAI.Name,
        Personality = Config.BotAI.Personality,
        Model = rig,
        Humanoid = humanoid,
        Root = root,
        Base = base,
        Coins = Config.StartingCoins,
        PendingCoins = 0,
        GreekEggs = 0,
        ZeusCount = 0,
        BaseLevel = 1,
        State = "Idle",
    }
    rig:SetAttribute("SAG_Bot", true)
    rig:SetAttribute("SAG_BotName", bot.Name)
    rig:SetAttribute("SAG_Personality", bot.Personality)
    rig:SetAttribute("SAG_Difficulty", "Normal")
    setState(bot, "Idle")
    syncAttributes(bot)

    startIncome(bot)
    task.spawn(runBot, bot, world)
end

return BotAIService