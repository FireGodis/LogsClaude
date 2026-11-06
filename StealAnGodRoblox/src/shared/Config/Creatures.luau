--[[
	Creatures.luau — catalog of every creature in STEAL AN GOD.
	48 biome creatures (4 per biome, slot 4 = strongest) + 4 event-exclusive creatures.

	Ability kinds (technical categories, implemented in AbilityService):
	  SpeedBurst   {mult, duration}            temporary WalkSpeed multiplier
	  Dash         {power}                     forward impulse
	  Leap         {power}                     upward + forward impulse
	  Reveal       {radius, duration, filter}  highlights eggs/guardians ("all"|"rare"|"special"|"guardians")
	  Shockwave    {radius, stun}              stuns guardians in radius
	  Frost        {radius, slow, duration}    slows guardians in radius
	  Decoy        {duration}                  spawns a clone that guardians chase
	  GuardShield  {duration}                  blocks the next guardian hit
	  EggShield    {duration}                  carried egg cannot be dropped
	  WeightRelief {reduction, duration}       reduces carry penalty (0..1 of the penalty)
	  TrapWard     {duration}                  immune to traps
	  Rescue       {}                          frees from trap/stun, returns to safety if fallen
	  HatchBoost   {seconds}                   removes seconds from all own incubating eggs (capped)
	  IncomeBoost  {mult, duration}            temporary pet income multiplier
	  TrainBoost   {mult, duration}            temporary treadmill gain multiplier
	  CatchReach   {radius, duration}          larger catch radius while defending the base

	Balance rules (see docs/ABILITIES.md): no teleports to the end of the map, no remote stealing,
	no infinite money, no stunning players, every ability has a cooldown + global immunity window.
]]

local C3 = Color3.fromRGB

local list = {
	-- ===================== GREEK =====================
	-- Biome 1 — Bosque de Arcadia
	{ id = "ArcadianNymph", name = "Arcadian Nymph", biome = 1, slot = 1, arch = "Spirit", colors = { C3(140, 220, 120), C3(255, 240, 200), C3(255, 150, 200) }, acc = "flower",
		desc = "Uma ninfa do bosque que faz as flores brotarem por onde passa.",
		ab = { name = "Bloom Step", kind = "SpeedBurst", cd = 40, p = { mult = 1.15, duration = 4 }, desc = "Pequena aceleração florida por 4s." } },
	{ id = "SatyrPiper", name = "Satyr Piper", biome = 1, slot = 2, arch = "Humanoid", colors = { C3(150, 100, 60), C3(230, 190, 150), C3(120, 200, 90) }, acc = "horns",
		desc = "O sátiro cuja flauta embala até os guardiões mais atentos.",
		ab = { name = "Lullaby Pipe", kind = "Frost", cd = 45, p = { radius = 30, slow = 0.35, duration = 4 }, desc = "A melodia deixa guardiões próximos 35% mais lentos por 4s." } },
	{ id = "Artemis", name = "Artemis", biome = 1, slot = 3, arch = "Humanoid", colors = { C3(220, 230, 255), C3(120, 150, 210), C3(240, 240, 255) }, acc = "bow",
		desc = "Deusa da caça, nada escapa de seus olhos sob a lua.",
		ab = { name = "Caçadora Celestial", kind = "Reveal", cd = 50, p = { radius = 140, duration = 8, filter = "rare" }, desc = "Revela ovos raros escondidos nas proximidades por 8s." } },
	{ id = "Hermes", name = "Hermes", biome = 1, slot = 4, arch = "Humanoid", colors = { C3(255, 220, 120), C3(240, 240, 240), C3(120, 200, 255) }, acc = "wings",
		desc = "O mensageiro dos deuses, com sandálias aladas.",
		ab = { name = "Passos Divinos", kind = "SpeedBurst", cd = 45, p = { mult = 1.35, duration = 5 }, desc = "Aceleração de 35% por 5s para fugas rápidas." } },

	-- Biome 2 — Costa do Mar Egeu
	{ id = "Hippocampus", name = "Hippocampus", biome = 2, slot = 1, arch = "Horse", colors = { C3(60, 170, 220), C3(200, 240, 255), C3(40, 220, 180) }, acc = "fins",
		desc = "Cavalo-marinho que galopa sobre as ondas do Egeu.",
		ab = { name = "Wave Gallop", kind = "Dash", cd = 35, p = { power = 70 }, desc = "Um galope curto para frente sobre a espuma." } },
	{ id = "Siren", name = "Siren", biome = 2, slot = 2, arch = "Bird", colors = { C3(90, 200, 230), C3(255, 210, 230), C3(255, 255, 255) }, acc = "none",
		desc = "Seu canto confunde os sentidos dos guardiões.",
		ab = { name = "Echo Song", kind = "Decoy", cd = 60, p = { duration = 4 }, desc = "Cria um eco ilusório que os guardiões perseguem por 4s." } },
	{ id = "Medusa", name = "Medusa", biome = 2, slot = 3, arch = "Serpent", colors = { C3(90, 160, 90), C3(200, 220, 160), C3(255, 220, 60) }, acc = "crown",
		desc = "Seu olhar petrifica — por pouco tempo.",
		ab = { name = "Stone Gaze", kind = "Shockwave", cd = 55, p = { radius = 22, stun = 2.5 }, desc = "Petrifica guardiões a até 22 studs por 2.5s." } },
	{ id = "Poseidon", name = "Poseidon", biome = 2, slot = 4, arch = "Humanoid", colors = { C3(40, 110, 200), C3(230, 240, 255), C3(80, 230, 210) }, acc = "trident",
		desc = "Senhor dos mares, carrega o tridente que move oceanos.",
		ab = { name = "Maré Protetora", kind = "WeightRelief", cd = 50, p = { reduction = 0.6, duration = 8 }, desc = "Reduz 60% da penalidade de peso do ovo por 8s." } },

	-- Biome 3 — Labirinto de Minos
	{ id = "Minotaur", name = "Minotaur", biome = 3, slot = 1, arch = "Quadruped", colors = { C3(120, 70, 40), C3(200, 170, 130), C3(230, 230, 230) }, acc = "horns",
		desc = "O guardião furioso do labirinto, agora seu aliado.",
		ab = { name = "Bull Rush", kind = "Dash", cd = 35, p = { power = 85 }, desc = "Uma investida violenta para frente." } },
	{ id = "Cerberus", name = "Cerberus", biome = 3, slot = 2, arch = "Canine", colors = { C3(50, 40, 45), C3(150, 40, 40), C3(255, 120, 40) }, acc = "flame",
		desc = "Três cabeças, três vezes mais atenção à sua base.",
		ab = { name = "Triple Watch", kind = "CatchReach", cd = 60, p = { radius = 14, duration = 12 }, desc = "Dobra seu alcance de captura de ladrões por 12s." } },
	{ id = "Hades", name = "Hades", biome = 3, slot = 3, arch = "Humanoid", colors = { C3(40, 30, 60), C3(120, 80, 200), C3(80, 255, 200) }, acc = "crown",
		desc = "Rei do submundo, nada o fere duas vezes.",
		ab = { name = "Escudo do Submundo", kind = "GuardShield", cd = 60, p = { duration = 10 }, desc = "Bloqueia o primeiro golpe de guardião por 10s." } },
	{ id = "Ares", name = "Ares", biome = 3, slot = 4, arch = "Humanoid", colors = { C3(170, 40, 40), C3(200, 170, 90), C3(255, 120, 60) }, acc = "helmet",
		desc = "Deus da guerra, sua fúria ecoa pelo labirinto.",
		ab = { name = "Fúria do Guerreiro", kind = "Shockwave", cd = 50, p = { radius = 28, stun = 3 }, desc = "Onda de choque que interrompe guardiões por 3s." } },

	-- Biome 4 — Monte Olimpo
	{ id = "Pegasus", name = "Pegasus", biome = 4, slot = 1, arch = "Horse", colors = { C3(250, 250, 255), C3(200, 220, 255), C3(255, 220, 120) }, acc = "wings",
		desc = "O cavalo alado nascido das nuvens do Olimpo.",
		ab = { name = "Cloud Leap", kind = "Leap", cd = 35, p = { power = 70 }, desc = "Um salto alado sobre obstáculos." } },
	{ id = "Athena", name = "Athena", biome = 4, slot = 2, arch = "Humanoid", colors = { C3(200, 200, 215), C3(90, 110, 160), C3(255, 210, 90) }, acc = "helmet",
		desc = "Deusa da sabedoria e da estratégia.",
		ab = { name = "Visão Estratégica", kind = "Reveal", cd = 55, p = { radius = 160, duration = 8, filter = "all" }, desc = "Revela ninhos, ovos especiais e guardiões por 8s." } },
	{ id = "Apollo", name = "Apollo", biome = 4, slot = 3, arch = "Humanoid", colors = { C3(255, 210, 90), C3(255, 250, 230), C3(255, 140, 40) }, acc = "lyre",
		desc = "Deus do sol e da música; sua luz acelera a vida.",
		ab = { name = "Luz da Vida", kind = "HatchBoost", cd = 120, p = { seconds = 30 }, desc = "Reduz 30s da incubação de todos os seus ovos." } },
	{ id = "Zeus", name = "Zeus", biome = 4, slot = 4, arch = "Humanoid", colors = { C3(240, 240, 255), C3(80, 120, 220), C3(255, 240, 80) }, acc = "lightning",
		desc = "O rei do Olimpo, senhor dos raios.",
		ab = { name = "Tempestade Divina", kind = "Dash", cd = 45, p = { power = 110 }, desc = "Impulso elétrico para escapar de situações perigosas." } },

	-- ===================== NORSE =====================
	-- Biome 5 — Campos de Midgard
	{ id = "Ratatoskr", name = "Ratatoskr", biome = 5, slot = 1, arch = "Quadruped", colors = { C3(200, 110, 50), C3(250, 220, 180), C3(120, 200, 255) }, acc = "rune",
		desc = "O esquilo mensageiro que corre pela Yggdrasil.",
		ab = { name = "Branch Sprint", kind = "SpeedBurst", cd = 40, p = { mult = 1.25, duration = 5 }, desc = "Corrida ágil de 25% por 5s." } },
	{ id = "Huginn", name = "Huginn", biome = 5, slot = 2, arch = "Bird", colors = { C3(30, 30, 40), C3(80, 80, 110), C3(120, 200, 255) }, acc = "rune",
		desc = "O corvo do pensamento, olhos de Odin.",
		ab = { name = "Raven Scout", kind = "Reveal", cd = 45, p = { radius = 120, duration = 7, filter = "guardians" }, desc = "Mostra todos os guardiões próximos por 7s." } },
	{ id = "Fenrir", name = "Fenrir", biome = 5, slot = 3, arch = "Canine", colors = { C3(90, 90, 110), C3(200, 200, 220), C3(120, 200, 255) }, acc = "rune",
		desc = "O lobo colossal que nenhuma corrente segura.",
		ab = { name = "Instinto Predatório", kind = "SpeedBurst", cd = 45, p = { mult = 1.3, duration = 5, carryingOnly = true }, desc = "Aceleração de 30% por 5s enquanto carrega um ovo." } },
	{ id = "Freyja", name = "Freyja", biome = 5, slot = 4, arch = "Humanoid", colors = { C3(255, 200, 150), C3(240, 160, 200), C3(255, 230, 120) }, acc = "crown",
		desc = "Senhora de Fólkvangr, abençoa tudo que nasce.",
		ab = { name = "Bênção de Fólkvangr", kind = "HatchBoost", cd = 110, p = { seconds = 45 }, desc = "Reduz 45s da incubação de todos os seus ovos." } },

	-- Biome 6 — Jotunheim
	{ id = "FrostTroll", name = "Frost Troll", biome = 6, slot = 1, arch = "Golem", colors = { C3(150, 200, 230), C3(230, 245, 255), C3(80, 140, 200) }, acc = "crystal",
		desc = "Um troll de gelo que hiberna em cavernas congeladas.",
		ab = { name = "Glacier Hide", kind = "GuardShield", cd = 55, p = { duration = 8 }, desc = "Pele de gelo bloqueia um golpe de guardião (8s)." } },
	{ id = "Skadi", name = "Skadi", biome = 6, slot = 2, arch = "Humanoid", colors = { C3(220, 240, 255), C3(80, 120, 170), C3(160, 230, 255) }, acc = "bow",
		desc = "Deusa do inverno e da caça nas montanhas.",
		ab = { name = "Passos Congelantes", kind = "Frost", cd = 45, p = { radius = 34, slow = 0.5, duration = 5 }, desc = "Guardiões próximos ficam 50% mais lentos por 5s." } },
	{ id = "JotunMammoth", name = "Jotun Mammoth", biome = 6, slot = 3, arch = "Quadruped", colors = { C3(120, 90, 70), C3(240, 240, 240), C3(170, 220, 255) }, acc = "horns",
		desc = "Um mamute gigante que carrega fardos sem esforço.",
		ab = { name = "Titan Back", kind = "WeightRelief", cd = 50, p = { reduction = 0.75, duration = 7 }, desc = "Reduz 75% da penalidade de peso por 7s." } },
	{ id = "Jormungandr", name = "Jormungandr", biome = 6, slot = 4, arch = "Serpent", colors = { C3(40, 120, 100), C3(150, 220, 180), C3(80, 255, 220) }, acc = "rune",
		desc = "A Serpente do Mundo que abraça Midgard.",
		ab = { name = "Serpente Mundial", kind = "Shockwave", cd = 55, p = { radius = 32, stun = 3 }, desc = "Uma onda que impede perseguições por 3s." } },

	-- Biome 7 — Forjas de Nidavellir
	{ id = "ForgeGolem", name = "Forge Golem", biome = 7, slot = 1, arch = "Golem", colors = { C3(80, 70, 70), C3(255, 120, 40), C3(255, 200, 80) }, acc = "flame",
		desc = "Construído por anões, alimentado por lava.",
		ab = { name = "Molten Shell", kind = "TrapWard", cd = 50, p = { duration = 12 }, desc = "Imune a armadilhas por 12s." } },
	{ id = "Brokkr", name = "Brokkr", biome = 7, slot = 2, arch = "Humanoid", colors = { C3(150, 90, 50), C3(200, 160, 120), C3(255, 200, 60) }, acc = "hammer",
		desc = "O mestre ferreiro que forjou o Mjölnir.",
		ab = { name = "Bellows Rhythm", kind = "TrainBoost", cd = 120, p = { mult = 1.5, duration = 30 }, desc = "+50% de Speed na esteira por 30s." } },
	{ id = "Nidhogg", name = "Nidhogg", biome = 7, slot = 3, arch = "Dragon", colors = { C3(60, 40, 40), C3(160, 60, 40), C3(255, 140, 40) }, acc = "flame",
		desc = "O dragão que rói as raízes da Árvore do Mundo.",
		ab = { name = "Root Burrow", kind = "Rescue", cd = 90, p = {}, desc = "Liberta de armadilhas e atordoamentos, salva de quedas." } },
	{ id = "Loki", name = "Loki", biome = 7, slot = 4, arch = "Humanoid", colors = { C3(40, 120, 60), C3(220, 200, 80), C3(120, 255, 120) }, acc = "horns",
		desc = "O trapaceiro dos nove reinos.",
		ab = { name = "Ilusão", kind = "Decoy", cd = 55, p = { duration = 6 }, desc = "Cria um clone que distrai os guardiões por 6s." } },

	-- Biome 8 — Asgard
	{ id = "Valkyrie", name = "Valkyrie", biome = 8, slot = 1, arch = "Humanoid", colors = { C3(220, 220, 230), C3(255, 210, 90), C3(255, 255, 255) }, acc = "wings",
		desc = "Guerreira alada que escolhe os bravos.",
		ab = { name = "Wing Glide", kind = "Leap", cd = 35, p = { power = 85 }, desc = "Um salto planado sobre obstáculos." } },
	{ id = "Heimdall", name = "Heimdall", biome = 8, slot = 2, arch = "Humanoid", colors = { C3(255, 220, 120), C3(240, 240, 255), C3(255, 120, 200) }, acc = "helmet",
		desc = "O guardião da Bifröst, vê e ouve tudo.",
		ab = { name = "Visão dos Nove Reinos", kind = "Reveal", cd = 50, p = { radius = 300, duration = 10, filter = "special" }, desc = "Revela ovos especiais e de evento a até 300 studs." } },
	{ id = "Thor", name = "Thor", biome = 8, slot = 3, arch = "Humanoid", colors = { C3(200, 50, 50), C3(255, 220, 120), C3(120, 200, 255) }, acc = "hammer",
		desc = "O deus do trovão e seu martelo Mjölnir.",
		ab = { name = "Martelo de Mjölnir", kind = "Shockwave", cd = 50, p = { radius = 30, stun = 3.5 }, desc = "Impacto que interrompe guardiões por 3.5s." } },
	{ id = "Odin", name = "Odin", biome = 8, slot = 4, arch = "Humanoid", colors = { C3(90, 90, 110), C3(200, 180, 120), C3(120, 200, 255) }, acc = "spear",
		desc = "O Pai de Todos, sábio além da medida.",
		ab = { name = "Conhecimento Ancestral", kind = "Reveal", cd = 55, p = { radius = 220, duration = 10, filter = "rare" }, desc = "Revela ovos raros e oportunidades a até 220 studs." } },

	-- ===================== EGYPTIAN =====================
	-- Biome 9 — Oasis do Nilo
	{ id = "SacredScarab", name = "Sacred Scarab", biome = 9, slot = 1, arch = "Insect", colors = { C3(40, 160, 140), C3(255, 200, 60), C3(80, 220, 255) }, acc = "sun",
		desc = "O escaravelho que rola o sol pelo céu.",
		ab = { name = "Sun Roll", kind = "IncomeBoost", cd = 120, p = { mult = 1.25, duration = 30 }, desc = "+25% de renda dos pets por 30s." } },
	{ id = "NileIbis", name = "Nile Ibis", biome = 9, slot = 2, arch = "Bird", colors = { C3(250, 250, 250), C3(30, 30, 30), C3(255, 120, 80) }, acc = "none",
		desc = "A ave sagrada que caminha pelas margens do Nilo.",
		ab = { name = "Marsh Stride", kind = "SpeedBurst", cd = 40, p = { mult = 1.25, duration = 5 }, desc = "+25% de velocidade por 5s." } },
	{ id = "Sobek", name = "Sobek", biome = 9, slot = 3, arch = "Dragon", colors = { C3(60, 110, 60), C3(200, 190, 120), C3(255, 210, 80) }, acc = "crown",
		desc = "Deus crocodilo, força bruta do Nilo.",
		ab = { name = "Força do Nilo", kind = "WeightRelief", cd = 45, p = { reduction = 0.7, duration = 8 }, desc = "Reduz 70% da penalidade de ovos pesados por 8s." } },
	{ id = "Bastet", name = "Bastet", biome = 9, slot = 4, arch = "Feline", colors = { C3(30, 30, 35), C3(255, 210, 80), C3(80, 200, 255) }, acc = "crown",
		desc = "Deusa felina, protetora dos lares.",
		ab = { name = "Agilidade Felina", kind = "Dash", cd = 30, p = { power = 75 }, desc = "Pequeno impulso felino de movimentação." } },

	-- Biome 10 — Necropole
	{ id = "Sphinx", name = "Sphinx", biome = 10, slot = 1, arch = "Feline", colors = { C3(210, 180, 120), C3(60, 90, 160), C3(255, 210, 80) }, acc = "mask",
		desc = "Guardiã dos enigmas, observa tudo sem piscar.",
		ab = { name = "Riddle Ward", kind = "CatchReach", cd = 60, p = { radius = 15, duration = 12 }, desc = "Alcance de captura ampliado por 12s." } },
	{ id = "Wadjet", name = "Wadjet", biome = 10, slot = 2, arch = "Serpent", colors = { C3(40, 150, 80), C3(255, 210, 80), C3(255, 80, 60) }, acc = "crown",
		desc = "A cobra protetora dos faraós.",
		ab = { name = "Cobra Hood", kind = "EggShield", cd = 55, p = { duration = 10 }, desc = "Seu ovo carregado não pode cair por 10s." } },
	{ id = "Anubis", name = "Anubis", biome = 10, slot = 3, arch = "Humanoid", colors = { C3(25, 25, 30), C3(255, 200, 60), C3(80, 160, 255) }, acc = "mask",
		desc = "Guardião dos mortos, pesa os corações.",
		ab = { name = "Proteção do Além", kind = "TrapWard", cd = 45, p = { duration = 15 }, desc = "Protege contra armadilhas por 15s." } },
	{ id = "Thoth", name = "Thoth", biome = 10, slot = 4, arch = "Humanoid", colors = { C3(240, 240, 240), C3(40, 40, 50), C3(80, 200, 255) }, acc = "ankh",
		desc = "O deus da sabedoria e da escrita.",
		ab = { name = "Sabedoria", kind = "HatchBoost", cd = 100, p = { seconds = 60 }, desc = "Reduz 60s da incubação de todos os seus ovos." } },

	-- Biome 11 — Reino de Duat
	{ id = "Ammit", name = "Ammit", biome = 11, slot = 1, arch = "Quadruped", colors = { C3(120, 90, 50), C3(60, 120, 60), C3(255, 80, 60) }, acc = "mask",
		desc = "A devoradora de corações dos injustos.",
		ab = { name = "Devour Dash", kind = "Dash", cd = 35, p = { power = 90 }, desc = "Investida devoradora para frente." } },
	{ id = "Apophis", name = "Apophis", biome = 11, slot = 2, arch = "Serpent", colors = { C3(40, 20, 60), C3(140, 60, 200), C3(255, 60, 120) }, acc = "flame",
		desc = "A serpente do caos que enfrenta Ra todas as noites.",
		ab = { name = "Chaos Coil", kind = "Frost", cd = 45, p = { radius = 36, slow = 0.55, duration = 5 }, desc = "Guardiões ficam 55% mais lentos por 5s." } },
	{ id = "Isis", name = "Isis", biome = 11, slot = 3, arch = "Humanoid", colors = { C3(60, 90, 200), C3(255, 210, 80), C3(255, 120, 200) }, acc = "wings",
		desc = "Senhora da magia, protege o que é precioso.",
		ab = { name = "Magia Protetora", kind = "EggShield", cd = 50, p = { duration = 12 }, desc = "Escudo mágico: seu ovo não cai por 12s." } },
	{ id = "Osiris", name = "Osiris", biome = 11, slot = 4, arch = "Humanoid", colors = { C3(40, 140, 90), C3(240, 240, 230), C3(255, 210, 80) }, acc = "crown",
		desc = "Senhor do renascimento e do além.",
		ab = { name = "Renascimento", kind = "Rescue", cd = 120, p = {}, desc = "Recupera de quedas e capturas (cooldown alto)." } },

	-- Biome 12 — Templo Solar
	{ id = "Bennu", name = "Bennu", biome = 12, slot = 1, arch = "Bird", colors = { C3(255, 140, 40), C3(255, 230, 120), C3(255, 60, 30) }, acc = "flame",
		desc = "A ave solar que renasce das próprias chamas.",
		ab = { name = "Rebirth Flight", kind = "Leap", cd = 30, p = { power = 95 }, desc = "Voo flamejante sobre obstáculos." } },
	{ id = "Sekhmet", name = "Sekhmet", biome = 12, slot = 2, arch = "Feline", colors = { C3(220, 120, 40), C3(255, 60, 40), C3(255, 220, 80) }, acc = "sun",
		desc = "A leoa da guerra, fúria solar encarnada.",
		ab = { name = "Fúria Solar", kind = "Shockwave", cd = 45, p = { radius = 34, stun = 3.5 }, desc = "Onda de energia solar contra guardiões (3.5s)." } },
	{ id = "Horus", name = "Horus", biome = 12, slot = 3, arch = "Bird", colors = { C3(60, 80, 160), C3(255, 210, 80), C3(255, 255, 255) }, acc = "crown",
		desc = "O deus-falcão, seu olho vê o reino inteiro.",
		ab = { name = "Olho do Céu", kind = "Reveal", cd = 50, p = { radius = 320, duration = 10, filter = "all" }, desc = "Revela ovos e guardiões numa área enorme por 10s." } },
	{ id = "Ra", name = "Ra", biome = 12, slot = 4, arch = "Humanoid", colors = { C3(255, 200, 60), C3(255, 120, 30), C3(255, 255, 200) }, acc = "sun",
		desc = "O deus sol, fonte de toda a energia.",
		ab = { name = "Energia Solar", kind = "IncomeBoost", cd = 120, p = { mult = 1.5, duration = 30 }, desc = "+50% de renda dos pets por 30s." } },

	-- ===================== EVENT EXCLUSIVES =====================
	{ id = "EclipsePhoenix", name = "Eclipse Phoenix", biome = 0, slot = 4, event = "DivineEclipse", rarity = "Secret", arch = "Bird", colors = { C3(30, 20, 50), C3(255, 120, 40), C3(200, 120, 255) }, acc = "halo",
		desc = "Surge apenas quando o sol é engolido pela lua.",
		ab = { name = "Umbra Veil", kind = "GuardShield", cd = 50, p = { duration = 12 }, desc = "Véu sombrio que bloqueia um golpe de guardião (12s)." } },
	{ id = "SurtrEmber", name = "Surtr Ember", biome = 0, slot = 4, event = "Ragnarok", rarity = "Eternal", arch = "Golem", colors = { C3(40, 20, 20), C3(255, 80, 20), C3(255, 200, 60) }, acc = "flame",
		desc = "Uma centelha do gigante de fogo do Ragnarok.",
		ab = { name = "Muspel Blaze", kind = "TrainBoost", cd = 120, p = { mult = 1.75, duration = 30 }, desc = "+75% de Speed na esteira por 30s." } },
	{ id = "AtenSunray", name = "Aten Sunray", biome = 0, slot = 4, event = "SolarAscension", rarity = "Eternal", arch = "Spirit", colors = { C3(255, 240, 150), C3(255, 160, 40), C3(255, 255, 255) }, acc = "sun",
		desc = "O disco solar personificado durante a Ascensão.",
		ab = { name = "Solar Disk", kind = "IncomeBoost", cd = 120, p = { mult = 1.4, duration = 40 }, desc = "+40% de renda dos pets por 40s." } },
	{ id = "Kronos", name = "Kronos", biome = 0, slot = 4, event = "FuryOfGods", rarity = "Divine", arch = "Humanoid", colors = { C3(60, 50, 40), C3(200, 170, 90), C3(140, 255, 220) }, acc = "halo",
		desc = "O titã do tempo, libertado pela Fúria dos Deuses.",
		ab = { name = "Time Warp", kind = "Frost", cd = 50, p = { radius = 40, slow = 0.6, duration = 5 }, desc = "Distorce o tempo: guardiões 60% mais lentos por 5s." } },
}

local RARITY_NAMES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Eternal", "Divine" }

local Creatures = {}
Creatures.List = list
Creatures.ById = {}
Creatures.ByBiome = {}
Creatures.Events = {}

for index, c in ipairs(list) do
	c.order = index
	if c.biome > 0 then
		local rarityIndex = math.clamp(math.floor((c.biome - 1) * 0.6) + c.slot, 1, 9)
		c.rarity = RARITY_NAMES[rarityIndex]
		c.mythology = (c.biome <= 4 and "Greek") or (c.biome <= 8 and "Norse") or "Egyptian"
		Creatures.ByBiome[c.biome] = Creatures.ByBiome[c.biome] or {}
		Creatures.ByBiome[c.biome][c.slot] = c
	else
		c.mythology = "Event"
		Creatures.Events[c.event] = c
	end
	c.ab.id = c.id .. "_Ability"
	Creatures.ById[c.id] = c
end

Creatures.RarityNames = RARITY_NAMES

return Creatures
