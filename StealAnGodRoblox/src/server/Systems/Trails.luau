--[[
	Trails — purchasable trails (GOLD) that multiply TREADMILL gains only, plus their visuals
	(Trail + light particles that follow the character) and the VIP aura/tag.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local Formulas = require(Shared.Util.Formulas)
local ModelFactory = require(Shared.Factory.ModelFactory)

local Trails = {}
local S

function Trails.init(sys)
	S = sys
end

local function rgb(a)
	return Color3.fromRGB(a[1], a[2], a[3])
end

function Trails.apply(id: number, character: Model?)
	character = character or S.Actors.character(id)
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	for _, name in { "SAG_Trail", "SAG_TrailA0", "SAG_TrailA1", "SAG_TrailFX" } do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local p = S.PlayerData.get(id)
	local def = p and Formulas.trail(p.equippedTrail)
	if not def then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "SAG_TrailA0"
	a0.Position = Vector3.new(0, 0.9, 0.4)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "SAG_TrailA1"
	a1.Position = Vector3.new(0, -1.6, 0.4)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "SAG_Trail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(rgb(def.c1), rgb(def.c2))
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.45
	trail.LightEmission = def.particles and 0.7 or 0.3
	trail.FaceCamera = true
	trail.WidthScale = NumberSequence.new(1, 0.2)
	trail.Parent = root
	if def.particles then
		local pe = ModelFactory.addParticles(root, rgb(def.c1), 6, { color2 = rgb(def.c2), size = 0.3, speed = 0.6, life = 0.7 })
		pe.Name = "SAG_TrailFX"
		pe.EmissionDirection = Enum.NormalId.Back
		CollectionService:AddTag(pe, "VFX")
	end
end

function Trails.applyVipAura(id: number, character: Model?)
	character = character or S.Actors.character(id)
	local head = character and character:FindFirstChild("Head")
	if not head or head:FindFirstChild("SAG_VipTag") then
		return
	end
	local tag = Instance.new("BillboardGui")
	tag.Name = "SAG_VipTag"
	tag.Size = UDim2.fromOffset(80, 26)
	tag.StudsOffset = Vector3.new(0, 2.6, 0)
	tag.AlwaysOnTop = false
	tag.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "👑 VIP"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 215, 70)
	label.TextStrokeTransparency = 0.3
	label.Parent = tag
	tag.Parent = head
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local pe = ModelFactory.addParticles(root, Color3.fromRGB(255, 215, 80), 3, { size = 0.2, speed = 0.5 })
		pe.Name = "SAG_VipAura"
	end
end

function Trails.grant(id: number, trailId: string)
	local p = S.PlayerData.get(id)
	if not p or not Formulas.trail(trailId) then
		return
	end
	if not table.find(p.trailsOwned, trailId) then
		table.insert(p.trailsOwned, trailId)
	end
	p.equippedTrail = trailId
	Trails.apply(id)
	S.PlayerData.dirty(id)
	local player = S.Actors.player(id)
	if player then
		S.Net.fire(player, "Notify", { kind = "Trail", title = "Novo Trail!", text = Formulas.trail(trailId).name })
	end
end

function Trails.buy(id: number, trailId: any): (boolean, string?)
	if typeof(trailId) ~= "string" then
		return false, "Trail inválido"
	end
	local def = Formulas.trail(trailId)
	local p = S.PlayerData.get(id)
	if not def or not p or def.price < 0 then
		return false, "Trail indisponível"
	end
	if table.find(p.trailsOwned, trailId) then
		return false, "Você já possui este Trail"
	end
	if not S.Economy.spend(id, def.price) then
		return false, "GOLD insuficiente"
	end
	table.insert(p.trailsOwned, trailId)
	p.equippedTrail = trailId
	Trails.apply(id)
	S.PlayerData.dirty(id)
	S.Tutorial.progress(id, "BuyTrail")
	return true, def.name .. " equipado! (" .. def.mult .. "x treino)"
end

function Trails.equip(id: number, trailId: any): (boolean, string?)
	local p = S.PlayerData.get(id)
	if not p then
		return false
	end
	if trailId == nil or trailId == false then
		p.equippedTrail = nil
	elseif typeof(trailId) == "string" and table.find(p.trailsOwned, trailId) then
		p.equippedTrail = trailId
	else
		return false, "Você não possui este Trail"
	end
	Trails.apply(id)
	S.PlayerData.dirty(id)
	return true
end

-- Best affordable next trail (used by bots).
function Trails.nextTrail(id: number)
	local p = S.PlayerData.get(id)
	if not p then
		return nil
	end
	local best = Formulas.trail(p.equippedTrail)
	for _, t in Balance.trails do
		if not table.find(p.trailsOwned, t.id) and (not best or t.mult > best.mult) then
			return t
		end
	end
	return nil
end

function Trails.start()
	S.Net.handle("BuyTrail", function(player, payload)
		return Trails.buy(player.UserId, payload.id)
	end)
	S.Net.handle("EquipTrail", function(player, payload)
		return Trails.equip(player.UserId, payload.id)
	end)
	S.Actors.CharacterAdded:Connect(function(id, char)
		task.wait(0.2)
		Trails.apply(id, char)
		if S.Monetization.has(id, "VIP") then
			Trails.applyVipAura(id, char)
		end
	end)
end

return Trails
