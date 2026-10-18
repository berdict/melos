--!strict
-- 순수 계산 함수 모음. 서버(검증)와 클라이언트(표시) 양쪽에서 같은 식을 쓴다.
local Config = require(script.Parent.Config)

local Economy = {}

local fishCostCache: { [number]: number } = { [0] = Config.FishBaseCost }

-- n번째 창조 직후 다음 가격에 곱해지는 배율 (어비스리움 물고기 가격 증가율 표)
local function fishRatio(created: number): number
	if created <= 2 then
		return 5
	elseif created == 3 then
		return 53.24
	elseif created <= 9 then
		return 11
	elseif created <= 59 then
		return 7
	elseif created <= 69 then
		return 6
	elseif created <= 80 then
		return 5
	end
	return 3.5
end

local function doublings(level: number, every: number): number
	return 2 ^ math.floor(level / every)
end

-- 이미 `created`마리를 창조했을 때, 다음 1마리의 가격
function Economy.fishCost(created: number): number
	local cached = fishCostCache[created]
	if cached then
		return cached
	end
	local cost = Economy.fishCost(created - 1) * fishRatio(created)
	fishCostCache[created] = cost
	return cost
end

-- 산호석 level -> level+1 비용
function Economy.stoneCostOne(level: number): number
	return Config.Stone.BaseCost * Config.Stone.CostGrowth ^ (level - 1)
end

-- 산호석을 n레벨 올리는 총 비용 (등비수열 합)
function Economy.stoneCostMany(level: number, n: number): number
	local g = Config.Stone.CostGrowth
	return Economy.stoneCostOne(level) * (g ^ n - 1) / (g - 1)
end

-- Keyboard Escape 연동: Speed가 높을수록 모든 생명력 생산이 늘어난다
function Economy.speedMultiplier(speed: number): number
	return 1 + speed * Config.Speed.LifeBonusPerSpeed
end

-- 한 걸음당 생명력 (걷기가 곧 클릭이다)
function Economy.stepValue(stoneLevel: number, fishCount: number, speed: number): number
	return stoneLevel
		* doublings(stoneLevel, Config.Stone.DoubleEvery)
		* 2 ^ fishCount
		* Economy.speedMultiplier(speed)
end

-- level -> level+1 비용 (level 0이면 최초 구매 비용)
function Economy.coralCost(index: number, level: number): number
	return Config.Corals[index].BaseCost * Config.Coral.CostGrowth ^ level
end

function Economy.coralProd(index: number, level: number): number
	if level <= 0 then
		return 0
	end
	return Config.Corals[index].BaseProd * level * doublings(level, Config.Coral.DoubleEvery)
end

function Economy.passivePerSecond(corals: { number }, fishCount: number, speed: number): number
	local total = 0
	for index, level in corals do
		total += Economy.coralProd(index, level)
	end
	return total * 2 ^ fishCount * Economy.speedMultiplier(speed)
end

return Economy
