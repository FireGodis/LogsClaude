--[[
	Panels — one modal panel open at a time, with pop-in animation; shared ScreenGui.
]]

local TweenService = game:GetService("TweenService")
local Kit = require(script.Parent.Parent.UI.Kit)

local Panels = {}
local C
local registry = {} -- [name] = {frame, onOpen}
local current: string? = nil
Panels.screen = nil

function Panels.init(ctx)
	C = ctx
	Panels.screen = Kit.screen("SAG_Panels", 10)
	Kit.autoScale(Panels.screen)
end

function Panels.register(name: string, panel, onOpen)
	registry[name] = { frame = panel.frame, onOpen = onOpen }
	panel.close.Activated:Connect(function()
		Panels.close()
	end)
end

function Panels.open(name: string)
	local entry = registry[name]
	if not entry then
		return
	end
	if current and current ~= name then
		registry[current].frame.Visible = false
	end
	current = name
	entry.frame.Visible = true
	local scale = entry.frame:FindFirstChild("PopScale") or Kit.new("UIScale", { Name = "PopScale", Parent = entry.frame })
	scale.Scale = 0.85
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	if entry.onOpen then
		task.spawn(entry.onOpen)
	end
end

function Panels.close()
	if current and registry[current] then
		registry[current].frame.Visible = false
	end
	current = nil
end

function Panels.toggle(name: string)
	if current == name then
		Panels.close()
	else
		Panels.open(name)
	end
end

function Panels.isOpen(name: string?): boolean
	if name then
		return current == name
	end
	return current ~= nil
end

return Panels
