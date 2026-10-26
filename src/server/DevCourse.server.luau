--!nonstrict
-- 개발용: 맵에 EscapeZone 태그 파트가 하나도 없을 때만 시험 코스를 자동으로 만든다.
-- 실제 맵을 만들어 태그를 붙이면 이 스크립트는 아무것도 하지 않는다.
local CollectionService = game:GetService("CollectionService")

if #CollectionService:GetTagged("EscapeZone") > 0 then
	return
end

local course = Instance.new("Folder")
course.Name = "DevCourse"
course.Parent = workspace

local function makePart(name: string, size: Vector3, position: Vector3, color: Color3, tag: string?)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = course
	if tag then
		CollectionService:AddTag(part, tag)
	end
	return part
end

-- 걸음이 집계되는 영역 (보이지 않음). 시작 지점 근처부터 골 너머까지 덮는다.
local zone = makePart("Zone", Vector3.new(230, 40, 24), Vector3.new(95, 20, 0), Color3.new(1, 1, 1), "EscapeZone")
zone.Transparency = 1
zone.CanCollide = false
zone.CanTouch = false
zone.CanQuery = false

-- 시작 지점 + 직선 길
makePart("Start", Vector3.new(12, 1, 12), Vector3.new(24, 0.5, 0), Color3.fromRGB(90, 200, 120), "EscapeSpawn")
makePart("Walkway", Vector3.new(160, 1, 12), Vector3.new(110, 0.5, 0), Color3.fromRGB(240, 190, 220))

-- 길 절반만 막는 위험 파트 (반대쪽으로 피해 갈 수 있다)
makePart("Kill1", Vector3.new(4, 0.4, 6), Vector3.new(80, 1.2, 3), Color3.fromRGB(220, 50, 50), "KillBrick")
makePart("Kill2", Vector3.new(4, 0.4, 6), Vector3.new(140, 1.2, -3), Color3.fromRGB(220, 50, 50), "KillBrick")

-- 골
local goal = makePart("Goal", Vector3.new(6, 1, 12), Vector3.new(193, 0.5, 0), Color3.fromRGB(255, 210, 60), "EscapeGoal")
goal:SetAttribute("Gems", 25)

print("[DevCourse] 시험 코스를 만들었습니다. 출발 지점은 X=24, 골은 X=193 입니다.")
