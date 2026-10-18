--!strict
-- 모든 밸런스 수치는 여기서만 조정한다. 코랄 수치는 자리표시용(placeholder)이다.

export type CoralDef = {
	Name: string,
	BaseCost: number,
	BaseProd: number,
}

local Config = {
	AutosaveInterval = 60,
	OfflineCapSeconds = 3 * 60 * 60, -- 방치 수익 상한 3시간
	MaxFish = 150,

	Stone = {
		BaseCost = 10,
		CostGrowth = 1.07, -- 레벨당 비용 +7%
		DoubleEvery = 25, -- 25레벨마다 걸음당 생명력 2배
	},

	Coral = {
		CostGrowth = 1.07,
		DoubleEvery = 25,
	},

	FishBaseCost = 50,

	Speed = {
		StudsPerStep = 3, -- 이 거리를 달리면 1걸음
		SpeedPerStep = 1, -- 걸음당 +1 Speed
		LifeBonusPerSpeed = 0.001, -- Speed 1당 생명력 +0.1% (빨라지면 걸음 수도 늘어나므로 작게)
		WalkSpeedBase = 16,
		WalkSpeedPerSpeed = 0.02,
		WalkSpeedMax = 80,
	},

	Escape = {
		DefaultGems = 25,
		GoalCooldown = 5,
	},

	Corals = {
		{ Name = "연약한 가지산호", BaseCost = 100, BaseProd = 1 },
		{ Name = "싱그러운 해초", BaseCost = 2000, BaseProd = 12 },
		{ Name = "붉은 부채산호", BaseCost = 4e4, BaseProd = 150 },
		{ Name = "신비의 불가사리", BaseCost = 8e5, BaseProd = 1800 },
		{ Name = "새하얀 말미잘", BaseCost = 1.6e7, BaseProd = 22000 },
		{ Name = "진주빛 말미잘", BaseCost = 3.2e8, BaseProd = 2.7e5 },
		{ Name = "푸른 버섯돌산호", BaseCost = 6.4e9, BaseProd = 3.3e6 },
		{ Name = "진홍 나팔돌산호", BaseCost = 1.28e11, BaseProd = 4e7 },
	} :: { CoralDef },
}

return Config
