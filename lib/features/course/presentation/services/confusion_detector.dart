import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_constants.dart';

class ConfusionDetector {
  int _pauseCount = 0;
  int _rewindCount = 0;
  int _skipCount = 0;
  String _lastEmotion = 'neutral';
  double _lastEmotionConfidence = 0;
  bool _gazeStill = false;
  bool _eyeLocked = false;
  DateTime? _lastTriggerTime;
  final void Function() onConfusionDetected;

  final List<String> _emotionWindow = [];
  static const int _windowSize = 3;
  static const _cooldownMinutes = 5;

  double _lastMlProbability = 0;
  String _lastModelType = 'rule_based';
  bool _mlPredictionPending = false;

  double _confusedRatio = 0;
  double _frustratedRatio = 0;
  int _emotionTransitions = 0;
  int _negEmotionStreak = 0;
  int _rewindSameSpot = 0;
  int _longPauseCount = 0;
  double _avgPauseDuration = 0;
  bool _speedDecrease = false;

  final List<double> _pauseDurations = [];
  final List<int> _rewindTargets = [];
  int _totalEmotionUpdates = 0;
  int _confusedUpdates = 0;
  int _frustratedUpdates = 0;
  int _currentNegStreak = 0;
  String _prevEmotion = 'neutral';

  ConfusionDetector({required this.onConfusionDetected});

  String get lastEmotion => _lastEmotion;
  double get lastMlProbability => _lastMlProbability;
  String get lastModelType => _lastModelType;

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

  void updateDetailedBehavior({
    double? pauseDuration,
    int? rewindTarget,
    bool? speedDecreased,
  }) {
    if (pauseDuration != null) {
      _pauseDurations.add(pauseDuration);
      if (pauseDuration > 10) _longPauseCount++;
      _avgPauseDuration = _pauseDurations.isEmpty
          ? 0
          : _pauseDurations.reduce((a, b) => a + b) / _pauseDurations.length;
    }
    if (rewindTarget != null) {
      for (final prev in _rewindTargets) {
        if ((prev - rewindTarget).abs() <= 10) {
          _rewindSameSpot++;
          break;
        }
      }
      _rewindTargets.add(rewindTarget);
    }
    if (speedDecreased == true) _speedDecrease = true;
  }

  void updateEmotion(String emotion, double confidence,
      {bool gazeStill = false, bool eyeLocked = false}) {
    _lastEmotion = emotion;
    _lastEmotionConfidence = confidence;
    _gazeStill = gazeStill;
    _eyeLocked = eyeLocked;

    if (confidence >= 0.3) {
      _emotionWindow.add(emotion);
    } else {
      _emotionWindow.add('neutral');
    }
    if (_emotionWindow.length > _windowSize) {
      _emotionWindow.removeAt(0);
    }

    _totalEmotionUpdates++;
    if (emotion == 'confused') _confusedUpdates++;
    if (emotion == 'frustrated') _frustratedUpdates++;

    if (_totalEmotionUpdates > 0) {
      _confusedRatio = _confusedUpdates / _totalEmotionUpdates;
      _frustratedRatio = _frustratedUpdates / _totalEmotionUpdates;
    }

    if (emotion != _prevEmotion) _emotionTransitions++;

    if (emotion == 'confused' || emotion == 'frustrated' || emotion == 'bored') {
      _currentNegStreak++;
      if (_currentNegStreak > _negEmotionStreak) {
        _negEmotionStreak = _currentNegStreak;
      }
    } else {
      _currentNegStreak = 0;
    }
    _prevEmotion = emotion;

    _evaluate();
  }

  Map<String, dynamic> _buildFeatureVector() {
    return {
      'pause_count': _pauseCount,
      'avg_pause_duration': _avgPauseDuration,
      'long_pause_count': _longPauseCount,
      'rewind_count': _rewindCount,
      'rewind_same_spot': _rewindSameSpot,
      'speed_decrease': _speedDecrease ? 1 : 0,
      'confused_ratio': _confusedRatio,
      'frustrated_ratio': _frustratedRatio,
      'emotion_transitions': _emotionTransitions,
      'neg_emotion_streak': _negEmotionStreak,
      'quiz_score': 50,
      'quiz_time': 30,
    };
  }

  void _evaluate() {
    if (_lastTriggerTime != null) {
      final elapsed = DateTime.now().difference(_lastTriggerTime!).inMinutes;
      if (elapsed < _cooldownMinutes) return;
    }

    final features = _buildFeatureVector();

    if (!_mlPredictionPending) {
      _requestMlPrediction(features);
    }

    final score = _calculateRuleScore();

    if (_lastMlProbability >= 0.6 || score >= 35) {
      _trigger();
    }
  }

  int _calculateRuleScore() {
    int score = 0;

    if (_pauseCount >= 3) score += 30;
    if (_rewindCount >= 2) score += 40;
    if (_rewindCount >= 1 && _pauseCount >= 2) score += 10;
    if (_skipCount == 0 && _pauseCount >= 2) score += 10;

    int negativeEmotionCount = _emotionWindow
        .where((e) => e == 'confused' || e == 'frustrated')
        .length;

    if (negativeEmotionCount == 3) {
      score += 40;
    } else if (negativeEmotionCount == 2) {
      score += 15;
    } else if (negativeEmotionCount == 1) {
      score += 5;
    }

    if (_lastEmotionConfidence >= 0.3) {
      switch (_lastEmotion) {
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

    if (_gazeStill && _eyeLocked) {
      if (_lastEmotion == 'confused' || _lastEmotion == 'frustrated') {
        score += 15;
      }
    } else if (_gazeStill) {
      if (_lastEmotion == 'confused' || _lastEmotion == 'frustrated') {
        score += 8;
      }
    }

    return score;
  }

  Future<void> _requestMlPrediction(Map<String, dynamic> features) async {
    _mlPredictionPending = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/confusion/predict'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'features': features,
          'threshold': 0.5,
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        _lastMlProbability = (result['probability'] as num?)?.toDouble() ?? 0;
        _lastModelType = result['modelType'] as String? ?? 'unknown';

        if (_lastMlProbability >= 0.6) {
          _trigger();
        }
      }
    } catch (_) {
    } finally {
      _mlPredictionPending = false;
    }
  }

  void _trigger() {
    if (_lastTriggerTime != null) {
      final elapsed = DateTime.now().difference(_lastTriggerTime!).inMinutes;
      if (elapsed < _cooldownMinutes) return;
    }

    _lastTriggerTime = DateTime.now();
    _resetCounters();
    onConfusionDetected();
  }

  void _resetCounters() {
    _pauseCount = 0;
    _rewindCount = 0;
    _skipCount = 0;
    _emotionWindow.clear();
    _totalEmotionUpdates = 0;
    _confusedUpdates = 0;
    _frustratedUpdates = 0;
    _confusedRatio = 0;
    _frustratedRatio = 0;
    _emotionTransitions = 0;
    _negEmotionStreak = 0;
    _currentNegStreak = 0;
    _longPauseCount = 0;
    _avgPauseDuration = 0;
    _pauseDurations.clear();
    _rewindSameSpot = 0;
    _rewindTargets.clear();
    _speedDecrease = false;
    _lastMlProbability = 0;
  }

  void reset() {
    _resetCounters();
    _lastEmotion = 'neutral';
    _lastEmotionConfidence = 0;
    _gazeStill = false;
    _eyeLocked = false;
    _lastTriggerTime = null;
    _prevEmotion = 'neutral';
    _lastModelType = 'rule_based';
  }
}
