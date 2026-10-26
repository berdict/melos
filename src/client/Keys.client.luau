--!strict
-- 키보드 ASMR: 발밑의 키가 바뀔 때마다 캡이 눌리고 클릭음이 난다. 표시/소리 전용이다.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

local player = Players.LocalPlayer
local stagesFolder = workspace:WaitForChild("Stages")

local PRESS_DEPTH = 0.45
local pressInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local releaseInfo = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- 소리: 같은 Sound를 연속 재생하면 끊기므로 여러 개를 돌려 쓴다
type Pool = { sounds: { Sound }, index: number, volume: number }

local soundFolder = Instance.new("Folder")
soundFolder.Name = "KeySounds"
soundFolder.Parent = SoundService

local function makePool(soundId: string, volume: number): Pool?
	if soundId == "" then
		return nil
	end
	local sounds = {}
	for _ = 1, 8 do
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume
		sound.Parent = soundFolder
		table.insert(sounds, sound)
	end
	return { sounds = sounds, index = 0, volume = volume }
end

local sc = Config.Sounds
local pressPool = makePool(sc.Press, sc.PressVolume)
local releasePool = makePool(sc.Release, sc.ReleaseVolume)

local function play(pool: Pool?, pitch: number, volumeScale: number)
	if not pool then
		return
	end
	pool.index = pool.index % #pool.sounds + 1
	local sound = pool.sounds[pool.index]
	sound.PlaybackSpeed = pitch
	sound.Volume = pool.volume * volumeScale
	sound.TimePosition = 0
	sound:Play()
end

local function jitter(base: number): number
	return base * (1 + (math.random() * 2 - 1) * sc.PitchJitter)
end

-- 캡 눌림 연출 (로컬에서만 보인다)
local function moveCap(key: Instance, depth: number, info: TweenInfo)
	local cap = key:FindFirstChild("Cap")
	if not (cap and cap:IsA("BasePart")) then
		return
	end
	local restY = cap:GetAttribute("RestY")
	if type(restY) ~= "number" then
		return
	end
	TweenService:Create(cap, info, {
		Position = Vector3.new(cap.Position.X, restY - depth, cap.Position.Z),
	}):Play()
end

local lastPressAt = 0

local function pressKey(key: Instance, volumeScale: number)
	lastPressAt = os.clock()
	moveCap(key, PRESS_DEPTH, pressInfo)
	play(pressPool, jitter(1), volumeScale)
end

local function releaseKey(key: Instance)
	moveCap(key, 0, releaseInfo)
	play(releasePool, jitter(sc.ReleasePitch), 1)
end

-- 발밑 키 판정
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { stagesFolder }

local currentKey: Instance? = nil

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end

	local result = workspace:Raycast(root.Position, Vector3.new(0, -Config.Steps.GroundRayLength, 0), rayParams)
	local key: Instance? = nil
	if result and CollectionService:HasTag(result.Instance, "Key") then
		key = result.Instance
	end

	if key ~= currentKey then
		if currentKey then
			releaseKey(currentKey)
		end
		if key then
			pressKey(key, 1)
		end
		currentKey = key
	end
end)

-- 점프 후 같은 키에 착지하면 다시 한 번 눌린다 (다른 키 착지는 위에서 이미 처리됨)
local function bindCharacter(character: Model)
	currentKey = nil
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed and currentKey and os.clock() - lastPressAt > 0.12 then
			pressKey(currentKey, 1.25)
		end
	end)
end

if player.Character then
	task.spawn(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)
