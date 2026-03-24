import 'dart:convert';
import 'dart:io';

import 'package:backend/database/database.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final userId = body['userId'] as int?;
    final lessonId = body['lessonId'] as int?;

    if (userId == null || lessonId == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'userId and lessonId are required'},
      );
    }

    final events = body['events'] as List<dynamic>? ?? [];
    final emotionTimeline = body['emotionTimeline'] as List<dynamic>? ?? [];
    final selfReports = body['selfReports'] as List<dynamic>? ?? [];
    final features = body['features'] as List<dynamic>? ?? [];
    final sessionDuration = body['sessionDuration'] as int? ?? 0;

    final db = context.read<AppDatabase>();

    await db.into(db.confusionLogs).insert(
      ConfusionLogsCompanion.insert(
        userId: userId,
        lessonId: lessonId,
        eventsJson: jsonEncode(events),
        emotionTimelineJson: jsonEncode(emotionTimeline),
        selfReportsJson: jsonEncode(selfReports),
        featuresJson: jsonEncode(features),
        sessionDuration: Value(sessionDuration),
        createdAt: DateTime.now(),
      ),
    );

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to save confusion log: $e'},
    );
  }
}

