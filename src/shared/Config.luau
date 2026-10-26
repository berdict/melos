--!strict
-- 모든 임시 수치는 여기서만 조정한다. 플레이하면서 맞춘다.

export type FishDef = {
	Multiplier: number,
}

local Config = {
	Steps = {
		Interval = 0.3, -- 이동 중일 때 이 간격(초)마다 1걸음
		MinMoveRatio = 0.4, -- 기대 이동거리의 이 비율 이상 실제로 움직여야 걸음으로 인정
	},

	-- 속도 수치 -> 실제 이동 속도(WalkSpeed). 속도 수치를 그대로 넣지 않는다.
	WalkSpeed = {
		Base = 16,
		PerDecade = 4, -- 속도 수치가 10배가 될 때마다 +4
		Max = 50,
	},

	-- 물고기 정의는 4단계에서 채운다. 키는 물고기 id.
	Fish = {} :: { [string]: FishDef },
}

return Config
