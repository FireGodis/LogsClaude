--!strict
-- Builds the first Greek-themed blockout and exposes its prompts/bases to server systems.
local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ServerStorage"):WaitForChild("SAG_Config"))

local WorldBuilder = {}
local MARBLE = Color3.fromRGB(238, 233, 218)
local GOLD = Color3.fromRGB(216, 169, 67)
local NAVY = Color3.fromRGB(31, 54, 86)
local SKY = Color3.fromRGB(102, 176, 222)
local WHITE = Color3.fromRGB(250, 247, 237)
local GREEN = Color3.fromRGB(115, 153, 97)

local function makePart(parent, name, size, position, color, material, shape, canCollide)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Anchored = true
    part.CanCollide = canCollide ~= false
    part.CanTouch = true
    part.CanQuery = true
    part.CastShadow = true
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color or WHITE
    local frame = CFrame.new(position)
    if shape then
        part.Shape = shape
        if shape == Enum.PartType.Cylinder then
            frame *= CFrame.Angles(0, 0, math.rad(90))
        end
    end
    part.CFrame = frame
    part.Parent = parent
    return part
end

local function addPrompt(part, promptName, actionText, objectText)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = promptName
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = Config.PromptHoldDuration
    prompt.MaxActivationDistance = Config.InteractionDistance
    prompt.RequiresLineOfSight = false
    prompt.Parent = part
    return prompt
end

local function addBillboard(part, labelName, text, width, height, offset, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = labelName .. "Billboard"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(width or 220, height or 54)
    billboard.StudsOffset = offset or Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 250
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = labelName
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or WHITE
    label.TextStrokeColor3 = NAVY
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard
    return label
end

local function addColumn(parent, center, height, goldCap)
    local baseY = center.Y
    makePart(parent, "ColumnFoot", Vector3.new(2.5, 0.5, 2.5), Vector3.new(center.X, baseY + 0.25, center.Z), GOLD, Enum.Material.Metal)
    makePart(parent, "ColumnShaft", Vector3.new(height, 1.5, 1.5), Vector3.new(center.X, baseY + 0.5 + height / 2, center.Z), MARBLE, Enum.Material.Marble, Enum.PartType.Cylinder)
    makePart(parent, "ColumnCapital", Vector3.new(2.7, 0.6, 2.7), Vector3.new(center.X, baseY + height + 0.8, center.Z), goldCap and GOLD or MARBLE, goldCap and Enum.Material.Metal or Enum.Material.Marble)
end

local function buildHub(root)
    local hub = Instance.new("Model")
    hub.Name = "SAG_GreekHub"
    hub.Parent = root

    makePart(hub, "HubLowerTrim", Vector3.new(66, 0.35, 66), Vector3.new(0, 0.2, 0), GOLD, Enum.Material.Metal)
    makePart(hub, "HubPlatform", Vector3.new(62, 1.8, 62), Vector3.new(0, 1.1, 0), MARBLE, Enum.Material.Marble)
    makePart(hub, "HubInnerFloor", Vector3.new(38, 0.35, 38), Vector3.new(0, 2.15, 0), NAVY, Enum.Material.Slate)

    for _, x in ipairs({-23, 23}) do
        for _, z in ipairs({-23, 23}) do
            addColumn(hub, Vector3.new(x, 2.0, z), 8.5, true)
        end
    end
    for _, x in ipairs({-12, 12}) do
        addColumn(hub, Vector3.new(x, 2.0, -23), 7.5, false)
    end

    local sign = makePart(hub, "HubSign", Vector3.new(12, 3, 0.7), Vector3.new(0, 6, -26), NAVY, Enum.Material.Slate)
    addBillboard(sign, "HubTitle", "OLYMPUS  •  DIVINE EGG SHOP", 340, 58, Vector3.new(0, 2.8, 0), GOLD)

    local eggPedestal = makePart(hub, "GreekEggStand", Vector3.new(5, 1, 5), Vector3.new(0, 2.95, 0), GOLD, Enum.Material.Metal)
    makePart(hub, "GreekEggSocket", Vector3.new(3.6, 0.35, 3.6), Vector3.new(0, 3.6, 0), NAVY, Enum.Material.Slate)
    local egg = makePart(hub, "GreekEgg", Vector3.new(2.8, 3.3, 2.4), Vector3.new(0, 5.35, 0), SKY, Enum.Material.Glass, Enum.PartType.Ball, false)
    egg.Transparency = 0.08
    makePart(hub, "EggGoldBand", Vector3.new(0.32, 3.05, 2.65), Vector3.new(0, 5.35, 0), GOLD, Enum.Material.Metal, Enum.PartType.Cylinder, false)
    local eggLabelPart = makePart(hub, "EggShopSign", Vector3.new(8, 1.1, 0.5), Vector3.new(0, 3.0, 8), NAVY, Enum.Material.Slate)
    addBillboard(eggLabelPart, "EggShopLabel", "GREEK EGG  •  " .. Config.GreekEggPrice .. " COINS", 310, 54, Vector3.new(0, 2.5, 0), WHITE)
    addPrompt(eggPedestal, "SAG_BuyGreekEggPrompt", "Buy Greek Egg", tostring(Config.GreekEggPrice) .. " Coins")
    return hub
end

local function buildBase(root, index)
    local angle = math.rad((index - 1) * (360 / Config.BaseCount) - 90)
    local center = Vector3.new(math.cos(angle) * Config.BaseRadius, 0, math.sin(angle) * Config.BaseRadius)

    local base = Instance.new("Model")
    base.Name = string.format("SAG_Base_%02d", index)
    base:SetAttribute("BaseIndex", index)
    base:SetAttribute("OwnerUserId", 0)
    base:SetAttribute("BaseLevel", 1)

    makePart(base, "BaseLowerTrim", Vector3.new(42, 0.35, 42), center + Vector3.new(0, 0.2, 0), GOLD, Enum.Material.Metal)
    makePart(base, "BasePlatform", Vector3.new(38, 1.4, 38), center + Vector3.new(0, 1.05, 0), MARBLE, Enum.Material.Marble)
    makePart(base, "BaseCenter", Vector3.new(26, 0.25, 26), center + Vector3.new(0, 1.88, 0), NAVY, Enum.Material.Slate)

    for _, dx in ipairs({-15, 15}) do
        for _, dz in ipairs({-15, 15}) do
            addColumn(base, center + Vector3.new(dx, 1.9, dz), 5.5, true)
        end
    end

    local sign = makePart(base, "BaseSign", Vector3.new(9, 2, 0.7), center + Vector3.new(0, 5.4, -16), NAVY, Enum.Material.Slate)
    local baseLabel = addBillboard(sign, "BaseLabel", "PLAYER BASE " .. index, 230, 52, Vector3.new(0, 2.1, 0), GOLD)

    local spawnPoint = makePart(base, "SpawnPoint", Vector3.new(2, 1, 2), center + Vector3.new(0, 3.5, 9), WHITE, Enum.Material.SmoothPlastic, nil, false)
    spawnPoint.Transparency = 1

    local coinPad = makePart(base, "CoinCollector", Vector3.new(5, 0.55, 5), center + Vector3.new(0, 2.1, 8), GREEN, Enum.Material.Grass)
    addBillboard(coinPad, "CoinCollectorLabel", "COIN ALTAR", 180, 42, Vector3.new(0, 2.1, 0), WHITE)
    addPrompt(coinPad, "SAG_CollectCoinsPrompt", "Collect Coins", "Your base")

    local hatchPad = makePart(base, "HatchAltar", Vector3.new(5, 0.8, 5), center + Vector3.new(0, 2.2, -8), GOLD, Enum.Material.Metal)
    makePart(base, "HatchInlay", Vector3.new(3.3, 0.15, 3.3), center + Vector3.new(0, 2.7, -8), NAVY, Enum.Material.Slate)
    addBillboard(hatchPad, "HatchAltarLabel", "DIVINE HATCH", 190, 42, Vector3.new(0, 2.4, 0), WHITE)
    addPrompt(hatchPad, "SAG_HatchGreekEggPrompt", "Hatch Greek Egg", "Your collection")

    local upgradePad = makePart(base, "BaseUpgrade", Vector3.new(4.5, 0.55, 4.5), center + Vector3.new(9, 2.05, 7), SKY, Enum.Material.Neon)
    addBillboard(upgradePad, "BaseUpgradeLabel", "BASE UPGRADE", 190, 42, Vector3.new(0, 2.2, 0), WHITE)
    addPrompt(upgradePad, "SAG_UpgradeBasePrompt", "Upgrade Base", tostring(Config.BaseUpgradeCost) .. " Coins")

    local slot = makePart(base, "GodSlot", Vector3.new(2, 1, 2), center + Vector3.new(7, 3.2, 0), WHITE, Enum.Material.SmoothPlastic, nil, false)
    slot.Transparency = 1

    base.Parent = root
    return base
end

local function buildWorld()
    local root = Instance.new("Model")
    root.Name = Config.WorldName
    buildHub(root)
    for index = 1, Config.BaseCount do
        buildBase(root, index)
    end
    root.Parent = Workspace
    return root
end

local function ensurePathways(root)
    if root:FindFirstChild("SAG_Pathways") then
        return
    end

    local pathways = Instance.new("Folder")
    pathways.Name = "SAG_Pathways"
    local innerRadius = 33
    local outerRadius = Config.BaseRadius - 21
    local length = outerRadius - innerRadius
    local middleRadius = (innerRadius + outerRadius) / 2

    for index = 1, Config.BaseCount do
        local angle = math.rad((index - 1) * (360 / Config.BaseCount) - 90)
        local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local center = direction * middleRadius
        local path = makePart(
            pathways,
            string.format("MarblePath_%02d", index),
            Vector3.new(8, 0.5, length),
            Vector3.new(center.X, 1.72, center.Z),
            MARBLE,
            Enum.Material.Marble
        )
        path.CFrame = CFrame.new(center.X, 1.72, center.Z) * CFrame.Angles(0, -angle, 0)

        for side = -1, 1, 2 do
            local trimCenter = center + Vector3.new(math.cos(angle + math.pi / 2), 0, math.sin(angle + math.pi / 2)) * (side * 4.15)
            local trim = makePart(
                pathways,
                string.format("GoldEdge_%02d_%s", index, side < 0 and "L" or "R"),
                Vector3.new(0.3, 0.65, length),
                Vector3.new(trimCenter.X, 1.8, trimCenter.Z),
                GOLD,
                Enum.Material.Metal
            )
            trim.CFrame = CFrame.new(trimCenter.X, 1.8, trimCenter.Z) * CFrame.Angles(0, -angle, 0)
        end
    end

    pathways.Parent = root
end

local function collectWorld(root)
    local hub = root:FindFirstChild("SAG_GreekHub")
    assert(hub, "SAG world is missing SAG_GreekHub")
    local eggStand = hub:FindFirstChild("GreekEggStand")
    assert(eggStand and eggStand:IsA("BasePart"), "SAG world is missing GreekEggStand")
    local eggPrompt = eggStand:FindFirstChild("SAG_BuyGreekEggPrompt")
    assert(eggPrompt and eggPrompt:IsA("ProximityPrompt"), "SAG world is missing the Greek Egg prompt")

    local bases = {}
    for index = 1, Config.BaseCount do
        local model = root:FindFirstChild(string.format("SAG_Base_%02d", index))
        assert(model and model:IsA("Model"), "SAG world is missing base " .. index)
        local spawnPoint = model:FindFirstChild("SpawnPoint")
        local coinPad = model:FindFirstChild("CoinCollector")
        local hatchPad = model:FindFirstChild("HatchAltar")
        local upgradePad = model:FindFirstChild("BaseUpgrade")
        local slot = model:FindFirstChild("GodSlot")
        local coinPrompt = coinPad and coinPad:FindFirstChild("SAG_CollectCoinsPrompt")
        local hatchPrompt = hatchPad and hatchPad:FindFirstChild("SAG_HatchGreekEggPrompt")
        local upgradePrompt = upgradePad and upgradePad:FindFirstChild("SAG_UpgradeBasePrompt")
        local label = model:FindFirstChild("BaseLabel", true)
        assert(spawnPoint and coinPad and hatchPad and upgradePad and slot and coinPrompt and hatchPrompt and upgradePrompt and label, "Base " .. index .. " is incomplete")
        if model:GetAttribute("BaseLevel") == nil then
            model:SetAttribute("BaseLevel", 1)
        end

        table.insert(bases, {
            Index = index,
            Model = model,
            SpawnCFrame = spawnPoint.CFrame,
            CoinPad = coinPad,
            CoinPrompt = coinPrompt,
            HatchPad = hatchPad,
            HatchPrompt = hatchPrompt,
            UpgradePad = upgradePad,
            UpgradePrompt = upgradePrompt,
            GodSlot = slot,
            BaseLevel = model:GetAttribute("BaseLevel") or 1,
            Label = label,
            OwnerUserId = model:GetAttribute("OwnerUserId") or 0,
        })
    end

    return {
        Root = root,
        Hub = hub,
        EggStand = eggStand,
        EggPrompt = eggPrompt,
        Bases = bases,
    }
end

local function ensureBaseUpgradePads(root)
    for index = 1, Config.BaseCount do
        local model = root:FindFirstChild(string.format("SAG_Base_%02d", index))
        if model then
            if model:GetAttribute("BaseLevel") == nil then
                model:SetAttribute("BaseLevel", 1)
            end
            if not model:FindFirstChild("BaseUpgrade") then
                local baseCenter = model:FindFirstChild("BasePlatform")
                if baseCenter then
                    local position = baseCenter.Position + Vector3.new(9, 1.0, 7)
                    local pad = makePart(model, "BaseUpgrade", Vector3.new(4.5, 0.55, 4.5), position, SKY, Enum.Material.Neon)
                    addBillboard(pad, "BaseUpgradeLabel", "BASE UPGRADE", 190, 42, Vector3.new(0, 2.2, 0), WHITE)
                    addPrompt(pad, "SAG_UpgradeBasePrompt", "Upgrade Base", tostring(Config.BaseUpgradeCost) .. " Coins")
                end
            end
        end
    end
end

function WorldBuilder.Build()
    local root = Workspace:FindFirstChild(Config.WorldName)
    if not root then
        root = buildWorld()
    end
    ensurePathways(root)
    ensureBaseUpgradePads(root)
    return collectWorld(root)
end

function WorldBuilder.ClaimBase(world, userId)
    for _, base in ipairs(world.Bases) do
        local currentOwner = base.Model:GetAttribute("OwnerUserId") or 0
        if currentOwner == 0 then
            base.OwnerUserId = userId
            base.Model:SetAttribute("OwnerUserId", userId)
            return base
        end
    end
    return nil
end

function WorldBuilder.SetBaseLabel(base, text)
    base.Label.Text = tostring(text)
end

function WorldBuilder.SetBaseLevel(base, level)
    local safeLevel = math.clamp(math.floor(tonumber(level) or 1), 1, Config.MaxBaseLevel)
    base.BaseLevel = safeLevel
    base.Model:SetAttribute("BaseLevel", safeLevel)
    if safeLevel < 2 or base.Model:FindFirstChild("SAG_BaseUpgrade_Level2") then
        return
    end

    local platform = base.Model:FindFirstChild("BasePlatform")
    if not platform then return end
    local center = platform.Position
    local upgrade = Instance.new("Model")
    upgrade.Name = "SAG_BaseUpgrade_Level2"
    for _, side in ipairs({-1, 1}) do
        makePart(upgrade, "GoldRailing", Vector3.new(30, 0.25, 0.45), center + Vector3.new(0, 1.55, side * 13.5), GOLD, Enum.Material.Metal)
        makePart(upgrade, "GoldRailing", Vector3.new(0.45, 0.25, 30), center + Vector3.new(side * 13.5, 1.55, 0), GOLD, Enum.Material.Metal)
    end
    upgrade.Parent = base.Model
end

function WorldBuilder.PlaceZeus(base)
    local existing = base.Model:FindFirstChild("SAG_ZeusStatue")
    if existing then return existing end

    local origin = base.GodSlot.Position
    local statue = Instance.new("Model")
    statue.Name = "SAG_ZeusStatue"

    makePart(statue, "ZeusPedestal", Vector3.new(4.6, 0.8, 4.6), origin + Vector3.new(0, -1.25, 0), GOLD, Enum.Material.Metal)
    makePart(statue, "ZeusBody", Vector3.new(2.5, 2.8, 1.35), origin + Vector3.new(0, 1.25, 0), MARBLE, Enum.Material.Marble)
    makePart(statue, "ZeusMantle", Vector3.new(2.9, 2.1, 0.45), origin + Vector3.new(0, 1.25, 0.86), NAVY, Enum.Material.SmoothPlastic, nil, false)
    makePart(statue, "ZeusHead", Vector3.new(1.65, 1.75, 1.55), origin + Vector3.new(0, 3.5, 0), MARBLE, Enum.Material.Marble, Enum.PartType.Ball, false)
    makePart(statue, "ZeusBeard", Vector3.new(1.15, 0.95, 0.72), origin + Vector3.new(0, 2.7, 0.82), WHITE, Enum.Material.Marble, Enum.PartType.Ball, false)
    makePart(statue, "ZeusCrown", Vector3.new(1.9, 0.28, 1.6), origin + Vector3.new(0, 4.42, 0), GOLD, Enum.Material.Metal, nil, false)
    makePart(statue, "ZeusLightningA", Vector3.new(0.48, 1.35, 0.48), origin + Vector3.new(1.6, 2.7, 0), GOLD, Enum.Material.Neon, nil, false)
    makePart(statue, "ZeusLightningB", Vector3.new(0.48, 1.2, 0.48), origin + Vector3.new(1.95, 2.15, 0), GOLD, Enum.Material.Neon, nil, false)
    makePart(statue, "ZeusLightningC", Vector3.new(0.48, 1.1, 0.48), origin + Vector3.new(1.58, 1.62, 0), GOLD, Enum.Material.Neon, nil, false)

    local labelPart = makePart(statue, "ZeusNameAnchor", Vector3.new(1, 1, 1), origin + Vector3.new(0, 5.15, 0), WHITE, Enum.Material.SmoothPlastic, nil, false)
    labelPart.Transparency = 1
    addBillboard(labelPart, "ZeusName", "ZEUS  •  THUNDER", 210, 48, Vector3.new(0, 0, 0), GOLD)

    statue:SetAttribute("PlaceholderAsset", true)
    statue.Parent = base.Model
    return statue
end

function WorldBuilder.ReleaseBase(base)
    base.OwnerUserId = 0
    base.Model:SetAttribute("OwnerUserId", 0)
    WorldBuilder.SetBaseLabel(base, "PLAYER BASE " .. base.Index)
    local statue = base.Model:FindFirstChild("SAG_ZeusStatue")
    if statue then statue:Destroy() end
end

return WorldBuilder
