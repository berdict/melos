# 달리기 키우기 (가칭)

달리면서 속도 수치를 쌓고, 스테이지를 클리어해 코인을 벌고, 어항의 물고기로 배율을 올리는 Roblox 키우기 게임.
기획은 [docs/기획서-1호.md](docs/기획서-1호.md)가 기준이다.

## 실행

1. [Rojo](https://rojo.space) 설치 후 `rojo plugin install`
2. 이 폴더에서 `rojo serve`
3. Roblox Studio에서 Baseplate를 열고 Plugins > Rojo > Connect
4. Play

## 구조

```
src/shared   Config(수치), Economy(계산), NumberFormat(K/M/B/T 표기)
src/server   PlayerData, Main(상태 전송), Steps(걸음/WalkSpeed), Stages(키보드 길/입구/낙하)
src/client   HUD, Keys(키 눌림 연출과 소리)
```

임시 수치는 `src/shared/Config.luau`에서만 조정한다.
