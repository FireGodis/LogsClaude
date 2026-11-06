--[[
	Tutorial — short gameplay objectives (no wall of text). Progress is driven by REAL gameplay
	events reported by the systems (StealEgg, Deposit, Hatch, ...), in any order. The client shows
	the first unfinished objective with an arrow/beam to the target.
]]

local Tutorial = {}
local S

Tutorial.Steps = {
	{ key = "SeeBase", text = "Esta é a sua base! Seus ovos e criaturas ficam aqui." },
	{ key = "StealEgg", text = "Vá ao Bosque de Arcádia e ROUBE um ovo (segure E)." },
	{ key = "Deposit", text = "Volte para a sua base com o ovo para depositá-lo." },
	{ key = "Hatch", text = "Espere o ovo chocar na incubadora." },
	{ key = "Collect", text = "Pise na plataforma dourada para coletar o GOLD dos pets." },
	{ key = "Train", text = "Corra na esteira da sua base para ganhar Speed." },
	{ key = "BuyTrail", text = "Compre seu primeiro Trail (multiplica o treino)." },
	{ key = "UnlockBiome", text = "Alcance 150 Speed e desbloqueie a Costa do Mar Egeu." },
	{ key = "OpenIndex", text = "Abra o Index e veja todas as criaturas." },
	{ key = "RaidTip", text = "Dica: você pode roubar ovos que estão incubando em outras bases!" },
}
local valid = {}
for _, s in Tutorial.Steps do
	valid[s.key] = true
end

function Tutorial.init(sys)
	S = sys
end

function Tutorial.progress(id: number, key: string)
	local p = S.PlayerData.get(id)
	if not p or S.Actors.isBot(id) then
		return
	end
	p.tutDone = p.tutDone or {}
	if valid[key] and not p.tutDone[key] then
		p.tutDone[key] = true
		local n = 0
		for _, s in Tutorial.Steps do
			if p.tutDone[s.key] then
				n += 1
			end
		end
		p.tutorial = n + 1
		S.PlayerData.dirty(id)
	end
end

function Tutorial.start()
	S.Net.handle("TutorialStep", function(player, payload)
		-- only purely informational steps can be completed by the client
		local key = payload.key
		if key == "OpenIndex" or key == "RaidTip" or key == "SeeBase" then
			Tutorial.progress(player.UserId, key)
			return true
		end
		return false
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for id in S.Actors.all() do
				if not S.Actors.isBot(id) and S.Bases.isInOwnBase(id) then
					Tutorial.progress(id, "SeeBase")
				end
			end
		end
	end)
end

return Tutorial
