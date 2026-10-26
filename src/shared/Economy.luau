--!strict
-- 서버(검증)와 클라이언트(표시)가 같이 쓰는 순수 계산 함수.
local Config = require(script.Parent.Config)

local Economy = {}

-- 총 배율 = 1 + 보유 물고기 배율의 합
function Economy.totalMultiplier(fish: { [string]: number }): number
	local total = 1
	for id, count in fish do
		local def = Config.Fish[id]
		if def then
			total += def.Multiplier * count
		end
	end
	return total
end

-- 속도 수치에서 실제 이동 속도를 구한다 (로그 곡선, 상한 있음)
function Economy.walkSpeed(speed: number): number
	local w = Config.WalkSpeed
	return math.min(w.Base + w.PerDecade * math.log10(1 + math.max(speed, 0)), w.Max)
end

return Economy
