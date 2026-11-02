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
		x = 504,
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
	for _, record in STORY_NPCS do
		local model = folder:FindFirstChild(record.id)
		if not model or not model:IsA("Model") then
			model = Instance.new("Model")
			model.Name = record.id
			local body = Instance.new("Part")
			body.Name = "Mantle"
			body.Anchored = true
			body.CanCollide = false
			body.Size = Vector3.new(2.1, 2.8, 1.25)
			body.Position = Vector3.new(record.x, 1.5, 0)
			body.Material = Enum.Material.Slate
			body.Color = if record.ability == "wings" then Color3.fromRGB(45, 56, 88) else Color3.fromRGB(42, 67, 52)
			body.Parent = model
			local head = Instance.new("Part")
			head.Name = "Face"
			head.Shape = Enum.PartType.Ball
			head.Anchored = true
			head.CanCollide = false
			head.Size = Vector3.new(1.6, 1.5, 1.4)
			head.Position = Vector3.new(record.x, 3.5, 0)
			head.Material = Enum.Material.SmoothPlastic
			head.Color = Color3.fromRGB(222, 226, 218)
			head.Parent = model
			local light = Instance.new("Part")
			light.Name = "Keepsake"
			light.Shape = Enum.PartType.Ball
			light.Anchored = true
			light.CanCollide = false
			light.Size = Vector3.new(0.55, 0.55, 0.55)
			light.Position = Vector3.new(record.x + 1.15, 2.25, 0.55)
			light.Material = Enum.Material.Neon
			light.Color = if record.ability == "wings" then Color3.fromRGB(177, 218, 255) else Color3.fromRGB(176, 233, 168)
			light.Parent = model
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
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false
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
