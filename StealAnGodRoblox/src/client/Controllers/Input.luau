--[[
	Input — keyboard + gamepad bindings (touch uses the on-screen HUD buttons).
	  Q / ButtonX  ability        T / ButtonY  place trap     R / DPadLeft  pick up trap
	  G / DPadDown drop egg       B / DPadUp   shop           Escape/ButtonB close panel
]]

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Util.Net)

local Input = {}
local C

function Input.init(ctx)
	C = ctx
end

local function bind(name: string, fn, ...)
	ContextActionService:BindAction(name, function(_, state)
		if state == Enum.UserInputState.Begin then
			fn()
		end
		return Enum.ContextActionResult.Pass
	end, false, ...)
end

function Input.start()
	bind("SAG_Ability", function()
		C.Hud.useAbility()
	end, Enum.KeyCode.Q, Enum.KeyCode.ButtonX)
	bind("SAG_Trap", function()
		C.Hud.placeTrap()
	end, Enum.KeyCode.T, Enum.KeyCode.ButtonY)
	bind("SAG_RemoveTrap", function()
		C.Hud.removeTrap()
	end, Enum.KeyCode.R, Enum.KeyCode.DPadLeft)
	bind("SAG_Drop", function()
		Net.send("DropEgg")
	end, Enum.KeyCode.G, Enum.KeyCode.DPadDown)
	bind("SAG_Shop", function()
		C.Panels.toggle("Shop")
	end, Enum.KeyCode.B, Enum.KeyCode.DPadUp)
	bind("SAG_Close", function()
		C.Panels.close()
	end, Enum.KeyCode.ButtonB)
end

return Input
