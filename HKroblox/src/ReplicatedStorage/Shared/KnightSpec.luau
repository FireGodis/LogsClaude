--!strict
-- Desenho do Cavaleiro: servidor constrói as peças, cada cliente anima.
-- Coordenadas no "espaço de frente": X positivo = para onde o cavaleiro olha.

export type PartSpec = {
	name: string,
	kind: string, -- "Ball" | "Block" | "Wedge"
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	joint: Vector3, -- ponto de articulação relativo ao HumanoidRootPart
	pivot: Vector3, -- centro da peça relativo à articulação
	rot: number, -- rotação estática no plano (rad)
	yaw: number, -- giro fixo da peça (cunhas precisam de 90 graus)
	group: string,
}

local BONE = Color3.fromRGB(236, 235, 228)
local INK = Color3.fromRGB(13, 13, 21)
local CLOAK = Color3.fromRGB(27, 32, 58)
local STEEL = Color3.fromRGB(206, 217, 232)
local SMOOTH = Enum.Material.SmoothPlastic
local HALF_PI = math.pi / 2

local Parts: { PartSpec } = {
	{ name = "Cloak", kind = "Wedge", size = Vector3.new(0.5, 2.8, 2.2), color = CLOAK, material = SMOOTH,
		joint = Vector3.new(-0.3, 0.7, 0), pivot = Vector3.new(-0.9, -1.25, 0), rot = 0, yaw = HALF_PI, group = "cloak" },
	{ name = "WingA", kind = "Wedge", size = Vector3.new(0.35, 1.65, 2.0), color = Color3.fromRGB(209, 236, 246), material = SMOOTH,
		joint = Vector3.new(0.4, 0.35, -0.72), pivot = Vector3.new(0.4, 0.35, 0), rot = 0, yaw = HALF_PI, group = "wingA" },
	{ name = "WingB", kind = "Wedge", size = Vector3.new(0.35, 1.65, 2.0), color = Color3.fromRGB(209, 236, 246), material = SMOOTH,
		joint = Vector3.new(0.4, 0.35, 0.72), pivot = Vector3.new(0.4, 0.35, 0), rot = 0, yaw = HALF_PI, group = "wingB" },
	{ name = "LegB", kind = "Block", size = Vector3.new(0.65, 1.3, 0.65), color = INK, material = SMOOTH,
		joint = Vector3.new(-0.3, -1.7, -0.45), pivot = Vector3.new(0, -0.6, 0), rot = 0, yaw = 0, group = "legB" },
	{ name = "ArmB", kind = "Block", size = Vector3.new(0.55, 1.4, 0.55), color = INK, material = SMOOTH,
		joint = Vector3.new(0, 0.35, -0.95), pivot = Vector3.new(0, -0.7, 0), rot = 0.1, yaw = 0, group = "armB" },
	{ name = "Body", kind = "Ball", size = Vector3.new(1.9, 2.5, 1.6), color = INK, material = SMOOTH,
		joint = Vector3.new(0, -0.55, 0), pivot = Vector3.zero, rot = 0, yaw = 0, group = "body" },
	{ name = "LegF", kind = "Block", size = Vector3.new(0.65, 1.3, 0.65), color = INK, material = SMOOTH,
		joint = Vector3.new(0.35, -1.7, 0.45), pivot = Vector3.new(0, -0.6, 0), rot = 0, yaw = 0, group = "legF" },
	{ name = "Head", kind = "Ball", size = Vector3.new(2.6, 2.4, 2.3), color = BONE, material = SMOOTH,
		joint = Vector3.new(0.3, 1.6, 0), pivot = Vector3.zero, rot = 0, yaw = 0, group = "head" },
	{ name = "HornB", kind = "Wedge", size = Vector3.new(0.34, 2.1, 0.8), color = BONE, material = SMOOTH,
		joint = Vector3.new(-0.2, 2.55, -0.45), pivot = Vector3.new(0, 1.0, 0), rot = 0.32, yaw = HALF_PI, group = "head" },
	{ name = "HornA", kind = "Wedge", size = Vector3.new(0.34, 2.1, 0.8), color = BONE, material = SMOOTH,
		joint = Vector3.new(0.95, 2.55, 0.5), pivot = Vector3.new(0, 1.0, 0), rot = -0.3, yaw = HALF_PI, group = "head" },
	{ name = "EyeB", kind = "Ball", size = Vector3.new(0.5, 0.95, 0.4), color = INK, material = SMOOTH,
		joint = Vector3.new(0.35, 1.7, 1.08), pivot = Vector3.zero, rot = 0.15, yaw = 0, group = "head" },
	{ name = "EyeA", kind = "Ball", size = Vector3.new(0.5, 0.95, 0.4), color = INK, material = SMOOTH,
		joint = Vector3.new(1.1, 1.7, 1.0), pivot = Vector3.zero, rot = -0.15, yaw = 0, group = "head" },
	{ name = "ArmF", kind = "Block", size = Vector3.new(0.55, 1.4, 0.55), color = INK, material = SMOOTH,
		joint = Vector3.new(0.25, 0.35, 0.95), pivot = Vector3.new(0, -0.7, 0), rot = -0.1, yaw = 0, group = "armF" },
	{ name = "Nail", kind = "Block", size = Vector3.new(0.2, 3.2, 0.2), color = STEEL, material = Enum.Material.Metal,
		joint = Vector3.new(0.25, 0.35, 0.95), pivot = Vector3.new(0, -2.8, 0), rot = -0.1, yaw = 0, group = "nail" },
}

return {
	Parts = Parts,
	Groups = { "head", "body", "cloak", "armF", "armB", "legF", "legB", "nail", "wingA", "wingB" },
}
