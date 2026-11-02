--!strict
-- Entrada unificada: teclado, controle e toque viram as mesmas ações.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Input = {}

local held: { [string]: boolean } = {}
local pressCallbacks: { [string]: { () -> () } } = {}
local releaseCallbacks: { [string]: { () -> () } } = {}
local stickX = 0
local stickY = 0
local enabled = false

local keyMap: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.A] = "left",
	[Enum.KeyCode.Left] = "left",
	[Enum.KeyCode.DPadLeft] = "left",
	[Enum.KeyCode.D] = "right",
	[Enum.KeyCode.Right] = "right",
	[Enum.KeyCode.DPadRight] = "right",
	[Enum.KeyCode.W] = "up",
	[Enum.KeyCode.Up] = "up",
	[Enum.KeyCode.DPadUp] = "up",
	[Enum.KeyCode.S] = "down",
	[Enum.KeyCode.Down] = "down",
	[Enum.KeyCode.DPadDown] = "down",
	[Enum.KeyCode.Space] = "jump",
	[Enum.KeyCode.K] = "jump",
	[Enum.KeyCode.ButtonA] = "jump",
	[Enum.KeyCode.J] = "attack",
	[Enum.KeyCode.ButtonX] = "attack",
	[Enum.KeyCode.L] = "dash",
	[Enum.KeyCode.LeftShift] = "dash",
	[Enum.KeyCode.ButtonB] = "dash",
	[Enum.KeyCode.ButtonR2] = "dash",
	[Enum.KeyCode.F] = "focus",
	[Enum.KeyCode.ButtonY] = "focus",
	[Enum.KeyCode.Q] = "pulse",
	[Enum.KeyCode.ButtonL1] = "pulse",
}

local function press(action: string)
	if not enabled or held[action] then
		return
	end
	held[action] = true
	local callbacks = pressCallbacks[action]
	if callbacks then
		for _, callback in callbacks do
			callback()
		end
	end
end

local function release(action: string)
	if not held[action] then
		return
	end
	held[action] = false
	local callbacks = releaseCallbacks[action]
	if callbacks then
		for _, callback in callbacks do
			callback()
		end
	end
end

function Input.onPress(action: string, callback: () -> ())
	local list = pressCallbacks[action]
	if not list then
		list = {}
		pressCallbacks[action] = list
	end
	table.insert(list, callback)
end

function Input.onRelease(action: string, callback: () -> ())
	local list = releaseCallbacks[action]
	if not list then
		list = {}
		releaseCallbacks[action] = list
	end
	table.insert(list, callback)
end

function Input.setEnabled(value: boolean)
	enabled = value
	if not value then
		for action in held do
			release(action)
		end
		stickX, stickY = 0, 0
	end
end

function Input.isHeld(action: string): boolean
	return enabled and held[action] == true
end

function Input.axisX(): number
	if not enabled then
		return 0
	end
	local keys = (if held.right then 1 else 0) - (if held.left then 1 else 0)
	if keys ~= 0 then
		return keys
	end
	if math.abs(stickX) > 0.35 then
		return if stickX > 0 then 1 else -1
	end
	return 0
end

function Input.axisY(): number
	if not enabled then
		return 0
	end
	local keys = (if held.up then 1 else 0) - (if held.down then 1 else 0)
	if keys ~= 0 then
		return keys
	end
	if math.abs(stickY) > 0.5 then
		return if stickY > 0 then 1 else -1
	end
	return 0
end

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		press("attack")
		return
	end
	local action = keyMap[input.KeyCode]
	if action then
		press(action)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		release("attack")
		return
	end
	local action = keyMap[input.KeyCode]
	if action then
		release(action)
	end
end)

UserInputService.InputChanged:Connect(function(input: InputObject)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		stickX = input.Position.X
		stickY = input.Position.Y
	end
end)

-- Botões de toque (celular/tablet).
function Input.buildTouchControls()
	if not UserInputService.TouchEnabled then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "RK_Touch"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 30
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local function makeButton(text: string, anchor: Vector2, position: UDim2, size: number, action: string)
		local button = Instance.new("TextButton")
		button.Name = action
		button.AnchorPoint = anchor
		button.Position = position
		button.Size = UDim2.fromOffset(size, size)
		button.BackgroundColor3 = Color3.fromRGB(14, 18, 34)
		button.BackgroundTransparency = 0.35
		button.Text = text
		button.TextColor3 = Color3.fromRGB(236, 235, 228)
		button.Font = Enum.Font.Garamond
		button.TextSize = math.floor(size * 0.34)
		button.AutoButtonColor = false
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = button
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(236, 235, 228)
		stroke.Transparency = 0.5
		stroke.Thickness = 2
		stroke.Parent = button
		button.MouseButton1Down:Connect(function()
			press(action)
		end)
		button.MouseButton1Up:Connect(function()
			release(action)
		end)
		button.MouseLeave:Connect(function()
			release(action)
		end)
		button.Parent = gui
	end

	makeButton("◀", Vector2.new(0, 1), UDim2.new(0, 24, 1, -24), 78, "left")
	makeButton("▶", Vector2.new(0, 1), UDim2.new(0, 114, 1, -24), 78, "right")
	makeButton("Pular", Vector2.new(1, 1), UDim2.new(1, -24, 1, -24), 84, "jump")
	makeButton("Golpe", Vector2.new(1, 1), UDim2.new(1, -120, 1, -48), 78, "attack")
	makeButton("Dash", Vector2.new(1, 1), UDim2.new(1, -24, 1, -122), 64, "dash")
	makeButton("Foco", Vector2.new(1, 1), UDim2.new(1, -100, 1, -140), 58, "focus")
	makeButton("Eco", Vector2.new(1, 1), UDim2.new(1, -166, 1, -128), 54, "pulse")
	makeButton("▲", Vector2.new(0, 1), UDim2.new(0, 69, 1, -110), 56, "up")
	makeButton("▼", Vector2.new(0, 1), UDim2.new(0, 69, 1, -176), 56, "down")
end

return Input
