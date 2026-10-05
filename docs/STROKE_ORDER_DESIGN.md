# 획순 표시 및 판정 설계

## 목표

- 정답 글자의 획을 순서대로 표시한다.
- 사용자의 획수, 획순, 시작점, 방향을 단계적으로 비교한다.
- 문자 인식 결과와 획순 평가 결과를 서로 독립적으로 관리한다.

## 1. 획순 표시용 원본

획순 데이터의 원본 형식은 SVG로 관리한다.

```xml
<svg viewBox="0 0 1024 1024">
  <path id="stroke-1" d="..." />
  <path id="stroke-2" d="..." />
</svg>
```

규칙:

- `viewBox`는 모든 문자가 같은 좌표계를 사용한다.
- `path` 하나가 한 획을 의미한다.
- `stroke-1`, `stroke-2`처럼 획순이 명시되어야 한다.
- SVG의 장식, 글자, 배경은 제거하고 획 경로만 저장한다.

## 2. 앱에서 사용할 획순 데이터

SVG는 제작과 확인을 위한 원본으로 사용한다. 앱에서는 SVG를 미리 변환한 JSON 데이터를 읽는 방향을 권장한다.

```json
{
  "character": "あ",
  "viewBox": [0, 0, 1024, 1024],
  "strokes": [
    {
      "order": 1,
      "path": "...",
      "start": [120, 180],
      "end": [780, 190]
    }
  ]
}
```

이렇게 분리하면 런타임마다 SVG 구조를 해석하지 않아도 되고, 표시와 판정에서 같은 획 데이터를 재사용할 수 있다.

## 3. 획순 표시

Flutter의 `CustomPainter`에서 정답 획을 순서대로 그린다.

```text
StrokeOrderData
      ↓
Path 목록
      ↓
PathMetric으로 현재 길이만 추출
      ↓
CustomPainter로 애니메이션 표시
```

표시 모드:

- 전체 획순 미리보기
- 현재 획만 강조
- 1획부터 순차 애니메이션
- 사용자가 다음에 그려야 할 획의 시작점 표시

## 4. 판정 결과 구조

문자 정답과 획순 정답을 분리한다.

```dart
class HandwritingEvaluation {
  final bool characterCorrect;
  final StrokeOrderEvaluation strokeOrder;
}

class StrokeOrderEvaluation {
  final bool strokeCountCorrect;
  final bool orderCorrect;
  final List<StrokeEvaluation> strokes;
}

class StrokeEvaluation {
  final int expectedOrder;
  final bool startPointCorrect;
  final bool directionCorrect;
  final double shapeScore;
}
```

초기 버전에서는 모든 필드를 한 번에 구현하지 않는다.

```text
1단계: 획수 비교
2단계: 획별 시작점과 끝점 비교
3단계: 진행 방향 비교
4단계: 획 모양 유사도 비교
```

## 5. 사용자 획 비교 과정

화면 크기가 달라도 비교할 수 있도록 사용자 좌표와 정답 좌표를 같은 범위로 정규화한다.

```text
DrawingStroke
      ↓
불필요하게 가까운 점 제거
      ↓
일정한 개수의 점으로 재표본화
      ↓
0~1 좌표로 정규화
      ↓
정답 획과 시작점·방향·모양 비교
```

획 모양은 처음부터 완전 일치를 요구하지 않는다. 시작점 거리, 끝점 거리, 진행 방향, 표본점 평균 거리를 각각 점수화한 뒤 허용 범위를 적용한다.

## 6. 정오답 정책

추천 결과 정책:

```text
문자 인식 성공 + 획순 성공 → 정답
문자 인식 성공 + 획순 실패 → 정답, 획순 교정 안내
문자 인식 실패             → 오답
```

획순 집중 모드가 추가되면 두 조건을 모두 만족해야 정답으로 처리할 수 있다. 기본 문제 풀이에서는 획순을 보조 피드백으로 두는 편이 학습 흐름에 적합하다.

## 다음 구현 순서

1. 디버그 획수 표시로 `DrawingStroke` 생성 확인
2. `StrokeOrderData` 모델 정의
3. 샘플 문자 하나의 SVG와 변환 데이터 준비
4. 정답 획순 미리보기 Painter 구현
5. 획수 비교부터 판정 기능 시작
