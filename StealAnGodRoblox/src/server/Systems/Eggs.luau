--[[
	Eggs — the heart of STEAL AN GOD.

	World eggs live in nests (respawning per biome cycle), on the ground (dropped, 20s to recover),
	or are special/event eggs. Grabbing one attaches it to the character's back; carrying slows you
	down by the egg size. Entering your own base with an egg deposits it automatically into a free
	incubator. Incubating eggs are rendered on pedestals with a live countdown (client-driven).

	Base raids (stealing incubating eggs from other bases) are validated by Systems/Theft.
]]

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local WeightedRandom = require(Shared.Util.WeightedRandom)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Net = require(Shared.Util.Net)

local Eggs = {}
local S

local worldEggs = {} -- [eggId] = {id, record, model, kind, nest, expiresAt}
local nests = {} -- array {id, biome, cframe, egg = eggId?, respawnAt}
local nextEggId = 0
local fullWarned = {}

local RARITY_LABEL = { "Comum", "Incomum", "Raro", "Épico", "Lendário", "Mítico", "Secreto", "Eterno", "Divino" }

function Eggs.init(sys)
	S = sys
end

-- ===================== RECORDS =====================
local function rollSize(minIndex: number?)
	local pool = {}
	for _, s in Balance.sizes do
		if s.index >= (minIndex or 1) then
			table.insert(pool, s)
		end
	end
	return WeightedRandom.pick(pool, function(s)
		return s.weight
	end).name
end

local function rollMutation(forceMutation: boolean?)
	local pool = {}
	for _, m in Balance.mutations do
		if not forceMutation or m.name ~= "None" then
			table.insert(pool, m)
		end
	end
	return WeightedRandom.pick(pool, function(m)
		return m.weight
	end).name
end
Eggs.rollMutation = rollMutation

-- variant: "normal" | "rare" | "special" | "event"
function Eggs.makeRecord(biome: number, variant: string?, opts)
	opts = opts or {}
	variant = variant or "normal"
	local special = variant == "special"
	return {
		uid = S.PlayerData.newUid(),
		biome = math.clamp(biome, 1, #Balance.biomes),
		variant = variant,
		size = rollSize(special and 3 or 1),
		mutation = rollMutation(special),
		event = opts.event,
		tier = opts.tier,
	}
end

function Eggs.displayName(record): string
	local size = Formulas.size(record.size).eggName
	if record.variant == "event" and record.event then
		for _, e in GameConfig.Events do
			if e.id == record.event then
				return "Ovo " .. e.name .. " (" .. size .. ")"
			end
		end
	end
	local b = Formulas.biome(record.biome)
	local prefix = (record.variant == "special" and "Ovo Divino") or (record.variant == "rare" and "Ovo Dourado") or "Ovo"
	return prefix .. " — " .. b.name .. " (" .. size .. ")"
end

function Eggs.rarityLabel(record): string
	if record.variant == "special" then
		return "Divino"
	elseif record.variant == "event" then
		return "Evento"
	elseif record.variant == "rare" then
		return RARITY_LABEL[math.clamp(math.floor((record.biome - 1) * 0.75) + 3, 1, 9)]
	end
	return RARITY_LABEL[math.clamp(math.floor((record.biome - 1) * 0.75) + 1, 1, 9)]
end

-- Possible content with chances (for egg info UI).
function Eggs.contents(record)
	if record.variant == "event" and record.event then
		local c = Creatures.Events[record.event]
		return { { species = c and c.id or "?", chance = 100 } }
	end
	local weights = Balance.speciesHatchWeights[record.variant] or Balance.speciesHatchWeights.normal
	local total = 0
	for _, w in weights do
		total += w
	end
	local list = {}
	for slot = 1, 4 do
		local c = Creatures.ByBiome[record.biome][slot]
		table.insert(list, { species = c.id, chance = math.floor(weights[slot] / total * 1000 + 0.5) / 10 })
	end
	return list
end

-- ===================== WORLD EGGS =====================
local function eggsFolder()
	return Workspace.Runtime.Eggs
end

local function addBillboard(model: Model, record, kind: string)
	local root = model.PrimaryPart
	local bb = Instance.new("BillboardGui")
	bb.Name = "EggInfo"
	bb.Size = UDim2.fromOffset(200, 54)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4.5 * Formulas.size(record.size).scale, 0)
	bb.MaxDistance = kind == "special" and 600 or 70
	bb.AlwaysOnTop = kind == "special" or kind == "event"
	bb.LightInfluence = 0
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Font = GameConfig.Theme.Font
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0.2
	title.Text = Eggs.rarityLabel(record) .. " • " .. Formulas.size(record.size).eggName
	title.Parent = bb
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Position = UDim2.fromScale(0, 0.55)
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.BackgroundTransparency = 1
	sub.Font = GameConfig.Theme.FontBody
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(255, 225, 120)
	sub.TextStrokeTransparency = 0.3
	sub.Text = record.mutation ~= "None" and (record.mutation .. " ✦") or Formulas.biome(record.biome).name
	sub.Parent = bb
	bb.Parent = root
end

local function setEggAttributes(model: Model, record)
	model:SetAttribute("EggName", Eggs.displayName(record))
	model:SetAttribute("Biome", record.biome)
	model:SetAttribute("Size", record.size)
	model:SetAttribute("Mutation", record.mutation)
	model:SetAttribute("Variant", record.variant)
	model:SetAttribute("EventId", record.event)
	model:SetAttribute("Rarity", Eggs.rarityLabel(record))
end

function Eggs.spawnWorldEgg(record, cf: CFrame, kind: string, opts)
	opts = opts or {}
	nextEggId += 1
	local id = nextEggId
	local eventColor = nil
	if record.variant == "event" and record.event then
		for _, e in GameConfig.Events do
			if e.id == record.event then
				eventColor = e.color
			end
		end
	end
	local model = ModelFactory.egg(record.biome, record.size, record.mutation, record.variant, eventColor)
	model.Name = "WorldEgg_" .. id
	model:PivotTo(cf)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanQuery = true
		end
	end
	setEggAttributes(model, record)
	model:SetAttribute("WorldEggId", id)
	model:SetAttribute("Kind", kind)
	addBillboard(model, record, kind)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Roubar"
	prompt.ObjectText = Eggs.displayName(record)
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		Eggs.tryPickup(player.UserId, id)
	end)
	CollectionService:AddTag(model, "WorldEgg")
	model.Parent = eggsFolder()
	local entry = { id = id, record = record, model = model, kind = kind, nest = opts.nest, expiresAt = opts.lifetime and (os.clock() + opts.lifetime) or nil, position = cf.Position }
	worldEggs[id] = entry
	return entry
end

function Eggs.removeWorldEgg(id: number)
	local e = worldEggs[id]
	if not e then
		return
	end
	worldEggs[id] = nil
	if e.model then
		e.model:Destroy()
	end
	if e.nest then
		e.nest.egg = nil
		local b = Formulas.biome(e.nest.biome)
		e.nest.respawnAt = os.clock() + b.nestRespawn * (0.8 + math.random() * 0.4)
	end
end

function Eggs.worldEggs()
	return worldEggs
end

function Eggs.nests()
	return nests
end

local function spawnNestEgg(nest)
	local variant = math.random() < Balance.rareEggChance and "rare" or "normal"
	local record = Eggs.makeRecord(nest.biome, variant)
	local entry = Eggs.spawnWorldEgg(record, nest.cframe, "nest", { nest = nest })
	nest.egg = entry.id
	return entry
end

-- ===================== CARRY =====================
local function attachCarryModel(id: number, record)
	local char = S.Actors.character(id)
	local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
	if not torso then
		return nil
	end
	local model = ModelFactory.egg(record.biome, record.size, record.mutation, record.variant)
	model.Name = "CarriedEgg"
	ModelFactory.unanchor(model)
	local scale = Formulas.size(record.size).scale
	model:PivotTo(torso.CFrame * CFrame.new(0, 0.2, 0.9 + scale * 0.9) * CFrame.new(0, -1.3 * scale, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	model.Parent = char
	return model
end

function Eggs.isCarrying(id: number): boolean
	local st = S.Actors.state(id)
	return st ~= nil and st.carry ~= nil
end

function Eggs.setCarry(id: number, record, origin)
	local st = S.Actors.state(id)
	if not st then
		return false
	end
	st.carry = { record = record, origin = origin, model = attachCarryModel(id, record), since = os.clock() }
	local char = S.Actors.character(id)
	if char then
		char:SetAttribute("CarryingEgg", true)
	end
	S.PlayerData.dirty(id)
	return true
end

local function clearCarry(id: number)
	local st = S.Actors.state(id)
	if not st or not st.carry then
		return nil
	end
	local carry = st.carry
	st.carry = nil
	if carry.model then
		carry.model:Destroy()
	end
	local char = S.Actors.character(id)
	if char then
		char:SetAttribute("CarryingEgg", nil)
	end
	S.PlayerData.dirty(id)
	return carry
end

function Eggs.tryPickup(id: number, eggId: number): (boolean, string?)
	local e = worldEggs[eggId]
	local st = S.Actors.state(id)
	if not e or not st or not S.PlayerData.get(id) then
		return false, "Ovo indisponível"
	end
	if not S.Actors.alive(id) or S.Actors.isStuck(id) then
		return false, "Você não pode pegar agora"
	end
	if st.carry then
		return false, "Você já está carregando um ovo"
	end
	if S.Security.isSuspect(id) then
		return false, "Ação bloqueada"
	end
	if not S.Security.within(id, e.position, 12) then
		return false, "Muito longe"
	end
	if e.kind == "nest" and not S.Biomes.canEnter(id, e.record.biome) then
		return false, "Bioma bloqueado"
	end
	local record = e.record
	local kind = e.kind
	Eggs.removeWorldEgg(eggId)
	Eggs.setCarry(id, record, { kind = kind })
	local p = S.PlayerData.get(id)
	p.stats.eggsStolen += 1
	local player = S.Actors.player(id)
	if player then
		Net.fire(player, "Notify", { kind = "Egg", title = "VOCÊ ROUBOU UM OVO!", text = "Leve-o até a sua base! (" .. Eggs.displayName(record) .. ")" })
		Net.fire(player, "Effect", { kind = "Pickup", position = e.position, variant = record.variant })
	end
	if kind == "special" then
		Net.fireAll("Announce", { type = "SpecialEggTaken", by = S.Actors.name(id) })
		S.Events.onSpecialTaken()
	end
	S.Collection.checkAchievements(id)
	S.Tutorial.progress(id, "StealEgg")
	return true
end

-- Drop the carried egg (guardian hit, death, voluntary, caught). Base-stolen eggs go back home.
function Eggs.dropCarry(id: number, reason: string, position: Vector3?)
	local st = S.Actors.state(id)
	if not st or not st.carry then
		return
	end
	if reason ~= "caught" and reason ~= "leave" and S.Actors.buff(id, "EggShield") then
		return -- protected by Isis/Wadjet
	end
	local pos = position or S.Actors.position(id) or (st.lastSafePosition or Vector3.zero)
	local carry = clearCarry(id)
	if not carry then
		return
	end
	if carry.origin.kind == "base" then
		S.Theft.returnEgg(carry)
		return
	end
	if reason == "leave" and carry.origin.kind ~= "special" then
		return -- egg vanishes; nest already respawning
	end
	local ground = Vector3.new(pos.X, math.max(pos.Y - 2.5, 0.2), pos.Z)
	Eggs.spawnWorldEgg(carry.record, CFrame.new(ground), carry.origin.kind == "special" and "special" or "ground", { lifetime = Balance.protection.droppedEggSeconds })
	local player = S.Actors.player(id)
	if player and reason ~= "leave" then
		Net.fire(player, "Notify", { kind = "Warning", title = "Você derrubou o ovo!", text = "Recupere-o rápido antes que desapareça." })
	end
end

-- ===================== INCUBATORS =====================
function Eggs.freeSlot(id: number): number?
	local p = S.PlayerData.get(id)
	if not p then
		return nil
	end
	for slot = 1, S.Bases.incubatorCount(id) do
		if p.eggs[tostring(slot)] == nil then
			return slot
		end
	end
	return nil
end

-- Places a record into a free incubator. remaining = seconds left (keeps progress of stolen eggs).
function Eggs.deposit(id: number, record, remaining: number?): boolean
	local p = S.PlayerData.get(id)
	local slot = Eggs.freeSlot(id)
	if not p or not slot then
		return false
	end
	local now = os.time()
	local duration = Formulas.incubationSeconds(record.biome, record.size, S.Monetization.has(id, "DoubleGrowth"), record.variant == "special")
	if record.variant == "event" then
		duration = math.floor(duration * 0.6)
	end
	local left = remaining and math.min(remaining, duration) or duration
	record.duration = duration
	record.hatchAt = now + left
	record.ready = nil
	p.eggs[tostring(slot)] = record
	Eggs.renderBaseEggs(id)
	S.PlayerData.dirty(id)
	return true
end

function Eggs.grantEggToBase(id: number, record): boolean
	return Eggs.deposit(id, record)
end

local function tryDeposit(id: number)
	local st = S.Actors.state(id)
	if not st or not st.carry or not S.Bases.isInOwnBase(id) or S.Security.isSuspect(id) then
		return
	end
	local carry = st.carry
	local remaining = nil
	if carry.origin.kind == "base" then
		remaining = carry.origin.remaining
	end
	if not Eggs.freeSlot(id) then
		if not fullWarned[id] or os.clock() - fullWarned[id] > 8 then
			fullWarned[id] = os.clock()
			local player = S.Actors.player(id)
			if player then
				Net.fire(player, "Notify", { kind = "Warning", title = "Incubadoras cheias!", text = "Melhore sua base ou espere um ovo chocar." })
			end
		end
		return
	end
	clearCarry(id)
	if carry.origin.kind == "base" then
		S.Theft.completeRaid(id, carry)
	end
	Eggs.deposit(id, carry.record, remaining)
	local player = S.Actors.player(id)
	if player then
		Net.fire(player, "Notify", { kind = "Egg", title = "Ovo depositado!", text = "Incubando: " .. Eggs.displayName(carry.record) })
		Net.fire(player, "Effect", { kind = "Deposit", position = S.Actors.position(id) })
	end
	S.Tutorial.progress(id, "Deposit")
end

-- Rebuilds egg models on the pedestals of an actor's base.
function Eggs.renderBaseEggs(id: number)
	local m = S.Bases.modelOf(id)
	local p = S.PlayerData.get(id)
	if not m or not p then
		return
	end
	local folder = m.Incubating
	folder:ClearAllChildren()
	for slotKey, record in p.eggs do
		local slot = tonumber(slotKey)
		local cf = slot and S.Bases.slotCFrame(id, slot)
		if cf and not S.Theft.isBeingStolen(id, slotKey) then
			local model = ModelFactory.egg(record.biome, record.size, record.mutation, record.variant)
			model.Name = "Incubating_" .. slotKey
			model:PivotTo(cf * CFrame.new(0, 0.5, 0))
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					d.CanQuery = true
				end
			end
			setEggAttributes(model, record)
			model:SetAttribute("Owner", id)
			model:SetAttribute("Slot", slotKey)
			model:SetAttribute("HatchAt", record.hatchAt)
			model:SetAttribute("Duration", record.duration)
			model:SetAttribute("Ready", record.ready == true)
			CollectionService:AddTag(model, "IncubatingEgg")
			-- countdown billboard (text updated client-side from attributes)
			local bb = Instance.new("BillboardGui")
			bb.Name = "Timer"
			bb.Size = UDim2.fromOffset(120, 44)
			bb.StudsOffsetWorldSpace = Vector3.new(0, 4 * Formulas.size(record.size).scale, 0)
			bb.MaxDistance = 60
			bb.LightInfluence = 0
			local label = Instance.new("TextLabel")
			label.Name = "Time"
			label.Size = UDim2.fromScale(1, 0.6)
			label.BackgroundTransparency = 1
			label.Font = GameConfig.Theme.Font
			label.TextScaled = true
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0.2
			label.Text = ""
			label.Parent = bb
			local barBg = Instance.new("Frame")
			barBg.Name = "BarBg"
			barBg.Position = UDim2.fromScale(0.1, 0.68)
			barBg.Size = UDim2.fromScale(0.8, 0.22)
			barBg.BackgroundColor3 = Color3.fromRGB(30, 25, 60)
			barBg.BorderSizePixel = 0
			barBg.Parent = bb
			local bar = Instance.new("Frame")
			bar.Name = "Bar"
			bar.Size = UDim2.fromScale(0, 1)
			bar.BackgroundColor3 = Color3.fromRGB(255, 205, 70)
			bar.BorderSizePixel = 0
			bar.Parent = barBg
			Instance.new("UICorner").Parent = barBg
			Instance.new("UICorner").Parent = bar
			bb.Parent = model.PrimaryPart
			-- raid prompt (validated by Theft; hidden for the owner client-side)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "RaidPrompt"
			prompt.ActionText = "Roubar"
			prompt.ObjectText = "Ovo de " .. S.Actors.name(id)
			prompt.HoldDuration = 1.2
			prompt.MaxActivationDistance = 9
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("Owner", id)
			prompt.Parent = model.PrimaryPart
			prompt.Triggered:Connect(function(player)
				S.Theft.tryStealFromBase(player.UserId, id, slotKey)
			end)
			model.Parent = folder
		end
	end
end

-- ===================== LIFECYCLE =====================
function Eggs.start()
	-- collect nests from the map
	for _, biomeFolder in Workspace.Map:GetChildren() do
		local biomeId = biomeFolder:GetAttribute("BiomeId")
		local nestFolder = biomeFolder:FindFirstChild("Nests")
		if biomeId and nestFolder then
			for _, nm in nestFolder:GetChildren() do
				local point = nm:FindFirstChild("EggPoint")
				if point then
					table.insert(nests, { id = biomeId * 100 + (nm:GetAttribute("NestIndex") or 0), biome = biomeId, cframe = point.CFrame, egg = nil, respawnAt = 0 })
				end
			end
		end
	end
	for _, nest in nests do
		spawnNestEgg(nest)
	end

	S.Net.on("DropEgg", function(player)
		Eggs.dropCarry(player.UserId, "voluntary")
	end)

	S.Actors.Removed:Connect(function(id)
		Eggs.dropCarry(id, "leave")
		fullWarned[id] = nil
	end)
	S.Actors.CharacterAdded:Connect(function(id, char)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				Eggs.dropCarry(id, "died")
			end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()
			-- respawn nests
			for _, nest in nests do
				if not nest.egg and now >= nest.respawnAt then
					spawnNestEgg(nest)
				end
			end
			-- expire ground/special eggs
			for id, e in worldEggs do
				if e.expiresAt and now >= e.expiresAt then
					if e.kind == "special" then
						S.Events.onSpecialExpired()
					end
					Eggs.removeWorldEgg(id)
				end
			end
			-- deposit carriers that reached their base
			for id in S.Actors.all() do
				tryDeposit(id)
			end
		end
	end)
end

return Eggs
