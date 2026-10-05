import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as ml_kit;

import '../models/drawing_stroke.dart';
import 'handwriting_recognizer.dart';

/// Google ML Kit 일본어 Digital Ink 모델을 사용하는 실제 필기 인식기다.
class MlKitHandwritingRecognizer implements HandwritingRecognizer {
  static const String japaneseLanguageCode = 'ja';

  final String languageCode;
  final bool wifiOnly;
  final ml_kit.DigitalInkRecognizer _recognizer;
  final ml_kit.DigitalInkRecognizerModelManager _modelManager;

  Future<void>? _preparing;
  bool _isClosed = false;

  MlKitHandwritingRecognizer({
    this.languageCode = japaneseLanguageCode,
    this.wifiOnly = false,
  })  : _recognizer = ml_kit.DigitalInkRecognizer(
          languageCode: languageCode,
        ),
        _modelManager = ml_kit.DigitalInkRecognizerModelManager();

  @override
  Future<void> prepare() {
    _ensureOpen();
    return _preparing ??= _prepareModel().catchError((Object error) {
      _preparing = null;
      throw error;
    });
  }

  Future<void> _prepareModel() async {
    final downloaded = await _modelManager.isModelDownloaded(languageCode);
    if (downloaded) {
      return;
    }

    final succeeded = await _modelManager.downloadModel(
      languageCode,
      isWifiRequired: wifiOnly,
    );
    if (!succeeded) {
      throw StateError('$languageCode 필기 인식 모델을 다운로드하지 못했어.');
    }
  }

  @override
  Future<HandwritingRecognitionResult> recognize({
    required List<DrawingStroke> strokes,
  }) async {
    _ensureOpen();

    final drawableStrokes =
        strokes.where((stroke) => stroke.points.isNotEmpty).toList();
    if (drawableStrokes.isEmpty) {
      throw ArgumentError.value(strokes, 'strokes', '인식할 필기 획이 없어.');
    }

    await prepare();

    final ink = ml_kit.Ink()
      ..strokes = drawableStrokes.map((drawingStroke) {
        return ml_kit.Stroke()
          ..points = drawingStroke.points.map((point) {
            return ml_kit.StrokePoint(
              x: point.position.dx,
              y: point.position.dy,
              t: point.timestamp,
            );
          }).toList(growable: false);
      }).toList(growable: false);

    final candidates = await _recognizer.recognize(ink);
    return HandwritingRecognitionResult(
      candidates: candidates.map((candidate) {
        return HandwritingCandidate(
          text: candidate.text,
          score: candidate.score,
        );
      }),
    );
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    await _recognizer.close();
  }

  void _ensureOpen() {
    if (_isClosed) {
      throw StateError('이미 닫힌 필기 인식기는 사용할 수 없어.');
    }
  }
}
