--!strict
-- First playable loop: buy an egg, hatch Zeus, generate and collect Coins.
local Players = game:GetService("Players")
local Config = require(game:GetService("ServerStorage"):WaitForChild("SAG_Config"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BotAIService = require(script.Parent:WaitForChild("BotAIService"))

local GameService = {}
local initialized = false
local world = nil
local baseByPlayer = {}
local actionTimes = {}

local function canUseAction(player, actionName, cooldown)
    local userId = player.UserId
    local now = os.clock()
    actionTimes[userId] = actionTimes[userId] or {}
    local last = actionTimes[userId][actionName]
    if last and now - last < cooldown then
        return false
    end
    actionTimes[userId][actionName] = now
    return true
end

local function isNear(player, part)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
        return false
    end
    return (root.Position - part.Position).Magnitude <= Config.InteractionDistance + 2
end

local function ownsBase(player, base)
    return baseByPlayer[player] == base
        and base.Model:GetAttribute("OwnerUserId") == player.UserId
end

local function handleBuyEgg(player)
    if not PlayerDataService.Get(player) then return end
    if not canUseAction(player, "BuyGreekEgg", 0.6) then return end
    if not isNear(player, world.EggStand) then
        PlayerDataService.SetStatus(player, "Aproxime-se do pedestal de ovos.")
        return
    end

    local ok, message = PlayerDataService.TryBuyGreekEgg(player)
    PlayerDataService.SetStatus(player, message)
end

local function handleHatch(player, base)
    if not PlayerDataService.Get(player) then return end
    if not ownsBase(player, base) then
        PlayerDataService.SetStatus(player, "Esse altar pertence a outro jogador.")
        return
    end
    if not canUseAction(player, "HatchGreekEgg", 1.25) then return end
    if not isNear(player, base.HatchPad) then
        PlayerDataService.SetStatus(player, "Aproxime-se do altar da sua base.")
        return
    end

    local ok, message = PlayerDataService.TryHatchGreekEgg(player)
    if ok then
        WorldBuilder.PlaceZeus(base)
        message = message .. " Produção: +" .. Config.ZeusIncomePerSecond .. " Coins/s. Colete no altar verde."
    end
    PlayerDataService.SetStatus(player, message)
end

local function handleCollect(player, base)
    if not PlayerDataService.Get(player) then return end
    if not ownsBase(player, base) then
        PlayerDataService.SetStatus(player, "Esse altar pertence a outro jogador.")
        return
    end
    if not canUseAction(player, "CollectCoins", 0.4) then return end
    if not isNear(player, base.CoinPad) then
        PlayerDataService.SetStatus(player, "Aproxime-se do altar verde.")
        return
    end

    local amount = PlayerDataService.CollectPendingCoins(player)
    if amount > 0 then
        PlayerDataService.SetStatus(player, "+" .. amount .. " Coins coletadas.")
    else
        PlayerDataService.SetStatus(player, "Ainda não há Coins para coletar.")
    end
end

local function handleUpgrade(player, base)
    if not PlayerDataService.Get(player) then return end
    if not ownsBase(player, base) then
        PlayerDataService.SetStatus(player, "Esse altar pertence a outro jogador.")
        return
    end
    if not canUseAction(player, "UpgradeBase", 1.0) then return end
    if not isNear(player, base.UpgradePad) then
        PlayerDataService.SetStatus(player, "Aproxime-se do altar de melhoria da sua base.")
        return
    end

    local ok, message = PlayerDataService.TryUpgradeBase(player)
    if ok then
        local data = PlayerDataService.Get(player)
        WorldBuilder.SetBaseLevel(base, data.BaseLevel)
    end
    PlayerDataService.SetStatus(player, message)
end

local function moveCharacterToBase(player, character)
    local base = baseByPlayer[player]
    if not base or not character or not character.Parent then return end
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if root and root:IsA("BasePart") and base.Model.Parent then
        character:PivotTo(base.SpawnCFrame + Vector3.new(0, 2.5, 0))
    end
end

local function onPlayerAdded(player)
    if PlayerDataService.Get(player) then return end

    player.CharacterAdded:Connect(function(character)
        task.defer(moveCharacterToBase, player, character)
    end)

    local data, loadError = PlayerDataService.Load(player)
    if not data then
        warn("[SAG] Could not load " .. player.Name .. "'s profile: " .. tostring(loadError))
        player:Kick("Não foi possível carregar seus dados com segurança. Tente entrar novamente.")
        return
    end

    local base = WorldBuilder.ClaimBase(world, player.UserId)
    if not base then
        PlayerDataService.SetStatus(player, "Não há uma base livre neste servidor.")
        PlayerDataService.Unload(player)
        player:Kick("Este servidor está sem bases disponíveis. Tente entrar novamente.")
        return
    end

    baseByPlayer[player] = base
    PlayerDataService.SetBaseIndex(player, base.Index)
    WorldBuilder.SetBaseLabel(base, player.DisplayName .. "  •  BASE " .. base.Index)
    WorldBuilder.SetBaseLevel(base, data.BaseLevel or 1)
    if data.Gods.Zeus > 0 then
        WorldBuilder.PlaceZeus(base)
    end
    PlayerDataService.SetStatus(player, "Sua base está pronta. Compre um Greek Egg no hub.")

    if player.Character then
        task.defer(moveCharacterToBase, player, player.Character)
    end
end

local function onPlayerRemoving(player)
    local base = baseByPlayer[player]
    if base then
        WorldBuilder.ReleaseBase(base)
        baseByPlayer[player] = nil
    end
    PlayerDataService.Unload(player)
    actionTimes[player.UserId] = nil
end

local function startIncomeLoop()
    task.spawn(function()
        while initialized do
            task.wait(1)
            for player, base in pairs(baseByPlayer) do
                local data = PlayerDataService.Get(player)
                if data and ownsBase(player, base) and data.Gods.Zeus > 0 then
                    local multiplier = 1 + math.max(0, (data.BaseLevel or 1) - 1) * Config.BaseUpgradeIncomeBonus
                    PlayerDataService.AddPendingCoins(player, math.floor(Config.ZeusIncomePerSecond * multiplier))
                end
            end
        end
    end)
end

local function startAutosaveLoop()
    task.spawn(function()
        while initialized do
            task.wait(Config.AutoSaveSeconds)
            if not PlayerDataService.IsStudioMemoryMode() then
                for player in pairs(baseByPlayer) do
                    task.spawn(function()
                        if not PlayerDataService.Save(player, false) then
                            PlayerDataService.SetStatus(player, "O salvamento está tentando novamente.")
                        end
                    end)
                end
            end
        end
    end)
end

function GameService.Init()
    if initialized then return end
    initialized = true
    world = WorldBuilder.Build()
    if Config.BotAI.Enabled then
        BotAIService.Start(world)
    end

    world.EggPrompt.Triggered:Connect(handleBuyEgg)
    for _, base in ipairs(world.Bases) do
        base.HatchPrompt.Triggered:Connect(function(player)
            handleHatch(player, base)
        end)
        base.CoinPrompt.Triggered:Connect(function(player)
            handleCollect(player, base)
        end)
        base.UpgradePrompt.Triggered:Connect(function(player)
            handleUpgrade(player, base)
        end)
    end

    Players.PlayerAdded:Connect(function(player)
        task.spawn(onPlayerAdded, player)
    end)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(onPlayerAdded, player)
    end

    startIncomeLoop()
    startAutosaveLoop()

    game:BindToClose(function()
        local remaining = 0
        for player in pairs(baseByPlayer) do
            remaining += 1
            task.spawn(function()
                PlayerDataService.Save(player, true)
                remaining -= 1
            end)
        end
        local deadline = os.clock() + 25
        while remaining > 0 and os.clock() < deadline do
            task.wait(0.1)
        end
    end)
end

return GameService
