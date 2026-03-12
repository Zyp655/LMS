import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alarmm/core/error/failures.dart';
import 'package:alarmm/features/notifications/domain/entities/notification_entity.dart';
import 'package:alarmm/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:alarmm/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:alarmm/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:alarmm/features/notifications/domain/usecases/delete_notification_usecase.dart';
import 'package:alarmm/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:alarmm/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:alarmm/features/notifications/presentation/bloc/notification_event.dart';
import 'package:alarmm/features/notifications/presentation/bloc/notification_state.dart';

// ── Mocks ──
class MockGetNotificationsUseCase extends Mock
    implements GetNotificationsUseCase {}

class MockMarkNotificationReadUseCase extends Mock
    implements MarkNotificationReadUseCase {}

class MockMarkAllNotificationsReadUseCase extends Mock
    implements MarkAllNotificationsReadUseCase {}

class MockDeleteNotificationUseCase extends Mock
    implements DeleteNotificationUseCase {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

void main() {
  late NotificationBloc bloc;
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockMarkNotificationReadUseCase mockMarkRead;
  late MockMarkAllNotificationsReadUseCase mockMarkAllRead;
  late MockDeleteNotificationUseCase mockDelete;
  late MockGetUnreadCountUseCase mockUnreadCount;

  final tNotification = NotificationEntity(
    id: 1,
    userId: 1,
    type: 'new_course',
    title: 'Khóa học mới',
    message: 'Đã thêm Flutter Basics',
    isRead: false,
    createdAt: DateTime(2026, 2, 20),
  );

  final tNotificationRead = NotificationEntity(
    id: 1,
    userId: 1,
    type: 'new_course',
    title: 'Khóa học mới',
    message: 'Đã thêm Flutter Basics',
    isRead: true,
    createdAt: DateTime(2026, 2, 20),
  );

  final tNotifications = [tNotification];

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockMarkRead = MockMarkNotificationReadUseCase();
    mockMarkAllRead = MockMarkAllNotificationsReadUseCase();
    mockDelete = MockDeleteNotificationUseCase();
    mockUnreadCount = MockGetUnreadCountUseCase();
    bloc = NotificationBloc(
      getNotifications: mockGetNotifications,
      markNotificationRead: mockMarkRead,
      markAllNotificationsRead: mockMarkAllRead,
      deleteNotification: mockDelete,
      getUnreadCount: mockUnreadCount,
    );
  });

  tearDown(() => bloc.close());

  test('initial state is NotificationInitial', () {
    expect(bloc.state, isA<NotificationInitial>());
  });

  // ── Load Notifications ──
  group('LoadNotifications', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits [Loading, Loaded] when succeeds',
      build: () {
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            unreadOnly: any(named: 'unreadOnly'),
          ),
        ).thenAnswer((_) async => Right(tNotifications));
        when(
          () => mockUnreadCount(any()),
        ).thenAnswer((_) async => const Right(1));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications(userId: 1)),
      expect: () => [isA<NotificationLoading>(), isA<NotificationsLoaded>()],
      verify: (_) {
        verify(
          () => mockGetNotifications(userId: 1, unreadOnly: false),
        ).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [Loading, Error] when fails',
      build: () {
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            unreadOnly: any(named: 'unreadOnly'),
          ),
        ).thenAnswer((_) async => Left(ServerFailure('Server error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications(userId: 1)),
      expect: () => [isA<NotificationLoading>(), isA<NotificationError>()],
    );
  });

  // ── Mark Notification Read ──
  group('MarkNotificationRead', () {
    blocTest<NotificationBloc, NotificationState>(
      'updates notification isRead in loaded state',
      build: () {
        when(
          () => mockMarkRead(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          NotificationsLoaded(notifications: tNotifications, unreadCount: 1),
      act: (bloc) => bloc.add(const MarkNotificationRead(1)),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.first.isRead, 'isRead', true)
            .having((s) => s.unreadCount, 'unreadCount', 0),
      ],
    );
  });

  // ── Mark All Read ──
  group('MarkAllNotificationsRead', () {
    blocTest<NotificationBloc, NotificationState>(
      'marks all as read and emits success',
      build: () {
        when(
          () => mockMarkAllRead(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          NotificationsLoaded(notifications: tNotifications, unreadCount: 1),
      act: (bloc) => bloc.add(const MarkAllNotificationsRead(1)),
      expect: () => [
        isA<NotificationsLoaded>().having(
          (s) => s.unreadCount,
          'unreadCount',
          0,
        ),
        isA<NotificationActionSuccess>(),
      ],
    );
  });

  // ── Delete Notification ──
  group('DeleteNotification', () {
    blocTest<NotificationBloc, NotificationState>(
      'removes notification from loaded state',
      build: () {
        when(
          () => mockDelete(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          NotificationsLoaded(notifications: tNotifications, unreadCount: 1),
      act: (bloc) => bloc.add(const DeleteNotification(1)),
      expect: () => [
        isA<NotificationsLoaded>().having(
          (s) => s.notifications,
          'notifications',
          isEmpty,
        ),
      ],
    );
  });
}
