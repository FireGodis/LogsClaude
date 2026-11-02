--!strict
-- Dados do mundo: salas, portas, biomas, marcos, inimigos e colecionáveis.
-- Usado pelo construtor do mapa (Studio) e pelo cliente (luz e câmera por sala).
-- Convenção: cada sala é um retângulo VAZIO (x0,y0)-(x1,y1); y0 é o chão.
-- Tudo que não é sala nem porta vira rocha sólida. Salas vizinhas ficam separadas por 8 de parede.

export type Rect = { x0: number, y0: number, x1: number, y1: number }
export type Room = {
	id: string,
	name: string,
	biome: string,
	x0: number,
	y0: number,
	x1: number,
	y1: number,
	pattern: string, -- "ledges" | "arena" | "shaft" | "flat"
	exitY: number?, -- poço: altura do chão da saída (para as plataformas subirem até lá)
	camera: number,
	seed: number,
}
export type Biome = {
	name: string,
	rock: Color3,
	rockMaterial: Enum.Material,
	accent: Color3,
	far: Color3,
	mid: Color3,
	ambient: Color3,
	outdoor: Color3,
	brightness: number,
	fogColor: Color3,
	fogDensity: number,
	tint: Color3,
	style: string,
	rain: boolean,
}

local C = Color3.fromRGB

local Biomes: { [string]: Biome } = {
	town = {
		name = "Vila das Lanternas", rock = C(30, 36, 60), rockMaterial = Enum.Material.Slate, accent = C(150, 190, 255),
		far = C(20, 28, 54), mid = C(26, 34, 62), ambient = C(58, 72, 112), outdoor = C(44, 58, 100), brightness = 1.6,
		fogColor = C(26, 36, 72), fogDensity = 0.32, tint = C(238, 244, 255), style = "town", rain = true,
	},
	well = {
		name = "Poço Cego", rock = C(22, 28, 46), rockMaterial = Enum.Material.Slate, accent = C(120, 170, 255),
		far = C(14, 20, 36), mid = C(20, 26, 44), ambient = C(40, 54, 88), outdoor = C(30, 42, 74), brightness = 1.2,
		fogColor = C(12, 18, 36), fogDensity = 0.38, tint = C(226, 236, 255), style = "well", rain = false,
	},
	galeria = {
		name = "Galeria do Vidro Cego", rock = C(24, 38, 60), rockMaterial = Enum.Material.Slate, accent = C(87, 225, 216),
		far = C(16, 30, 54), mid = C(22, 40, 68), ambient = C(48, 72, 104), outdoor = C(32, 54, 88), brightness = 1.4,
		fogColor = C(14, 30, 54), fogDensity = 0.34, tint = C(226, 244, 255), style = "arches", rain = false,
	},
	garden = {
		name = "Jardim Murmurante", rock = C(24, 44, 38), rockMaterial = Enum.Material.Slate, accent = C(140, 235, 160),
		far = C(14, 36, 28), mid = C(20, 50, 38), ambient = C(52, 92, 76), outdoor = C(36, 70, 56), brightness = 1.5,
		fogColor = C(12, 36, 28), fogDensity = 0.34, tint = C(232, 255, 240), style = "trees", rain = false,
	},
	crystal = {
		name = "Cavernas de Cristal", rock = C(40, 30, 62), rockMaterial = Enum.Material.Slate, accent = C(232, 132, 255),
		far = C(28, 20, 50), mid = C(38, 28, 66), ambient = C(88, 62, 124), outdoor = C(64, 44, 96), brightness = 1.5,
		fogColor = C(28, 16, 50), fogDensity = 0.34, tint = C(250, 232, 255), style = "crystals", rain = false,
	},
	city = {
		name = "Cidade Chuvosa", rock = C(32, 38, 64), rockMaterial = Enum.Material.Slate, accent = C(184, 204, 255),
		far = C(20, 26, 52), mid = C(28, 36, 66), ambient = C(60, 72, 112), outdoor = C(46, 58, 98), brightness = 1.5,
		fogColor = C(22, 28, 58), fogDensity = 0.3, tint = C(236, 242, 255), style = "towers", rain = true,
	},
	abyss = {
		name = "Abismo", rock = C(12, 14, 24), rockMaterial = Enum.Material.Slate, accent = C(200, 220, 255),
		far = C(8, 10, 18), mid = C(12, 14, 24), ambient = C(30, 36, 58), outdoor = C(22, 26, 44), brightness = 1.0,
		fogColor = C(4, 5, 10), fogDensity = 0.5, tint = C(214, 226, 255), style = "abyss", rain = false,
	},
}

local function room(id: string, name: string, biome: string, x0: number, y0: number, x1: number, y1: number, pattern: string, camera: number, seed: number, exitY: number?): Room
	return { id = id, name = name, biome = biome, x0 = x0, y0 = y0, x1 = x1, y1 = y1, pattern = pattern, camera = camera, seed = seed, exitY = exitY }
end

local Rooms: { Room } = {
	room("t1", "Vila das Lanternas", "town", -60, 0, 170, 52, "ledges", 40, 11, nil),
	room("t2", "Ponte da Chuva", "town", 178, 0, 318, 52, "ledges", 40, 12, nil),
	room("s1", "Poço Cego", "well", 100, -86, 136, -8, "shaft", 34, 13, 0),
	room("g1", "Galeria do Vidro Cego", "galeria", 144, -86, 308, -40, "ledges", 38, 14, nil),
	room("g2", "Câmara do Vigia", "galeria", 316, -86, 466, -26, "arena", 62, 15, nil),
	room("l1", "Avenida Alagada", "city", 474, -86, 644, -30, "ledges", 40, 16, nil),
	room("l2", "Torres Chorosas", "city", 652, -86, 812, -22, "ledges", 40, 17, nil),
	room("a1", "Queda Muda", "abyss", 702, -182, 742, -94, "shaft", 34, 18, -86),
	room("a2", "Salão do Eco Último", "abyss", 750, -182, 920, -132, "ledges", 40, 19, nil),
	room("j1", "Jardim Murmurante", "garden", 326, 0, 486, 46, "ledges", 38, 20, nil),
	room("j2", "Alameda de Musgo", "garden", 494, 0, 634, 46, "ledges", 38, 21, nil),
	room("j3", "Garganta Verde", "garden", 642, 0, 682, 104, "shaft", 34, 22, 112),
	room("c1", "Galeria de Cristal", "crystal", 642, 112, 822, 158, "ledges", 40, 23, nil),
	room("c2", "Coração Cintilante", "crystal", 830, 112, 990, 164, "ledges", 40, 24, nil),
}

-- Aberturas nas paredes (retângulos de vazio entre salas).
local Doors: { Rect } = {
	{ x0 = 170, y0 = 0, x1 = 178, y1 = 14 },
	{ x0 = 100, y0 = -8, x1 = 136, y1 = 0 },
	{ x0 = 318, y0 = 0, x1 = 326, y1 = 14 },
	{ x0 = 486, y0 = 0, x1 = 494, y1 = 14 },
	{ x0 = 634, y0 = 0, x1 = 642, y1 = 14 },
	{ x0 = 646, y0 = 104, x1 = 678, y1 = 112 },
	{ x0 = 822, y0 = 112, x1 = 830, y1 = 126 },
	{ x0 = 136, y0 = -86, x1 = 144, y1 = -72 },
	{ x0 = 308, y0 = -86, x1 = 316, y1 = -72 },
	{ x0 = 466, y0 = -86, x1 = 474, y1 = -72 },
	{ x0 = 644, y0 = -86, x1 = 652, y1 = -72 },
	{ x0 = 702, y0 = -94, x1 = 742, y1 = -86 },
	{ x0 = 742, y0 = -182, x1 = 750, y1 = -168 },
}

-- Marcos de descanso (bancos). x absoluto; o y é o chão da sala.
local Benches = {
	{ id = "t1", room = "t1", x = 40, name = "Banco da Vila" },
	{ id = "g1", room = "g1", x = 296, name = "Banco da Galeria" },
	{ id = "j2", room = "j2", x = 510, name = "Banco do Musgo" },
	{ id = "c1", room = "c1", x = 662, name = "Banco do Cristal" },
	{ id = "l1", room = "l1", x = 490, name = "Banco da Avenida" },
	{ id = "a2", room = "a2", x = 772, name = "Banco do Eco" },
}

-- Inimigos: kind, x absoluto, altura acima do chão (só voadores), alcance de ronda.
local Spawns = {
	{ room = "t2", kind = "Crawler", x = 250, range = 18 },
	{ room = "g1", kind = "Crawler", x = 184, range = 14 },
	{ room = "g1", kind = "Shield", x = 238, range = 12 },
	{ room = "g1", kind = "Crawler", x = 270, range = 10 },
	{ room = "j1", kind = "Crawler", x = 360, range = 16 },
	{ room = "j1", kind = "Flier", x = 410, lift = 14, range = 18 },
	{ room = "j1", kind = "Crawler", x = 450, range = 12 },
	{ room = "j2", kind = "Flier", x = 540, lift = 16, range = 16 },
	{ room = "j2", kind = "Shield", x = 590, range = 14 },
	{ room = "j2", kind = "Crawler", x = 614, range = 8 },
	{ room = "j3", kind = "Flier", x = 662, lift = 34, range = 4 },
	{ room = "j3", kind = "Flier", x = 662, lift = 70, range = 4 },
	{ room = "c1", kind = "Flier", x = 710, lift = 16, range = 16 },
	{ room = "c1", kind = "Shield", x = 750, range = 16 },
	{ room = "c1", kind = "Flier", x = 780, lift = 18, range = 14 },
	{ room = "c1", kind = "Crawler", x = 804, range = 8 },
	{ room = "c2", kind = "Shield", x = 880, range = 16 },
	{ room = "c2", kind = "Flier", x = 920, lift = 16, range = 14 },
	{ room = "c2", kind = "Crawler", x = 956, range = 10 },
	{ room = "l1", kind = "Shield", x = 530, range = 14 },
	{ room = "l1", kind = "Crawler", x = 580, range = 14 },
	{ room = "l1", kind = "Flier", x = 610, lift = 16, range = 14 },
	{ room = "l2", kind = "Crawler", x = 672, range = 6 },
	{ room = "l2", kind = "Flier", x = 722, lift = 16, range = 14 },
	{ room = "l2", kind = "Shield", x = 780, range = 12 },
	{ room = "a1", kind = "Flier", x = 722, lift = 30, range = 5 },
	{ room = "a1", kind = "Flier", x = 722, lift = 60, range = 5 },
	{ room = "a2", kind = "Shield", x = 812, range = 14 },
	{ room = "a2", kind = "Crawler", x = 850, range = 12 },
	{ room = "a2", kind = "Flier", x = 884, lift = 16, range = 14 },
}

local Collectibles = {
	{ id = "vidro_01", room = "g1", x = 214, lift = 15 },
	{ id = "vidro_02", room = "j1", x = 430, lift = 16 },
	{ id = "vidro_03", room = "c2", x = 976, lift = 3 },
	{ id = "vidro_04", room = "a2", x = 906, lift = 3 },
	{ id = "vidro_05", room = "t2", x = 262, lift = 18 },
}

return {
	Rooms = Rooms,
	Doors = Doors,
	Biomes = Biomes,
	Benches = Benches,
	Spawns = Spawns,
	Collectibles = Collectibles,
	Boss = { room = "g2", x = 430, arenaMin = 320, arenaMax = 462 },
	Barrier = { x0 = 466, y0 = -86, x1 = 474, y1 = -72 },
	Start = { room = "t1", x = -30 },
	Bounds = { minX = -120, maxX = 1060, minY = -240, maxY = 220, killY = -230 },
}
