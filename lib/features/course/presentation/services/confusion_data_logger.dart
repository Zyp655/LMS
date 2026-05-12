import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_constants.dart';
import 'confusion_detector.dart';

class ConfusionEvent {
  final String type;
  final int timestampSeconds;
  final double? duration;
  final double? distance;
  final double? playbackSpeed;
  final String? emotion;
  final double? emotionConfidence;
  final DateTime createdAt;

  ConfusionEvent({
    required this.type,
    required this.timestampSeconds,
    this.duration,
    this.distance,
    this.playbackSpeed,
    this.emotion,
    this.emotionConfidence,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestampSeconds': timestampSeconds,
    'duration': duration,
    'distance': distance,
    'playbackSpeed': playbackSpeed,
    'emotion': emotion,
    'emotionConfidence': emotionConfidence,
    'createdAt': createdAt.toIso8601String(),
  };
}

class EmotionSnapshot {
  final int timestampSeconds;
  final String emotion;
  final double confidence;

  EmotionSnapshot({
    required this.timestampSeconds,
    required this.emotion,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    't': timestampSeconds,
    'emotion': emotion,
    'confidence': confidence,
  };
}

class SelfReport {
  final int timestampSeconds;
  final int level;
  final DateTime createdAt;

  SelfReport({
    required this.timestampSeconds,
    required this.level,
  }) : createdAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'timestampSeconds': timestampSeconds,
    'level': level,
    'createdAt': createdAt.toIso8601String(),
  };
}

class ConfusionDataLogger {
  final int userId;
  final int lessonId;
  final List<ConfusionEvent> _events = [];
  final List<EmotionSnapshot> _emotionTimeline = [];
  final List<SelfReport> _selfReports = [];
  final List<int> _rewindTargets = [];

  DateTime? _lastPauseStart;
  double _currentSpeed = 1.0;
  int _currentPositionSeconds = 0;

  ConfusionDetector? _detector;
  double _lastQuizScore = 50;
  double _lastQuizTime = 30;

  ConfusionDataLogger({
    required this.userId,
    required this.lessonId,
  });

  void attachDetector(ConfusionDetector detector) {
    _detector = detector;
  }

  void updateQuizResult(double score, double timeSeconds) {
    _lastQuizScore = score;
    _lastQuizTime = timeSeconds;
  }

  void updatePosition(int positionSeconds) {
    _currentPositionSeconds = positionSeconds;
  }

  void onPause(int positionSeconds) {
    _lastPauseStart = DateTime.now();
    _currentPositionSeconds = positionSeconds;
  }

  void onResume(int positionSeconds) {
    if (_lastPauseStart != null) {
      final duration = DateTime.now().difference(_lastPauseStart!).inMilliseconds / 1000.0;
      _events.add(ConfusionEvent(
        type: 'pause',
        timestampSeconds: _currentPositionSeconds,
        duration: duration,
        playbackSpeed: _currentSpeed,
      ));
      _detector?.updateDetailedBehavior(pauseDuration: duration);
      _lastPauseStart = null;
    }
    _currentPositionSeconds = positionSeconds;
  }

  void onRewind(int fromSeconds, int toSeconds) {
    final distance = (fromSeconds - toSeconds).toDouble();
    _rewindTargets.add(toSeconds);
    _events.add(ConfusionEvent(
      type: 'rewind',
      timestampSeconds: fromSeconds,
      distance: distance,
      playbackSpeed: _currentSpeed,
    ));
    _detector?.updateDetailedBehavior(rewindTarget: toSeconds);
  }

  void onSkip(int fromSeconds, int toSeconds) {
    final distance = (toSeconds - fromSeconds).toDouble();
    _events.add(ConfusionEvent(
      type: 'skip',
      timestampSeconds: fromSeconds,
      distance: distance,
    ));
  }

  void onSpeedChange(double newSpeed) {
    final oldSpeed = _currentSpeed;
    _currentSpeed = newSpeed;
    _events.add(ConfusionEvent(
      type: 'speed_change',
      timestampSeconds: _currentPositionSeconds,
      playbackSpeed: newSpeed,
      duration: oldSpeed,
    ));
    if (newSpeed < oldSpeed) {
      _detector?.updateDetailedBehavior(speedDecreased: true);
    }
  }

  void addEmotionSnapshot(int positionSeconds, String emotion, double confidence) {
    _emotionTimeline.add(EmotionSnapshot(
      timestampSeconds: positionSeconds,
      emotion: emotion,
      confidence: confidence,
    ));
  }

  void addSelfReport(int positionSeconds, int level) {
    _selfReports.add(SelfReport(
      timestampSeconds: positionSeconds,
      level: level,
    ));
  }

  int getRewindCountToSameSpot({int toleranceSeconds = 10}) {
    if (_rewindTargets.length < 2) return 0;
    int count = 0;
    for (int i = 0; i < _rewindTargets.length; i++) {
      for (int j = i + 1; j < _rewindTargets.length; j++) {
        if ((_rewindTargets[i] - _rewindTargets[j]).abs() <= toleranceSeconds) {
          count++;
        }
      }
    }
    return count;
  }

  Map<String, dynamic> extractFeaturesForSegment(int startSec, int endSec) {
    final segEvents = _events.where(
      (e) => e.timestampSeconds >= startSec && e.timestampSeconds < endSec,
    ).toList();

    final pauses = segEvents.where((e) => e.type == 'pause').toList();
    final rewinds = segEvents.where((e) => e.type == 'rewind').toList();
    final speedChanges = segEvents.where((e) => e.type == 'speed_change').toList();

    final segEmotions = _emotionTimeline.where(
      (e) => e.timestampSeconds >= startSec && e.timestampSeconds < endSec,
    ).toList();

    final segReports = _selfReports.where(
      (r) => r.timestampSeconds >= startSec && r.timestampSeconds < endSec,
    ).toList();

    final totalEmotions = segEmotions.length;
    final confusedCount = segEmotions.where((e) => e.emotion == 'confused').length;
    final frustratedCount = segEmotions.where((e) => e.emotion == 'frustrated').length;

    int emotionTransitions = 0;
    for (int i = 1; i < segEmotions.length; i++) {
      if (segEmotions[i].emotion != segEmotions[i - 1].emotion) {
        emotionTransitions++;
      }
    }

    int negStreak = 0;
    int maxNegStreak = 0;
    for (final e in segEmotions) {
      if (e.emotion == 'confused' || e.emotion == 'frustrated' || e.emotion == 'bored') {
        negStreak++;
        if (negStreak > maxNegStreak) maxNegStreak = negStreak;
      } else {
        negStreak = 0;
      }
    }

    final segRewindTargets = rewinds.map((r) => r.timestampSeconds).toList();
    int rewindSameSpot = 0;
    for (int i = 0; i < segRewindTargets.length; i++) {
      for (int j = i + 1; j < segRewindTargets.length; j++) {
        if ((segRewindTargets[i] - segRewindTargets[j]).abs() <= 10) {
          rewindSameSpot++;
          break;
        }
      }
    }

    bool speedDecrease = speedChanges.any(
      (e) => e.playbackSpeed != null && e.duration != null && e.playbackSpeed! < e.duration!,
    );

    final avgPauseDuration = pauses.isEmpty
        ? 0.0
        : pauses.map((p) => p.duration ?? 0).reduce((a, b) => a + b) / pauses.length;

    final longPauses = pauses.where((p) => (p.duration ?? 0) > 10).length;

    int groundTruthLabel = 0;
    if (segReports.isNotEmpty) {
      groundTruthLabel = segReports.map((r) => r.level).reduce((a, b) => a > b ? a : b);
    }

    return {
      'startSec': startSec,
      'endSec': endSec,
      'pause_count': pauses.length,
      'avg_pause_duration': avgPauseDuration,
      'long_pause_count': longPauses,
      'rewind_count': rewinds.length,
      'rewind_same_spot': rewindSameSpot,
      'speed_decrease': speedDecrease ? 1 : 0,
      'confused_ratio': totalEmotions > 0 ? confusedCount / totalEmotions : 0.0,
      'frustrated_ratio': totalEmotions > 0 ? frustratedCount / totalEmotions : 0.0,
      'emotion_transitions': emotionTransitions,
      'neg_emotion_streak': maxNegStreak,
      'quiz_score': _lastQuizScore,
      'quiz_time': _lastQuizTime,
      'ground_truth': groundTruthLabel,
    };
  }

  List<Map<String, dynamic>> extractAllFeatures(int totalDurationSeconds, {int segmentSize = 300}) {
    final segments = <Map<String, dynamic>>[];
    for (int start = 0; start < totalDurationSeconds; start += segmentSize) {
      final end = (start + segmentSize).clamp(0, totalDurationSeconds);
      segments.add(extractFeaturesForSegment(start, end));
    }
    return segments;
  }

  Future<void> flush(int totalDurationSeconds) async {
    if (_events.isEmpty && _emotionTimeline.isEmpty && _selfReports.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final features = extractAllFeatures(totalDurationSeconds);

      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/confusion/log'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'lessonId': lessonId,
          'events': _events.map((e) => e.toJson()).toList(),
          'emotionTimeline': _emotionTimeline.map((e) => e.toJson()).toList(),
          'selfReports': _selfReports.map((r) => r.toJson()).toList(),
          'features': features,
          'sessionDuration': totalDurationSeconds,
        }),
      );
    } catch (_) {}
  }

  void reset() {
    _events.clear();
    _emotionTimeline.clear();
    _selfReports.clear();
    _rewindTargets.clear();
    _lastPauseStart = null;
    _currentSpeed = 1.0;
  }
}
