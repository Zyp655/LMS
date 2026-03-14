import 'package:backend/database/database.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final startTime = DateTime.now();

  String dbStatus;
  int dbLatencyMs;
  try {
    final db = context.read<AppDatabase>();
    final sw = Stopwatch()..start();

    await (db.select(db.users)..limit(1)).get();
    sw.stop();
    dbLatencyMs = sw.elapsedMilliseconds;
    dbStatus = 'connected';
  } catch (e) {
    dbStatus = 'error';
    dbLatencyMs = -1;
  }

  final overallStatus = dbStatus == 'connected' ? 'healthy' : 'degraded';

  return Response.json(
    statusCode: overallStatus == 'healthy' ? 200 : 503,
    body: {
      'status': overallStatus,
      'timestamp': startTime.toIso8601String(),
      'version': '1.0.0',
      'checks': {
        'database': {
          'status': dbStatus,
          'latencyMs': dbLatencyMs,
        },
      },
    },
  );
}
