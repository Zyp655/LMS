import 'dart:convert';
import 'package:backend/database/database.dart';
import 'package:drift/drift.dart';
import 'package:dotenv/dotenv.dart';
import 'ai_service.dart';

class VideoSegmentService {
  final AppDatabase db;

  VideoSegmentService(this.db);

  Future<void> processLesson(int lessonId) async {
    final lesson = await (db.select(db.lessons)
          ..where((l) => l.id.equals(lessonId)))
        .getSingleOrNull();
    if (lesson == null) throw Exception('Lesson not found');
    if (lesson.contentUrl == null || lesson.contentUrl!.isEmpty) {
      throw Exception('Lesson has no video URL');
    }

    final existing = await (db.select(db.videoSegments)
          ..where((s) => s.lessonId.equals(lessonId)))
        .get();
    if (existing.isNotEmpty) return;

    final env = DotEnv(includePlatformEnvironment: true)..load();
    final apiKey = env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception('OPENAI_API_KEY not configured');
    final aiService = AIService(openaiApiKey: apiKey);

    final transcript = await _extractTranscript(aiService, lesson.contentUrl!);
    if (transcript.isEmpty) throw Exception('Could not extract transcript');

    final totalDurationSec = lesson.durationMinutes * 60.0;

    final segments =
        await _semanticSegmentation(aiService, transcript, totalDurationSec);

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final quiz = await _generateSegmentQuiz(
        aiService,
        seg['transcript'] as String,
        i,
        seg['summary'] as String? ?? '',
      );

      await db.into(db.videoSegments).insert(VideoSegmentsCompanion.insert(
            lessonId: lessonId,
            segmentIndex: i,
            startTimestamp: (seg['start'] as num).toDouble(),
            endTimestamp: (seg['end'] as num).toDouble(),
            transcript: seg['transcript'] as String,
            summary: Value(seg['summary'] as String?),
            quizQuestion: jsonEncode(quiz),
            createdAt: DateTime.now(),
          ));
    }
  }

  Future<String> _extractTranscript(
      AIService aiService, String videoUrl) async {
    try {
      final text = await aiService.chatWithAssistant(
        history: [],
        question:
            'Extract and transcribe the audio content from this video lecture. '
            'Return the full transcript with timestamps in format [MM:SS]. '
            'Video URL: $videoUrl',
      );
      return text;
    } catch (e) {
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> _semanticSegmentation(
    AIService aiService,
    String transcript,
    double totalDurationSec,
  ) async {
    final text = await aiService.chatWithAssistant(
      history: [],
      question:
          '''Analyze this lecture transcript and divide it into knowledge segments of 5-7 minutes each.
For each segment, provide:
- start: start time in seconds
- end: end time in seconds
- transcript: the text content of that segment
- summary: a brief 1-sentence summary

Total video duration: ${totalDurationSec.toInt()} seconds.

Return ONLY valid JSON array format:
[{"start": 0, "end": 360, "transcript": "...", "summary": "..."}, ...]

Transcript:
$transcript''',
    );

    try {
      final jsonStr = _extractJsonArray(text);
      final parsed = jsonDecode(jsonStr) as List;
      return parsed.cast<Map<String, dynamic>>();
    } catch (_) {
      final segmentDuration = 360.0;
      final segments = <Map<String, dynamic>>[];
      var start = 0.0;
      int idx = 0;
      while (start < totalDurationSec) {
        final end = (start + segmentDuration).clamp(0.0, totalDurationSec);
        segments.add({
          'start': start,
          'end': end,
          'transcript': transcript.length > 200
              ? transcript.substring(
                  (idx * 200).clamp(0, transcript.length).toInt(),
                  ((idx + 1) * 200).clamp(0, transcript.length).toInt(),
                )
              : transcript,
          'summary': 'Segment ${idx + 1}',
        });
        start = end;
        idx++;
        if (start >= totalDurationSec) break;
      }
      return segments;
    }
  }

  Future<Map<String, dynamic>> _generateSegmentQuiz(
    AIService aiService,
    String segmentTranscript,
    int index,
    String summary,
  ) async {
    final text = await aiService.chatWithAssistant(
      history: [],
      question:
          '''Based on this lecture segment, create exactly 1 multiple-choice question to test understanding.

Segment content: $segmentTranscript
Summary: $summary

Return ONLY valid JSON format:
{"question": "...", "options": ["A...", "B...", "C...", "D..."], "correctIndex": 0}

Rules:
- Question must be in Vietnamese
- 4 options (A, B, C, D)
- correctIndex is 0-based
- Focus on key concepts from this segment''',
    );

    try {
      final jsonStr = _extractJsonObject(text);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {
        'question': 'Câu hỏi kiểm tra phân đoạn ${index + 1}',
        'options': [
          'Đáp án A',
          'Đáp án B',
          'Đáp án C',
          'Đáp án D',
        ],
        'correctIndex': 0,
      };
    }
  }

  String _extractJsonArray(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return '[]';
  }

  String _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return '{}';
  }
}
