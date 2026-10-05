# Japanese Handwriting - 프로젝트 구조 명세서

Flutter 기반의 일본어 필기 연습 앱입니다.

## 현재 구현 기능

- 히라가나 / 가타카나 기본 문자 연습
- 탁음 연습
- 반탁음 연습
- 요음 연습
- 순차 / 랜덤 진행
- 연습 기록 이동
- 일본어 문자 표시 ON/OFF
- 필기 가이드 ON/OFF
- 글자 선택창
- 직접 필기 및 지우기
- 이전 / 다음 문자 이동
- 휴대폰 화면 높이에 따른 문자 메뉴 크기 대응

## 디렉토리 구조

japanese_handwriting/
├── assets/
│   └── fonts/
├── lib/
│   ├── data/
│   │   └── kana_data.dart
│   ├── models/
│   │   └── kana.dart
│   ├── painters/
│   │   └── drawing_painter.dart
│   ├── screens/
│   │   ├── menu_screen.dart
│   │   ├── practice_menu_screen.dart
│   │   └── practice_screen.dart
│   ├── widgets/
│   │   ├── bottom_controls.dart
│   │   ├── character_card.dart
│   │   ├── drawing_canvas.dart
│   │   └── mode_controls.dart
│   └── main.dart
├── test/
├── pubspec.yaml
└── analysis_options.yaml

## 주요 파일

### main.dart
앱 진입점과 Material 3 테마를 설정합니다.
Nixgon을 기본 UI 폰트로 사용하며 일본어 문자에는 KleeOne을 사용합니다.

### data/kana_data.dart
연습에 사용하는 가나 데이터를 보관합니다.

현재 데이터:
- 히라가나 기본 46자
- 가타카나 기본 46자
- 히라가나/가타카나 탁음 각 20자
- 히라가나/가타카나 반탁음 각 5자
- 히라가나/가타카나 요음 각 33자

### models/kana.dart
가나 한 글자의 데이터 구조입니다.

필드:
- character: 일본어 문자
- korean: 한국어 발음 표기
- romaji: 로마자 표기

### screens/menu_screen.dart
앱의 메인 메뉴입니다.
현재 문자 연습 메뉴가 활성화되어 있으며 향후 다른 학습 기능을 추가할 수 있습니다.

### screens/practice_menu_screen.dart
연습 종류를 선택하는 화면입니다.

분류:
- 기본 문자
- 탁음
- 반탁음
- 요음

각 분류에서 히라가나와 가타카나를 선택할 수 있습니다.

### screens/practice_screen.dart
실제 필기 연습의 핵심 화면입니다.

기능:
- 순차 / 랜덤 진행
- 기록 이동
- 글자 선택
- 문자 표시 ON/OFF
- 필기 가이드 ON/OFF
- 이전 / 다음
- 필기 내용 지우기

### widgets/character_card.dart
현재 연습할 문자와 한국어 발음을 표시합니다.
요음과 같이 두 글자로 이루어진 문자도 크기를 조절하여 표시합니다.

### widgets/drawing_canvas.dart
노트 형태의 필기 영역입니다.
가이드 문자를 표시하고 사용자의 드래그 입력을 받습니다.

### painters/drawing_painter.dart
사용자가 입력한 좌표를 선으로 그립니다.

### widgets/mode_controls.dart
순차/랜덤, 기록, 문자 표시, 가이드 표시를 제어합니다.

### widgets/bottom_controls.dart
현재 문자 번호를 표시하고 이전, 지우기, 다음 기능을 제공합니다.

## 현재 데이터 흐름

kana_data.dart
    ↓
Kana
    ↓
PracticeScreen
    ↓
CharacterCard / DrawingCanvas / Controls

사용자의 필기 좌표는 PracticeScreen에서 관리되고,
DrawingCanvas를 거쳐 DrawingPainter가 화면에 렌더링합니다.