--[[
	Traps — the divine snare. Each player owns 3 traps; placing one consumes it and it comes back
	when it is triggered, removed or expires (5 min, so no permanent blockades).

	• cannot be placed in safe areas: spawn plaza, shop plaza, OTHER players' bases, gates, nests
	• only triggers on characters CARRYING an egg who are not the owner (anti-grief)
	• holds the victim 4s (no egg drop: the owner gets a chance to catch them), then 8s immunity
	• Anubis/Forge Golem abilities grant immunity; Osiris/Nidhogg free you
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Balance = require(Shared.Config.Balance)
local GameConfig = require(Shared.Config.GameConfig)
local ModelFactory = require(Shared.Factory.ModelFactory)
local Net = require(Shared.Util.Net)

local Traps = {}
local S
local T = Balance.traps
local W = GameConfig.World

local traps = {} -- [trapId] = {id, owner, position, model, expiresAt}
local nextId = 0
local holding = {} -- [actorId] = trapId currently holding them

function Traps.init(sys)
	S = sys
end

function Traps.activeCount(id: number): number
	local n = 0
	for _, t in traps do
		if t.owner == id then
			n += 1
		end
	end
	return n
end

function Traps.listFor(id: number)
	local out = {}
	for _, t in traps do
		if t.owner == id then
			table.insert(out, t)
		end
	end
	return out
end

-- Returns nil when allowed, otherwise the reason.
function Traps.placementBlocked(id: number, position: Vector3): string?
	if (position - W.SpawnPosition).Magnitude < 40 then
		return "Área segura (spawn)"
	end
	local plaza = Vector3.new(W.BaseOffsetX, 0, W.BaseRows[4])
	if (Vector3.new(position.X, 0, position.Z) - plaza).Magnitude < 45 then
		return "Área segura (loja)"
	end
	local inBase = S.Bases.baseAt(position)
	if inBase and inBase ~= S.Bases.baseIndexOf(id) then
		return "Não é possível colocar na base de outro jogador"
	end
	for b = 1, #Balance.biomes do
		local z0 = S.WorldBuilder.biomeZ(b)
		if math.abs(position.Z - z0) < 10 then
			return "Muito perto de um portão"
		end
	end
	for _, nest in S.Eggs.nests() do
		if (nest.cframe.Position - position).Magnitude < T.safeRadiusFromNest then
			return "Muito perto de um ninho"
		end
	end
	for _, t in traps do
		if (t.position - position).Magnitude < T.minSpacing then
			return "Muito perto de outra armadilha"
		end
	end
	return nil
end

function Traps.place(id: number): (boolean, string?)
	local pos = S.Actors.position(id)
	local p = S.PlayerData.get(id)
	if not pos or not p or not S.Actors.alive(id) then
		return false, "Indisponível"
	end
	if Traps.activeCount(id) >= T.maxActive then
		return false, "Máximo de " .. T.maxActive .. " armadilhas ativas"
	end
	local ground = Vector3.new(pos.X, pos.Y - 2.9, pos.Z)
	local reason = Traps.placementBlocked(id, ground)
	if reason then
		return false, reason
	end
	nextId += 1
	local model = ModelFactory.trap()
	model.Name = "Trap_" .. nextId
	model:PivotTo(CFrame.new(ground))
	model:SetAttribute("Owner", id)
	model:SetAttribute("OwnerName", S.Actors.name(id))
	model.Parent = Workspace.Runtime.Traps
	traps[nextId] = { id = nextId, owner = id, position = ground, model = model, expiresAt = os.clock() + T.lifetimeSeconds }
	S.PlayerData.dirty(id)
	S.Tutorial.progress(id, "Trap")
	return true, "Armadilha colocada (" .. Traps.activeCount(id) .. "/" .. T.maxActive .. ")"
end

local function removeTrap(trapId: number)
	local t = traps[trapId]
	if not t then
		return
	end
	traps[trapId] = nil
	if t.model then
		t.model:Destroy()
	end
	S.PlayerData.dirty(t.owner)
end

function Traps.remove(id: number, trapId: any): (boolean, string?)
	if trapId == nil then
		-- remove the nearest own trap
		local pos = S.Actors.position(id)
		local best, bd = nil, 20
		for tid, t in traps do
			if t.owner == id and pos and (t.position - pos).Magnitude < bd then
				best, bd = tid, (t.position - pos).Magnitude
			end
		end
		trapId = best
	end
	local t = typeof(trapId) == "number" and traps[trapId]
	if not t or t.owner ~= id then
		return false, "Nenhuma armadilha sua por perto"
	end
	removeTrap(trapId)
	return true, "Armadilha recolhida"
end

function Traps.releaseActor(id: number)
	holding[id] = nil
	local st = S.Actors.state(id)
	if st then
		st.trappedUntil = 0
	end
end

local function trigger(t, victim: number)
	local st = S.Actors.state(victim)
	if not st then
		return
	end
	local now = os.clock()
	st.trappedUntil = now + T.stunSeconds
	st.trapImmuneUntil = now + T.stunSeconds + T.immunitySeconds
	holding[victim] = t.id
	t.model:SetAttribute("Triggered", true)
	Net.fireAll("Effect", { kind = "TrapSnap", position = t.position })
	local vp = S.Actors.player(victim)
	if vp then
		Net.fire(vp, "Trapped", T.stunSeconds)
		Net.fire(vp, "Notify", { kind = "Alarm", title = "PRESO NUMA ARMADILHA!", text = "Armadilha de " .. S.Actors.name(t.owner) })
	end
	local op = S.Actors.player(t.owner)
	if op then
		Net.fire(op, "Notify", { kind = "Reward", title = "Sua armadilha pegou alguém!", text = S.Actors.name(victim) .. " está preso por " .. T.stunSeconds .. "s" })
	end
	-- trap returns to the owner after the snap animation
	local tid = t.id
	task.delay(1.2, function()
		removeTrap(tid)
	end)
end

function Traps.start()
	S.Net.handle("PlaceTrap", function(player)
		return Traps.place(player.UserId)
	end)
	S.Net.handle("RemoveTrap", function(player, payload)
		return Traps.remove(player.UserId, payload.id)
	end)
	S.Actors.Removed:Connect(function(id)
		for tid, t in traps do
			if t.owner == id then
				removeTrap(tid)
			end
		end
		holding[id] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(0.15)
			local now = os.clock()
			for tid, t in traps do
				if now > t.expiresAt then
					removeTrap(tid)
				elseif not t.model:GetAttribute("Triggered") then
					for id in S.Actors.all() do
						if id ~= t.owner then
							local st = S.Actors.state(id)
							local pos = S.Actors.position(id)
							if st and pos and st.carry and st.trapImmuneUntil < now and not S.Actors.buff(id, "TrapWard")
								and (Vector3.new(pos.X, t.position.Y, pos.Z) - t.position).Magnitude < T.triggerRadius
								and math.abs(pos.Y - t.position.Y) < 6 then
								trigger(t, id)
								break
							end
						end
					end
				end
			end
		end
	end)
end

return Traps
