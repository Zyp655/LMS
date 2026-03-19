import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final moduleId = int.tryParse(id);
  if (moduleId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'ID module không hợp lệ'},
    );
  }

  try {
    final db = context.read<AppDatabase>();

    final quizzes = await (db.select(db.quizzes)
          ..where((q) => q.moduleId.equals(moduleId))
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)]))
        .get();

    final result = <Map<String, dynamic>>[];
    for (final quiz in quizzes) {
      final questions = await (db.select(db.quizQuestions)
            ..where((q) => q.quizId.equals(quiz.id))
            ..orderBy([(q) => OrderingTerm.asc(q.orderIndex)]))
          .get();

      result.add({
        'id': quiz.id,
        'moduleId': quiz.moduleId,
        'quiz': {
          'id': quiz.id,
          'topic': quiz.topic,
          'difficulty': quiz.difficulty,
          'questionCount': quiz.questionCount,
        },
        'topic': quiz.topic,
        'difficulty': quiz.difficulty,
        'questionCount': quiz.questionCount,
        'createdAt': quiz.createdAt.toIso8601String(),
        'questions': questions.map((q) {
          List<dynamic> optionsList;
          try {
            optionsList = jsonDecode(q.options) as List<dynamic>;
          } catch (_) {
            optionsList = [q.options];
          }
          return {
            'id': q.id,
            'question': q.question,
            'questionType': q.questionType,
            'options': optionsList,
            'correctIndex': q.correctIndex,
            'correctAnswer': q.correctAnswer,
            'explanation': q.explanation,
          };
        }).toList(),
      });
    }

    return Response.json(
      body: {'quizzes': result},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Lỗi khi tải quiz: $e'},
    );
  }
}
