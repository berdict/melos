--!strict
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config") :: ModuleScript)

export type Data = {
	life: number,
	gems: number,
	pearls: number,
	stoneLevel: number,
	fishCount: number,
	corals: { number },
	speed: number,
	clears: number,
	lastSeen: number,
}

local store = DataStoreService:GetDataStore("AquaEscapeV1")

local sessions: { [Player]: Data } = {}
local readOnly: { [Player]: boolean } = {} -- 로드 실패 시 빈 데이터로 덮어쓰지 않기 위함
local dirty: { [Player]: boolean } = {}

local PlayerData = {}

local function num(value: any, fallback: number): number
	if type(value) == "number" and value == value then
		return value
	end
	return fallback
end

local function default(): Data
	local corals = {}
	for _ = 1, #Config.Corals do
		table.insert(corals, 0)
	end
	return {
		life = 0,
		gems = 0,
		pearls = 0,
		stoneLevel = 1,
		fishCount = 0,
		corals = corals,
		speed = 0,
		clears = 0,
		lastSeen = 0,
	}
end

local function reconcile(saved: any): Data
	local data = default()
	if type(saved) ~= "table" then
		return data
	end
	data.life = num(saved.life, 0)
	data.gems = num(saved.gems, 0)
	data.pearls = num(saved.pearls, 0)
	data.stoneLevel = math.max(1, num(saved.stoneLevel, 1))
	data.fishCount = num(saved.fishCount, 0)
	data.speed = num(saved.speed, 0)
	data.clears = num(saved.clears, 0)
	data.lastSeen = num(saved.lastSeen, 0)
	if type(saved.corals) == "table" then
		for index = 1, #data.corals do
			data.corals[index] = num(saved.corals[index], 0)
		end
	end
	return data
end

function PlayerData.load(player: Player): Data
	local ok, result = pcall(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if not ok then
		warn(`[PlayerData] load failed for {player.Name}: {result}`)
		readOnly[player] = true
	end
	local data = reconcile(if ok then result else nil)
	sessions[player] = data
	return data
end

function PlayerData.get(player: Player): Data?
	return sessions[player]
end

function PlayerData.markDirty(player: Player)
	dirty[player] = true
end

-- 변경된 플레이어 목록을 가져오고 비운다
function PlayerData.takeDirty(): { Player }
	local list = {}
	for player in dirty do
		table.insert(list, player)
	end
	table.clear(dirty)
	return list
end

function PlayerData.save(player: Player)
	local data = sessions[player]
	if not data or readOnly[player] then
		return
	end
	data.lastSeen = os.time()
	local ok, err = pcall(function()
		store:SetAsync(tostring(player.UserId), data)
	end)
	if not ok then
		warn(`[PlayerData] save failed for {player.Name}: {err}`)
	end
end

function PlayerData.release(player: Player)
	sessions[player] = nil
	readOnly[player] = nil
	dirty[player] = nil
end

return PlayerData
