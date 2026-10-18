--!strict
-- 어비스리움식 성장(업그레이드/물고기/산호) 처리. 생명력 획득은 걸음마다 Escape.server.luau가 한다.
-- 모든 수치 검증은 서버에서 한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Economy = require(Shared:WaitForChild("Economy") :: ModuleScript)
local PlayerData = require(script.Parent:WaitForChild("PlayerData") :: ModuleScript)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local actionEvent = Instance.new("RemoteEvent")
actionEvent.Name = "Action"
actionEvent.Parent = remotes

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

local ALLOWED_STONE_STEPS = { [1] = true, [10] = true, [25] = true }

local function snapshot(data: PlayerData.Data)
	local corals = {}
	for index, def in Config.Corals do
		local level = data.corals[index]
		table.insert(corals, {
			name = def.Name,
			level = level,
			cost = Economy.coralCost(index, level),
			prod = Economy.coralProd(index, level),
			unlocked = index == 1 or data.corals[index - 1] >= 1,
		})
	end
	return {
		life = data.life,
		gems = data.gems,
		pearls = data.pearls,
		stoneLevel = data.stoneLevel,
		fishCount = data.fishCount,
		speed = data.speed,
		clears = data.clears,
		stepValue = Economy.stepValue(data.stoneLevel, data.fishCount, data.speed),
		passive = Economy.passivePerSecond(data.corals, data.fishCount, data.speed),
		stoneCost1 = Economy.stoneCostMany(data.stoneLevel, 1),
		stoneCost25 = Economy.stoneCostMany(data.stoneLevel, 25),
		fishCost = Economy.fishCost(data.fishCount),
		maxFish = Config.MaxFish,
		corals = corals,
	}
end

local function pushState(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	stateEvent:FireClient(player, snapshot(data))

	local stats = player:FindFirstChild("leaderstats")
	local speedValue = stats and stats:FindFirstChild("Speed")
	if speedValue and speedValue:IsA("IntValue") then
		speedValue.Value = math.floor(data.speed)
	end
end

actionEvent.OnServerEvent:Connect(function(player: Player, action: unknown, arg: unknown)
	local data = PlayerData.get(player)
	if not data or type(action) ~= "string" then
		return
	end

	if action == "UpgradeStone" then
		if type(arg) ~= "number" or not ALLOWED_STONE_STEPS[arg] then
			return
		end
		local cost = Economy.stoneCostMany(data.stoneLevel, arg)
		if data.life < cost then
			return
		end
		data.life -= cost
		data.stoneLevel += arg
	elseif action == "CreateFish" then
		if data.fishCount >= Config.MaxFish then
			return
		end
		local cost = Economy.fishCost(data.fishCount)
		if data.life < cost then
			return
		end
		data.life -= cost
		data.fishCount += 1
	elseif action == "BuyCoral" then
		if type(arg) ~= "number" or arg % 1 ~= 0 or not Config.Corals[arg] then
			return
		end
		if arg > 1 and data.corals[arg - 1] < 1 then
			return
		end
		local cost = Economy.coralCost(arg, data.corals[arg])
		if data.life < cost then
			return
		end
		data.life -= cost
		data.corals[arg] += 1
	else
		return
	end

	PlayerData.markDirty(player)
end)

local function onJoin(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local speedValue = Instance.new("IntValue")
	speedValue.Name = "Speed"
	speedValue.Parent = stats
	stats.Parent = player

	local data = PlayerData.load(player)

	-- 접속하지 않은 동안 산호가 모은 생명력 (최대 3시간)
	if data.lastSeen > 0 then
		local elapsed = math.clamp(os.time() - data.lastSeen, 0, Config.OfflineCapSeconds)
		data.life += Economy.passivePerSecond(data.corals, data.fishCount, data.speed) * elapsed
	end

	PlayerData.markDirty(player)
end

Players.PlayerAdded:Connect(onJoin)
for _, player in Players:GetPlayers() do
	task.spawn(onJoin, player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.save(player)
	PlayerData.release(player)
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerData.save(player)
	end
end)

-- 산호 방치 수익: 초당 1회 지급
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local data = PlayerData.get(player)
			if data then
				data.life += Economy.passivePerSecond(data.corals, data.fishCount, data.speed)
				PlayerData.markDirty(player)
			end
		end
	end
end)

-- 변경된 플레이어에게만 0.1초 간격으로 상태 전송
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

task.spawn(function()
	while true do
		task.wait(Config.AutosaveInterval)
		for _, player in Players:GetPlayers() do
			PlayerData.save(player)
		end
	end
end)
