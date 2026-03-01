import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {},
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleDailyNotification() async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Nhắc nhở học tập',
      body: 'Chào ngày mới! Bạn có bài học đang chờ, hãy bắt đầu ngay nhé!',
      scheduledDate: _nextInstanceOf8AM(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_learning_channel',
          'Daily Learning Reminders',
          channelDescription: 'Reminder to learn every day',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf8AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancel(int? id) async {
    if (id != null) {
      await flutterLocalNotificationsPlugin.cancel(id: id);
    }
  }

  Future<void> scheduleAssignmentNotification({
    required int? id,
    required String title,
    required DateTime dueDate,
  }) async {
    if (id == null) return;

    final deadline24h = dueDate.subtract(const Duration(hours: 24));
    if (deadline24h.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id + 200000,
        title: 'Nhắc nhở bài tập: $title',
        body: 'Còn 24 giờ nữa là đến hạn nộp bài. Hãy hoàn thành sớm nhé!',
        scheduledDate: tz.TZDateTime.from(deadline24h, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'assignment_reminder_channel',
            'Assignment Reminders',
            channelDescription: 'Reminders for assignment deadlines',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    final deadline1h = dueDate.subtract(const Duration(hours: 1));
    if (deadline1h.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id + 300000,
        title: 'Sắp đến hạn nộp bài: $title',
        body: 'Chỉ còn 1 giờ nữa! Nộp bài ngay để không bị trễ hạn.',
        scheduledDate: tz.TZDateTime.from(deadline1h, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'assignment_reminder_channel',
            'Assignment Reminders',
            channelDescription: 'Reminders for assignment deadlines',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showWarningNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'warning_channel',
          'Warning Notifications',
          channelDescription: 'Important warnings from teachers',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> scheduleExamNotification({
    required int id,
    required String subject,
    required String room,
    required DateTime startTime,
    required int minutesBefore,
  }) async {
    final scheduledDate = startTime.subtract(Duration(minutes: minutesBefore));
    if (scheduledDate.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: ' Nhắc nhở thi: $subject',
      body:
          'Bạn có kỳ thi lúc ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} tại phòng $room. Hãy chuẩn bị kỹ!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'exam_reminder_channel',
          'Exam Reminders',
          channelDescription: 'Important exam reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleClassNotification({
    required int id,
    required String subject,
    required String room,
    required DateTime startTime,
    required int minutesBefore,
    required bool isRepeating,
  }) async {
    final scheduledDate = startTime.subtract(Duration(minutes: minutesBefore));
    if (scheduledDate.isBefore(DateTime.now()) && !isRepeating) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'Nhắc nhở lớp học: $subject',
      body:
          'Bạn có lớp học lúc ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} tại phòng $room.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_reminder_channel',
          'Class Reminders',
          channelDescription: 'Reminders for class schedules',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: isRepeating
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
    );
  }

  Future<void> scheduleStudyReminder({
    required int id,
    required String subject,
    required DateTime startTime,
  }) async {
    final scheduledDate = startTime.subtract(const Duration(minutes: 5));
    if (scheduledDate.isBefore(DateTime.now())) return;

    final messages = [
      'Đến giờ học rồi! Cố gắng lên nhé! ',
      'Học tập là chìa khóa thành công! ',
      '5 phút mỗi ngày, kiến thức bay xa! ',
      'Bạn đã sẵn sàng chưa? Vào học thôi! ',
      'Kiến thức đang chờ bạn khám phá! ',
      'Một chút nỗ lực cho ngày hôm nay! ',
    ];

    final messageIndex =
        (subject.hashCode + startTime.millisecondsSinceEpoch) % messages.length;
    final body = messages[messageIndex];

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: '⏰ Nhắc nhở học tập: $subject',
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminder_channel',
          'Study Reminders',
          channelDescription: 'Encouraging study reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAllStudyReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
