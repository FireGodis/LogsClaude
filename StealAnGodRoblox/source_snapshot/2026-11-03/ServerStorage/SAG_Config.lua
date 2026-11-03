--!strict
-- Tunables for the initial STEAL A GOD vertical slice.
-- Keep balance values centralized; move them to ConfigService when live tuning/experiments are needed.
return {
    WorldName = "SAG_GameWorld",
    BaseCount = 7,
    BaseRadius = 108,
    InteractionDistance = 14,
    PromptHoldDuration = 0.25,

    StartingCoins = 150,
    GreekEggPrice = 100,
    MaxGreekEggs = 10,
    MaxZeus = 1,
    ZeusIncomePerSecond = 4,
    MaxBaseLevel = 2,
    BaseUpgradeCost = 100,
    BaseUpgradeIncomeBonus = 0.25,

    BotAI = {
        Enabled = true,
        Name = "ARES",
        Personality = "Aggressive",
        SpawnBaseIndex = 7,
        DecisionInterval = 1.25,
        IncomeInterval = 1,
        WalkSpeed = 16,
        MaxPathRetries = 3,
    },

    DataVersion = 1,
    DataStoreName = "SAG_PlayerData_v1",
    AutoSaveSeconds = 120,
    SessionLeaseSeconds = 240,
    StudioMemoryOnly = true,
}