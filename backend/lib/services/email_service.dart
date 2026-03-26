import 'package:backend/database/database.dart';
import 'package:backend/helpers/env_helper.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static String get _smtpEmail {
    return loadEnv()['SMTP_EMAIL'] ?? '';
  }

  static String get _smtpPassword {
    return loadEnv()['SMTP_PASSWORD'] ?? '';
  }

  static Future<void> notifyNewAssignment({
    required AppDatabase db,
    required List<int> studentIds,
    required String assignmentTitle,
    required String className,
    required DateTime dueDate,
  }) async {
    final emails = await _getEmails(db, studentIds);
    if (emails.isEmpty) return;

    final dueDateStr =
        '${dueDate.day}/${dueDate.month}/${dueDate.year} ${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}';

    final html = _buildTemplate(
      icon: '📝',
      color: '#14B8A6',
      heading: 'Bài tập mới',
      body: '''
        <p>Lớp <strong>$className</strong> có bài tập mới:</p>
        <div style="background:#F0FDFA;border-radius:12px;padding:16px;margin:12px 0;">
          <p style="font-size:18px;font-weight:bold;color:#0D9488;margin:0 0 8px;">$assignmentTitle</p>
          <p style="margin:0;color:#64748B;">⏰ Hạn nộp: <strong>$dueDateStr</strong></p>
        </div>
        <p>Hãy mở ứng dụng để xem chi tiết và nộp bài đúng hạn.</p>
      ''',
    );

    _sendBatch(
      emails: emails,
      subject: '📝 Bài tập mới: $assignmentTitle',
      html: html,
    );
  }

  static Future<void> notifyNewQuiz({
    required AppDatabase db,
    required List<int> studentIds,
    required String quizTopic,
    required String difficulty,
    required int questionCount,
  }) async {
    final emails = await _getEmails(db, studentIds);
    if (emails.isEmpty) return;

    final difficultyLabel = switch (difficulty) {
      'easy' => '🟢 Dễ',
      'medium' => '🟡 Trung bình',
      'hard' => '🔴 Khó',
      _ => difficulty,
    };

    final html = _buildTemplate(
      icon: '🧩',
      color: '#3B82F6',
      heading: 'Quiz mới',
      body: '''
        <p>Giáo viên vừa tạo quiz mới cho bạn:</p>
        <div style="background:#EFF6FF;border-radius:12px;padding:16px;margin:12px 0;">
          <p style="font-size:18px;font-weight:bold;color:#2563EB;margin:0 0 8px;">$quizTopic</p>
          <p style="margin:0;color:#64748B;">📊 Độ khó: <strong>$difficultyLabel</strong></p>
          <p style="margin:0;color:#64748B;">❓ Số câu hỏi: <strong>$questionCount</strong></p>
        </div>
        <p>Hãy mở ứng dụng để làm quiz ngay!</p>
      ''',
    );

    _sendBatch(
      emails: emails,
      subject: '🧩 Quiz mới: $quizTopic',
      html: html,
    );
  }

  static Future<List<String>> _getEmails(
    AppDatabase db,
    List<int> userIds,
  ) async {
    if (userIds.isEmpty) return [];
    final users = await (db.select(db.users)
          ..where((u) => u.id.isIn(userIds)))
        .get();
    return users.map((u) => u.email).where((e) => e.isNotEmpty).toList();
  }

  static void _sendBatch({
    required List<String> emails,
    required String subject,
    required String html,
  }) {
    final username = _smtpEmail;
    final password = _smtpPassword;
    if (username.isEmpty || password.isEmpty) return;

    Future(() async {
      final smtpServer = gmail(username, password);
      for (final email in emails) {
        try {
          final message = Message()
            ..from = Address(username, 'EduAlarm LMS')
            ..recipients.add(email)
            ..subject = subject
            ..html = html;
          await send(message, smtpServer);
          print('[EMAIL] Sent to $email: $subject');
        } catch (e) {
          print('[EMAIL] Failed $email: $e');
        }
      }
    });
  }

  static String _buildTemplate({
    required String icon,
    required String color,
    required String heading,
    required String body,
  }) {
    return '''
      <div style="font-family:'Segoe UI',Arial,sans-serif;max-width:520px;margin:0 auto;padding:0;">
        <div style="background:$color;padding:24px;border-radius:16px 16px 0 0;text-align:center;">
          <span style="font-size:40px;">$icon</span>
          <h1 style="color:#fff;margin:12px 0 0;font-size:22px;">$heading</h1>
        </div>
        <div style="background:#fff;padding:24px;border:1px solid #E2E8F0;border-top:none;border-radius:0 0 16px 16px;">
          $body
        </div>
        <p style="text-align:center;color:#94A3B8;font-size:12px;margin-top:16px;">
          Email tự động từ EduAlarm LMS — Vui lòng không trả lời email này.
        </p>
      </div>
    ''';
  }
}
