--!strict
-- 모든 임시 수치는 여기서만 조정한다. 플레이하면서 맞춘다.

export type FishDef = {
	Multiplier: number,
}

export type IslandDef = {
	Gap: number, -- 앞 요소(시작 키/이전 섬)와의 틈 거리(스터드, 가장자리 사이)
	Keys: number, -- 섬을 이루는 키 개수
}

export type StageDef = {
	Name: string,
	RecommendedSpeed: number, -- 입구 표지판에 표시되는 권장 속도 수치
	BaseColor: Color3,
	CapColors: { Color3 },
	Islands: { IslandDef },
	EndGap: number, -- 마지막 섬과 끝 키 사이 틈
}

local Config = {
	Steps = {
		Interval = 0.3, -- 이동 중일 때 이 간격(초)마다 1걸음
		MinMoveRatio = 0.4, -- 기대 이동거리의 이 비율 이상 실제로 움직여야 걸음으로 인정
		GroundRayLength = 7, -- 발밑 레이 길이. 이 안에 "Key" 태그 파트가 있어야 걸음으로 인정
	},

	Jump = {
		Height = 7.2, -- 틈 설계의 기준이 되는 점프 높이 (Roblox 기본값)
	},

	-- 속도 수치 -> 실제 이동 속도(WalkSpeed). 속도 수치를 그대로 넣지 않는다.
	WalkSpeed = {
		Base = 16,
		PerDecade = 4, -- 속도 수치가 10배가 될 때마다 +4
		Max = 50,
	},

	-- 물고기 정의는 4단계에서 채운다. 키는 물고기 id.
	Fish = {} :: { [string]: FishDef },

	-- 로비(지상)의 입구 패드. 밟으면 해당 스테이지 시작 키로 이동한다.
	Lobby = {
		PortalX = 30,
		PortalSpacing = 30,
	},

	-- 스테이지는 하늘(Y)에 만든다. 틈에서 떨어지면 시작 키로 돌아온다.
	Course = {
		Y = 200,
		OriginX = 0,
		LaneSpacing = 60,
		KeySize = 6, -- 키 한 변 (모바일을 위해 넉넉하게)
		KeyGap = 0.4, -- 같은 섬 안 키 사이 간격
		KeyHeight = 1.0,
		CapHeight = 0.35,
		StartLength = 12,
		EndLength = 14,
		FallBelow = 25, -- 길보다 이만큼 아래로 내려가면 낙하로 판정
	},

	-- 틈 설계 기준(추정): 점프로 건너는 거리 ≈ WalkSpeed × 0.54 + 약 1
	-- WalkSpeed 16 -> 약 9.7 / 24 -> 약 14 / 30 -> 약 17. 플레이하면서 조정한다.
	Stages = {
		{
			Name = "스테이지 1",
			RecommendedSpeed = 0,
			BaseColor = Color3.fromRGB(92, 52, 40),
			CapColors = { Color3.fromRGB(255, 170, 200), Color3.fromRGB(255, 240, 225) },
			Islands = {
				{ Gap = 3, Keys = 4 },
				{ Gap = 4, Keys = 3 },
				{ Gap = 3, Keys = 4 },
				{ Gap = 5, Keys = 3 },
				{ Gap = 4, Keys = 5 },
				{ Gap = 5, Keys = 3 },
			},
			EndGap = 4,
		},
		{
			Name = "스테이지 2",
			RecommendedSpeed = 100,
			BaseColor = Color3.fromRGB(60, 36, 30),
			CapColors = { Color3.fromRGB(150, 230, 200), Color3.fromRGB(130, 85, 60) },
			Islands = {
				{ Gap = 7, Keys = 3 },
				{ Gap = 8, Keys = 3 },
				{ Gap = 9, Keys = 3 },
				{ Gap = 8.5, Keys = 3 },
				{ Gap = 9.5, Keys = 3 },
				{ Gap = 10, Keys = 3 },
				{ Gap = 9, Keys = 3 },
			},
			EndGap = 10,
		},
		{
			Name = "스테이지 3",
			RecommendedSpeed = 3000,
			BaseColor = Color3.fromRGB(40, 24, 20),
			CapColors = { Color3.fromRGB(230, 160, 70), Color3.fromRGB(255, 225, 150) },
			Islands = {
				{ Gap = 11, Keys = 3 },
				{ Gap = 12, Keys = 3 },
				{ Gap = 13, Keys = 3 },
				{ Gap = 12, Keys = 3 },
				{ Gap = 13.5, Keys = 3 },
				{ Gap = 14, Keys = 3 },
				{ Gap = 13, Keys = 3 },
			},
			EndGap = 14,
		},
	} :: { StageDef },

	-- 키 소리. 지금은 Roblox 내장음(임시)이다. 직접 만든 소리를 올린 뒤
	-- "rbxassetid://숫자"로 바꾸면 된다. 빈 문자열이면 그 소리는 재생하지 않는다.
	Sounds = {
		Press = "rbxasset://sounds/switch.wav",
		PressVolume = 0.6,
		Release = "rbxasset://sounds/switch.wav",
		ReleaseVolume = 0.18,
		ReleasePitch = 1.5,
		PitchJitter = 0.08, -- 매번 음높이를 이만큼 랜덤하게 흔들어 기계적인 느낌을 줄인다
	},
}

return Config
