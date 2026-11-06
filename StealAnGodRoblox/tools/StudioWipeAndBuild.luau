--[[
	StudioWipeAndBuild.luau — paste into Roblox Studio's COMMAND BAR (View > Command Bar).

	STEP 1 (WIPE) deletes EVERYTHING the previous version left in the open place
	("UPD Steal An God"): scripts, maps, GUIs, lighting effects, terrain. This is destructive by
	design — save a copy first (File > Save to File As...) if you want a backup.

	STEP 2 (BUILD) runs after the new code is in the place (Rojo sync of default.project.json, or
	copy from build/StealAnGod.rbxlx) and generates the full map in EDIT mode so it is saved with
	the place and visible in Studio before you press Play.

	Set the two flags below and press Enter.
]]

local DO_WIPE = true
local DO_BUILD = false -- set true after the new scripts are in the place

if DO_WIPE then
	local ChangeHistoryService = game:GetService("ChangeHistoryService")
	ChangeHistoryService:SetWaypoint("SAG before wipe")
	local keepWorkspace = { Camera = true, Terrain = true }
	local removed = 0
	for _, child in workspace:GetChildren() do
		if not keepWorkspace[child.Name] and not child:IsA("Camera") and not child:IsA("Terrain") then
			pcall(function()
				child:Destroy()
				removed += 1
			end)
		end
	end
	workspace.Terrain:Clear()
	local containers = {
		game:GetService("ReplicatedStorage"), game:GetService("ReplicatedFirst"), game:GetService("ServerScriptService"),
		game:GetService("ServerStorage"), game:GetService("StarterGui"), game:GetService("StarterPack"),
		game:GetService("Lighting"), game:GetService("SoundService"), game:GetService("Teams"),
		game:GetService("StarterPlayer"):FindFirstChildOfClass("StarterPlayerScripts"),
		game:GetService("StarterPlayer"):FindFirstChildOfClass("StarterCharacterScripts"),
	}
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				local ok = pcall(function()
					child:Destroy()
				end)
				if ok then
					removed += 1
				end
			end
		end
	end
	ChangeHistoryService:SetWaypoint("SAG wiped")
	print(("[SAG] Wipe complete: %d objects removed. Now sync/insert the new project, then run with DO_BUILD = true."):format(removed))
end

if DO_BUILD then
	local server = game:GetService("ServerScriptService"):FindFirstChild("Server")
	local builder = server and server:FindFirstChild("World") and server.World:FindFirstChild("WorldBuilder")
	assert(builder, "ServerScriptService.Server.World.WorldBuilder not found — sync the project first (Rojo or the .rbxlx).")
	local t0 = os.clock()
	require(builder).build(true)
	print(("[SAG] Map generated in %.1fs. Save the place (Ctrl+S) and publish."):format(os.clock() - t0))
end
