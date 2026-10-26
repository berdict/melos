--!strict
-- 표시 전용. 숫자는 서버가 보낸 상태만 보여 준다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat") :: ModuleScript)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent
local readyEvent = remotes:WaitForChild("Ready") :: RemoteEvent

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- 화면 위쪽 가운데. 좌상단의 기본 로블록스 메뉴와 겹치지 않는다.
local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0, 12)
frame.Size = UDim2.fromOffset(300, 84)
frame.BackgroundColor3 = Color3.fromRGB(20, 24, 48)
frame.BackgroundTransparency = 0.2
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local function makeRow(index: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -24, 0.5, -6)
	label.Position = UDim2.new(0, 12, 0.5 * (index - 1), if index == 1 then 6 else 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = frame

	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 28
	limit.Parent = label
	return label
end

local speedLabel = makeRow(1, Color3.fromRGB(120, 220, 255))
local coinLabel = makeRow(2, Color3.fromRGB(255, 215, 90))
speedLabel.Text = "속도  0"
coinLabel.Text = "코인  0"

stateEvent.OnClientEvent:Connect(function(state)
	speedLabel.Text = "속도  " .. NumberFormat.format(state.speed)
	coinLabel.Text = "코인  " .. NumberFormat.format(state.coins)
end)

readyEvent:FireServer()
