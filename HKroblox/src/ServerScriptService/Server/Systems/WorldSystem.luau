--!strict
-- Mundo interativo: bancos de descanso (checkpoints), colecionáveis por jogador, pontes de eco.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local Net = require(script.Parent.Net)
local PlayerData = require(script.Parent.PlayerData)

local WorldSystem = {}

local mundo = Workspace:WaitForChild("Mundo")
local spawns = mundo:WaitForChild("Spawns")
local expiry: { [BasePart]: number } = {}
local npcParts: { [string]: BasePart } = {}
local pendingStories: { [Player]: string } = {}

type StoryNPC = {
	id: string,
	name: string,
	region: string,
	x: number,
	ability: string,
	lines: { string },
	repeatLines: { string },
}

local STORY_NPCS: { StoryNPC } = {
	{
		id = "lumeira",
		name = "Lumeira, Guardiã do Pavio",
		region = "Vila das Lanternas",
		x = 66,
		ability = "wings",
		lines = {
			"Guardo a última chama que não exige nada de quem a carrega.",
			"Quando o chão se afasta, deixa que o ar te responda.",
			"Leva estas plumas de luz. Usa-as uma vez antes de tocar o chão.",
		},
		repeatLines = { "A chama não te apressa. O céu ainda está aí." },
	},
	{
		id = "orvalho",
		name = "Orvalho, Tecelão de Raízes",
		region = "Alameda de Musgo",
		x = 556,
		ability = "claw",
		lines = {
			"As raízes aprendem a pedra pelo tato.",
			"Não forces a parede. Escuta onde ela oferece apoio.",
			"Leva este gancho de raiz: salta de uma face e procura a outra.",
		},
		repeatLines = { "Uma parede também pode ser caminho, viajante." },
	},
}

local function createStoryNPCs()
	local folder = mundo:FindFirstChild("NPCs")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "NPCs"
		folder.Parent = mundo
	end

	local function makePart(model: Model, name: string, size: Vector3, position: Vector3, color: Color3, shape: Enum.PartType?, material: Enum.Material?, transparency: number?, rotation: number?): BasePart
		local part: BasePart
		if name == "Mantle" or string.find(name, "Leaf") or string.find(name, "Wing") then
			part = Instance.new("WedgePart")
		else
			part = Instance.new("Part")
			if shape then
				(part :: Part).Shape = shape
			end
		end
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Size = size
		part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, rotation or 0)
		part.Material = material or Enum.Material.SmoothPlastic
		part.Color = color
		part.Transparency = transparency or 0
		part.Parent = model
		return part
	end

	for _, record in STORY_NPCS do
		local model = folder:FindFirstChild(record.id)
		if model and (not model:IsA("Model") or model:GetAttribute("VisualRevision") ~= 2) then
			model:Destroy()
			model = nil
		end
		if not model then
			model = Instance.new("Model")
			model.Name = record.id
			local x = record.x
			local isLumeira = record.ability == "wings"
			local mantleColor = if isLumeira then Color3.fromRGB(34, 43, 74) else Color3.fromRGB(32, 61, 48)
			local accentColor = if isLumeira then Color3.fromRGB(139, 178, 210) else Color3.fromRGB(120, 185, 129)
			local ivory = Color3.fromRGB(230, 230, 214)
			local ink = Color3.fromRGB(18, 23, 29)
			local mantle = makePart(model, "Mantle", Vector3.new(2.35, 2.55, 1.3), Vector3.new(x, 1.35, 0), mantleColor, nil, Enum.Material.Slate)
			makePart(model, "MantleHem", Vector3.new(2.55, 0.45, 1.38), Vector3.new(x, 0.25, 0.03), accentColor, Enum.PartType.Ball)
			makePart(model, "Collar", Vector3.new(2.1, 0.55, 1.5), Vector3.new(x, 2.55, 0.05), accentColor, Enum.PartType.Ball)
			makePart(model, "Face", Vector3.new(1.6, 1.7, 1.35), Vector3.new(x, 3.25, 0.03), ivory, Enum.PartType.Ball)
			makePart(model, "EyeLeft", Vector3.new(0.16, 0.28, 0.11), Vector3.new(x - 0.34, 3.23, 0.69), ink, Enum.PartType.Ball)
			makePart(model, "EyeRight", Vector3.new(0.16, 0.28, 0.11), Vector3.new(x + 0.34, 3.23, 0.69), ink, Enum.PartType.Ball)
			makePart(model, "AntennaLeft", Vector3.new(0.3, 1.2, 0.4), Vector3.new(x - 0.47, 4.2, 0.02), ivory, nil, Enum.Material.SmoothPlastic, 0, -0.32)
			makePart(model, "AntennaRight", Vector3.new(0.3, 1.2, 0.4), Vector3.new(x + 0.47, 4.2, 0.02), ivory, nil, Enum.Material.SmoothPlastic, 0, 0.32)
			makePart(model, "Sash", Vector3.new(1.9, 0.22, 1.42), Vector3.new(x, 1.55, 0.66), accentColor, Enum.PartType.Ball)
			makePart(model, "Pouch", Vector3.new(0.55, 0.62, 0.4), Vector3.new(x - 0.72, 1.05, 0.82), Color3.fromRGB(93, 76, 54), Enum.PartType.Ball, Enum.Material.Leather)
			if isLumeira then
				makePart(model, "WingLeft", Vector3.new(1.55, 2.25, 0.24), Vector3.new(x - 1.25, 2.15, -0.42), Color3.fromRGB(87, 108, 157), nil, Enum.Material.SmoothPlastic, 0.12, -0.2)
				makePart(model, "WingRight", Vector3.new(1.55, 2.25, 0.24), Vector3.new(x + 1.25, 2.15, -0.42), Color3.fromRGB(87, 108, 157), nil, Enum.Material.SmoothPlastic, 0.12, 0.2)
			else
				makePart(model, "LeafLeft", Vector3.new(1.2, 0.9, 0.22), Vector3.new(x - 0.95, 2.7, 0.24), Color3.fromRGB(81, 145, 91), nil, Enum.Material.Grass, 0.02, -0.48)
				makePart(model, "LeafRight", Vector3.new(1.2, 0.9, 0.22), Vector3.new(x + 0.95, 2.7, 0.24), Color3.fromRGB(108, 174, 106), nil, Enum.Material.Grass, 0.02, 0.48)
			end
			local seedColor = if isLumeira then Color3.fromRGB(177, 218, 255) else Color3.fromRGB(174, 255, 183)
			local seed = makePart(model, "Keepsake", Vector3.new(0.48, 0.48, 0.48), Vector3.new(x + 1.18, 2.08, 0.95), seedColor, Enum.PartType.Ball, Enum.Material.Neon)
			makePart(model, "KeepsakeHalo", Vector3.new(0.9, 0.9, 0.9), seed.Position, seedColor, Enum.PartType.Ball, Enum.Material.Neon, 0.8)
			local light = Instance.new("PointLight")
			light.Name = "KeepsakeGlow"
			light.Color = seedColor
			light.Brightness = 1.1
			light.Range = 9
			light.Parent = seed
			model:SetAttribute("VisualRevision", 2)
			model.Parent = folder
		end

		model:SetAttribute("NPCId", record.id)
		model:SetAttribute("Region", record.region)
		model:SetAttribute("GrantsAbility", record.ability)
		local face = model:FindFirstChild("Face")
		if face and face:IsA("BasePart") then
			local prompt = face:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt?
			if not prompt then
				prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Conversar"
				prompt.ObjectText = record.name
				prompt.KeyboardKeyCode = Enum.KeyCode.E
				prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
				prompt.HoldDuration = 0.15
				prompt.MaxActivationDistance = 8
				prompt.RequiresLineOfSight = false
				prompt.UIOffset = Vector2.new(0, 44)
				prompt.Parent = face
			end
			npcParts[record.id] = face
			prompt.Triggered:Connect(function(player: Player)
				local profile = PlayerData.get(player)
				if not profile or pendingStories[player] then
					return
				end
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if not root or not root:IsA("BasePart") or (root.Position - face.Position).Magnitude > 14 then
					return
				end
				pendingStories[player] = record.id
				local lines = if profile.abilities[record.ability] then record.repeatLines else record.lines
				Net.fire("Story", player, "Open", record.id, record.name, lines)
			end)
		end
	end
end

local function finishStory(player: Player, npcId: unknown)
	if typeof(npcId) ~= "string" or pendingStories[player] ~= npcId then
		return
	end
	pendingStories[player] = nil
	local face = npcParts[npcId]
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local profile = PlayerData.get(player)
	if not face or not root or not root:IsA("BasePart") or not profile or (root.Position - face.Position).Magnitude > 16 then
		return
	end
	for _, record in STORY_NPCS do
		if record.id == npcId and not profile.abilities[record.ability] then
			profile.abilities[record.ability] = true
			profile.flags["ability_" .. record.ability .. "_unlocked"] = true
			PlayerData.publish(player)
			if not PlayerData.saveNow(player) then
				warn("[WorldSystem] Falha ao salvar habilidade liberada: " .. record.ability)
			end
			Net.fire("Story", player, "Reward", record.ability)
			break
		end
	end
end

local function setBridge(bridge: BasePart, revealed: boolean)
	bridge:SetAttribute("Revelada", revealed)
	bridge.Transparency = if revealed then 0.25 else 0.9
	bridge.CanCollide = revealed
	bridge.CanTouch = revealed
end

-- Cada ponte guarda o instante em que deve sumir. Pulsos seguidos só estendem o prazo.
function WorldSystem.revealEcho()
	local duration = Config.Combat.EchoDuration
	local limit = os.clock() + duration
	for _, tagged in CollectionService:GetTagged("EchoBridge") do
		if tagged:IsA("BasePart") then
			local bridge = tagged
			expiry[bridge] = limit
			setBridge(bridge, true)
			task.delay(duration + 0.05, function()
				local expires = expiry[bridge]
				if bridge.Parent and expires and os.clock() >= expires then
					setBridge(bridge, false)
				end
			end)
		end
	end
end

local function spawnLocation(id: string): SpawnLocation?
	local found = spawns:FindFirstChild("Spawn_" .. id)
	return if found and found:IsA("SpawnLocation") then found else nil
end

function WorldSystem.spawnFor(profile: Types.Profile): SpawnLocation
	local bench = if profile.checkpoint ~= "Inicio" then spawnLocation(profile.checkpoint) else nil
	return bench or (spawns:WaitForChild("Spawn_Inicio") :: SpawnLocation)
end

local function wireCollectible(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local id = instance:GetAttribute("CollectibleId")
	if typeof(id) ~= "string" then
		return
	end
	local collectibleId: string = id
	instance.Touched:Connect(function(hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = if character then Players:GetPlayerFromCharacter(character) else nil
		if not player then
			return
		end
		local profile = PlayerData.get(player)
		if not profile or profile.collected[collectibleId] then
			return
		end
		profile.collected[collectibleId] = true
		profile.fragments += 1
		PlayerData.publish(player)
		Net.fire("Notify", player, "Um fragmento de vidro repousa na sua mão.")
	end)
end

function WorldSystem.start(deps: { restore: (Player) -> (), respawnEnemies: () -> () })
	createStoryNPCs()
	Net.on("Story", 3, 2, function(player: Player, action: unknown, npcId: unknown)
		if action == "Finish" then
			finishStory(player, npcId)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		pendingStories[player] = nil
	end)
	for _, seat in CollectionService:GetTagged("Bench") do
		local id = seat:GetAttribute("BenchId")
		local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
		if typeof(id) == "string" and prompt then
			local benchId: string = id
			prompt.Triggered:Connect(function(player: Player)
				local profile = PlayerData.get(player)
				local spawn = spawnLocation(benchId)
				if not profile or not spawn then
					return
				end
				profile.checkpoint = benchId
				player.RespawnLocation = spawn
				if not PlayerData.saveNow(player) then
					warn(`[WorldSystem] Falha ao salvar checkpoint do banco {benchId} para {player.UserId}.`)
				end
				deps.restore(player)
				deps.respawnEnemies()
				Net.fire("Notify", player, "Você descansa. O vazio espera, paciente.")
				Net.fireAll("Fx", "Bench", spawn.Position)
			end)
		end
	end
	for _, tagged in CollectionService:GetTagged("Collectible") do
		wireCollectible(tagged)
	end
	CollectionService:GetInstanceAddedSignal("Collectible"):Connect(wireCollectible)
end

return WorldSystem
