import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/confusion_predictor.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final features = body['features'] as Map<String, dynamic>?;

    if (features == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'features object is required'},
      );
    }

    final predictor = ConfusionPredictor();

    if (!predictor.isReady) {
      _tryLoadWeights(predictor);
    }

    final probability = predictor.predict(features);
    final threshold = (body['threshold'] as num?)?.toDouble() ?? 0.5;
    final isConfused = probability >= threshold;

    return Response.json(body: {
      'success': true,
      'probability': probability,
      'isConfused': isConfused,
      'threshold': threshold,
      'modelType': predictor.isReady ? 'ml' : 'rule_based',
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Prediction failed: $e'},
    );
  }
}

void _tryLoadWeights(ConfusionPredictor predictor) {
  try {
    final mlpFile = File('assets/models/mlp_weights.json');
    if (mlpFile.existsSync()) {
      predictor.loadMlpWeights(mlpFile.readAsStringSync());
      return;
    }

    final lrFile = File('assets/models/lr_weights.json');
    if (lrFile.existsSync()) {
      predictor.loadLrWeights(lrFile.readAsStringSync());
    }
  } catch (_) {}
}
