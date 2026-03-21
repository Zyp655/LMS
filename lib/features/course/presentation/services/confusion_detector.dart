class ConfusionDetector {
  int _pauseCount = 0;
  int _rewindCount = 0;
  int _skipCount = 0;
  String _lastEmotion = 'neutral';
  double _lastEmotionConfidence = 0;
  DateTime? _lastTriggerTime;
  final void Function() onConfusionDetected;

  static const _cooldownMinutes = 5;
  static const _threshold = 60;

  ConfusionDetector({required this.onConfusionDetected});

  void updateVideoBehavior({
    required int pauseCount,
    required int rewindCount,
    required int skipCount,
  }) {
    _pauseCount = pauseCount;
    _rewindCount = rewindCount;
    _skipCount = skipCount;
    _evaluate();
  }

  void updateEmotion(String emotion, double confidence) {
    _lastEmotion = emotion;
    _lastEmotionConfidence = confidence;
    _evaluate();
  }

  void _evaluate() {
    if (_lastTriggerTime != null) {
      final elapsed = DateTime.now().difference(_lastTriggerTime!).inMinutes;
      if (elapsed < _cooldownMinutes) return;
    }

    int score = 0;

    if (_pauseCount >= 3) score += 30;
    if (_rewindCount >= 2) score += 40;
    if (_rewindCount >= 1 && _pauseCount >= 2) score += 10;
    if (_skipCount == 0 && _pauseCount >= 2) score += 10;

    if (_lastEmotionConfidence >= 0.5) {
      switch (_lastEmotion) {
        case 'confused':
          score += 40;
          break;
        case 'frustrated':
          score += 35;
          break;
        case 'bored':
          score += 20;
          break;
        case 'focused':
          score -= 20;
          break;
        case 'happy':
          score -= 10;
          break;
      }
    }

    if (score >= _threshold) {
      _lastTriggerTime = DateTime.now();
      _pauseCount = 0;
      _rewindCount = 0;
      _skipCount = 0;
      onConfusionDetected();
    }
  }

  void reset() {
    _pauseCount = 0;
    _rewindCount = 0;
    _skipCount = 0;
    _lastEmotion = 'neutral';
    _lastEmotionConfidence = 0;
    _lastTriggerTime = null;
  }
}
