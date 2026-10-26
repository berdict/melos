--!strict
-- 플레이어 세션 데이터 (메모리). DataStore 저장은 5단계에서 추가한다.

export type Data = {
	speed: number, -- 화면에 표시되는 성장 수치
	coins: number,
	fish: { [string]: number }, -- 물고기 id -> 보유 수
}

local sessions: { [Player]: Data } = {}
local dirty: { [Player]: boolean } = {}

local PlayerData = {}

function PlayerData.create(player: Player): Data
	local data: Data = {
		speed = 0,
		coins = 0,
		fish = {},
	}
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

function PlayerData.release(player: Player)
	sessions[player] = nil
	dirty[player] = nil
end

return PlayerData
