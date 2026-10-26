--!strict
-- 플레이어 데이터 생성과 클라이언트로의 상태 전송. 계산은 전부 서버에서 한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerData = require(script.Parent:WaitForChild("PlayerData") :: ModuleScript)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

-- 클라이언트 UI가 준비되면 현재 상태를 한 번 보내 달라고 요청한다
local readyEvent = Instance.new("RemoteEvent")
readyEvent.Name = "Ready"
readyEvent.Parent = remotes

local function pushState(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	stateEvent:FireClient(player, {
		speed = data.speed,
		coins = data.coins,
	})
end

readyEvent.OnServerEvent:Connect(function(player)
	PlayerData.markDirty(player)
end)

local function onJoin(player: Player)
	PlayerData.create(player)
	PlayerData.markDirty(player)
end

Players.PlayerAdded:Connect(onJoin)
for _, player in Players:GetPlayers() do
	onJoin(player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.release(player)
end)

-- 변경된 플레이어에게만 0.1초 간격으로 전송
local flushTimer = 0
RunService.Heartbeat:Connect(function(dt)
	flushTimer += dt
	if flushTimer < 0.1 then
		return
	end
	flushTimer = 0
	for _, player in PlayerData.takeDirty() do
		if player.Parent then
			pushState(player)
		end
	end
end)

print("[Main] 준비 완료")
