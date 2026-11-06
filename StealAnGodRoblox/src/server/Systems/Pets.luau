--[[
	Pets — inventory, capacity, selling, the active divine companion and base display.

	All pets generate GOLD (Economy). Only ONE pet is equipped as the active companion: it follows
	the character and grants its ability (Abilities). Pets are displayed on the base pads sorted by
	income; clicking/pressing on a displayed pet opens its info card (client).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage.Shared
local Creatures = require(Shared.Config.Creatures)
local Formulas = require(Shared.Util.Formulas)
local NumberFormatter = require(Shared.Util.NumberFormatter)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Net = require(Shared.Util.Net)

local Pets = {}
local S
local companions = {} -- [id] = Model
local renderQueued = {}

function Pets.init(sys)
	S = sys
end

function Pets.capacity(id: number): number
	return S.Bases.petSlotCount(id)
end

function Pets.find(id: number, uid: string)
	local p = S.PlayerData.get(id)
	if not p then
		return nil, nil
	end
	for i, pet in p.pets do
		if pet.uid == uid then
			return pet, i
		end
	end
	return nil, nil
end

-- Adds a pet. Returns true if the species was newly discovered.
function Pets.add(id: number, pet): boolean
	local p = S.PlayerData.get(id)
	table.insert(p.pets, pet)
	local isNew = S.Collection.discover(id, pet)
	if not p.equippedPet then
		Pets.equip(id, pet.uid)
	end
	Pets.queueRender(id)
	return isNew
end

function Pets.sell(id: number, uid: any): (boolean, string?)
	if typeof(uid) ~= "string" then
		return false, "Pet inválido"
	end
	local p = S.PlayerData.get(id)
	local pet, index = Pets.find(id, uid)
	if not p or not pet then
		return false, "Pet não encontrado"
	end
	local value = Formulas.sellValue(pet)
	table.remove(p.pets, index)
	if p.equippedPet == uid then
		p.equippedPet = nil
		Pets.spawnCompanion(id)
	end
	S.Economy.addGold(id, value, "Sell")
	Pets.queueRender(id)
	S.PlayerData.dirty(id)
	return true, "Vendido por " .. NumberFormatter.format(value) .. " GOLD"
end

function Pets.equip(id: number, uid: any): (boolean, string?)
	local p = S.PlayerData.get(id)
	if not p then
		return false
	end
	if uid ~= nil and (typeof(uid) ~= "string" or not Pets.find(id, uid)) then
		return false, "Pet não encontrado"
	end
	p.equippedPet = uid
	Pets.spawnCompanion(id)
	S.PlayerData.dirty(id)
	return true
end

function Pets.equipped(id: number)
	local p = S.PlayerData.get(id)
	if not p or not p.equippedPet then
		return nil
	end
	return (Pets.find(id, p.equippedPet))
end

-- Best pet by income (used by bots and auto-equip).
function Pets.best(id: number)
	local p = S.PlayerData.get(id)
	local best, bestIncome = nil, -1
	for _, pet in p and p.pets or {} do
		local inc = Formulas.petIncome(pet)
		if inc > bestIncome then
			best, bestIncome = pet, inc
		end
	end
	return best
end

-- ===================== COMPANION =====================
function Pets.spawnCompanion(id: number)
	local old = companions[id]
	if old then
		old:Destroy()
		companions[id] = nil
	end
	local pet = Pets.equipped(id)
	local char = S.Actors.character(id)
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not pet or not root then
		return
	end
	local model = ModelFactory.creature(pet.species, pet.size, pet.mutation, { scale = 0.6 })
	model.Name = "Companion_" .. tostring(id)
	ModelFactory.unanchor(model)
	local primary = model.PrimaryPart :: BasePart
	primary.Massless = false
	model:PivotTo(root.CFrame * CFrame.new(3, 1, 3))
	local a0 = Instance.new("Attachment")
	a0.Parent = primary
	local a1 = Instance.new("Attachment")
	a1.Name = "SAG_CompanionTarget"
	a1.Position = Vector3.new(3.5, 0.5, 3)
	a1.Parent = root
	local align = Instance.new("AlignPosition")
	align.Attachment0 = a0
	align.Attachment1 = a1
	align.Responsiveness = 18
	align.MaxForce = 1e6
	align.Parent = primary
	local orient = Instance.new("AlignOrientation")
	orient.Attachment0 = a0
	orient.Attachment1 = a1
	orient.Responsiveness = 14
	orient.MaxTorque = 1e6
	orient.Parent = primary
	model:SetAttribute("Owner", id)
	CollectionService:AddTag(model, "Companion")
	model.Parent = workspace.Runtime.Pets
	local player = S.Actors.player(id)
	pcall(function()
		primary:SetNetworkOwner(player)
	end)
	companions[id] = model
	model.Destroying:Connect(function()
		if a1.Parent then
			a1:Destroy()
		end
	end)
end

-- ===================== BASE DISPLAY =====================
function Pets.queueRender(id: number)
	if renderQueued[id] then
		return
	end
	renderQueued[id] = true
	task.delay(0.3, function()
		renderQueued[id] = nil
		Pets.renderBase(id)
	end)
end

function Pets.renderBase(id: number)
	local m = S.Bases.modelOf(id)
	local p = S.PlayerData.get(id)
	if not m or not p then
		return
	end
	local folder = m.PetDisplays
	folder:ClearAllChildren()
	local sorted = table.clone(p.pets)
	table.sort(sorted, function(a, b)
		return Formulas.petIncome(a) > Formulas.petIncome(b)
	end)
	for n = 1, math.min(#sorted, Pets.capacity(id)) do
		local pet = sorted[n]
		local cf = S.Bases.petCFrame(id, n)
		if cf then
			local model = ModelFactory.creature(pet.species, pet.size, pet.mutation, { scale = 0.85 })
			model.Name = "Pet_" .. pet.uid
			model:PivotTo(cf * CFrame.new(0, -0.3, 0))
			local c = Creatures.ById[pet.species]
			model:SetAttribute("Owner", id)
			model:SetAttribute("Uid", pet.uid)
			model:SetAttribute("Species", pet.species)
			model:SetAttribute("Size", pet.size)
			model:SetAttribute("Mutation", pet.mutation)
			model:SetAttribute("Income", Formulas.petIncome(pet))
			model:SetAttribute("Rarity", c and c.rarity or "Common")
			CollectionService:AddTag(model, "PetDisplay")
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "InspectPrompt"
			prompt.ActionText = "Ver"
			prompt.ObjectText = (pet.mutation ~= "None" and (pet.mutation .. " ") or "") .. pet.size .. " " .. (c and c.name or pet.species)
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Style = Enum.ProximityPromptStyle.Default
			prompt:SetAttribute("Inspect", true)
			prompt.Parent = model.PrimaryPart
			model.Parent = folder
		end
	end
end

function Pets.start()
	S.Net.handle("EquipPet", function(player, payload)
		return Pets.equip(player.UserId, payload.uid)
	end)
	S.Net.handle("SellPet", function(player, payload)
		return Pets.sell(player.UserId, payload.uid)
	end)
	S.Actors.CharacterAdded:Connect(function(id)
		task.wait(0.5)
		Pets.spawnCompanion(id)
	end)
	S.Actors.Removed:Connect(function(id)
		if companions[id] then
			companions[id]:Destroy()
			companions[id] = nil
		end
	end)
end

return Pets
