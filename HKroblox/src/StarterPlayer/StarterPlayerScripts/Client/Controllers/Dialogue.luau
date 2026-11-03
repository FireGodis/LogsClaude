--!strict
-- Interface reutilizável para conversas narrativas recebidas do servidor.
-- O cliente apresenta texto; progressão e recompensas permanecem no servidor.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Net = require(script.Parent.Net)
local Audio = require(script.Parent.Audio)
local Movement = require(script.Parent.Movement)

local Dialogue = {}
local player = Players.LocalPlayer
local active = false
local closeDialogue: (() -> ())? = nil
local generation = 0

local function buildGui(): (ScreenGui, TextLabel, TextLabel, TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "RK_Dialogue"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 80
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -34, 0, 34)
	panel.Size = UDim2.new(0.56, 0, 0, 205)
	panel.BackgroundColor3 = Color3.fromRGB(8, 11, 20)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(156, 196, 220)
	stroke.Transparency = 0.35
	stroke.Thickness = 1
	stroke.Parent = panel

	local ornament = Instance.new("TextLabel")
	ornament.Name = "Ornament"
	ornament.AnchorPoint = Vector2.new(0.5, 0)
	ornament.Position = UDim2.new(0.5, 0, 0, 4)
	ornament.Size = UDim2.new(0.4, 0, 0, 26)
	ornament.BackgroundTransparency = 1
	ornament.Font = Enum.Font.Garamond
	ornament.Text = "—  ◇  —"
	ornament.TextColor3 = Color3.fromRGB(183, 213, 226)
	ornament.TextSize = 20
	ornament.Parent = panel

	local body = Instance.new("TextLabel")
	body.Name = "Line"
	body.Position = UDim2.new(0, 28, 0, 43)
	body.Size = UDim2.new(1, -56, 0, 112)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Garamond
	body.TextColor3 = Color3.fromRGB(237, 235, 228)
	body.TextSize = 25
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Center
	body.Text = ""
	body.TextTransparency = 1
	body.Parent = panel

	local name = Instance.new("TextLabel")
	name.Name = "Speaker"
	name.AnchorPoint = Vector2.new(0, 1)
	name.Position = UDim2.new(0, 44, 1, -38)
	name.Size = UDim2.new(0.62, 0, 0, 54)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.Garamond
	name.TextColor3 = Color3.fromRGB(190, 220, 235)
	name.TextSize = 34
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextStrokeColor3 = Color3.fromRGB(5, 8, 15)
	name.TextStrokeTransparency = 0.35
	name.TextTransparency = 1
	name.ZIndex = 3
	name.Parent = gui

	local hint = Instance.new("TextLabel")
	hint.Name = "ContinueHint"
	hint.AnchorPoint = Vector2.new(1, 1)
	hint.Position = UDim2.new(1, -18, 1, -8)
	hint.Size = UDim2.fromOffset(190, 20)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Garamond
	hint.Text = "Espaço para continuar"
	hint.TextColor3 = Color3.fromRGB(140, 158, 179)
	hint.TextSize = 15
	hint.TextTransparency = 1
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Parent = panel
	return gui, body, name, hint
end

local function openDialogue(npcId: string, speaker: string, rawLines: any)
	if active or typeof(npcId) ~= "string" or typeof(speaker) ~= "string" or typeof(rawLines) ~= "table" then
		return
	end
	local lines: { string } = {}
	for _, line in rawLines do
		if typeof(line) == "string" then
			table.insert(lines, string.sub(line, 1, 320))
		end
	end
	if #lines == 0 then
		return
	end

	active = true
	generation += 1
	local thisGeneration = generation
	local releaseControls = Movement.acquireControlLock()
	local gui, body, name, hint = buildGui()
	local finished = false
	local typing = false
	local fullText = ""
	local lineIndex = 1
	local typeToken = 0
	local inputConnection: RBXScriptConnection? = nil
	local characterConnection: RBXScriptConnection? = nil
	local cleanup: () -> () = function()
		if finished then
			return
		end
		finished = true
		active = false
		typeToken += 1
		if inputConnection then
			inputConnection:Disconnect()
			inputConnection = nil
		end
		if characterConnection then
			characterConnection:Disconnect()
			characterConnection = nil
		end
		releaseControls()
		TweenService:Create(body, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		TweenService:Create(name, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		TweenService:Create(hint, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		task.delay(0.3, function()
			if gui.Parent then
				gui:Destroy()
			end
		end)
		if closeDialogue == cleanup then
			closeDialogue = nil
		end
	end
	closeDialogue = cleanup

	local function showLine(index: number)
		lineIndex = index
		fullText = lines[index]
		body.Text = ""
		typing = true
		typeToken += 1
		local token = typeToken
		task.spawn(function()
			for charIndex = 1, #fullText do
				if finished or token ~= typeToken or thisGeneration ~= generation then
					return
				end
				body.Text = string.sub(fullText, 1, charIndex)
				if charIndex % 5 == 1 then
					Audio.play("blip")
				end
				task.wait(0.024)
			end
			typing = false
		end)
	end

	TweenService:Create(body, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
	TweenService:Create(hint, TweenInfo.new(0.35), { TextTransparency = 0.12 }):Play()
	name.Text = speaker
	TweenService:Create(name, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
	task.delay(2.8, function()
		if finished or thisGeneration ~= generation then
			return
		end
		TweenService:Create(name, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
		task.delay(0.78, function()
			if not finished and thisGeneration == generation then
				showLine(1)
			end
		end)
	end)

	inputConnection = UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or finished then
			return
		end
		local key = input.KeyCode
		if key ~= Enum.KeyCode.Space and key ~= Enum.KeyCode.Return and key ~= Enum.KeyCode.E and key ~= Enum.KeyCode.ButtonA and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if typing then
			typeToken += 1
			body.Text = fullText
			typing = false
			return
		end
		if lineIndex < #lines then
			showLine(lineIndex + 1)
		else
			Net.send("Story", "Finish", npcId)
			cleanup()
		end
	end)

	characterConnection = player.CharacterRemoving:Connect(function()
		if closeDialogue == cleanup then
			cleanup()
		end
	end)
end

function Dialogue.start()
	Net.on("Story", function(action: any, npcId: any, speaker: any, lines: any)
		if action == "Open" then
			openDialogue(npcId, speaker, lines)
		elseif action == "Reward" then
			Audio.play("relic")
		end
	end)
end

return Dialogue