import 'package:dart_frog/dart_frog.dart';
Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'message': 'Quiz API',
      'endpoints': {
        'POST /quiz/generate': 'Generate quiz with AI',
      },
    },
  );
}
