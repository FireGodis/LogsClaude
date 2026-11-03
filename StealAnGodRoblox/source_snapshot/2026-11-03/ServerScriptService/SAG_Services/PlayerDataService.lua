--!strict
-- Server-authoritative player profile service.
-- Studio uses in-memory data so local playtests never touch the live experience DataStore.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ServerStorage"):WaitForChild("SAG_Config"))
local PlayerDataService = {}

local profiles = {}
local statuses = {}
local baseIndices = {}
local saveBusy = {}
local store = nil
local studioMemoryOnly = Config.StudioMemoryOnly and RunService:IsStudio()

local function defaultProfile()
    return {
        DataVersion = Config.DataVersion,
        Coins = Config.StartingCoins,
        PendingCoins = 0,
        GreekEggs = 0,
        Gods = { Zeus = 0 },
        BaseLevel = 1,
        _SAGSession = nil,
    }
end

local function sanitizeProfile(source)
    local data = defaultProfile()
    if type(source) ~= "table" then
        return data
    end

    local coins = tonumber(source.Coins)
    local pending = tonumber(source.PendingCoins)
    local eggs = tonumber(source.GreekEggs)
    local baseLevel = tonumber(source.BaseLevel)
    local gods = source.Gods
    local zeus = type(gods) == "table" and tonumber(gods.Zeus) or nil

    if coins and coins >= 0 then data.Coins = math.floor(coins) end
    if pending and pending >= 0 then data.PendingCoins = math.floor(pending) end
    if eggs and eggs >= 0 then data.GreekEggs = math.min(Config.MaxGreekEggs, math.floor(eggs)) end
    if zeus and zeus >= 0 then data.Gods.Zeus = math.min(Config.MaxZeus, math.floor(zeus)) end
    if baseLevel and baseLevel >= 1 then
        data.BaseLevel = math.clamp(math.floor(baseLevel), 1, Config.MaxBaseLevel)
    end
    data.DataVersion = Config.DataVersion

    if type(source._SAGSession) == "table" then
        data._SAGSession = {
            JobId = tostring(source._SAGSession.JobId or ""),
            ExpiresAt = tonumber(source._SAGSession.ExpiresAt) or 0,
        }
    end

    return data
end

local function storageCopy(data, releaseLock)
    local saved = sanitizeProfile(data)
    if releaseLock then
        saved._SAGSession = nil
    else
        saved._SAGSession = {
            JobId = game.JobId,
            ExpiresAt = os.time() + Config.SessionLeaseSeconds,
        }
    end
    return saved
end

local function getStore()
    if not store then
        store = DataStoreService:GetDataStore(Config.DataStoreName)
    end
    return store
end

local function publish(player, data)
    if not player or player.Parent ~= Players then return end
    player:SetAttribute("SAG_DataReady", profiles[player] ~= nil)
    player:SetAttribute("SAG_Coins", data and data.Coins or 0)
    player:SetAttribute("SAG_PendingCoins", data and data.PendingCoins or 0)
    player:SetAttribute("SAG_GreekEggs", data and data.GreekEggs or 0)
    player:SetAttribute("SAG_ZeusCount", data and data.Gods.Zeus or 0)
    player:SetAttribute("SAG_BaseLevel", data and data.BaseLevel or 1)
    player:SetAttribute("SAG_BaseIndex", baseIndices[player] or 0)
    player:SetAttribute("SAG_Status", statuses[player] or "Carregando perfil...")
end

local function waitForSaveSlot(player)
    while saveBusy[player] do
        task.wait(0.05)
    end
    saveBusy[player] = true
end

local function releaseSaveSlot(player)
    saveBusy[player] = nil
end

function PlayerDataService.Load(player)
    if profiles[player] then
        return profiles[player]
    end

    local loaded
    if studioMemoryOnly then
        loaded = defaultProfile()
        warn("[SAG] Studio memory mode: DataStore persistence is disabled for this playtest.")
    else
        local now = os.time()
        local ok, result = pcall(function()
            return getStore():UpdateAsync("Player_" .. player.UserId, function(oldData)
                local current = sanitizeProfile(oldData)
                local session = current._SAGSession
                if session and session.JobId ~= game.JobId and session.ExpiresAt > now then
                    return nil
                end
                current._SAGSession = {
                    JobId = game.JobId,
                    ExpiresAt = now + Config.SessionLeaseSeconds,
                }
                return current
            end)
        end)

        if not ok then
            return nil, tostring(result)
        end
        if type(result) ~= "table" or type(result._SAGSession) ~= "table"
            or result._SAGSession.JobId ~= game.JobId then
            return nil, "Perfil já está ativo em outro servidor."
        end
        loaded = sanitizeProfile(result)
    end

    profiles[player] = loaded
    statuses[player] = "Vá ao hub e compre um Greek Egg."
    publish(player, loaded)
    return loaded
end

function PlayerDataService.Get(player)
    return profiles[player]
end

function PlayerDataService.SetBaseIndex(player, index)
    baseIndices[player] = index or 0
    local data = profiles[player]
    publish(player, data)
end

function PlayerDataService.SetStatus(player, message)
    statuses[player] = tostring(message or "")
    publish(player, profiles[player])
end

function PlayerDataService.TryBuyGreekEgg(player)
    local data = profiles[player]
    if not data then return false, "Seu perfil ainda está carregando." end
    if data.GreekEggs >= Config.MaxGreekEggs then
        return false, "Seu inventário de ovos está cheio."
    end
    if data.Coins < Config.GreekEggPrice then
        return false, "Você precisa de mais Coins."
    end

    data.Coins -= Config.GreekEggPrice
    data.GreekEggs += 1
    publish(player, data)
    return true, "Greek Egg comprado."
end

function PlayerDataService.TryHatchGreekEgg(player)
    local data = profiles[player]
    if not data then return false, "Seu perfil ainda está carregando." end
    if data.GreekEggs < 1 then return false, "Compre um Greek Egg no hub primeiro." end
    if data.Gods.Zeus >= Config.MaxZeus then return false, "Você já tem Zeus neste protótipo." end

    data.GreekEggs -= 1
    data.Gods.Zeus += 1
    publish(player, data)
    return true, "O ovo chocou: Zeus entrou na sua coleção."
end

function PlayerDataService.TryUpgradeBase(player)
    local data = profiles[player]
    if not data then return false, "Seu perfil ainda está carregando." end
    if data.BaseLevel >= Config.MaxBaseLevel then
        return false, "Sua base já está no nível máximo deste protótipo."
    end
    if data.Coins < Config.BaseUpgradeCost then
        return false, "Você precisa de mais Coins para melhorar a base."
    end

    data.Coins -= Config.BaseUpgradeCost
    data.BaseLevel += 1
    publish(player, data)
    return true, "Base melhorada para o nível " .. data.BaseLevel .. "."
end

function PlayerDataService.AddPendingCoins(player, amount)
    local data = profiles[player]
    if not data or type(amount) ~= "number" or amount <= 0 then return end
    data.PendingCoins += math.floor(amount)
    publish(player, data)
end

function PlayerDataService.CollectPendingCoins(player)
    local data = profiles[player]
    if not data then return 0 end
    local amount = math.floor(data.PendingCoins)
    if amount <= 0 then return 0 end
    data.PendingCoins -= amount
    data.Coins += amount
    publish(player, data)
    return amount
end

function PlayerDataService.Save(player, releaseLock)
    local data = profiles[player]
    if not data then return false end
    if studioMemoryOnly then return true end

    waitForSaveSlot(player)
    local snapshot = storageCopy(data, releaseLock == true)
    local ok, result = pcall(function()
        return getStore():UpdateAsync("Player_" .. player.UserId, function(oldData)
            if type(oldData) == "table" and type(oldData._SAGSession) == "table"
                and oldData._SAGSession.JobId ~= game.JobId then
                return nil
            end
            return snapshot
        end)
    end)
    releaseSaveSlot(player)

    if not ok or result == nil then
        warn("[SAG] Save failed for " .. player.Name .. ": " .. tostring(result))
        return false
    end
    return true
end

function PlayerDataService.Unload(player)
    PlayerDataService.Save(player, true)
    profiles[player] = nil
    statuses[player] = nil
    baseIndices[player] = nil
    saveBusy[player] = nil
end

function PlayerDataService.IsStudioMemoryMode()
    return studioMemoryOnly
end

return PlayerDataService
