--!strict
-- 최소 기능 UI. 상태는 서버가 보내는 스냅샷만 표시한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared:WaitForChild("NumberFormat") :: ModuleScript)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local actionEvent = remotes:WaitForChild("Action") :: RemoteEvent
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AquaEscapeUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function makeButton(text: string, parent: Instance, order: number): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 44)
	button.LayoutOrder = order
	button.BackgroundColor3 = Color3.fromRGB(40, 60, 110)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.Parent = parent
	return button
end

local hud = Instance.new("TextLabel")
hud.Size = UDim2.fromOffset(320, 110)
hud.Position = UDim2.fromOffset(12, 12)
hud.BackgroundColor3 = Color3.fromRGB(15, 20, 40)
hud.BackgroundTransparency = 0.25
hud.TextColor3 = Color3.new(1, 1, 1)
hud.TextXAlignment = Enum.TextXAlignment.Left
hud.TextYAlignment = Enum.TextYAlignment.Top
hud.Font = Enum.Font.Gotham
hud.TextSize = 18
hud.Text = "불러오는 중..."
hud.Parent = gui

local panel = Instance.new("ScrollingFrame")
panel.Size = UDim2.new(0, 280, 0.7, 0)
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.Position = UDim2.new(1, -12, 0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 40)
panel.BackgroundTransparency = 0.25
panel.CanvasSize = UDim2.new()
panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel.Parent = gui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local stoneOne = makeButton("걸음 강화 +1", panel, 1)
local stoneTwentyFive = makeButton("걸음 강화 +25", panel, 2)
local fishButton = makeButton("물고기 창조", panel, 3)
stoneOne.MouseButton1Click:Connect(function()
	actionEvent:FireServer("UpgradeStone", 1)
end)
stoneTwentyFive.MouseButton1Click:Connect(function()
	actionEvent:FireServer("UpgradeStone", 25)
end)
fishButton.MouseButton1Click:Connect(function()
	actionEvent:FireServer("CreateFish")
end)

local coralButtons: { TextButton } = {}

stateEvent.OnClientEvent:Connect(function(state)
	hud.Text = string.format(
		"생명력 %s\n걸음당 %s  |  초당 %s\nSpeed %s  |  보석 %s  |  클리어 %d",
		NumberFormat.format(state.life),
		NumberFormat.format(state.stepValue),
		NumberFormat.format(state.passive),
		NumberFormat.format(state.speed),
		NumberFormat.format(state.gems),
		state.clears
	)

	stoneOne.Text = string.format("걸음 강화 Lv%d +1  (%s)", state.stoneLevel, NumberFormat.format(state.stoneCost1))
	stoneTwentyFive.Text = string.format("걸음 강화 +25  (%s)", NumberFormat.format(state.stoneCost25))
	fishButton.Text = string.format(
		"물고기 창조 %d/%d  (%s)",
		state.fishCount,
		state.maxFish,
		NumberFormat.format(state.fishCost)
	)

	for index, coral in state.corals do
		local button = coralButtons[index]
		if not button then
			button = makeButton("", panel, 10 + index)
			button.MouseButton1Click:Connect(function()
				actionEvent:FireServer("BuyCoral", index)
			end)
			coralButtons[index] = button
		end
		button.Visible = coral.unlocked
		button.Text = string.format("%s Lv%d  (%s)", coral.name, coral.level, NumberFormat.format(coral.cost))
	end
end)
