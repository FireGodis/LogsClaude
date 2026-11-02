--!strict
-- Desenho e dados dos inimigos. O servidor monta as peças, o cliente anima as juntas.
-- Coordenadas no "espaço de frente": X positivo = para onde o inimigo olha.

export type EnemyPart = {
	name: string,
	kind: string, -- "Ball" | "Block" | "Wedge"
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	joint: Vector3,
	pivot: Vector3,
	rot: number,
	yaw: number,
	group: string,
	glow: boolean, -- peça de "brilho": muda de cor nos avisos de ataque
}

export type EnemyDef = {
	id: string,
	displayName: string,
	parts: { EnemyPart },
	groups: { string },
	health: number,
	radiusX: number,
	radiusY: number,
	rootSize: Vector3,
	footOffset: number, -- distância da raiz até o chão (0 = voador)
	flying: boolean,
	blocksFront: boolean,
	reward: number,
	contactDamage: number,
}

local HALF_PI = math.pi / 2
local SMOOTH = Enum.Material.SmoothPlastic
local METAL = Enum.Material.Metal
local NEON = Enum.Material.Neon

type Opts = { pivot: Vector3?, rot: number?, yaw: number?, glow: boolean?, material: Enum.Material? }

local function P(name: string, kind: string, size: Vector3, color: Color3, joint: Vector3, group: string, opts: Opts?): EnemyPart
	local o: Opts = opts or {}
	local material = o.material or SMOOTH
	local lit = if material == NEON then color else Color3.new(math.min(1, color.R * 1.6), math.min(1, color.G * 1.6), math.min(1, color.B * 1.6))
	return {
		name = name,
		kind = kind,
		size = size,
		color = lit,
		material = material,
		joint = joint,
		pivot = o.pivot or Vector3.zero,
		rot = o.rot or 0,
		yaw = o.yaw or 0,
		group = group,
		glow = o.glow or false,
	}
end

local function scaled(parts: { EnemyPart }, factor: number): { EnemyPart }
	local out: { EnemyPart } = {}
	for _, part in parts do
		local copy = table.clone(part)
		copy.size = part.size * factor
		copy.joint = part.joint * factor
		copy.pivot = part.pivot * factor
		table.insert(out, copy)
	end
	return out
end

local V = Vector3.new
local C = Color3.fromRGB

-- RASTEJADOR DE VIDRO ---------------------------------------------------------
local SHELL, PLATE, HEAD, LEG = C(54, 72, 112), C(98, 126, 180), C(26, 32, 56), C(22, 28, 48)
local EMBER = C(255, 170, 80)
local crawlerParts: { EnemyPart } = {
	P("LegF3", "Block", V(0.4, 1.6, 0.4), LEG, V(-1.3, -0.9, -1.0), "legB", { pivot = V(0, -0.7, 0) }),
	P("LegF2", "Block", V(0.4, 1.6, 0.4), LEG, V(0, -0.9, -1.0), "legA", { pivot = V(0, -0.7, 0) }),
	P("LegF1", "Block", V(0.4, 1.6, 0.4), LEG, V(1.3, -0.9, -1.0), "legB", { pivot = V(0, -0.7, 0) }),
	P("Shell", "Ball", V(4.2, 3.0, 3.6), SHELL, V(0, 0.3, 0), "body"),
	P("Plate", "Block", V(2.8, 0.5, 3.0), PLATE, V(-0.2, 1.7, 0), "body", { rot = 0 }),
	P("Ridge", "Wedge", V(0.5, 1.2, 1.6), PLATE, V(-1.4, 1.5, 0), "body", { yaw = HALF_PI, pivot = V(0, 0.4, 0) }),
	P("Head", "Ball", V(1.9, 1.6, 1.8), HEAD, V(2.1, 0.0, 0), "head"),
	P("AntennaB", "Block", V(0.16, 1.5, 0.16), HEAD, V(2.3, 0.6, -0.35), "head", { pivot = V(0.45, 0.7, 0), rot = -0.9 }),
	P("EyeB", "Ball", V(0.45, 0.5, 0.35), EMBER, V(2.65, 0.2, -0.62), "head", { material = NEON, glow = true }),
	P("LegN3", "Block", V(0.4, 1.6, 0.4), LEG, V(-1.3, -0.9, 1.0), "legA", { pivot = V(0, -0.7, 0) }),
	P("LegN2", "Block", V(0.4, 1.6, 0.4), LEG, V(0, -0.9, 1.0), "legB", { pivot = V(0, -0.7, 0) }),
	P("LegN1", "Block", V(0.4, 1.6, 0.4), LEG, V(1.3, -0.9, 1.0), "legA", { pivot = V(0, -0.7, 0) }),
	P("AntennaA", "Block", V(0.16, 1.5, 0.16), HEAD, V(2.3, 0.6, 0.35), "head", { pivot = V(0.45, 0.7, 0), rot = -0.9 }),
	P("EyeA", "Ball", V(0.45, 0.5, 0.35), EMBER, V(2.65, 0.2, 0.62), "head", { material = NEON, glow = true }),
}

-- MARIPOSA DE CINZA -----------------------------------------------------------
local MOTH, WING, MOTHDARK = C(64, 62, 90), C(150, 162, 202), C(30, 30, 46)
local flierParts: { EnemyPart } = {
	P("WingB", "Wedge", V(0.15, 3.2, 2.4), C(110, 120, 160), V(-0.2, 0.7, -0.5), "wingB", { pivot = V(-0.9, 1.5, 0), rot = 0.5, yaw = HALF_PI }),
	P("Abdomen", "Ball", V(1.3, 1.7, 1.2), EMBER, V(-1.1, -0.5, 0), "body", { material = NEON, glow = true }),
	P("Body", "Ball", V(1.7, 2.3, 1.5), MOTH, V(0, 0, 0), "body"),
	P("Head", "Ball", V(1.3, 1.3, 1.2), MOTHDARK, V(1.0, 0.8, 0), "head"),
	P("EyeA", "Ball", V(0.4, 0.4, 0.3), C(210, 235, 255), V(1.5, 0.95, 0.5), "head", { material = NEON, glow = true }),
	P("AntennaA", "Block", V(0.12, 1.2, 0.12), MOTHDARK, V(1.3, 1.4, 0.2), "head", { pivot = V(0.3, 0.55, 0), rot = -0.8 }),
	P("WingA", "Wedge", V(0.15, 3.4, 2.6), WING, V(-0.2, 0.7, 0.6), "wingA", { pivot = V(-0.9, 1.6, 0), rot = 0.5, yaw = HALF_PI }),
}

-- GUARDIÃO DE CASCO -----------------------------------------------------------
local ARMOR, ARMORLIGHT, HELM, SHIELD = C(70, 76, 98), C(98, 106, 134), C(192, 198, 214), C(124, 134, 170)
local shieldParts: { EnemyPart } = {
	P("LegB", "Block", V(1.3, 2.2, 1.3), LEG, V(-0.7, -2.7, -0.9), "legB", { pivot = V(0, -1.0, 0) }),
	P("Body", "Ball", V(4.6, 5.4, 3.8), ARMOR, V(0, 0, 0), "body"),
	P("Belly", "Ball", V(3.6, 3.4, 3.1), ARMORLIGHT, V(0.5, -0.8, 0), "body"),
	P("Helm", "Ball", V(2.7, 2.7, 2.5), HELM, V(0.9, 3.1, 0), "head"),
	P("Horn", "Wedge", V(0.4, 2.4, 1.1), HELM, V(0.5, 4.3, 0.2), "head", { pivot = V(0, 1.1, 0), rot = -0.25, yaw = HALF_PI }),
	P("Visor", "Block", V(0.9, 0.28, 0.2), EMBER, V(1.9, 3.2, 1.15), "head", { material = NEON, glow = true }),
	P("LegF", "Block", V(1.3, 2.2, 1.3), LEG, V(0.8, -2.7, 0.9), "legF", { pivot = V(0, -1.0, 0) }),
	P("ArmF", "Block", V(0.85, 2.6, 0.85), ARMOR, V(0.4, 1.7, 1.95), "armF", { pivot = V(0, -1.3, 0) }),
	P("Mace", "Block", V(1.7, 1.7, 1.7), C(34, 38, 56), V(0.4, 1.7, 1.95), "armF", { pivot = V(0, -3.4, 0), material = METAL }),
	P("Shield", "Block", V(0.7, 5.0, 3.6), SHIELD, V(2.7, 0.3, 0), "shield", { material = METAL }),
	P("ShieldCore", "Ball", V(0.9, 1.4, 1.4), EMBER, V(3.1, 0.3, 0), "shield", { material = NEON, glow = true }),
}

-- VIGIA RACHADO (CHEFE) -------------------------------------------------------
local BARMOR, BDARK, BLIGHT, BIVORY, BCRACK = C(84, 92, 122), C(30, 34, 52), C(172, 178, 202), C(206, 209, 222), C(120, 230, 255)
local bossRaw: { EnemyPart } = {
	P("LegB", "Block", V(3.2, 6.5, 3.2), BDARK, V(-0.8, -5.2, -2.0), "legB", { pivot = V(0, -3.0, 0) }),
	P("ArmB", "Block", V(2.0, 4.5, 2.0), BDARK, V(0.2, 4.6, -4.4), "armB", { pivot = V(0, -2.25, 0) }),
	P("ShoulderB", "Ball", V(4.0, 4.0, 4.0), BARMOR, V(0.2, 4.6, -4.4), "armB"),
	P("Pelvis", "Ball", V(7, 4.5, 6), BDARK, V(0, -4.8, 0), "pelvis"),
	P("Torso", "Ball", V(10, 11, 7.6), BARMOR, V(0, 1, 0), "torso"),
	P("Band1", "Block", V(9.4, 0.7, 7.9), BLIGHT, V(0.1, -0.8, 0), "torso", { material = METAL }),
	P("Band2", "Block", V(9.8, 0.7, 8.1), BLIGHT, V(0.1, 2.0, 0), "torso", { material = METAL }),
	P("Chest", "Ball", V(2.4, 2.8, 1.4), BCRACK, V(2.9, 2.2, 3.7), "torso", { material = NEON, glow = true }),
	P("Head", "Ball", V(4.8, 4.4, 4.4), BLIGHT, V(1.8, 7.6, 0), "head"),
	P("HornB", "Wedge", V(0.9, 5.5, 1.8), BIVORY, V(1.0, 9.4, -0.7), "head", { pivot = V(0, 2.6, 0), rot = 0.35, yaw = HALF_PI }),
	P("HornA", "Wedge", V(0.9, 5.5, 1.8), BIVORY, V(2.9, 9.2, 0.7), "head", { pivot = V(0, 2.6, 0), rot = -0.4, yaw = HALF_PI }),
	P("Visor", "Block", V(2.2, 0.55, 0.4), BCRACK, V(3.6, 7.9, 2.0), "head", { material = NEON, glow = true }),
	P("LegF", "Block", V(3.2, 6.5, 3.2), BDARK, V(0.8, -5.2, 2.0), "legF", { pivot = V(0, -3.0, 0) }),
	P("ArmF", "Block", V(2.2, 4.5, 2.2), BARMOR, V(0.2, 4.6, 4.4), "armF", { pivot = V(0, -2.25, 0) }),
	P("Haft", "Block", V(1.0, 8.5, 1.0), BIVORY, V(0.2, 4.6, 4.4), "armF", { pivot = V(0, -8.25, 0) }),
	P("HammerHead", "Block", V(4.8, 3.6, 4.2), C(92, 100, 130), V(0.2, 4.6, 4.4), "armF", { pivot = V(0, -14.3, 0), material = METAL }),
	P("HammerCrack", "Block", V(5.0, 0.4, 4.4), BCRACK, V(0.2, 4.6, 4.4), "armF", { pivot = V(0, -14.3, 0), material = NEON, glow = true }),
	P("ShoulderF", "Ball", V(4.2, 4.2, 4.2), BARMOR, V(0.2, 4.6, 4.4), "armF"),
}
local BOSS_SCALE = 0.85

local defs: { [string]: EnemyDef } = {
	Crawler = {
		id = "Crawler", displayName = "Rastejador de Vidro", parts = crawlerParts,
		groups = { "body", "head", "legA", "legB" },
		health = 6, radiusX = 2.3, radiusY = 1.9, rootSize = V(3, 3, 3), footOffset = 2.3,
		flying = false, blocksFront = false, reward = 4, contactDamage = 1,
	},
	Flier = {
		id = "Flier", displayName = "Mariposa de Cinza", parts = flierParts,
		groups = { "body", "head", "wingA", "wingB" },
		health = 4, radiusX = 1.6, radiusY = 1.5, rootSize = V(2, 2, 2), footOffset = 0,
		flying = true, blocksFront = false, reward = 5, contactDamage = 1,
	},
	Shield = {
		id = "Shield", displayName = "Guardião de Casco", parts = shieldParts,
		groups = { "body", "head", "legF", "legB", "armF", "shield" },
		health = 10, radiusX = 2.8, radiusY = 3.6, rootSize = V(4, 6, 4), footOffset = 4.8,
		flying = false, blocksFront = true, reward = 12, contactDamage = 1,
	},
	Boss = {
		id = "Boss", displayName = "Vigia Rachado", parts = scaled(bossRaw, BOSS_SCALE),
		groups = { "torso", "pelvis", "head", "armF", "armB", "legF", "legB" },
		health = 36, radiusX = 4.4, radiusY = 8.5, rootSize = V(6, 12, 6), footOffset = 11.5 * BOSS_SCALE,
		flying = false, blocksFront = false, reward = 60, contactDamage = 1,
	},
}

return {
	Defs = defs,
	BossScale = BOSS_SCALE,
	Colors = { Calm = BCRACK, Warn = C(255, 96, 70) },
}
