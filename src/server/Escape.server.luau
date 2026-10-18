--!strict
-- Keyboard Escape식 시스템: 구역 안에서 걸으면 걸음마다 +1 Speed와 생명력을 얻는다 (걷기가 곧 클릭).
-- 맵 파트는 CollectionService 태그로 지정한다:
--   EscapeZone  : 걸음이 집계되는 영역 (투명 파트로 키보드 코스 전체를 덮는다)
--   KillBrick   : 닿으면 시작점으로 복귀 (Speed는 유지)
--   EscapeGoal  : 닿으면 보상 지급 후 시작점으로 복귀. Attribute "Gems"로 보상 조절
--   EscapeSpawn : 복귀 위치 (첫 번째 파트 사용)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Economy = require(Shared:WaitForChild("Economy") :: ModuleScript)
local PlayerData = require(script.Parent:WaitForChild("PlayerData") :: ModuleScript)

local ZONE_TAG = "EscapeZone"
local KILL_TAG = "KillBrick"
local GOAL_TAG = "EscapeGoal"
local SPAWN_TAG = "EscapeSpawn"
local TICK = 0.1

type Tracker = {
	lastPos: Vector3?,
	carry: number, -- 아직 1걸음이 안 된 누적 거리
	goalReadyAt: number,
}

local trackers: { [Player]: Tracker } = {}

local function insidePart(part: BasePart, position: Vector3): boolean
	local localPos = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z
end

local function inAnyZone(position: Vector3): boolean
	for _, instance in CollectionService:GetTagged(ZONE_TAG) do
		if instance:IsA("BasePart") and insidePart(instance, position) then
			return true
		end
	end
	return false
end

local function sendToSpawn(player: Player)
	local spawnPart = CollectionService:GetTagged(SPAWN_TAG)[1]
	local character = player.Character
	if spawnPart and spawnPart:IsA("BasePart") and character then
		character:PivotTo(spawnPart.CFrame + Vector3.new(0, 5, 0))
	end
	local tracker = trackers[player]
	if tracker then
		tracker.lastPos = nil
		tracker.carry = 0
	end
end

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

local function bindKillBrick(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	instance.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player and trackers[player] then
			sendToSpawn(player)
		end
	end)
end

local function bindGoal(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	instance.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		local tracker = player and trackers[player]
		local data = player and PlayerData.get(player)
		if not player or not tracker or not data then
			return
		end
		local now = os.clock()
		if now < tracker.goalReadyAt then
			return
		end
		tracker.goalReadyAt = now + Config.Escape.GoalCooldown

		local reward = instance:GetAttribute("Gems")
		data.gems += if type(reward) == "number" then reward else Config.Escape.DefaultGems
		data.clears += 1
		PlayerData.markDirty(player)
		sendToSpawn(player)
	end)
end

for _, instance in CollectionService:GetTagged(KILL_TAG) do
	bindKillBrick(instance)
end
CollectionService:GetInstanceAddedSignal(KILL_TAG):Connect(bindKillBrick)

for _, instance in CollectionService:GetTagged(GOAL_TAG) do
	bindGoal(instance)
end
CollectionService:GetInstanceAddedSignal(GOAL_TAG):Connect(bindGoal)

local function track(player: Player)
	trackers[player] = { lastPos = nil, carry = 0, goalReadyAt = 0 }
end

Players.PlayerAdded:Connect(track)
for _, player in Players:GetPlayers() do
	track(player)
end
Players.PlayerRemoving:Connect(function(player)
	trackers[player] = nil
end)

while true do
	local dt = task.wait(TICK)
	for player, tracker in trackers do
		local data = PlayerData.get(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (data and root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
			tracker.lastPos = nil
			continue
		end

		-- Speed가 오를수록 이동 속도도 빨라진다 (리스폰 직후에도 여기서 맞춰진다)
		local targetWalkSpeed = math.min(
			Config.Speed.WalkSpeedBase + data.speed * Config.Speed.WalkSpeedPerSpeed,
			Config.Speed.WalkSpeedMax
		)
		if humanoid.WalkSpeed ~= targetWalkSpeed then
			humanoid.WalkSpeed = targetWalkSpeed
		end

		local position = root.Position
		local lastPos = tracker.lastPos
		tracker.lastPos = position

		if not inAnyZone(position) then
			tracker.carry = 0
			continue
		end

		if lastPos and humanoid.FloorMaterial ~= Enum.Material.Air then
			local horizontal = Vector3.new(position.X - lastPos.X, 0, position.Z - lastPos.Z).Magnitude
			-- 서버에서 잰 이동 거리만 인정. 순간이동성 이동은 걸음으로 치지 않는다.
			local plausible = (humanoid.WalkSpeed * 1.5 + 10) * dt
			if horizontal > 0 and horizontal <= plausible then
				tracker.carry += horizontal
				local steps = math.floor(tracker.carry / Config.Speed.StudsPerStep)
				if steps > 0 then
					tracker.carry -= steps * Config.Speed.StudsPerStep
					-- 걸음당 생명력은 지금 Speed 기준으로 계산하고, 그 뒤에 Speed를 올린다
					data.life += steps * Economy.stepValue(data.stoneLevel, data.fishCount, data.speed)
					data.speed += steps * Config.Speed.SpeedPerStep
					PlayerData.markDirty(player)
				end
			end
		end
	end
end
