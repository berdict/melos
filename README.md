# AquaEscape

탭으로 키우는 수족관 + 걸음마다 Speed가 오르는 키보드 탈출 코스를 합친 Roblox 게임. 설계는 [docs/DESIGN.md](docs/DESIGN.md) 참고.

## 실행

1. [Rojo](https://rojo.space) 설치
2. 이 폴더에서 `rojo serve` 실행 후 Roblox Studio의 Rojo 플러그인으로 연결
3. 맵에 `EscapeZone`, `KillBrick`, `EscapeGoal`, `EscapeSpawn` 태그를 단 파트를 배치 (DESIGN.md 5장)
4. DataStore 저장을 테스트하려면 Studio의 Game Settings > Security > Enable Studio Access to API Services 켜기

## 구조

```
src/shared   Config, Economy(순수 계산), NumberFormat
src/server   PlayerData(저장), Main(탭/업그레이드), Escape(Speed/구역)
src/client   UI
```

수치 조정은 `src/shared/Config.luau`에서만 한다.
