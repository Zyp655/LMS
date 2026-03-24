import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final params = context.request.uri.queryParameters;
    final lessonId = int.tryParse(params['lessonId'] ?? '');

    if (lessonId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'lessonId is required'},
      );
    }

    final db = context.read<AppDatabase>();

    final logs = await (db.select(db.confusionLogs)
          ..where((l) => l.lessonId.equals(lessonId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();

    final allFeatures = <Map<String, dynamic>>[];
    for (final log in logs) {
      final features = jsonDecode(log.featuresJson) as List<dynamic>;
      for (final f in features) {
        final feature = Map<String, dynamic>.from(f as Map);
        feature['userId'] = log.userId;
        feature['sessionId'] = log.id;
        feature['createdAt'] = log.createdAt.toIso8601String();
        allFeatures.add(feature);
      }
    }

    final aggregated = _aggregateFeatures(allFeatures);

    final confusionHotspots = _findHotspots(allFeatures);

    return Response.json(body: {
      'lessonId': lessonId,
      'totalSessions': logs.length,
      'totalSegments': allFeatures.length,
      'aggregatedFeatures': aggregated,
      'confusionHotspots': confusionHotspots,
      'rawFeatures': allFeatures,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to get confusion analytics: $e'},
    );
  }
}

Map<String, dynamic> _aggregateFeatures(List<Map<String, dynamic>> features) {
  if (features.isEmpty) {
    return {
      'avg_pause_count': 0,
      'avg_rewind_count': 0,
      'avg_confused_ratio': 0,
      'avg_neg_streak': 0,
      'confusion_rate': 0,
    };
  }

  double sum(String key) =>
      features.fold(0.0, (s, f) => s + ((f[key] as num?)?.toDouble() ?? 0.0));

  final count = features.length;
  final confusedSegments = features.where((f) => (f['ground_truth'] as int? ?? 0) >= 1).length;

  return {
    'avg_pause_count': sum('pause_count') / count,
    'avg_pause_duration': sum('avg_pause_duration') / count,
    'avg_long_pause_count': sum('long_pause_count') / count,
    'avg_rewind_count': sum('rewind_count') / count,
    'avg_rewind_same_spot': sum('rewind_same_spot') / count,
    'speed_decrease_rate': sum('speed_decrease') / count,
    'avg_confused_ratio': sum('confused_ratio') / count,
    'avg_frustrated_ratio': sum('frustrated_ratio') / count,
    'avg_emotion_transitions': sum('emotion_transitions') / count,
    'avg_neg_streak': sum('neg_emotion_streak') / count,
    'confusion_rate': confusedSegments / count,
    'total_segments': count,
    'confused_segments': confusedSegments,
  };
}

List<Map<String, dynamic>> _findHotspots(List<Map<String, dynamic>> features) {
  final hotspots = <Map<String, dynamic>>[];

  final bySegment = <int, List<Map<String, dynamic>>>{};
  for (final f in features) {
    final start = f['startSec'] as int? ?? 0;
    bySegment.putIfAbsent(start, () => []).add(f);
  }

  for (final entry in bySegment.entries) {
    final segments = entry.value;
    final confusedCount = segments.where((s) => (s['ground_truth'] as int? ?? 0) >= 1).length;
    final confusionRate = segments.isEmpty ? 0.0 : confusedCount / segments.length;

    if (confusionRate >= 0.3) {
      final avgRewind = segments.fold(0.0, (s, f) => s + ((f['rewind_count'] as num?)?.toDouble() ?? 0.0)) / segments.length;

      hotspots.add({
        'startSec': entry.key,
        'endSec': (segments.first['endSec'] as int?) ?? entry.key + 300,
        'confusionRate': confusionRate,
        'sessionCount': segments.length,
        'confusedCount': confusedCount,
        'avgRewindCount': avgRewind,
      });
    }
  }

  hotspots.sort((a, b) => (b['confusionRate'] as double).compareTo(a['confusionRate'] as double));
  return hotspots;
}
