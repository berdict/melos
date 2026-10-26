--!strict
-- 스테이지(키보드 키 모양 점프맵)와 로비 입구를 만들고, 낙하 시 시작 키로 되돌린다.
-- 키는 Base 파트(충돌, "Key" 태그) + Cap 파트(장식, 클라이언트가 눌림 연출)로 이루어진다.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local NumberFormat = require(Shared:WaitForChild("NumberFormat") :: ModuleScript)

local KEY_TAG = "Key"
local LETTERS = "QWERTYUIOPASDFGHJKLZXCVBNM"
local LABEL_COLOR = Color3.fromRGB(95, 55, 45)

local course = Config.Course

local stagesFolder = Instance.new("Folder")
stagesFolder.Name = "Stages"
stagesFolder.Parent = workspace

local startPositions: { [number]: Vector3 } = {}
local currentStage: { [Player]: number } = {}

local function makeKey(
	parent: Instance,
	name: string,
	center: Vector3,
	lengthX: number,
	label: string,
	capColor: Color3,
	baseColor: Color3
): Part
	local base = Instance.new("Part")
	base.Name = name
	base.Anchored = true
	base.Size = Vector3.new(lengthX, course.KeyHeight, course.KeySize)
	base.Position = center
	base.Color = baseColor
	base.Material = Enum.Material.SmoothPlastic
	base.Parent = parent
	CollectionService:AddTag(base, KEY_TAG)

	local capSize = Vector3.new(lengthX - 0.8, course.CapHeight, course.KeySize - 0.8)
	local restY = center.Y + course.KeyHeight / 2 + course.CapHeight / 2

	local cap = Instance.new("Part")
	cap.Name = "Cap"
	cap.Anchored = true
	cap.CanCollide = false
	cap.CanQuery = false
	cap.CanTouch = false
	cap.Size = capSize
	cap.Position = Vector3.new(center.X, restY, center.Z)
	cap.Color = capColor
	cap.Material = Enum.Material.SmoothPlastic
	cap:SetAttribute("RestY", restY) -- 클라이언트가 눌림 연출의 기준으로 쓴다
	cap.Parent = base

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = cap

	local text = Instance.new("TextLabel")
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.Position = UDim2.fromScale(0.5, 0.5)
	text.BackgroundTransparency = 1
	text.Text = label
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = LABEL_COLOR
	if lengthX <= course.KeySize + 0.001 then
		-- 정사각형 키: 걷는 방향(+X)에서 글자가 바로 보이도록 돌린다
		text.Size = UDim2.fromScale(1, 1)
		text.Rotation = 90
	else
		text.Size = UDim2.fromScale(0.9, 0.6)
	end
	text.Parent = gui

	return base
end

local function buildStage(index: number, def: Config.StageDef)
	local folder = Instance.new("Folder")
	folder.Name = "Stage" .. index
	folder.Parent = stagesFolder

	local laneZ = (index - 2) * course.LaneSpacing
	local centerY = course.Y - course.KeyHeight / 2
	local cursor = course.OriginX -- 마지막으로 놓은 키의 오른쪽 끝
	local letterIndex = 0
	local capIndex = 0

	local function place(name: string, length: number, gapBefore: number, label: string?, wide: boolean): Part
		local centerX = cursor + gapBefore + length / 2
		cursor += gapBefore + length
		local text = label
		if not text then
			letterIndex = letterIndex % #LETTERS + 1
			text = string.sub(LETTERS, letterIndex, letterIndex)
		end
		capIndex = capIndex % #def.CapColors + 1
		local capColor = def.CapColors[capIndex]
		if wide then
			capColor = def.CapColors[1]
		end
		return makeKey(folder, name, Vector3.new(centerX, centerY, laneZ), length, text :: string, capColor, def.BaseColor)
	end

	local startKey = place("Start", course.StartLength, 0, "START", true)
	startKey:SetAttribute("StageIndex", index)
	startPositions[index] = Vector3.new(course.OriginX + course.StartLength / 2, course.Y + 5, laneZ)

	for _, island in def.Islands do
		for keyNumber = 1, island.Keys do
			local gapBefore = if keyNumber == 1 then island.Gap else course.KeyGap
			place("Key", course.KeySize, gapBefore, nil, false):SetAttribute("StageIndex", index)
		end
	end

	-- 끝 키: 3단계에서 클리어 버튼이 이 위에 놓인다
	local endKey = place("End", course.EndLength, def.EndGap, "SPACE", true)
	endKey:SetAttribute("StageIndex", index)
	endKey:SetAttribute("StageEnd", true)
end

local function teleportTo(player: Player, position: Vector3)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character and root and root:IsA("BasePart") then
		character:PivotTo(CFrame.new(position))
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local function buildPortal(index: number, def: Config.StageDef)
	local lobby = Config.Lobby
	local pad = Instance.new("Part")
	pad.Name = "Portal" .. index
	pad.Anchored = true
	pad.Size = Vector3.new(12, 1, 12)
	pad.Position = Vector3.new(lobby.PortalX, 0.5, (index - 2) * lobby.PortalSpacing)
	pad.Color = def.CapColors[1]
	pad.Material = Enum.Material.Neon
	pad.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Adornee = pad
	gui.Size = UDim2.fromOffset(260, 90)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.MaxDistance = 150
	gui.Parent = pad

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 48)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = string.format("%s\n권장 속도 %s", def.Name, NumberFormat.format(def.RecommendedSpeed))
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label

	local cooldown: { [Player]: number } = {}
	pad.Touched:Connect(function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if not player then
			return
		end
		local now = os.clock()
		if cooldown[player] and now < cooldown[player] then
			return
		end
		cooldown[player] = now + 1
		currentStage[player] = index
		teleportTo(player, startPositions[index])
	end)
end

for index, def in Config.Stages do
	buildStage(index, def)
	buildPortal(index, def)
end

local function trackPlayer(player: Player)
	-- 죽거나 리셋하면 로비에서 다시 시작하므로 스테이지 정보를 지운다
	player.CharacterAdded:Connect(function()
		currentStage[player] = nil
	end)
end

Players.PlayerAdded:Connect(trackPlayer)
for _, player in Players:GetPlayers() do
	trackPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	currentStage[player] = nil
end)

-- 낙하: 길보다 FallBelow 아래로 내려가면 해당 스테이지 시작 키로 되돌린다 (속도 수치는 그대로)
while true do
	task.wait(0.2)
	for player, index in currentStage do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and root.Position.Y < course.Y - course.FallBelow then
			teleportTo(player, startPositions[index])
		end
	end
end
