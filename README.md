# Japanese Handwriting

Flutter로 제작 중인 일본어 필기 연습 앱입니다.

히라가나와 가타카나를 화면에서 직접 따라 쓰면서 연습할 수 있도록 제작하고 있습니다.

현재는 가나 문자 연습 기능을 중심으로 구현되어 있으며,
향후 일본 교육과정을 기준으로 한 한자 학습 기능 등을 추가할 예정입니다.

---

## 현재 구현 기능

### 가나 문자 연습

- 히라가나 기본 문자 46자
- 가타카나 기본 문자 46자
- 탁음 각 20자
- 반탁음 각 5자
- 요음 각 33자

지원하는 연습 분류:

- 기본 문자
- 탁음
- 반탁음
- 요음

---

## 필기 연습 기능

- 화면에 직접 글자 쓰기
- 필기 내용 지우기
- 이전 / 다음 문자 이동
- 현재 문자 번호 표시
- 글자 선택창
- 순차 진행
- 랜덤 진행
- 연습 기록 이동
- 일본어 문자 표시 ON/OFF
- 필기 가이드 ON/OFF

요음처럼 두 글자로 구성된 문자도
카드, 필기 가이드, 글자 선택창에서 정상적으로 표시되도록 대응되어 있습니다.

---

## UI

앱은 Material 3를 기반으로 제작되었습니다.

전체적으로 종이와 노트를 연상시키는 따뜻한 색상의 UI를 사용하며,
필기 영역에는 노트 줄, 종이 질감, 왼쪽 여백선과 스프링 표현이 적용되어 있습니다.

### 사용 폰트

- 일반 UI: Nixgon
- 일본어 문자: KleeOne

일부 화면은 휴대폰 높이에 따라 카드 크기와 문자 크기가 자동으로 조절됩니다.

---

## 프로젝트 구조

```text
lib/
├── data/
│   └── kana_data.dart
├── models/
│   └── kana.dart
├── painters/
│   └── drawing_painter.dart
├── screens/
│   ├── menu_screen.dart
│   ├── practice_menu_screen.dart
│   └── practice_screen.dart
├── widgets/
│   ├── bottom_controls.dart
│   ├── character_card.dart
│   ├── drawing_canvas.dart
│   └── mode_controls.dart
└── main.dart
```

자세한 구조와 각 파일의 역할은 `PROJECT_STRUCTURE.md`를 참고합니다.

---

## 데이터 구조

현재 가나 데이터는 `Kana` 모델을 사용합니다.

```dart
class Kana {
  final String character;
  final String korean;
  final String romaji;
}
```

각 문자는 다음 정보를 가지고 있습니다.

- 일본어 문자
- 한국어 발음 표기
- 로마자 표기

현재 문자 데이터는 앱 내부의 정적 데이터로 관리됩니다.

---

## 실행

Flutter 개발 환경이 준비되어 있는 상태에서 프로젝트 루트에서 실행합니다.

```bash
flutter pub get
flutter run
```

Android APK 빌드:

```bash
flutter build apk --release
```

아키텍처별 APK 빌드:

```bash
flutter build apk --release --split-per-abi
```

Play Store 배포용 App Bundle:

```bash
flutter build appbundle --release
```

---

## 개발 상태

현재 가나 필기 연습 기능은 기본적인 구현과 실기기 테스트가 완료된 상태입니다.

다음 주요 개발 후보:

- 상용한자 필기 연습
- 일본 교육과정 기준 학년별 한자 분류
- 한자 획순 표시
- 학습 진행도 저장
- 추가 학습 기능

---

## 기술

- Flutter
- Dart
- Material 3
- CustomPainter
- GestureDetector
