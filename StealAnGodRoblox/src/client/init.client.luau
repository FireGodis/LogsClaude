--[[
	STEAL AN GOD — the single client entry point (two-phase: init all, then start all).
]]

local Client = script
local State = require(Client.State)

local ORDER = {
	"Sound", "Panels", "Notifications", "Hud", "Effects", "World", "Input", "Training", "Tutorial",
	"ShopUI", "InventoryUI", "IndexUI", "UpgradesUI", "RewardsUI", "EventsUI", "SettingsUI", "PetInfoUI",
}

local C = { State = State }
for _, name in ORDER do
	local module = Client.Controllers:FindFirstChild(name) or Client.UI:FindFirstChild(name)
	C[name] = require(module)
end

State.start()
for _, name in ORDER do
	if typeof(C[name].init) == "function" then
		C[name].init(C)
	end
end
for _, name in ORDER do
	if typeof(C[name].start) == "function" then
		task.spawn(C[name].start)
	end
end
