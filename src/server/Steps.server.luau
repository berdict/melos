--!strict
-- 걸음 감지: 서버가 직접 잰 이동으로만 걸음을 인정하고, 걸음마다 속도 수치를 올린다.
--   속도 수치 += 1 × 총 배율
-- WalkSpeed는 속도 수치와 별개로 완만한 곡선(Economy.walkSpeed)으로 올린다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Economy = require(Shared:WaitForChild("Economy") :: ModuleScript)
local PlayerData = require(script.Parent:WaitForChild("PlayerData") :: ModuleScript)

local TICK = 0.1

type Tracker = {
	lastPos: Vector3?,
	elapsed: number, -- 이동 중에 쌓인 시간. Interval이 차면 1걸음
}

local trackers: { [Player]: Tracker } = {}

local function track(player: Player)
	trackers[player] = { lastPos = nil, elapsed = 0 }
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

		-- 이동 속도 (리스폰 직후에도 여기서 맞춰진다)
		local walkSpeed = Economy.walkSpeed(data.speed)
		if humanoid.WalkSpeed ~= walkSpeed then
			humanoid.WalkSpeed = walkSpeed
		end

		local position = root.Position
		local lastPos = tracker.lastPos
		tracker.lastPos = position
		if not lastPos then
			continue
		end

		-- 키를 누른 채 벽에 막혀 있는 경우나 순간이동은 걸음으로 치지 않는다
		local moved = Vector3.new(position.X - lastPos.X, 0, position.Z - lastPos.Z).Magnitude
		local expected = walkSpeed * dt
		local plausibleMax = (walkSpeed * 1.5 + 10) * dt
		local isWalking = humanoid.MoveDirection.Magnitude > 0
			and moved >= expected * Config.Steps.MinMoveRatio
			and moved <= plausibleMax

		if isWalking then
			tracker.elapsed += dt
			local steps = math.floor(tracker.elapsed / Config.Steps.Interval)
			if steps > 0 then
				tracker.elapsed -= steps * Config.Steps.Interval
				data.speed += steps * Economy.totalMultiplier(data.fish)
				PlayerData.markDirty(player)
			end
		end
	end
end
