--[[
	GameConfig.luau — non-numeric tunables: world layout, events, achievements, index rewards,
	sounds, UI theme and bot personalities. Numeric balance lives in Balance.json.
]]

local C3 = Color3.fromRGB

local GameConfig = {}

-- ===================== WORLD LAYOUT =====================
-- The avenue runs along +Z. Hub (spawn + bases) is Z in [0, HUB_LENGTH].
GameConfig.World = {
	HubLength = 340,
	HubWidth = 260,
	AvenueWidth = 44,
	BiomeLength = 240,
	BiomeWidth = 190,
	NestsPerBiome = 6,
	BaseSize = Vector3.new(76, 1, 70), -- local X = width, local Z = depth (entrance at -Z)
	BaseOffsetX = 88, -- distance from avenue center to base center
	BaseRows = { 50, 130, 210, 290 }, -- Z positions: left side uses all 4, right side the first 3 (row 4 right = shop plaza)
	SpawnPosition = Vector3.new(0, 5, 20),
	FloorY = 0,
}

-- ===================== WORLD EVENTS =====================
GameConfig.Events = {
	{ id = "DivineEclipse", name = "ECLIPSE DIVINO", mythology = "Greek", color = C3(150, 90, 255),
		desc = "O céu escurece, raios caem e ovos do eclipse surgem pelo mapa!",
		lighting = { ClockTime = 0.5, Brightness = 1, Ambient = C3(60, 40, 90), OutdoorAmbient = C3(70, 50, 110), FogColor = C3(40, 20, 70) } },
	{ id = "Ragnarok", name = "RAGNAROK", mythology = "Norse", color = C3(255, 90, 40),
		desc = "O fim dos tempos chegou: brasas caem do céu e ovos de Muspelheim aparecem!",
		lighting = { ClockTime = 18.2, Brightness = 2, Ambient = C3(110, 50, 30), OutdoorAmbient = C3(140, 60, 40), FogColor = C3(90, 30, 20) } },
	{ id = "SolarAscension", name = "ASCENSÃO SOLAR", mythology = "Egyptian", color = C3(255, 200, 60),
		desc = "Rá brilha mais forte que nunca: ovos solares dourados descem do céu!",
		lighting = { ClockTime = 12, Brightness = 4, Ambient = C3(160, 130, 70), OutdoorAmbient = C3(200, 170, 90), FogColor = C3(255, 220, 150) } },
	{ id = "FuryOfGods", name = "FÚRIA DOS DEUSES", mythology = "All", color = C3(255, 60, 90),
		desc = "Os guardiões estão enfurecidos (+20% velocidade), mas os ovos de evento valem muito!",
		lighting = { ClockTime = 16.5, Brightness = 2.2, Ambient = C3(120, 60, 70), OutdoorAmbient = C3(150, 70, 80), FogColor = C3(80, 30, 40) } },
}

-- ===================== INDEX REWARDS =====================
-- type: Gold (seconds of income, min), Trail, Title, Keys (reliquary keys), SpecialEgg
GameConfig.IndexMilestones = {
	{ id = "First", percent = 0, count = 1, label = "Primeira criatura", reward = { type = "Gold", seconds = 120, minimum = 200 } },
	{ id = "P25", percent = 25, label = "25% do Index", reward = { type = "Gold", seconds = 900, minimum = 5000, keys = 1 } },
	{ id = "P50", percent = 50, label = "50% do Index", reward = { type = "SpecialEgg", keys = 1, title = "Colecionador" } },
	{ id = "P75", percent = 75, label = "75% do Index", reward = { type = "Trail", trail = "Collector", keys = 2 } },
	{ id = "P100", percent = 100, label = "100% do Index", reward = { type = "Gold", seconds = 7200, minimum = 1e9, keys = 5, title = "Mestre do Panteão" } },
	{ id = "Greek", mythology = "Greek", label = "Panteão Grego completo", reward = { type = "Gold", seconds = 3600, minimum = 50000, title = "Herói do Olimpo", keys = 1 } },
	{ id = "Norse", mythology = "Norse", label = "Panteão Nórdico completo", reward = { type = "Gold", seconds = 3600, minimum = 5e6, title = "Einherjar", keys = 1 } },
	{ id = "Egyptian", mythology = "Egyptian", label = "Panteão Egípcio completo", reward = { type = "Gold", seconds = 3600, minimum = 5e8, title = "Filho de Rá", keys = 1 } },
}
-- Every biome whose 4 creatures are all discovered grants this (scaled by biome).
GameConfig.BiomeCompleteReward = { type = "Gold", seconds = 600, minimumPerBiome = 500 }

-- ===================== ACHIEVEMENTS =====================
-- badgeId = 0 means no Roblox badge is awarded (create badges, then fill ids).
GameConfig.Achievements = {
	{ id = "FirstEgg", name = "First Egg", desc = "Roube seu primeiro ovo.", stat = "eggsStolen", goal = 1, badgeId = 0, icon = "🥚" },
	{ id = "FirstHatch", name = "First Hatch", desc = "Choque seu primeiro ovo.", stat = "hatched", goal = 1, badgeId = 0, icon = "🐣" },
	{ id = "FirstDivine", name = "First Divine Pet", desc = "Obtenha uma criatura Divine.", stat = "divinePets", goal = 1, badgeId = 0, icon = "✨" },
	{ id = "FirstMillion", name = "First Million", desc = "Acumule 1M de GOLD ganho.", stat = "totalEarned", goal = 1e6, badgeId = 0, icon = "💰" },
	{ id = "FirstBillion", name = "First Billion", desc = "Acumule 1B de GOLD ganho.", stat = "totalEarned", goal = 1e9, badgeId = 0, icon = "🏦" },
	{ id = "FirstRaid", name = "First Raid", desc = "Roube um ovo da base de outro jogador.", stat = "raids", goal = 1, badgeId = 0, icon = "🗡" },
	{ id = "FirstDefense", name = "First Successful Defense", desc = "Recupere um ovo de um ladrão.", stat = "defenses", goal = 1, badgeId = 0, icon = "🛡" },
	{ id = "FirstBiome", name = "First Biome Unlocked", desc = "Desbloqueie a Costa do Mar Egeu.", stat = "biomesUnlocked", goal = 2, badgeId = 0, icon = "🗺" },
	{ id = "Collector", name = "Collector", desc = "Descubra 12 criaturas.", stat = "discovered", goal = 12, badgeId = 0, icon = "📖" },
	{ id = "MasterCollector", name = "Master Collector", desc = "Descubra 40 criaturas.", stat = "discovered", goal = 40, badgeId = 0, icon = "📚" },
	{ id = "GodHunter", name = "God Hunter", desc = "Choque 250 ovos.", stat = "hatched", goal = 250, badgeId = 0, icon = "🏹" },
	{ id = "AllGreek", name = "All Greek Gods", desc = "Complete o panteão grego.", stat = "greekComplete", goal = 1, badgeId = 0, icon = "⚡" },
	{ id = "AllNorse", name = "All Norse Gods", desc = "Complete o panteão nórdico.", stat = "norseComplete", goal = 1, badgeId = 0, icon = "🔨" },
	{ id = "AllEgyptian", name = "All Egyptian Gods", desc = "Complete o panteão egípcio.", stat = "egyptianComplete", goal = 1, badgeId = 0, icon = "☀" },
}

-- ===================== SOUNDS =====================
-- Only built-in engine sounds (rbxasset://) are referenced by default. Replace with your own
-- uploaded/authorized asset ids ("rbxassetid://123") — see docs/AUDIO.md. Empty string = silent.
GameConfig.Sounds = {
	UIClick = "rbxasset://sounds/button.wav",
	Notify = "rbxasset://sounds/electronicpingshort.wav",
	Pickup = "rbxasset://sounds/electronicpingshort.wav",
	Steal = "rbxasset://sounds/swordlunge.wav",
	Deposit = "rbxasset://sounds/electronicpingshort.wav",
	Hatch = "rbxasset://sounds/electronicpingshort.wav",
	Purchase = "rbxasset://sounds/button.wav",
	Unlock = "rbxasset://sounds/electronicpingshort.wav",
	Coins = "",
	Ability = "rbxasset://sounds/swordlunge.wav",
	GuardianAttack = "rbxasset://sounds/swordlunge.wav",
	Trap = "rbxasset://sounds/swordlunge.wav",
	Alarm = "rbxasset://sounds/electronicpingshort.wav",
	EventStart = "",
	MusicGreek = "",
	MusicNorse = "",
	MusicEgyptian = "",
	MusicHub = "",
}

-- ===================== UI THEME =====================
GameConfig.Theme = {
	Panel = C3(24, 22, 48),
	PanelLight = C3(42, 38, 82),
	Gold = C3(255, 206, 64),
	GoldDark = C3(196, 132, 20),
	Accent = C3(110, 200, 255),
	Text = C3(255, 255, 255),
	TextDim = C3(190, 190, 220),
	Good = C3(90, 220, 110),
	Bad = C3(255, 80, 90),
	Greek = C3(90, 170, 255),
	Norse = C3(130, 220, 255),
	Egyptian = C3(255, 190, 70),
	Event = C3(255, 110, 200),
	Font = Enum.Font.FredokaOne,
	FontBody = Enum.Font.GothamBold,
}

-- ===================== BOTS =====================
GameConfig.BotNames = {
	"NovaRunner", "PixelHermes", "ZephyrKid", "LunaBlaze", "OrbitFox", "TitanTaco", "AzureWolf", "SunnyRaptor",
	"MythMaker", "GlitchOwl", "CosmoBean", "RuneRider", "FrostByte", "AmberLynx", "KiloKraken", "VoltPanda",
	"EchoSprite", "NimbusJay", "BlazeOtter", "QuartzBunny", "SableComet", "MangoMinotaur", "RiftRacer", "TidalTurtle",
	"NeonPharaoh", "Valkyrix", "ObsidianCat", "PrismPegasus", "SkyScarab", "HexHopper",
}

GameConfig.BotPersonalities = {
	Beginner = { label = "Iniciante", train = 1.4, steal = 0.8, raid = 0.1, collect = 0.6, upgrade = 0.7, explore = 0.4, special = 0.4, risk = 0.25, idle = 1.8, skill = 0.55, maxBiomeAhead = 0 },
	Collector = { label = "Colecionador", train = 1.0, steal = 1.2, raid = 0.25, collect = 1.5, upgrade = 1.1, explore = 0.8, special = 0.8, risk = 0.45, idle = 1.0, skill = 0.75, maxBiomeAhead = 1 },
	Competitive = { label = "Competitivo", train = 1.1, steal = 1.2, raid = 1.2, collect = 0.8, upgrade = 1.0, explore = 0.9, special = 1.6, risk = 0.8, idle = 0.6, skill = 0.9, maxBiomeAhead = 0 },
	Investor = { label = "Investidor", train = 0.9, steal = 1.0, raid = 0.3, collect = 1.0, upgrade = 1.7, explore = 0.5, special = 0.7, risk = 0.4, idle = 0.9, skill = 0.8, maxBiomeAhead = 0 },
	Explorer = { label = "Explorador", train = 1.0, steal = 1.0, raid = 0.5, collect = 1.0, upgrade = 0.9, explore = 1.6, special = 1.1, risk = 0.6, idle = 1.0, skill = 0.7, maxBiomeAhead = 1 },
}

return GameConfig
